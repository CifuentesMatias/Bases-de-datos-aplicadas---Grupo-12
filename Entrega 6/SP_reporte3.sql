/** Reporte 3 **
	Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
	(ordinario, extraordinario, etc.) según el periodo
	
	//quizas me pidan algo asi
	CONSORCIO		 ANIO	MES 	ORDINARIO 	EXTRAORDINARIO 	COCHERA 	BAULERA   
	altos del oeste  2020	12   	20      	1000			5 			12
	altos del oeste  2020	11  	20      	1000			0 			0
	............
	altos del oeste  2020	1   	20      	1000
*/
CREATE PROCEDURE sp_reporte3(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;

	IF @fechaFin IS NULL
		SET @fechaFin = GETDATE();

	DECLARE @id_consorcio INT = (SELECT TOP 1 id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);

	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;
	IF @fechaInicio < '2000-1-1' OR @fechaInicio > @fechaFin 
	BEGIN
		RAISERROR('fecha invalida', 16, 2);
		RETURN;
	END;

	EXEC sp_corregirPeriodo @id_consorcio, @fechaInicio OUTPUT, @fechaFin OUTPUT;

	DECLARE @anio_del_mes_anterior INT = YEAR(@fechaInicio);
	DECLARE @mes_anterior INT = MONTH(@fechaInicio) - 1;
	IF @mes_anterior = 0
	BEGIN
		SET @mes_anterior = 12;
		SET @anio_del_mes_anterior = @anio_del_mes_anterior -1;
	END;

	DECLARE @anio_1er_fac INT, @mes_1er_fac INT;
	SELECT TOP 1
		@anio_1er_fac = anio,
		@mes_1er_fac = mes
	FROM
	  	prorateo 
	WHERE
	  	id_consorcio = @id_consorcio
	ORDER BY
	  	anio ASC,
	  	mes ASC

	WITH
		-- si no existe prorateo anterior defaultear a 0
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

		--no tengo campo intereses, entonces lo infiero. luego joineo el saldo_anterior
		prorateo_periodo AS (SELECT
								p.anio,
								p.mes,
								p.id_uf,
								pa.saldo_anterior,
						        p.monto_coc + p.monto_bau AS adicionales,
						        p.monto_ord,
						        p.monto_ext,
						        p.pagos_recibidos,
						        p.saldo_final,
						        p.pagos_recibidos - pa.saldo_anterior AS disp_enmes,
    							CASE 
    								WHEN pa.saldo_anterior > 0 
    								THEN p.saldo_final + p.pagos_recibidos - (pa.saldo_anterior + p.monto_coc + p.monto_bau + p.monto_ord + p.monto_ext),
    								ELSE 0 
    							END AS intereses
							 FROM
								prorateo p
							 JOIN
							 	prorateo_anterior pa
							 	ON pa.id_uf = p.id_uf
							 WHERE
								p.id_consorcio = @id_consorcio AND
								DATEFROMPARTS(p.anio, p.mes, 1) BETWEEN DATEFROMPARTS(@anio_1er_fac, @mes_1er_fac, 1) AND @fechaFin),
		
		-- disp_enmes: Pago disponible para cargos nuevos
		-- pagos_recibidos - saldo_anterior
	    calculo1 AS (SELECT
			          anio,
			          mes,
					  -- Saldo anterior (solo si era deuda)
					  CASE 
					    WHEN saldo_anterior <= 0 THEN 0
					    ELSE LEAST(pagos_recibidos, saldo_anterior)
					  END AS pago_saldo_anterior,
					  
					  -- Intereses
					  CASE 
					    WHEN saldo_anterior <= 0 THEN 0
					    WHEN disp_enmes <= 0 THEN 0
					    ELSE LEAST(disp_enmes, intereses)
					  END AS pago_intereses,
					  
					  -- Ordinario
					  CASE 
					    WHEN disp_enmes <= intereses THEN 0
					    ELSE LEAST(disp_enmes - intereses, monto_ord)
					  END AS pago_ordinario,
					  
					  -- Adicionales
					  CASE 
					    WHEN disp_enmes <= (intereses + monto_ord) THEN 0
					    ELSE LEAST(disp_enmes - intereses - monto_ord, adicionales)
					  END AS pago_adicionales,
					  
					  -- Extraordinario
					  CASE 
					    WHEN disp_enmes <= (intereses + monto_ord + adicionales) THEN 0
					    ELSE LEAST(disp_enmes - intereses - monto_ord - adicionales, monto_ext)
					  END AS pago_extraordinario
			         FROM
			            prorateo_periodo),

		expensas_periodo AS (SELECT
								anio,
								mes,
								monto_ord,
								monto_ext
							 FROM
							 	expensa
							 WHERE
							 	id_consorcio = @id_consorcio AND
							 	DATEFROMPARTS(p.anio, p.mes, 1) BETWEEN @fechaInicio AND @fechaFin),

		calculo2 AS (SELECT
				        anio, 
				        mes,
				        SUM(pago_saldo_anterior) AS pago_saldo_anterior,
					    SUM(pago_intereses) AS pago_intereses,
					    SUM(pago_ordinario) AS pago_ordinario,
					    SUM(pago_adicionales) AS pago_adicionales,
					    SUM(pago_extraordinario) AS pago_extraordinario
				     FROM 
				    	calculo1
				     WHERE
						DATEFROMPARTS(anio, mes, 1) BETWEEN @fechaInicio AND @fechaFin
				     GROUP BY
				    	anio,
				    	mes),
	 
	 SELECT 
		@nombre_consorcio AS consorcio,
		anio AS anio,
		mes AS mes,
	    pago_intereses AS intereses,
	    pago_ordinario AS ordinario,
	    pago_adicionales AS adicionales,
	    pago_extraordinario AS extraordinario
	FROM 
		calculo2
	ORDER BY
		anio,
		mes;
END; 
GO
