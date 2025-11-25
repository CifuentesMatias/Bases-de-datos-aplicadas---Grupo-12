if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go
use Com2900G12
go

IF OBJECT_ID('sp_generarEstadoCuenta', 'P') IS NOT NULL
    DROP PROCEDURE sp_generarEstadoCuenta;
GO

CREATE PROCEDURE sp_generarEstadoCuenta(@nombre_consorcio NVARCHAR(50), @anio INT, @mes INT, @debug BIT = 0) AS
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
	ELSE SET @fecha = DATEADD(day, 20, dbo.fn_5TODIAHABIL(DATEADD(month, 1, DATEFROMPARTS(@anio, @mes, 1))));


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
		Uf_porConsorcio AS (SELECT
								id,
								porcentaje,
								(CASE piso WHEN 0 THEN 'PB' ELSE CAST(piso AS VARCHAR(2)) END) + '-' + depto AS depto
							FROM
								UF
							WHERE
								id_consorcio = @id_consorcio),

		-- si el prorateo anterior no existe tener valores de backup
		prorateo_anterior AS (SELECT
								uf.id, 
							  	COALESCE(p.saldo_final, 0) AS saldo_anterior
							  FROM
							  	UF uf
							  LEFT JOIN
							  	Estado_de_cuenta p
							  	ON p.id_consorcio = uf.id_consorcio
							  	AND p.id_uf = uf.id
							  	AND p.anio = @anio_del_mes_anterior
							  	AND p.mes = @mes_anterior
							  WHERE
							  	uf.id_consorcio = @id_consorcio)
	SELECT
		@nombre_consorcio as [Consorcio],
		@anio as [Anio],
		@mes as [Mes],
		uc.id as [Uf], 
		uc.porcentaje as [%],
		uc.depto as [Piso-Depto],
		ur.propietario as [Propietario],

		pa.saldo_anterior as [Saldo anterior],
		pr.pagos_registrados as [Pagos recibidos],
		CASE 
			WHEN GREATEST(pa.saldo_anterior - pr.pagos_registrados, 0) > 0 
			THEN CAST((pa.saldo_anterior - pr.pagos_registrados) AS VARCHAR(20))
			ELSE '-'
		END as [Deuda],
		CASE 
			WHEN LEAST(pa.saldo_anterior - pr.pagos_registrados, 0) < 0 
			THEN CAST(ABS(pa.saldo_anterior - pr.pagos_registrados) AS VARCHAR(20))
			ELSE '-'
		END as [Saldo a favor],
		pr.saldo_final - pr.gasto_ord - pr.gasto_ext - pa.saldo_anterior + pr.pagos_registrados as [Intereses por mora], -- se puede inferir
		pr.gasto_ord as [Expensas ordinarias],
		pr.gasto_ext as [Expensas extraordinarias],
		pr.gasto_ord + pr.gasto_ext as [Total a pagar],
		pr.saldo_final as [Saldo final],

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
		Estado_de_cuenta pr
	JOIN
		prorateo_anterior pa
		ON pa.id = pr.id_uf
	JOIN
		Uf_porConsorcio uc
		ON uc.id = pr.id_uf
	JOIN
		fn_ultimoResidentes(@id_consorcio, @fecha) ur
		ON ur.id_uf = pr.id_uf
	WHERE
		pr.id_consorcio = @id_consorcio AND
		pr.anio = @anio AND pr.mes = @mes
	ORDER BY
		uc.id ASC;
END; 
GO

EXEC sp_generarEstadoCuenta @nombre_consorcio = 'Azcuenaga', @anio = 2024, @mes = 5, @debug = 1;

