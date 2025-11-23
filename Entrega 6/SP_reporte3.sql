/** Reporte 3 **
	Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
	(ordinario, extraordinario, etc.) según el periodo
	
	//quizas me pidan algo asi
	CONSORCIO		 ANIO	MES 	ORDINARIO 	EXTRAORDINARIO 	   
	altos del oeste  2020	12   	20      	1000			
	altos del oeste  2020	11  	20      	1000			
	............
	altos del oeste  2020	1   	20      	1000
*/
CREATE PROCEDURE sp_reporte3(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;

	IF @fechaFin IS NULL SET @fechaFin = GETDATE();

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
		personas_consorcio AS (SELECT
								  puf.id_uf,
								  pers.cbu_cvu,
								  puf.es_propietario
							   FROM
								  persona_uf puf
							   LEFT JOIN
							   	  persona pers
							   	  ON pers.id_persona = puf.id_persona
							   WHERE
							   	  puf.id_consorcio = @id_consorcio),
		pagos_periodo AS (SELECT
							p.monto,
							YEAR(p.fecha_pago) AS anio,
							MONTH(p.fecha_pago) AS mes,
							CASE WHEN pc.es_propietario = 0 THEN 0 ELSE 1 END AS tipo_gasto
						  FROM 
						  	pago p
						  JOIN
						    personas_consorcio pc
						    ON pc.cbu_cvu = p.cbu_cvu
						  WHERE 
						  	p.id_consorcio = @id_consorcio AND
						  	p.fecha_pago BETWEEN @fechaInicio AND @fechaFin)

	SELECT
		@nombre_consorcio AS consorcio, 
		anio,
		mes,
		ISNULL([0], 0) AS ordinarias,
		ISNULL([1], 0) AS extraordinarias
	FROM 
		pagos_periodo
		PIVOT(SUM(monto) FOR tipo_gasto IN([0], [1])) AS piv
	ORDER BY
		anio,
		mes;
END; 
GO
