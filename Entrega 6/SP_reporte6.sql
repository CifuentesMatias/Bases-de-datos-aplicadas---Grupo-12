/** Reporte 6 **
	Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
	pasan entre un pago y el siguiente, para el conjunto examinado.
	
	//quizas me pidan algo asi
	CONSORCIO 		  Piso-Depto  fPago 	 diff_dias
	altos del oeste   PB-A 	 	 2020-10-5 	 2
	altos del oeste   PB-A		 2020-10-7 	 3
	altos del oeste   PB-A 	 	 2020-10-10  -
	altos del oeste   P1-E 	 	 2020-10-5 	 60
	altos del oeste   P1-E		 2020-12-5 	 3
	altos del oeste   P1-E 	 	 2020-12-5   0
	altos del oeste   P1-E 	 	 2020-12-7   0
*/
CREATE PROCEDURE sp_reporte6(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
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


	WITH
		pagos_periodo AS (SELECT 
							id_uf,
							fecha_pago
						  FROM 
						  	pago
						  WHERE
						  	id_consorcio = @id_consorcio AND
						  	fecha_pago BETWEEN @fechaInicio AND @fechaFin),
		Uf_porConsorcio AS (SELECT
								id_uf,
								((CASE piso WHEN 0 THEN 'PB' ELSE CAST(piso as VARCHAR(2)) END) + '-' + depto) AS dpto
						    FROM 
						    	unidad_funcional
							WHERE 
								id_consorcio = @id_consorcio)
	SELECT 
		@nombre_consorcio AS consorcio,
		ufc.dpto AS [Piso-Depto], 
		pp.fecha_pago AS fPago,
		COALESCE(
			CAST(DATEDIFF(DAY, 
					 	  LAG(pp.fecha_pago) OVER (PARTITION BY ufc.id_uf ORDER BY pp.fecha_pago),
					 	  pp.fecha_pago) AS VARCHAR(10)),
		    '-'
		) AS diff_dias
	FROM 
		pagos_periodo pp
	JOIN 
		Uf_porConsorcio ufc 
		ON ufc.id_uf = pp.id_uf
	ORDER BY 
		ufc.id_uf,
		pp.fecha_pago;
END;
GO
