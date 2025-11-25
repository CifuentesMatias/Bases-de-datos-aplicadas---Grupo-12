CREATE OR ALTER PROCEDURE sp_generarEstadoFinanciero(@nombre_consorcio NVARCHAR(50), @anio INT, @mes INT, @debug BIT = 0) AS
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
	IF @debug = 1 SET @fecha = DATEADD(day, 20, dbo.fn_5TODIAHABIL(DATEFROMPARTS(@anio, @mes, 1)));
	SET @fecha = DATEFROMPARTS(@anio, @mes, 1);


	DECLARE @anio_del_mes_anterior INT = @anio;
	DECLARE @mes_anterior INT = @mes - 1;
	IF @mes_anterior = 0
	BEGIN
	    SET @mes_anterior = 12;
	    SET @anio_del_mes_anterior = @anio_del_mes_anterior - 1;
	END;

	DECLARE @vencimiento2 DATE = (SELECT vence2 FROM expensa WHERE id_consorcio = @id_consorcio AND anio = @anio AND mes = @mes);

	-- usamos el mes pasado
	IF @debug = 0 AND (@vencimiento2 IS NULL OR @fecha < @vencimiento2)
	BEGIN
		SET @mes = @mes - 1;
		IF @mes = 0
		BEGIN
			SET @mes = 12;
			SET @anio = @anio - 1;
		END;

		SET @mes_anterior = @mes_anterior - 1;
		IF @mes_anterior = 0
		BEGIN
			SET @mes_anterior = 12;
			SET @anio_del_mes_anterior = @anio_del_mes_anterior - 1;
		END;
	END;


	WITH
		expensa_periodo AS (SELECT
								monto_ext,
								monto_ord
							FROM 
								expensa
							WHERE
								id_consorcio = @id_consorcio AND
								anio = @anio AND mes = @mes),
		caja_periodo AS (SELECT
							ingreso_termino,
							ingreso_adeudado,
							ingreso_adelantado,
							saldo_final
						  FROM 
							Estado_financiero
						  WHERE
							id_consorcio = @id_consorcio AND
							anio = @anio AND mes = @mes),
		-- esta caja podria ser null para la primera creacion de expensa
		caja_anterior AS (SELECT
							COALESCE(MAX(saldo_final), 0) AS saldo_anterior
						  FROM 
						  	Estado_financiero
						  WHERE
                    		id_consorcio = @id_consorcio AND
                    		anio = @anio_del_mes_anterior AND mes = @mes_anterior)
	SELECT
		@nombre_consorcio as [Consorcio],
		@anio as [Anio],
		@mes as [Mes],
		ca.saldo_anterior as [Saldo anterior],
		cp.ingreso_termino as [Pagos expensas en-termino],
		cp.ingreso_adeudado as [Pagos expensas adeudadas],
		cp.ingreso_adelantado as [Pagos expensas adelantadas],
		ep.monto_ext + ep.monto_ord as [Gastos mes actual],
		CASE 
			WHEN cp.saldo_final > 0 THEN CAST(ABS(cp.saldo_final) AS VARCHAR(20))
			ELSE '-'
		END as [Saldo a favor],
		cp.saldo_final as [Saldo al cierre]
	FROM
		expensa_periodo ep
	CROSS JOIN
		caja_periodo cp
	CROSS JOIN
		caja_anterior ca;
END; 
GO

EXEC sp_generarEstadoFinanciero
@nombre_consorcio = 'Azcuenaga',
    @anio = 2025,
    @mes = 5,
    @debug = 1;
