CREATE PROCEDURE sp_generarProrateo(@nombre_consorcio NVARCHAR(50), @anio INT, @mes INT, @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	
	DECLARE @fecha DATE;
	IF @anio IS NULL OR @mes IS NULL OR @anio < 2020 OR @mes NOT BETWEEN 1 AND 12
	BEGIN
		SET @fecha = GETDATE();
		SET @anio = YEAR(@fecha);
		SET @mes = MONTH(@fecha);
	END;
	ELSE SET @fecha = dbo.fn_5TODIAHABIL(DATEADD(month, 1, DATEFROMPARTS(@anio, @mes, 1)));


	DECLARE @quintoDiaHabil DATE = dbo.fn_5TODIAHABIL(@fecha);
	DECLARE @vencimiento2 DATE = (SELECT vence2 FROM expensa WHERE id_consorcio = @id_consorcio AND anio = @anio AND mes = @mes);
	IF @debug = 0 AND (@vencimiento2 IS NULL OR @fecha NOT BETWEEN @quintoDiaHabil AND @vencimiento2)
	BEGIN
		RAISERROR('algo anda mal con las fechas', 16, 2);
		RETURN;
	END;


	WITH
		consorcio_uf AS (SELECT 
							id,
							porcentaje
						 FROM 
						 	UF
						 WHERE 
						 	id_consorcio = @id_consorcio),

		expensa_periodo AS (SELECT 
								* 
							FROM 
								expensa 
							WHERE
								id_consorcio = @id_consorcio AND
								anio = @anio AND mes = @mes)

	INSERT INTO Estado_de_cuenta(id_consorcio, anio, mes, id_uf, gasto_ord, gasto_ext)
	SELECT
		@id_consorcio,
		@anio,
		@mes,
		cuf.id,
		e.monto_ord * (cuf.porcentaje/100.00) AS ordinarias,
		e.monto_ext * (cuf.porcentaje/100.00) AS extraordinarias
	FROM
		consorcio_uf cuf
	CROSS JOIN 
		expensa_periodo e;


	IF @debug = 1
	BEGIN
		SELECT *
		FROM Estado_de_cuenta
		WHERE id_consorcio = @id_consorcio  
		AND	anio = @anio AND mes = @mes;
	END;
END;
GO

-- AGREGAR COLUMNAS EN EXPENSA: monto_ord, monto_ext
