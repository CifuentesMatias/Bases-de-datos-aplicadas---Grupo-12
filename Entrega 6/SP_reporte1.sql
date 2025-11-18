/** Reporte 1 **
	Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por
	pagos ordinarios y extraordinarios de cada semana, el promedio en el periodo, y el
	acumulado progresivo.
	
	//quizas me pidan algo asi
	CONSORCIO 			ANIO 	MES  SEMANA  ORDINARIO  EXTRAORDINARIO PROMEDIO_PERIODO	ACUMULADO
	altoes del oeste 	2020	1 	 1 		 20 mil	 	50mil 	        40mil			70 mil
	altoes del oeste 	2020	1 	 2 		 50 mil	 	60mil 	        40mil			180 mil
*/
CREATE PROCEDURE sp_reporte1(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
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

	WITH periodo_pagos AS (SELECT 
							anio,
							mes,
							fn_NROSEMANA_MES(DATEFROMPARTS(anio, mes, 1)) AS semana,
							SUM(pagos_exp_ord) AS ordinarias,
							SUM(pagos_exp_ext) AS extraordinarias
						  FROM 
						  	pago p
						  WHERE 
						  	id_consorcio = @id_consorcio AND
						  	fecha_pago BETWEEN @fechaInicio AND @fechaFin
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
		periodo_pagos
	ORDER BY
		anio,
		mes,
		semana;
END; 
GO
