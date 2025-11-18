CREATE PROCEDURE sp_generarEstadoCuenta(@nombre_consorcio NVARCHAR(50), @debug BIT = 0) AS
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
		Uf_porConsorcio AS (SELECT
								id_uf,
								coef,
								(CASE piso WHEN 0 THEN 'PB' ELSE CAST(piso AS VARCHAR(2)) END) + '-' + depto AS depto
							FROM
								unidad_funcional
							WHERE
								id_consorcio = @id_consorcio),

		-- si el prorateo anterior no existe tener valores de backup
		prorateo_anterior AS (SELECT
								uf.id_uf, 
							  	COALESCE(p.saldo_final, 0) AS saldo_anterior
							  FROM
							  	unidad_funcional uf
							  LEFT JOIN
							  	prorateo p
							  	ON p.id_consorcio = uf.id_consorcio
							  	AND p.id_uf = uf.id_uf
							  	AND p.anio = @anio_del_mes_anterior
							  	AND p.mes = @mes_anterior
							  WHERE
							  	uf.id_consorcio = @id_consorcio)
	SELECT
		@nombre_consorcio as [Consorcio],
		@anio as [Anio],
		@mes as [Mes],
		uc.id_uf as [Uf], 
		uc.coef as [%],
		uc.depto as [Piso-Depto],
		ur.propietario as [Propietario],
		pa.saldo_anterior as [Saldo anterior],
		pr.pagos_recibidos as [Pagos recibidos],
		pa.saldo_anterior - pr.pagos_recibidos as [Deuda],
		pr.saldo_final - pr.monto_ord - pr.monto_coc - pr.monto_bau - pr.monto_ext - pa.saldo_anterior + pr.pagos_recibidos as [Intereses por mora], -- se puede inferir
		pr.monto_ord as [Expensas ordinarias],
		pr.monto_coc as [Cocheras],
		pr.monto_bau as [Bauleras],
		pr.monto_ext as [Expensas extraordinarias],
		pr.saldo_final as [Total a Pagar],
		CASE 
			WHEN ur.prop_email <> '' THEN ur.prop_email
			WHEN ur.prop_tel <> '' THEN ur.prop_tel
			ELSE 'copia_impresa'
		END as [Forma envio propietario],
		CASE 
			WHEN ur.inq_email <> '' THEN ur.inq_email
			WHEN ur.inq_tel <> '' THEN ur.inq_tel
			ELSE 'copia_impresa' 
		END as [Forma envio inquilino] 
	FROM 
		prorateo pr
	JOIN
		prorateo_anterior pa
		ON pa.id_uf = pr.id_uf
	JOIN
		Uf_porConsorcio uc
		ON uc.id_uf = pr.id_uf
	JOIN
		fn_ultimoResidentes(@id_consorcio, @fecha_actual) ur
		ON ur.id_uf = pr.id_uf
	WHERE
		pr.id_consorcio = @id_consorcio AND
		pr.anio = @anio AND pr.mes = @mes
	ORDER BY
		uc.id_uf ASC;
END; 
GO
