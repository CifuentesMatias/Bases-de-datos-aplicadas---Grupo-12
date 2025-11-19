CREATE PROCEDURE sp_agregarPersonaUf(@dni INT, @cbu_cvu CHAR(22), @nombre_consorcio NVARCHAR(50), @piso INT, @depto CHAR(1), @es_propietario BIT) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @id_consorcio INT = (SELECT id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);
	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;

	DECLARE @id_uf INT = (SELECT id_uf FROM unidad_funcional WHERE id_consorcio = @id_consorcio AND piso = @piso AND depto = @depto);
	IF @id_uf IS NULL
	BEGIN
		RAISERROR('Esa unidad funcional no existe', 16, 2);
		RETURN;
	END;

	IF EXISTS (SELECT 1 FROM persona WHERE dni = @dni) OR EXISTS (SELECT 1 FROM persona WHERE cbu_cvu = @cbu_cvu)
	BEGIN
		RAISERROR('Esa persona ya existe', 16, 3);
		RETURN;
	END;
	SET NOCOUNT OFF;

	INSERT INTO persona(dni, cbu_cvu) VALUES (@dni, @cbu_cvu);
	DECLARE @id_persona INT = SCOPE_IDENTITY();
	INSERT INTO persona_uf(id_consorcio, id_uf, id_persona, es_propietario, fecha_alta) VALUES
	(@id_consorcio, @id_uf, @id_persona, @es_propietario, GETDATE());
END;
GO
