IF DB_ID('Com2900G12') IS NULL
    CREATE DATABASE Com2900G12 COLLATE Modern_Spanish_CI_AS;
GO

USE Com2900G12;
GO

CREATE OR ALTER PROCEDURE SP_ImportarUFDesdeArchivo
    @RutaArchivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF OBJECT_ID('tempdb..#UF_RAW') IS NOT NULL
            DROP TABLE #UF_RAW;
        
        CREATE TABLE #UF_RAW (
            razon_social NVARCHAR(200),
            nroUnidadFuncional NVARCHAR(10),
            piso NVARCHAR(10),
            departamento NVARCHAR(10),
            coeficiente NVARCHAR(20),
            m2_unidad_funcional NVARCHAR(20),
            bauleras NVARCHAR(10),
            cochera NVARCHAR(10),
            m2_baulera NVARCHAR(20),
            m2_cochera NVARCHAR(20)
        );
        
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #UF_RAW
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ''\t'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                TABLOCK
            );
        ';
        
        EXEC sp_executesql @sql;

        INSERT INTO UF (id_consorcio, id, m2, porcentaje, depto, piso)
        SELECT 
            c.id,
            TRY_CAST(r.nroUnidadFuncional AS INT),
            TRY_CAST(REPLACE(r.m2_unidad_funcional, ',', '.') AS DECIMAL(10,2)),
            TRY_CAST(REPLACE(r.coeficiente, ',', '.') AS DECIMAL(10,2)),
            r.departamento,
            CASE WHEN r.piso = 'PB' THEN 0 ELSE TRY_CAST(r.piso AS INT) END
        FROM #UF_RAW r
        INNER JOIN Consorcio c ON c.razon_social = r.razon_social
        WHERE NOT EXISTS (
            SELECT 1 FROM UF u
            WHERE u.id_consorcio = c.id 
              AND u.id = TRY_CAST(r.nroUnidadFuncional AS INT)
        );
        
        INSERT INTO Adicionales (id_consorcio, id_uf, m2, porcentaje, id_tipo_adicional)
        SELECT 
            c.id,
            TRY_CAST(r.nroUnidadFuncional AS INT),
            TRY_CAST(REPLACE(r.m2_baulera, ',', '.') AS DECIMAL(10,2)),
            TRY_CAST(REPLACE(r.coeficiente, ',', '.') AS DECIMAL(10,2)) * 0.1,
            (SELECT id FROM Tipo_adicional WHERE descripcion LIKE '%Baulera%')
        FROM #UF_RAW r
        INNER JOIN Consorcio c ON c.razon_social = r.razon_social
        WHERE UPPER(r.bauleras) = 'SI'
          AND NOT EXISTS (
              SELECT 1 FROM Adicionales a
              WHERE a.id_consorcio = c.id 
                AND a.id_uf = TRY_CAST(r.nroUnidadFuncional AS INT)
                AND a.id_tipo_adicional = (SELECT id FROM Tipo_adicional WHERE descripcion LIKE '%Baulera%')
          );

        INSERT INTO Adicionales (id_consorcio, id_uf, m2, porcentaje, id_tipo_adicional)
        SELECT 
            c.id,
            TRY_CAST(r.nroUnidadFuncional AS INT),
            TRY_CAST(REPLACE(r.m2_cochera, ',', '.') AS DECIMAL(10,2)),
            TRY_CAST(REPLACE(r.coeficiente, ',', '.') AS DECIMAL(10,2)) * 0.15,
            (SELECT id FROM Tipo_adicional WHERE descripcion LIKE '%Cochera%')
        FROM #UF_RAW r
        INNER JOIN Consorcio c ON c.razon_social = r.razon_social
        WHERE UPPER(r.cochera) = 'SI'
          AND NOT EXISTS (
              SELECT 1 FROM Adicionales a
              WHERE a.id_consorcio = c.id 
                AND a.id_uf = TRY_CAST(r.nroUnidadFuncional AS INT)
                AND a.id_tipo_adicional = (SELECT id FROM Tipo_adicional WHERE descripcion LIKE '%Cochera%')
          );
        
        DROP TABLE #UF_RAW;
        
        COMMIT TRANSACTION;
        PRINT '✓ Importación completada';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

EXEC SP_ImportarUFDesdeArchivo 
    @RutaArchivo = 'C:\Temp\Consorcios\UF por consorcio.txt';

SELECT * FROM UF;
SELECT * FROM Adicionales;
