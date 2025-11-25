/** Reporte 1 **
	Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por
	pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el
	acumulado progresivo.
	
	//quizas me pidan algo asi
	CONSORCIO 			ANIO 	MES  SEMANA  ORDINARIO  EXTRAORDINARIO PROMEDIO_PERIODO	ACUMULADO
	altoes del oeste 	2020	1 	 1 		 20 mil	 	50mil 	        40mil			70 mil
	altoes del oeste 	2020	1 	 2 		 50 mil	 	60mil 	        40mil			180 mil
*/
CREATE OR ALTER PROCEDURE sp_reporte1(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;

	IF @fechaFin IS NULL SET @fechaFin = GETDATE();

	DECLARE @id_consorcio INT = (SELECT TOP 1 id FROM consorcio WHERE razon_social = @nombre_consorcio);

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

	WITH
		personas_consorcio AS (SELECT
								  puf.id_uf,
								  pers.cvu_cbu,
								  -- CORRECCIÓN: es_propietario se calcula inversamente a id_tipo_relacion (bool).
								  CASE 
										WHEN pers.id_tipo_relacion = 1 THEN 0 
										ELSE 1                                 
								  END AS es_propietario
							   FROM
								  persona_uf puf
							   LEFT JOIN
							   	  persona pers
							   	  ON pers.cvu_cbu = puf.cvu_cbu
							   	WHERE
							   	  puf.id_consorcio = @id_consorcio),
		
		pagos_periodo AS (SELECT
							p.id_uf,
							p.monto,
							YEAR(p.fecha_pago) AS anio,
							MONTH(p.fecha_pago) AS mes,
							dbo.fn_NROSEMANA_MES(p.fecha_pago) AS semana,
							pc.es_propietario
						  FROM 
						  	pago p
						  JOIN
						    personas_consorcio pc
						    ON pc.cvu_cbu = p.cbu_cvu
						  WHERE 
						  	p.id_consorcio = @id_consorcio AND
						  	p.fecha_pago BETWEEN @fechaInicio AND @fechaFin),
							
		pagos_segregados AS (SELECT 
								anio,
								mes,
								semana,
								SUM(CASE WHEN es_propietario = 0 THEN monto ELSE 0 END) AS ordinarias,
								SUM(CASE WHEN es_propietario = 1 THEN monto ELSE 0 END) AS extraordinarias
							  FROM
							  	pagos_periodo
							  GROUP BY 
							  	anio,
							  	mes,
							  	semana)
								
	SELECT
		@nombre_consorcio AS consorcio, 
		anio,
		mes,
		semana,
		ordinarias,
		extraordinarias,
		AVG(ordinarias + extraordinarias) OVER () AS promedio_periodo,
		SUM(ordinarias + extraordinarias) OVER (ORDER BY anio, mes, semana) AS acumulado_periodo
	FROM 
		pagos_segregados
	ORDER BY
		anio,
		mes,
		semana;
END; 
GO

EXEC sp_reporte1 @nombre_consorcio = 'Azcuenaga',  @fechaFin = '2025-06-03';