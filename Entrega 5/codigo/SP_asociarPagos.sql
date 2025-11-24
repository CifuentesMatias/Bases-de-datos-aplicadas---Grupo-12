CREATE or ALTER PROCEDURE sp_asociarPagos(@debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

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
								*
						   	   FROM
						   			persona_uf
						   	   WHERE
						   			fecha <= GETDATE()),
		uf_persona AS (SELECT
							pc.id_consorcio,
							pc.id_uf,
							pers.id,
							pc.es_propietario,
							pers.cvu_cbu
					   FROM
					   	 	persona pers
					   JOIN 
					   		personas_consorcio pc
					   		ON pc.cvu_cbu = pers.cvu_cbu) -- CAMBIÓ
	UPDATE p SET
		p.id_consorcio = ufp.id_consorcio,
		p.id_uf = ufp.id_uf
	FROM
		pago p
	JOIN
		uf_persona ufp
		ON ufp.cvu_cbu = p.cbu_cvu -- CAMBIÓ
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

-- AGREGAR A LA TABLA PAGO: id_consorcio, id_uf