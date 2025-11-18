CREATE PROCEDURE sp_corregirPeriodo(@id_consorcio INT, @fechaInicio DATE OUTPUT, @fechaFin DATE OUTPUT) AS
BEGIN
	DECLARE @anio INT = YEAR(@fechaFin);
	DECLARE @mes INT = MONTH(@fechaFin);
	DECLARE @anio_aux INT = YEAR(@fechaInicio);
	DECLARE @mes_aux INT = MONTH(@fechaInicio);
	DECLARE @periodo_final DATE = (SELECT vencimiento2 FROM expensa 
								   WHERE id_consorcio = @id_consorcio
								   AND anio = @anio 
								   AND mes = @mes);
	DECLARE @periodo_inicial DATE = (SELECT vencimiento2 FROM expensa 
								   	 WHERE id_consorcio = @id_consorcio
								  	 AND anio = @anio_aux 
								   	 AND mes = @mes_aux);

	IF @periodo_final IS NULL OR @fechaFin < @periodo_final 
	BEGIN
		SET @mes = @mes - 1;
		IF @mes = 0
		BEGIN
			SET @mes = 12;
			SET @anio = @anio - 1; 
		END;


		SET @periodo_final = (SELECT vencimiento2 FROM expensa 
							  WHERE id_consorcio = @id_consorcio
							  AND anio = @anio 
							  AND mes = @mes);
		IF @periodo_final IS NULL
		BEGIN
			RAISERROR('error.. no hay fechas de vencimiento', 16, 2);
			RETURN;
		END;
	END;

	-- Si fechaInicio es antes del vencimiento2 del mes en cuestion, usar el mes siguiente
	IF @fechaInicio < @periodo_inicial 
	BEGIN
		SET @mes_aux = @mes_aux + 1;
		IF @mes_aux = 13
		BEGIN
			SET @mes_aux = 1;
			SET @anio_aux = @anio_aux + 1; 
		END;
	

		SET @periodo_inicial = (SELECT vencimiento2 FROM expensa 
							    WHERE id_consorcio = @id_consorcio
							  	AND anio = @anio_aux 
							  	AND mes = @mes_aux);

	END;
	IF @periodo_inicial IS NULL
	BEGIN
		--valor fallback
		SET @periodo_inicial = @fechaInicio; 
	END;

	SET @fechaFin = @periodo_final;
	SET @fechaInicio = @periodo_inicial;
END;
GO
