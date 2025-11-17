if db_id('Com2900G12') is null
	create database Com2900G12 collate Latin1_General_CI_AS;
go

use Com2900G12
go

--------------------------------------------------------

-- Crear usuario con rol
CREATE OR ALTER PROCEDURE dbo.SP_CrearUsuarioConRol
    @NombreUsuario NVARCHAR(128),
    @Password NVARCHAR(128),
    @TipoRol NVARCHAR(50),
    @Schema NVARCHAR(128) = 'dbo'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Mensaje NVARCHAR(500);
    
    BEGIN TRY
        -- Validaciones
        IF @NombreUsuario IS NULL OR LTRIM(RTRIM(@NombreUsuario)) = ''
        BEGIN
            RAISERROR('El nombre de usuario no puede estar vacío', 16, 1);
            RETURN;
        END
        
        IF @Password IS NULL OR LEN(@Password) < 6
        BEGIN
            RAISERROR('La contraseña debe tener al menos 6 caracteres', 16, 1);
            RETURN;
        END
        
        -- Verificar si el login ya existe
        IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @NombreUsuario)
        BEGIN
            -- Crear LOGIN
            SET @SQL = N'CREATE LOGIN ' + QUOTENAME(@NombreUsuario) + 
                       N' WITH PASSWORD = ' + QUOTENAME(@Password, '''') + 
                       N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF';
            EXEC sp_executesql @SQL;
            PRINT 'LOGIN ' + @NombreUsuario + ' creado exitosamente.';
        END
        ELSE
        BEGIN
            PRINT 'LOGIN ' + @NombreUsuario + ' ya existe.';
        END
        
        -- Verificar si el usuario ya existe en la base de datos
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @NombreUsuario)
        BEGIN
            -- Crear USER en la base de datos
            SET @SQL = N'CREATE USER ' + QUOTENAME(@NombreUsuario) + 
                       N' FOR LOGIN ' + QUOTENAME(@NombreUsuario) + 
                       N' WITH DEFAULT_SCHEMA = ' + QUOTENAME(@Schema);
            EXEC sp_executesql @SQL;
            PRINT 'USER ' + @NombreUsuario + ' creado exitosamente en la base de datos.';
        END
        ELSE
        BEGIN
            PRINT 'USER ' + @NombreUsuario + ' ya existe en la base de datos.';
        END
        
        -- Asignar permisos según el tipo de rol
        IF UPPER(@TipoRol) = 'ADMIN'
        BEGIN
            -- Administrador: acceso total (db_owner)
            EXEC sp_addrolemember 'db_owner', @NombreUsuario;
            SET @Mensaje = 'Usuario ' + @NombreUsuario + ' configurado como ADMINISTRADOR (db_owner).';
        END
        ELSE IF UPPER(@TipoRol) = 'TESORERO'
        BEGIN
            -- Tesorero: puede insertar, actualizar y consultar, pero NO eliminar
            EXEC sp_addrolemember 'db_datareader', @NombreUsuario;
            EXEC sp_addrolemember 'db_datawriter', @NombreUsuario;
            
            -- Denegar permisos de DELETE
            SET @SQL = N'DENY DELETE TO ' + QUOTENAME(@NombreUsuario);
            EXEC sp_executesql @SQL;
            
            SET @Mensaje = 'Usuario ' + @NombreUsuario + ' configurado como TESORERO (lectura/escritura sin DELETE).';
        END
        ELSE IF UPPER(@TipoRol) = 'CONSULTA'
        BEGIN
            -- Usuario de consorcio: solo lectura
            EXEC sp_addrolemember 'db_datareader', @NombreUsuario;
            SET @Mensaje = 'Usuario ' + @NombreUsuario + ' configurado como CONSULTA (solo lectura).';
        END
        ELSE
        BEGIN
            RAISERROR('Tipo de rol no válido. Use: ADMIN, TESORERO o CONSULTA', 16, 1);
            RETURN;
        END
        
        PRINT @Mensaje;
        PRINT 'Usuario creado y configurado exitosamente.';
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error al crear usuario: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

-- Llamar al SP CrearUsuarioConRol
CREATE OR ALTER PROCEDURE dbo.SP_CrearUsuariosDefault
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '========================================';
    PRINT 'Creando usuarios predeterminados...';
    PRINT '========================================';
    PRINT '';
    
    -- Crear Administrador
    EXEC dbo.SP_CrearUsuarioConRol 
        @NombreUsuario = 'admin_expensas',
        @Password = '124Admin!',
        @TipoRol = 'ADMIN';
    PRINT '';
    
    -- Crear Tesorero
    EXEC dbo.SP_CrearUsuarioConRol 
        @NombreUsuario = 'tesorero',
        @Password = 'Teso!124',
        @TipoRol = 'TESORERO';
    PRINT '';
    
    -- Crear Usuario de Consulta
    EXEC dbo.SP_CrearUsuarioConRol 
        @NombreUsuario = 'viewer',
        @Password = 'Consorcio2025!',
        @TipoRol = 'CONSULTA';
    PRINT '';
    
    PRINT '========================================';
    PRINT 'Proceso completado exitosamente.';
    PRINT '========================================';
END;
GO

exec dbo.SP_CrearUsuariosDefault;

-- Eliminar usuarios
CREATE OR ALTER PROCEDURE dbo.SP_EliminarUsuario
    @NombreUsuario NVARCHAR(128),
    @EliminarLogin BIT = 1 -- Si es 1, elimina también el LOGIN
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    BEGIN TRY
        -- Eliminar usuario de la base de datos
        IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @NombreUsuario)
        BEGIN
            SET @SQL = N'DROP USER ' + QUOTENAME(@NombreUsuario);
            EXEC sp_executesql @SQL;
            PRINT 'Usuario ' + @NombreUsuario + ' eliminado de la base de datos.';
        END
        
        -- Eliminar login del servidor (opcional)
        IF @EliminarLogin = 1
        BEGIN
            IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @NombreUsuario)
            BEGIN
                SET @SQL = N'DROP LOGIN ' + QUOTENAME(@NombreUsuario);
                EXEC sp_executesql @SQL;
                PRINT 'Login ' + @NombreUsuario + ' eliminado del servidor.';
            END
        END
        
        PRINT 'Usuario eliminado exitosamente.';
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error al eliminar usuario: %s', 16, 1, @ErrorMessage);
    END CATCH
END;
GO