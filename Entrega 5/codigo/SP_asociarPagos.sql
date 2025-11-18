CREATE PROCEDURE sp_asociarPagos(@nombre_consorcio NVARCHAR(50), @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM pago WHERE id_consorcio IS NULL)
	BEGIN
	    PRINT 'Todo en orden. No hace falta asociar pagos..';
	    RETURN;
	END;

	--antes
	IF @debug = 1
	BEGIN
	    SELECT * FROM pago
	    WHERE id_consorcio IS NULL;
	END;

	WITH
		personas_consorcio AS (SELECT
									id_uf,
									id_persona,
									es_propietario,
									ROW_NUMBER() OVER (PARTITION BY id_uf, es_propietario ORDER BY fecha_alta DESC) AS rn
						   	   FROM
						   			persona_uf
						   	   WHERE
						   			id_consorcio = @id_consorcio AND
						   			fecha_alta <= GETDATE()),
		uf_persona AS (SELECT
							pc.id_uf,
							pers.id_persona,
							pc.es_propietario,
							pers.cbu_cvu
					   FROM
					   	 	persona pers
					   JOIN 
					   		personas_consorcio pc
					   		ON pc.id_persona = pers.id_persona
					   WHERE
					   		pc.rn = 1)
	UPDATE p SET
		p.id_consorcio = @id_consorcio,
		p.id_uf = ufp.id_uf
	FROM
		pago p
	JOIN
		uf_persona ufp
		ON ufp.cbu_cvu = p.cbu_cvu
	WHERE
		p.id_consorcio IS NULL;

	--despues
	IF @debug = 1
	BEGIN
	    SELECT * FROM pago
	    WHERE id_consorcio IS NULL;
	END;
END;
GO
