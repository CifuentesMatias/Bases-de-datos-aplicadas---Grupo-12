CREATE PROCEDURE sp_generarEstadoFinanciero(@nombre_consorcio NVARCHAR(50), @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	DECLARE @fecha_actual DATE = GETDATE();
	DECLARE @anio INT = YEAR(@fecha_actual);
	DECLARE @mes INT = MONTH(@fecha_actual);
	DECLARE @anio_del_mes_anterior INT = @anio;
	DECLARE @mes_anterior INT = @mes - 1;
	IF @mes_anterior = 0
	BEGIN
	    SET @mes_anterior = 12;
	    SET @anio_del_mes_anterior = @anio_del_mes_anterior - 1;
	END;

	DECLARE @vencimiento2 DATE = (SELECT vencimiento2 FROM expensa WHERE id_consorcio = @id_consorcio AND anio = @anio AND mes = @mes);

	-- usamos el mes pasado
	IF @debug = 0 AND (@vencimiento2 IS NULL OR @fecha_actual < @vencimiento2)
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
							pagos_entermino,
							pagos_adeudados,
							pagos_adelantados,
							saldo_final
						  FROM 
							caja
						  WHERE
							id_consorcio = @id_consorcio AND
							anio = @anio AND mes = @mes),
		-- esta caja podria ser null para la primera creacion de expensa
		caja_anterior AS (SELECT
							saldo_final AS saldo_anterior
						  FROM 
						  	caja
						  WHERE
                    		id_consorcio = @id_consorcio AND
                    		anio = @anio_del_mes_anterior AND mes = @mes_anterior
                    	  UNION ALL
                    	  SELECT
                    	  	0 AS saldo_anterior)
	SELECT
		@nombre_consorcio as [Consorcio],
		@anio as [Anio],
		@mes as [Mes],
		ca.saldo_anterior as [Saldo anterior],
		cp.pagos_entermino as [Pagos expensas en-termino],
		cp.pagos_adeudados as [Pagos expensas adeudadas],
		cp.pagos_adelantados as [Pagos expensas adelantadas],
		ep.monto_ext + ep.monto_ord as [Gastos mes actual],
		cp.saldo_final as [Saldo al cierre]
	FROM
		expensa_periodo ep
	CROSS JOIN
		caja_periodo cp
	CROSS JOIN
		caja_anterior ca;
END; 
GO
