CREATE PROCEDURE sp_nuevaEdificacion(@nombre_consorcio NVARCHAR(50), @m2_edf NUMERIC(6,2), @piso INT, @depto CHAR(1), @debug BIT = 0) AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	IF @m2_edf <= 0 OR @piso < 0 
	BEGIN
		RAISERROR('Revisar argumentos', 16, 2);
		RETURN;
	END;

	IF EXISTS (SELECT 1 FROM unidad_funcional 
			   WHERE id_consorcio = @id_consorcio 
	       	   AND piso = @piso AND depto = @depto)
	BEGIN
		RAISERROR('ese depto ya existe en ese piso', 16, 2);
		RETURN;
	END;

	DECLARE @m2_consorcio NUMERIC(8,2) = (SELECT m2 FROM consorcio WHERE id_consorcio = @id_consorcio) + @m2_edf;
	DECLARE @ultima_uf INT = (SELECT TOP 1 id_uf FROM unidad_funcional 
					          WHERE id_consorcio = @id_consorcio ORDER BY id_uf DESC);
	
	BEGIN TRAN;
		UPDATE consorcio 
		SET m2 = @m2_consorcio
		WHERE id_consorcio = @id_consorcio;

		UPDATE unidad_funcional 
		SET coef = m2/@m2_consorcio
		WHERE id_consorcio = @id_consorcio;

		UPDATE adicional_uf 
		SET coef = m2/@m2_consorcio
		WHERE id_consorcio = @id_consorcio;

		INSERT INTO unidad_funcional(id_consorcio, id_uf, m2, coef, piso, depto) 
		VALUES (@id_consorcio, @ultima_uf + 1, @m2_edf, @m2_edf/@m2_consorcio, @piso, @depto);
	COMMIT;

	IF @debug = 1
	BEGIN
		SELECT * FROM unidad_funcional
		WHERE id_consorcio = @id_consorcio 
		AND	id_uf = @ultima_uf + 1;
	END;
END;
GO
