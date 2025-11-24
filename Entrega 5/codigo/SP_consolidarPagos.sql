CREATE PROCEDURE sp_consolidarPagos(@nombre_consorcio NVARCHAR(50), @anio INT, @mes INT, @coef_vto1 INT = 2, @coef_vto2 INT = 5, @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	-- deberiamos estar en el dia del 5to dia habil obviamente del mes que sige
	DECLARE @fecha DATE;
	IF @anio IS NULL OR @mes IS NULL OR @anio < 2020 OR @mes NOT BETWEEN 1 AND 12
	BEGIN
		SET @fecha = GETDATE();
		SET @anio = YEAR(@fecha);
		SET @mes = MONTH(@fecha);
	END;
	ELSE SET @fecha = dbo.fn_5TODIAHABIL(DATEADD(month, 1, DATEFROMPARTS(@anio, @mes, 1)));

	IF @debug = 0 AND @fecha <> dbo.fn_5TODIAHABIL(@fecha)
	BEGIN
		RAISERROR('la fecha no coincide con el 5to dia habil', 16, 3);
		RETURN;
	END;



	DECLARE @vencimiento1 DATE, @vencimiento2 DATE;
	SELECT 
		@vencimiento1 = vence1,
		@vencimiento2 = vence2
	FROM 
		expensa 
	WHERE 
		id_consorcio = @id_consorcio AND
	  	anio = @anio AND mes = @mes;

	IF @vencimiento2 IS NULL
	BEGIN
		RAISERROR('no existe vencimiento... abortando', 16, 4);
		RETURN;
	END;


	DECLARE @mes_anterior INT = @mes - 1;
	DECLARE @anio_del_mes_anterior INT = @anio;
	IF @mes_anterior = 0
	BEGIN
	    SET @mes_anterior = 12;
	    SET @anio_del_mes_anterior = @anio_del_mes_anterior - 1;
	END;

	DECLARE @5todihabil_anterior DATE = dbo.fn_5TODIAHABIL(DATEFROMPARTS(@anio_del_mes_anterior, @mes_anterior, 1));
	DECLARE @vencimiento2_anterior DATE = (SELECT vence2 FROM expensa
										   WHERE id_consorcio = @id_consorcio AND
	  									   anio = @anio_del_mes_anterior AND mes = @mes_anterior);
	IF @vencimiento2_anterior IS NULL
	SET @vencimiento2_anterior = DATEFROMPARTS(@anio_del_mes_anterior, @mes_anterior, 20);


	IF EXISTS (SELECT 1 FROM pago WHERE (id_consorcio IS NULL OR id_uf IS NULL) AND
										(fecha_pago BETWEEN @vencimiento2_anterior AND @vencimiento2))
	BEGIN
		RAISERROR('error.. existen pagos que no estan asociados!', 16, 5);
		RETURN;
	END;



	-- tabla temporal con los resultados de los CTEs
	DECLARE @tabla_intermedia TABLE 
	(
	    id_uf INT PRIMARY KEY,
	    pagos_5todia DECIMAL(10,2),
	    pagos_entermino DECIMAL(10,2),
	    pagos_entre_vtos DECIMAL(10,2),	    
	    pagos_totales DECIMAL(20,2),
	    saldo_al_5todia DECIMAL(10,2),
	    saldo_al_venc1 DECIMAL(10,2),
	    saldo_al_venc2 DECIMAL(10,2),
	    saldo_final DECIMAL(20,2)
	);

	-- Calcular todo una sola vez y guardar en la tabla intermedia
	WITH
		--PAGOS PERIODO
		pagos_periodo AS (SELECT 
					        id_uf,
					        fecha_pago,
					        monto AS pagos
				          FROM
				    		pago
				    	  WHERE 
				    		id_consorcio = @id_consorcio AND
				    		fecha_pago >= @vencimiento2_anterior AND
				    		fecha_pago < @vencimiento2),

		-- PAGOS HASTA 5to dia habil
		pagos_anteriores AS (SELECT 
						        uf.id,
						        SUM(COALESCE(pp.pagos, 0)) AS pagos_5todia
						     FROM
						     	UF uf
						     LEFT JOIN
						    	pagos_periodo pp
						    	ON pp.id_uf = uf.id
						     	AND pp.fecha_pago >= @vencimiento2_anterior 
						    	AND pp.fecha_pago <= @5todihabil_anterior
						     GROUP BY --puede haber mas de un pago
						    	uf.id),

		-- PAGOS HASTA 1er VENC
		pagos_venc1 AS (SELECT 
				        	uf.id,
				        	SUM(COALESCE(pp.pagos, 0)) AS pagos_entermino
				    	FROM
					     	UF uf
					    LEFT JOIN
					    	pagos_periodo pp
					    	ON pp.id_uf = uf.id
					    	AND pp.fecha_pago > @5todihabil_anterior 
					    	AND pp.fecha_pago <= @vencimiento1
					    GROUP BY --puede haber mas de un pago
						    uf.id),

		-- PAGOS HASTA 2do VENC
		pagos_venc2 AS (SELECT 
				        	uf.id,
				        	SUM(COALESCE(pp.pagos, 0)) AS pagos_entre_vtos
				    	FROM
					     	UF uf
					    LEFT JOIN
					    	pagos_periodo pp
					    	ON pp.id_uf = uf.id
					    	AND pp.fecha_pago > @vencimiento1
					    	AND pp.fecha_pago < @vencimiento2
					    GROUP BY --puede haber mas de un pago
						    uf.id),


		-- PERIODO ANTERIOR (para el caso de la primera vez, es seguro que no exista prorateo anterior)
		prorateo_anterior AS (SELECT 
						        uf.id,
						        COALESCE(p.saldo_final, 0) AS saldo_anterior
						      FROM 
						      	UF uf
						      LEFT JOIN 
						      	Estado_de_cuenta p
						        ON p.id_consorcio = uf.id_consorcio
						        AND p.id_uf = uf.id
						        AND p.anio = @anio_del_mes_anterior
						        AND p.mes = @mes_anterior
						      WHERE 
						        uf.id_consorcio = @id_consorcio),

		-- CALCULO DE SALDO AL 5to dia
		saldo_al_5todia AS (SELECT 
						        p5d.id_uf,
						        p5d.pagos_5todia AS saldo_pagado,           
						        pa.saldo_anterior - p5d.pagos_5todia AS saldo_restante
							FROM 
						    	pagos_anteriores p5d 
						    JOIN 
						    	prorateo_anterior pa
						    	ON pa.id_uf = p5d.id_uf),

		-- PERIODO ACTUAL (todas las uf existen)
		prorateo_periodo AS (SELECT 
						        id_uf,
						        gasto_ext + gasto_ord AS gastos_mes
						     FROM 
						    	Estado_de_cuenta
						     WHERE 
						    	id_consorcio = @id_consorcio AND
						    	anio = @anio AND mes = @mes),

		-- CALCULO DE SALDO AL 1ER VTO
		saldo_al_venc1 AS (SELECT 
						        s5d.id_uf,
						        s5d.saldo_restante AS saldo_pagado,           
						        s5d.saldo_restante + pp.gastos_mes - pv1.pagos_entermino AS saldo_restante
							FROM 
						    	saldo_al_5todia s5d 
						    JOIN 
						    	prorateo_periodo pp
						    	ON pp.id_uf = s5d.id_uf
						    JOIN
						    	pagos_venc1 pv1
						    	ON pv1.id_uf = s5d.id_uf),

		-- APLICO INTERES SI SIGUE DEBIENDO TRAS 1 VTO
		intereses1 AS (SELECT 
				        	id_uf,
				        	CASE 
				        		WHEN saldo_restante > 0 
				        		THEN saldo_restante * (@coef_vto1/100.00)
				            	ELSE 0
				        	END AS interes,
				        	saldo_restante
				      	FROM 
				    		saldo_al_venc1),

		-- SALDO AL 2DO VTO
		saldo_al_venc2 AS (SELECT 
						      i.id_uf,
						      pv2.pagos_entre_vtos AS saldo_pagado,
						      i.saldo_restante + i.interes - pv2.pagos_entre_vtos AS saldo_restante
						   FROM 
						      intereses1 i
						   JOIN 
						      pagos_venc2 pv2 
						   	  ON pv2.id_uf = i.id_uf),
		
		-- APLICO INTERES SI SIGUE DEBIENDO TRAS 2 VTO
		intereses2 AS (SELECT 
					  	  id_uf,
					      CASE 
					        WHEN saldo_restante > 0 
					        THEN saldo_restante * (@coef_vto2/100.00) 
					        ELSE 0 
					      END AS interes,
					      saldo_restante
					   FROM 
						  saldo_al_venc2)

	INSERT INTO @tabla_intermedia
	SELECT
	    pat.id_uf,
	    pat.pagos_5todia,
	    pv1.pagos_entermino,
	    pv2.pagos_entre_vtos,
	    pat.pagos_5todia + pv1.pagos_entermino + pv2.pagos_entre_vtos AS pagos_totales,
	    s5d.saldo_restante AS saldo_al_5todia,
	    sv1.saldo_restante AS saldo_al_venc1,
	    sv2.saldo_restante AS saldo_al_venc2,
	    i2.saldo_restante + i2.interes AS saldo_final
	FROM 
		pagos_anteriores pat
	JOIN 
		pagos_venc1 pv1 
		ON pv1.id_uf = pat.id_uf
	JOIN 
		pagos_venc2 pv2
		ON pv2.id_uf = pat.id_uf
	JOIN 
		saldo_al_venc1 sv1 
		ON sv1.id_uf = pat.id_uf
	JOIN 
		saldo_al_5todia s5d 
		ON s5d.id_uf = pat.id_uf
	JOIN 
		saldo_al_venc2 sv2 
		ON sv2.id_uf = pat.id_uf
	JOIN 
		intereses2 i2 
		ON i2.id_uf = pat.id_uf;




	UPDATE p SET 
		p.saldo_final = ti.saldo_final, --este sera el saldo que se utilizara como saldo anterior para proximo calculo
		p.pagos_registrados = ti.pagos_totales
	FROM 
	    Estado_de_cuenta p
	JOIN 
	    @tabla_intermedia ti
	    ON ti.id_uf = p.id_uf
	WHERE 
	    p.id_consorcio = @id_consorcio AND
	    p.anio = @anio AND p.mes = @mes;


	WITH
		-- PERIODO ANTERIOR (para el caso de la primera vez, es seguro que no exista prorateo anterior)
		prorateo_anterior AS (SELECT 
						        uf.id,
						        COALESCE(p.saldo_final, 0) AS saldo_anterior
						      FROM 
						      	UF uf
						      LEFT JOIN 
						      	Estado_de_cuenta p
						        ON p.id_consorcio = uf.id_consorcio
						        AND p.id_uf = uf.id
						        AND p.anio = @anio_del_mes_anterior
						        AND p.mes = @mes_anterior
						      WHERE 
						        uf.id_consorcio = @id_consorcio),

		pagos_clasificados AS (SELECT 
							        ti.id_uf,
							        ti.saldo_final,

							         -- Parte 1: pagos al 5to día
							        CASE -- cuanto se usa para deuda anterior
							            WHEN pra.saldo_anterior > 0 
							            THEN LEAST(ti.pagos_5todia, pra.saldo_anterior)
							            ELSE 0
							        END AS pago_a_deuda_anterior,
							        CASE -- restante después de cubrir deuda anterior
							            WHEN pra.saldo_anterior > 0 
							            THEN GREATEST(ti.pagos_5todia - pra.saldo_anterior, 0) --siempre devuelve 0 o mas
							            ELSE ti.pagos_5todia
							        END AS pago_restante,

							        -- Parte 2: pagos en término (necesitamos saldo después del 5to día)
							        CASE 
							            WHEN ti.saldo_al_5todia > 0  -- había deuda después del 5to día
							            THEN LEAST(ti.pagos_entermino, ti.saldo_al_5todia)
							            ELSE 0
							        END AS pago_a_deuda_entermino,
							        CASE 
							            WHEN ti.saldo_al_5todia > 0 
							            THEN GREATEST(ti.pagos_entermino - ti.saldo_al_5todia, 0)
							            ELSE ti.pagos_entermino
							        END AS pago_restante_entermino,

							         -- Parte 3: pagos entre vencimientos
							        CASE 
							            WHEN ti.saldo_al_venc1 > 0  -- existe deuda al 1er vto
							            THEN LEAST(ti.pagos_entre_vtos, ti.saldo_al_venc1)
							            ELSE 0
							        END AS pago_a_deuda_venc1,
							        CASE 
							            WHEN ti.saldo_al_venc1 > 0 
							            THEN GREATEST(ti.pagos_entre_vtos - ti.saldo_al_venc1, 0)
							            ELSE ti.pagos_entre_vtos
							        END AS pago_restante_entre_vtos
							   FROM 
							   		@tabla_intermedia ti
							   JOIN 
							    	prorateo_anterior pra
							        ON pra.id_uf = ti.id_uf),

		calculo_final AS (SELECT
					        SUM(pago_a_deuda_anterior + pago_a_deuda_venc1 + pago_a_deuda_entermino) AS pagos_adeudados,
					        SUM(pago_restante_entermino) AS pagos_entermino,
					        SUM(pago_restante + pago_restante_entre_vtos) AS pagos_adelantados
					      FROM 
					    	pagos_clasificados),

		-- Obtener saldo anterior y gastos
		calculo_caja AS (SELECT 
							COALESCE(MAX(saldo_final), 0) AS saldo_anterior -- esta caja podria ser null para la primera creacion de expensa
						FROM 
						  	Estado_financiero 
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

	INSERT INTO Estado_financiero(id_consorcio, anio, mes, pagos_adeudados, pagos_entermino, pagos_adelantados, saldo_final)
	SELECT
	    @id_consorcio,
	    @anio,
	    @mes,
	    cf.pagos_adeudados,
	    cf.pagos_entermino,
	    cf.pagos_adelantados,
	    cj.saldo_anterior + (cf.pagos_adeudados + cf.pagos_entermino + cf.pagos_adelantados) - ce.gastos
	FROM
		calculo_final cf
	CROSS JOIN
		calculo_caja cj
	CROSS JOIN
		calculo_expensa ce;

	IF @debug = 1
	BEGIN
		SELECT
			* 
		FROM
			@tabla_intermedia;

	    SELECT
	    	* 
	    FROM
	    	Estado_financiero
	    WHERE
	    	id_consorcio = @id_consorcio AND
	    	anio = @anio AND mes = @mes;
	END;
END; 
GO
