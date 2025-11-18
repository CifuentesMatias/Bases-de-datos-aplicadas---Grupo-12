if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go

use Com2900G12
go

--------------------------------------------------------

-------- IMPORTACION DE PERSONAS (inquilino-propietarios-datos.csv) --------
CREATE OR ALTER PROCEDURE SP_ImportarInquilinosDesdeArchivo
    @RutaArchivo NVARCHAR(500) = 'C:\Temp\Consorcios\Inquilino-propietarios-datos.csv'
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        
        -- Crear tabla temporal SIN restricciones para capturar todos los datos
        CREATE TABLE #tmpPersona (
	        nombre nvarchar(50) not null,
	        apellido nvarchar(50) not null,
            dni varchar(8) not null check(dni not like '%[^0-9]%'),
	        email varchar(200) not null,
            telefono varchar(10) not null,
	        cvu_cbu varchar(30) not null,
            propiedad tinyint not null,
        );
        
        -- Cargar archivo CSV usando BULK INSERT dinámico
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 
        N'BULK INSERT #tmpPersona
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );';
        
        EXEC (@SQL);
        
        
        -- Validar y limpiar datos antes de insertar
        INSERT INTO Persona(dni, nombre, apellido, email, cvu_cbu, telefono)
        SELECT dni, LOWER(TRIM(nombre)) as nombre, LOWER(TRIM(apellido)) as apellido, LOWER(TRIM(email)) as email, cvu_cbu, telefono FROM #tmpPersona;
        
        -- Limpiar tabla temporal
        DROP TABLE #tmpPersona;
        
    END TRY
    BEGIN CATCH
        PRINT 'Error en la importación';
        PRINT ERROR_MESSAGE();

        -- Limpiar si existe
        IF OBJECT_ID('tempdb..#tmpPersona') IS NOT NULL
            DROP TABLE #tmpPersona;
    END CATCH
END
GO

exec SP_ImportarInquilinosDesdeArchivo;

SELECT * FROM Persona;