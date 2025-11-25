/** Reporte 2 **
	Presente el total de recaudación por mes y departamento en formato de tabla cruzada.

	//quizas me pidan algo asi
	CONSORCIO 			ANIO 	MES  Piso-Depto	ENERO, Febrero.......
	altos del oeste 	2020	1    PB-A		20mil  0
						2020	1    2			20mil  0
						2020	1    3			20mil  0
*/
CREATE OR ALTER PROCEDURE sp_reporte2(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;

	IF @fechaFin IS NULL
		SET @fechaFin = GETDATE();

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


	WITH
		cte AS (SELECT *
				FROM Estado_de_cuenta
				WHERE id_consorcio = @id_consorcio AND
					  DATEFROMPARTS(anio, mes, 1) BETWEEN @fechaInicio AND @fechaFin)
	SELECT
	    @nombre_consorcio AS consorcio,
		anio,
		id_uf,
	    ISNULL([1],0) AS Enero,
	    ISNULL([2],0) AS Febrero,
	    ISNULL([3],0) AS Marzo,
	    ISNULL([4],0) AS Abril,
	    ISNULL([5],0) AS Mayo,
	    ISNULL([6],0) AS Junio,
	    ISNULL([7],0) AS Julio,
	    ISNULL([8],0) AS Agosto,
	    ISNULL([9],0) AS Septiembre,
	    ISNULL([10],0) AS Octubre,
	    ISNULL([11],0) AS Noviembre,
	    ISNULL([12],0) AS Diciembre
	FROM 
		cte
		PIVOT (SUM(pagos_registrados) FOR mes
		   	   IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS piv
	ORDER BY 
		anio, 
		id_uf;
END;
GO


EXEC sp_reporte2 @nombre_consorcio = 'Azcuenaga', @fechaFIn = '2025-06-28';