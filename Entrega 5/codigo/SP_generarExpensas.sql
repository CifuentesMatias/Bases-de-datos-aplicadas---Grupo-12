CREATE PROCEDURE sp_generarExpensas(@nombre_consorcio NVARCHAR(50), @dias_venc1 INT = 10, @dias_venc2 INT = 20, @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	--cuando se corre este sp se haria el 5to dia habil del mes siguiente, 
	DECLARE @fecha_actual DATE = GETDATE();
	DECLARE @quintoDiaHabil DATE = dbo.fn_5TODIAHABIL(@fecha_actual);
	IF @debug = 0 AND @fecha_actual <> @quintoDiaHabil
	BEGIN
		RAISERROR('No estamos en el 5to dia habil del mes', 16, 2);
		RETURN;
	END;


	IF @dias_venc1 <= 0 OR @dias_venc2 <= 0 OR @dias_venc1 >= @dias_venc2
	BEGIN
		RAISERROR('error con la cantidad de dias de vencimiento', 16, 3);
		RETURN;
	END;


	--la fecha de creacion  de este registro es al siguiente MES de los gastos producidos
	--por lo que que los gastos son del mes siguiente del dia 1 al 31 inclusive
	DECLARE @fecha_ini DATE = DATEFROMPARTS(YEAR(DATEADD(month, -1, @fecha_actual)),
                      						MONTH(DATEADD(month, -1, @fecha_actual)), 
                      						1);
    DECLARE @fecha_fin DATE = DATEADD(day, -1, DATEFROMPARTS(YEAR(@fecha_actual),
                      						   				 MONTH(@fecha_actual),
                      										 1));

	IF EXISTS (SELECT 1 FROM pago WHERE (id_consorcio IS NULL OR id_uf IS NULL) AND
										(fecha_pago BETWEEN @fecha_ini AND @fecha_fin))
	BEGIN
		RAISERROR('error.. existen pagos que no estan asociados!', 16, 4);
		RETURN;
	END;


	DECLARE @anio INT = YEAR(@fecha_actual);
	DECLARE @mes INT = MONTH(@fecha_actual);

	DECLARE @esExtraordinaria INT = (SELECT id FROM tipo_gasto WHERE descripcion = 'Extraordinarios');


	INSERT INTO expensa (id_consorcio, anio, mes, vencimiento1, vencimiento2, monto_ord, monto_ext)
	SELECT
		@id_consorcio,
		@anio,
		@mes,
		DATEADD(day, @dias_venc1, @fecha_actual),
		DATEADD(day, @dias_venc2, @fecha_actual),  
		SUM(CASE WHEN id_tipo_gasto <> @esExtraordinaria THEN importe ELSE 0 END), -- AS ordinarias,
		SUM(CASE WHEN id_tipo_gasto = @esExtraordinaria THEN importe ELSE 0 END) -- AS extraordinarias
	FROM 
		detalle_expensa
	WHERE
		id_consorcio = @id_consorcio AND 
		fecha_factura BETWEEN @fecha_ini AND @fecha_fin;


	IF @debug = 1
	BEGIN
		SELECT * FROM expensa
		WHERE id_consorcio = @id_consorcio 
		AND	anio = @anio AND mes = @mes;
	END;
END; 
GO
