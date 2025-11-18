/** Reporte 4 **
	Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos

	//quizas me pidan algo asi
	CONSORCIO 			ANIO 	MES  TIPO 	 	MONTO_TOTAL
	altos del oeste 	2020	5 	 gasto 	 	50mil
	.............
	altos del oeste 	2020	3 	 gasto 	 	20mil
	altos del oeste 	2020	6 	 ingresos  	50mil
	.............
	altos del oeste 	2020	5 	 ingresos 	20mil
*/
CREATE PROCEDURE sp_reporte4(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
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


	DECLARE @temp TABLE (anio INT, mes INT, tipo VARCHAR(7), monto DECIMAL(18,2));


	--mayores gastos
	INSERT INTO 
		@temp (anio, mes, tipo, monto)
	SELECT TOP 5
		anio,
		mes,
		'Gasto',
		(monto_ord + monto_ext) AS monto_total
	FROM 
		expensa
	WHERE 
		id_consorcio = @id_consorcio AND
		DATEFROMPARTS(anio, mes, 1) BETWEEN @fechaInicio AND @fechaFin
	ORDER BY
		monto_total DESC;


	--mayores ingresos 
	INSERT INTO 
		@temp (anio, mes, tipo, monto)
	SELECT TOP 5
		anio,
		mes,
		'Ingreso',
		(pagos_entermino + pagos_adeudados + pagos_adelantados) AS monto_total
	FROM
		caja
	WHERE
		id_consorcio = @id_consorcio AND
		DATEFROMPARTS(anio, mes, 1) BETWEEN @fechaInicio AND @fechaFin
	ORDER BY
		monto_total DESC;


	SELECT
		@nombre_consorcio as consorcio,
		anio,
		mes,
		tipo,
		monto
	FROM 
		@temp
	ORDER BY 
		tipo,
		monto;
END; 
GO
