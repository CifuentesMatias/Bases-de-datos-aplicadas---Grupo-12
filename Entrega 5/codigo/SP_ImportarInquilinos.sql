if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go

use Com2900G12
go

CREATE OR ALTER PROCEDURE SP_ImportarInquilinosDesdeArchivo
    @RutaArchivo NVARCHAR(500) = 'C:\Users\botta\Documents\GitHub\BaseDatosAplicadaGrupo12\Bases-de-datos-aplicadas---Grupo-12\Entrega 5\Archivos_para_importar\Inquilino-propietarios-datos.csv'
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        IF OBJECT_ID('tempdb..#tmpPersona') IS NOT NULL DROP TABLE #tmpPersona; 
        CREATE TABLE #tmpPersona (
            nombre nvarchar(50) not null,
            apellido nvarchar(50) not null,
            dni varchar(8) not null check(dni not like '%[^0-9]%'),
            email varchar(200) not null,
            telefono varchar(10) not null,
            cvu_cbu varchar(30) not null,
            propiedad tinyint not null
        );


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

        INSERT INTO Persona(dni, nombre, apellido, email, cvu_cbu, telefono, id_tipo_relacion)
        SELECT 
            t.dni, 
            LOWER(TRIM(t.nombre)) as nombre, 
            LOWER(TRIM(t.apellido)) as apellido, 
            LOWER(TRIM(t.email)) as email, 
            t.cvu_cbu, 
            t.telefono, 
            t.propiedad 
        FROM 
            #tmpPersona t
        WHERE NOT EXISTS ( 
            SELECT 1 
            FROM Persona p 
            WHERE p.cvu_cbu = t.cvu_cbu
        ); 

        DROP TABLE #tmpPersona;
        
        PRINT 'Importación de Personas completada exitosamente, evitando duplicados.';
    END TRY
    BEGIN CATCH
        PRINT 'Error en la importación';
        PRINT ERROR_MESSAGE();

        IF OBJECT_ID('tempdb..#tmpPersona') IS NOT NULL
            DROP TABLE #tmpPersona;
    END CATCH
END
GO

exec SP_ImportarInquilinosDesdeArchivo;

SELECT * FROM Persona;