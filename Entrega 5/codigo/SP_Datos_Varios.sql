IF DB_ID('Com2900G12') IS NULL
    CREATE DATABASE Com2900G12 COLLATE Modern_Spanish_CI_AS;
GO

USE Com2900G12;
GO



IF OBJECT_ID('SP_DatosVarios') IS NOT NULL
    DROP PROCEDURE SP_DatosVarios;
GO

CREATE PROCEDURE SP_DatosVarios
    @RutaExcel NVARCHAR(500) = 'C:\Users\botta\Documents\GitHub\BaseDatosAplicadaGrupo12\Bases-de-datos-aplicadas---Grupo-12\Entrega 5\Archivos_para_importar\datos varios.xlsx'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        
        -- Tabla temporal para Consorcios
        IF OBJECT_ID('tempdb..#TempConsorcios') IS NOT NULL 
            DROP TABLE #TempConsorcios;
            
        CREATE TABLE #TempConsorcios (
            ID_Consorcio varchar(30), 
            Nombre_Consorcio VARCHAR(50), 
            Domicilio VARCHAR(50), 
            Cant_Unidades_Funcionales INT, 
            M2_Totales DECIMAL(10, 2)
        );
        
        -- Importar Consorcios desde Excel
        DECLARE @SQLConsorcios NVARCHAR(MAX);
        SET @SQLConsorcios = '
            INSERT INTO #TempConsorcios (Id_Consorcio, Nombre_Consorcio, Domicilio, Cant_Unidades_Funcionales, M2_Totales)
            SELECT 
                *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;Database=' + @RutaExcel + ';HDR=YES'',
                ''SELECT * FROM [Consorcios$]''
            )';
        
        EXEC sp_executesql @SQLConsorcios;
        
        -- Insertar en tabla Consorcio
        INSERT INTO Consorcio (razon_social, domicilio, m2)
        SELECT 
            t.Nombre_Consorcio, 
            t.Domicilio, 
            t.M2_Totales
        FROM #TempConsorcios t
        WHERE NOT EXISTS (
            SELECT 1 FROM Consorcio c 
            WHERE c.razon_social = t.Nombre_Consorcio
        );
        
        -- Tabla temporal para Proveedores
        IF OBJECT_ID('tempdb..#TempProveedores') IS NOT NULL 
            DROP TABLE #TempProveedores;
            
        CREATE TABLE #TempProveedores (
            Tipo_Gasto NVARCHAR(50),
            Nombre_Detalle NVARCHAR(70), 
            Referencia NVARCHAR(40),    
            Nombre_Consorcio NVARCHAR(50)
        );
        
        -- Importar Proveedores desde Excel
        DECLARE @SQLProveedores NVARCHAR(MAX);
        SET @SQLProveedores = '
            INSERT INTO #TempProveedores (Tipo_Gasto, Nombre_Detalle, Referencia, Nombre_Consorcio)
            SELECT 
                *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;Database=' + @RutaExcel + ';HDR=YES'',
                ''SELECT * FROM [Proveedores$]''
            )';
        
        EXEC sp_executesql @SQLProveedores;
        
        -- Insertar en tabla Proveedor
        INSERT INTO Proveedor (razon_social, cuenta)
        SELECT DISTINCT
            TRIM(t.Nombre_Detalle), 
            TRIM(t.Referencia)
        FROM #TempProveedores t
        WHERE TRIM(t.Nombre_Detalle) IS NOT NULL 
            AND NOT EXISTS (
                SELECT 1 
                FROM Proveedor p 
                WHERE 
                    TRIM(p.razon_social) = TRIM(t.Nombre_Detalle) 
                    AND ISNULL(p.cuenta, '') = ISNULL(TRIM(t.Referencia), '')
            );
            -- Insertar en tabla Proveedor_Consorcio
        INSERT INTO Proveedor_Consorcio (id_consorcio, id_proveedor)
        SELECT DISTINCT 
            c.id,
            p.id
        FROM #TempProveedores t
        JOIN Consorcio c ON c.razon_social = trim(t.Nombre_Consorcio)
        JOIN Proveedor p ON p.razon_social = trim(t.Nombre_Detalle) AND ISNULL(p.cuenta, '') = ISNULL(TRIM(t.Referencia), '')
        WHERE NOT EXISTS (
            SELECT 1 FROM Proveedor_Consorcio pc 
            WHERE pc.id_consorcio = c.id AND pc.id_proveedor = p.id
        );
        
        INSERT INTO Proveedor_Consorcio (id_consorcio, id_proveedor)
        SELECT c.id, p.id 
        FROM Proveedor p 
        CROSS JOIN Consorcio c
        WHERE TRIM(c.razon_social) = 'Alberdi' 
          AND TRIM(p.razon_social) = 'BANCO CREDICOOP - Gastos bancario'
        AND NOT EXISTS (
            SELECT 1 FROM Proveedor_Consorcio pc 
            WHERE pc.id_consorcio = c.id AND pc.id_proveedor = p.id
        );


        INSERT INTO Proveedor_Consorcio (id_consorcio, id_proveedor)
        SELECT c.id, p.id 
        FROM Proveedor p 
        CROSS JOIN Consorcio c
        WHERE TRIM(c.razon_social) = 'Alberdi' 
          AND TRIM(p.razon_social) = 'FLAVIO HERNAN DIAZ - Honorarios'
        AND NOT EXISTS (
            SELECT 1 FROM Proveedor_Consorcio pc 
            WHERE pc.id_consorcio = c.id AND pc.id_proveedor = p.id
        );
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        
        PRINT 'Error en línea ' + CAST(@ErrorLine AS NVARCHAR(10)) + ': ' + @ErrorMessage;
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- Ejecutar el procedimiento
EXEC dbo.SP_DatosVarios;

SELECT * FROM Proveedor_Consorcio
Select * from Proveedor