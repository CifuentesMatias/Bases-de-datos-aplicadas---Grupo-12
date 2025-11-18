CREATE PROCEDURE sp_generarProrateo(@nombre_consorcio NVARCHAR(50), @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	DECLARE @fecha_actual DATE = GETDATE();
	DECLARE @quintoDiaHabil DATE = dbo.fn_5TODIAHABIL(@fecha_actual);
	DECLARE @anio INT = YEAR(@fecha_actual);
	DECLARE @mes INT = MONTH(@fecha_actual);
	DECLARE @vencimiento2 DATE = (SELECT vencimiento2 FROM expensa WHERE id_consorcio = @id_consorcio AND anio = @anio AND mes = @mes);

	IF @debug = 0 AND (@vencimiento2 IS NULL OR @fecha_actual NOT BETWEEN @quintoDiaHabil AND @vencimiento2)
	BEGIN
		RAISERROR('algo anda mal con las fechas', 16, 2);
		RETURN;
	END;

	DECLARE @esCochera INT = (SELECT id FROM tipo_adicional WHERE descripcion = 'Cochera');
	DECLARE @esBaulera INT = (SELECT id FROM tipo_adicional WHERE descripcion = 'Baulera');

	WITH
		consorcio_uf AS (SELECT 
							uf.id_uf,
							uf.coef,
							SUM(CASE WHEN auf.id_tipo_adicional = @esCochera THEN auf.coef ELSE 0 END) AS coef_cochera,
							SUM(CASE WHEN auf.id_tipo_adicional = @esBaulera THEN auf.coef ELSE 0 END) AS coef_baulera
						 FROM 
						 	unidad_funcional uf
						 LEFT JOIN 
						 	adicional_uf auf 
						 	ON auf.id_consorcio = uf.id_consorcio 
						 	AND auf.id_uf = uf.id_uf
						 WHERE 
						 	uf.id_consorcio = @id_consorcio
						 GROUP BY
						 	uf.id_uf,
						 	uf.coef),

		expensa_periodo AS (SELECT 
								* 
							FROM 
								expensa 
							WHERE
								id_consorcio = @id_consorcio AND
								anio = @anio AND mes = @mes)

	INSERT INTO prorateo(id_consorcio, anio, mes, id_uf, monto_ord, monto_coc, monto_bau, monto_ext)
	SELECT
		@id_consorcio,
		@anio,
		@mes,
		cuf.id_uf,
		(e.monto_ord * cuf.coef/100) AS ordinarias,
		((e.monto_ord + e.monto_ext) * cuf.coef_cochera/100) AS cocheras,
		((e.monto_ord + e.monto_ext) * cuf.coef_baulera/100) AS bauleras,
		(e.monto_ext * cuf.coef/100) AS extraordinarias
	FROM
		consorcio_uf cuf
	CROSS JOIN 
		expensa_periodo e;


	IF @debug = 1
	BEGIN
		SELECT * FROM prorateo
		WHERE id_consorcio = @id_consorcio  
		AND	anio = @anio AND mes = @mes;
	END;
END;
GO
