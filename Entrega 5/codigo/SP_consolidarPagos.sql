CREATE PROCEDURE sp_consolidarPagos(@nombre_consorcio NVARCHAR(50), @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	DECLARE @fecha_actual DATE = GETDATE(); -- deberiamos estar en el dia del 2do vto
	DECLARE @quintoDiaHabil DATE = dbo.fn_5TODIAHABIL(@fecha_actual);
	DECLARE @anio INT = YEAR(@fecha_actual);
	DECLARE @mes INT = MONTH(@fecha_actual);

	DECLARE @vencimiento1 DATE, @vencimiento2 DATE;
	SELECT 
		@vencimiento1 = vencimiento1,
		@vencimiento2 = vencimiento2
	FROM 
		expensa 
	WHERE 
		id_consorcio = @id_consorcio AND
	  	anio = @anio AND mes = @mes;
	
	IF @vencimiento2 IS NULL
	BEGIN
		RAISERROR('no existe fecha de vencimiento en el sistema, abortando...', 16, 2);
		RETURN;
	END;

	IF @debug = 1
	BEGIN
		SET @fecha_actual = @vencimiento2;
	END;

	IF @fecha_actual <> @vencimiento2
	BEGIN
		RAISERROR('la fecha no coincide con el vencimiento2', 16, 3);
		RETURN;
	END;


	DECLARE @mes_anterior INT = @mes - 1;
	DECLARE @anio_del_mes_anterior INT = @anio;
	IF @mes_anterior = 0
	BEGIN
	    SET @mes_anterior = 12;
	    SET @anio_del_mes_anterior = @anio_del_mes_anterior - 1;
	END;

	DECLARE @vencimiento2_anterior DATE = (SELECT vencimiento2
								  		   FROM expensa 
								  		   WHERE
								  		   		id_consorcio = @id_consorcio AND
								  				anio = @anio_del_mes_anterior AND mes = @mes_anterior);
	IF @vencimiento2_anterior IS NULL
	BEGIN
		-- fallback value
		SET @vencimiento2_anterior = DATEFROMPARTS(@anio_del_mes_anterior, @mes_anterior, 1);
	END;


	-- Crear tabla temporal con los resultados de los CTEs
	DECLARE @tabla_intermedia TABLE 
	(
	    id_uf INT PRIMARY KEY,
	    pagos_entermino DECIMAL(10,2),
	    pagos_entre_vtos DECIMAL(10,2),
	    saldo_al_venc1 DECIMAL(10,2),
	    interes1 DECIMAL(10,2),
	    saldo_al_venc2 DECIMAL(10,2),
	    interes2 DECIMAL(10,2)
	);

	-- Calcular todo una sola vez y guardar en la tabla intermedia
	WITH
		-- PERIODO ACTUAL (todas las uf existen)
		prorateo_periodo AS (SELECT 
						        id_uf,
						        (monto_ext + monto_ord + monto_coc + monto_bau) AS gastos_mes
						     FROM 
						    	prorateo
						     WHERE 
						    	id_consorcio = @id_consorcio AND
						    	anio = @anio AND mes = @mes),

		-- PERIODO ANTERIOR (para el caso de la primera vez, es seguro que no exista prorateo anterior)
		prorateo_anterior AS (SELECT 
						        uf.id_uf,
						        COALESCE(p.saldo_final, 0) AS saldo_anterior
						      FROM 
						      	unidad_funcional uf
						      LEFT JOIN 
						      	prorateo p
						        ON p.id_consorcio = uf.id_consorcio
						        AND p.id_uf = uf.id_uf
						        AND p.anio = @anio_del_mes_anterior
						        AND p.mes = @mes_anterior
						      WHERE 
						        uf.id_consorcio = @id_consorcio),

		-- PAGOS EN TÉRMINO (antes del 1er vencimiento)
		pagos_venc1 AS (SELECT 
					        uf.id_uf,
					        SUM(COALESCE(p.monto, 0)) AS pagos_entermino
					    FROM
					    	unidad_funcional uf
					    LEFT JOIN --me aseguro que todas las UF existan con algun pago por defecto
					    	pago p
					    	ON p.id_consorcio = uf.id_consorcio
					    	AND p.id_uf = uf.id_uf
					    	AND p.fecha_pago >= @vencimiento2_anterior AND p.fecha_pago <= @vencimiento1
					    WHERE 
					    	uf.id_consorcio = @id_consorcio
					    GROUP BY --puede haber mas de un pago
					    	uf.id_uf),

		-- PAGOS ENTRE 1ER Y 2DO VTO
		pagos_venc2 AS (SELECT 
					        uf.id_uf,
					        SUM(COALESCE(p.monto, 0)) AS pagos_entre_vtos
					    FROM
					    	unidad_funcional uf
					    LEFT JOIN --me aseguro que todas las UF existan con algun pago por defecto
					    	pago p
					    	ON p.id_consorcio = uf.id_consorcio
					    	AND p.id_uf = uf.id_uf
					      	AND fecha_pago > @vencimiento1 AND fecha_pago < @vencimiento2
					    WHERE 
					    	uf.id_consorcio = @id_consorcio
					    GROUP BY --puede haber mas de un pago
					    	uf.id_uf),

		-- CALCULO DE SALDO AL 1ER VTO
		saldo_al_venc1 AS (SELECT 
						        pv1.id_uf,
						        pp.gastos_mes + pa.saldo_anterior - pv1.pagos_entermino AS saldo_restante,
						        pv1.pagos_entermino AS saldo_pagado 
							FROM 
						    	pagos_venc1 pv1 
						    JOIN 
						    	prorateo_anterior pa
						    	ON pa.id_uf = pv1.id_uf    	
						    JOIN
						    	prorateo_periodo pp
						    	ON pp.id_uf = pv1.id_uf),

		-- APLICO INTERÉS SI SIGUE DEBIENDO TRAS 1 VTO
		intereses1 AS (SELECT 
				        id_uf,
				        CASE WHEN saldo_restante > 0 THEN saldo_restante * 0.02
				            						 ELSE 0 END AS interes,
				        saldo_restante
				      FROM 
				    	saldo_al_venc1),

		-- SALDO AL 2DO VTO
		saldo_al_venc2 AS (SELECT 
						        i.id_uf,
						        i.saldo_restante + i.interes - pv2.pagos_entre_vtos AS saldo_restante,
						        pv2.pagos_entre_vtos
						    FROM 
						    	intereses1 i
						    JOIN 
						    	pagos_venc2 pv2 
						    	ON pv2.id_uf = i.id_uf),
		
		-- APLICO INTERÉS SI SIGUE DEBIENDO TRAS 2 VTO
		intereses2 AS (SELECT 
					  		id_uf,
					        CASE WHEN saldo_restante > 0 THEN saldo_restante * 0.05 
					        					  ELSE 0 END AS interes,
					        saldo_restante
					   FROM 
						  	saldo_al_venc2)

	INSERT INTO @tabla_intermedia
	SELECT
	    pv1.id_uf,
	    pv1.pagos_entermino,
	    pv2.pagos_entre_vtos,
	    sv1.saldo_restante AS saldo_al_venc1,
	    i1.interes AS interes1,
	    sv2.saldo_restante AS saldo_al_venc2,
	    i2.interes AS interes2
	FROM 
		pagos_venc1 pv1 
	JOIN 
		pagos_venc2 pv2 
		ON pv2.id_uf = pv1.id_uf
	JOIN 
		saldo_al_venc1 sv1 
		ON sv1.id_uf = pv1.id_uf
	JOIN 
		intereses1 i1 
		ON i1.id_uf = pv1.id_uf
	JOIN 
		saldo_al_venc2 sv2 
		ON sv2.id_uf = pv1.id_uf
	JOIN 
		intereses2 i2 
		ON i2.id_uf = pv1.id_uf;




	UPDATE p SET 
		p.saldo_final = ti.saldo_al_venc2 + ti.interes2, --este sera el saldo que se utilizara como saldo anterior para proximo calculo
		p.pagos_recibidos = ti.pagos_entermino + ti.pagos_entre_vtos
	FROM 
	    prorateo p
	JOIN 
	    @tabla_intermedia ti
	    ON ti.id_uf = p.id_uf
	WHERE 
	    p.id_consorcio = @id_consorcio AND
	    p.anio = @anio AND p.mes = @mes;



	WITH
		-- Calcular totales
		calculo_pagos AS (SELECT
							-- Pagos registrados antes del primer vencimiento
						    SUM(pagos_entermino) AS pagos_entermino,

						    -- Si al 1er vencimiento el saldo es positivo, tengo que ver cuales son pagos de deuda y cuales fueron de adelantos
						    SUM(CASE 
							        WHEN saldo_al_venc1 > 0 AND saldo_al_venc2 >= 0 
							        THEN IIF(saldo_al_venc1 - saldo_al_venc2 > 0, saldo_al_venc1 - saldo_al_venc2, 0) 
							        -- redujo deuda pero no la saldó. o peor aun, no pago y se genero MAS deuda
							        WHEN saldo_al_venc1 > 0 AND saldo_al_venc2 < 0  
							        THEN saldo_al_venc1    -- pagó toda la deuda
							        ELSE 0
						    END) AS pagos_adeudados,

						    -- Si al 1er vencimiento mi saldo quedo en 0 o negativo, todos los pagos siguientes son adelantos
						    SUM(CASE 
							        WHEN saldo_al_venc1 > 0 AND saldo_al_venc2 < 0 
							        THEN ABS(saldo_al_venc2)  -- el excedente después de saldar deuda
							        WHEN saldo_al_venc1 <= 0 
							        THEN pagos_entre_vtos -- ya estaba al día, todo es adelanto
							        ELSE 0
						   	END) AS pagos_adelantados
						  FROM 
							@tabla_intermedia),

		-- Obtener saldo anterior y gastos
		calculo_caja AS (SELECT 
							COALESCE(MAX(saldo_final), 0) AS saldo_anterior -- esta caja podria ser null para la primera creacion de expensa
						FROM 
						  	caja 
						WHERE 
						  	id_consorcio = @id_consorcio AND
		  				  	anio = @anio_del_mes_anterior AND mes = @mes_anterior),

		calculo_expensa AS (SELECT 
								monto_ord + monto_ext AS gastos
						  	FROM 
						  		expensa
						  	WHERE 
						  		id_consorcio = @id_consorcio AND
								anio = @anio AND mes = @mes)

	INSERT INTO caja(id_consorcio, anio, mes, pagos_entermino, pagos_adeudados, pagos_adelantados, saldo_final)
	SELECT
	    @id_consorcio,
	    @anio,
	    @mes,
	    cp.pagos_entermino,
	    cp.pagos_adeudados,
	    cp.pagos_adelantados,
	    cj.saldo_anterior + ce.gastos - (cp.pagos_entermino + cp.pagos_adeudados + cp.pagos_adelantados)
	FROM
		calculo_pagos cp
	CROSS JOIN
		calculo_caja cj
	CROSS JOIN
		calculo_expensa ce;

	IF @debug = 1
	BEGIN
		SELECT * FROM @tabla_intermedia;

		SELECT * FROM prorateo
		WHERE id_consorcio = @id_consorcio
	    AND anio = @anio AND mes = @mes;

	    SELECT * FROM caja
	    WHERE id_consorcio = @id_consorcio
	    AND anio = @anio AND mes = @mes;
	END;
END; 
GO
