if db_id('Com2900G12') is null
	create database Com2900G12 collate Latin1_General_CI_AS;
go

use Com2900G12
go

--------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.GenerarSchemas
    @NombreSchema NVARCHAR(128),
    @Propietario NVARCHAR(128) = 'dbo',
    @ForzarCreacion BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Validar nombre del schema
    IF @NombreSchema IS NULL OR LTRIM(RTRIM(@NombreSchema)) = ''
    BEGIN
        RAISERROR('El nombre del schema no puede estar vacío', 16, 1);
        RETURN;
    END
    
    -- Verificar si el propietario existe
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @Propietario)
    BEGIN
        RAISERROR('El propietario especificado no existe en la base de datos', 16, 1);
        RETURN;
    END
    
    -- Verificar si el schema ya existe
    IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = @NombreSchema)
    BEGIN
        IF @ForzarCreacion = 0
        BEGIN
            PRINT 'El schema ' + @NombreSchema + ' ya existe.';
            RETURN;
        END
        ELSE
        BEGIN
            PRINT 'El schema ya existe pero se continuará con el proceso.';
        END
    END
    ELSE
    BEGIN
        -- Crear el schema
        SET @SQL = N'CREATE SCHEMA ' + QUOTENAME(@NombreSchema) + 
                   N' AUTHORIZATION ' + QUOTENAME(@Propietario);
        
        BEGIN TRY
            EXEC sp_executesql @SQL;
            PRINT 'Schema ' + @NombreSchema + ' creado exitosamente con propietario ' + @Propietario;
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            RAISERROR('Error al crear el schema: %s', 16, 1, @ErrorMessage);
        END CATCH
    END
END;
GO