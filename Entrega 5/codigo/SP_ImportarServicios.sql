IF DB_ID('Com2900G12') IS NULL
    CREATE DATABASE Com2900G12 COLLATE Modern_Spanish_CI_AS;;
GO

USE Com2900G12;
GO

-- Eliminar SP si existe
IF OBJECT_ID('SP_ImportarServicios', 'P') IS NOT NULL
    DROP PROCEDURE SP_ImportarServicios;
GO

CREATE PROCEDURE SP_ImportarServicios
    @json NVARCHAR(MAX),              -- JSON a importar
    @anio INT = 2024,                 -- Año de las expensas (default: 2024)
    @crearProveedores BIT = 1         -- Si crear proveedores que no existen
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#TempServicios') IS NOT NULL DROP TABLE #TempServicios;
        
        CREATE TABLE #TempServicios (
            RowNum INT IDENTITY(1,1),
            NombreConsorcio NVARCHAR(100),
            Mes NVARCHAR(20),
            MesNumero INT,
            Anio INT,
            Bancarios DECIMAL(18,2),
            Limpieza DECIMAL(18,2),
            Administracion DECIMAL(18,2),
            Seguros DECIMAL(18,2),
            GastosGenerales DECIMAL(18,2),
            ServiciosAgua DECIMAL(18,2),
            ServiciosLuz DECIMAL(18,2),
            IdConsorcio INT,
            IdExpensa INT
        );
        
        INSERT INTO #TempServicios (NombreConsorcio, Mes, Anio, Bancarios, Limpieza, Administracion, 
                                    Seguros, GastosGenerales, ServiciosAgua, ServiciosLuz)
        SELECT 
            JSON_VALUE(value, '$."Nombre del consorcio"') COLLATE Modern_Spanish_CI_AS AS NombreConsorcio,
            RTRIM(JSON_VALUE(value, '$.Mes')) AS Mes,
            @anio AS Anio,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$.BANCARIOS'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS Bancarios,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$.LIMPIEZA'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS Limpieza,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$.ADMINISTRACION'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS Administracion,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$.SEGUROS'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS Seguros,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$."GASTOS GENERALES"'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS GastosGenerales,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$."SERVICIOS PUBLICOS-Agua"'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS ServiciosAgua,
            TRY_CAST(REPLACE(REPLACE(JSON_VALUE(value, '$."SERVICIOS PUBLICOS-Luz"'), '.', ''), ',', '.') AS DECIMAL(18,2)) AS ServiciosLuz
        FROM OPENJSON(@json)
        WHERE JSON_VALUE(value, '$."Nombre del consorcio"') IS NOT NULL;

        UPDATE #TempServicios
        SET MesNumero = CASE LOWER(RTRIM(Mes))
            WHEN 'enero' THEN 1
            WHEN 'febrero' THEN 2
            WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4
            WHEN 'mayo' THEN 5
            WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7
            WHEN 'agosto' THEN 8
            WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10
            WHEN 'noviembre' THEN 11
            WHEN 'diciembre' THEN 12
        END;

        UPDATE t
        SET t.IdConsorcio = c.id
        FROM #TempServicios t
        INNER JOIN Consorcio c ON c.razon_social LIKE '%' + t.NombreConsorcio + '%';
        
        IF EXISTS (SELECT 1 FROM #TempServicios WHERE IdConsorcio IS NULL)
        BEGIN
            PRINT 'ERROR: Los siguientes consorcios NO EXISTEN en la BD:';
            SELECT DISTINCT NombreConsorcio 
            FROM #TempServicios 
            WHERE IdConsorcio IS NULL;
            PRINT '';
            PRINT 'Debe crear estos consorcios manualmente antes de importar.';
            
            RAISERROR('Existen consorcios no encontrados. Créelos antes de importar.', 16, 1);
            RETURN;
        END
        
        -- =====================================================
        -- PASO 6: Crear proveedores por consorcio si no existen
        -- =====================================================
        IF OBJECT_ID('tempdb..#ProveedoresNecesarios') IS NOT NULL DROP TABLE #ProveedoresNecesarios;
        
        CREATE TABLE #ProveedoresNecesarios (
            IdConsorcio INT,
            NombreConsorcio NVARCHAR(100),
            TipoProveedor NVARCHAR(50),
            RazonSocial NVARCHAR(200),
            IdProveedor INT
        );
        
        -- Identificar proveedores necesarios
        INSERT INTO #ProveedoresNecesarios (IdConsorcio, NombreConsorcio, TipoProveedor, RazonSocial)
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Banco', 'Banco ' + NombreConsorcio 
        FROM #TempServicios WHERE Bancarios > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Limpieza', 'Limpieza ' + NombreConsorcio 
        FROM #TempServicios WHERE Limpieza > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Administracion', 'Administración ' + NombreConsorcio 
        FROM #TempServicios WHERE Administracion > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Seguro', 'Seguros ' + NombreConsorcio 
        FROM #TempServicios WHERE Seguros > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Luz', 'EDESUR - ' + NombreConsorcio 
        FROM #TempServicios WHERE ServiciosLuz > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'Agua', 'AYSA - ' + NombreConsorcio 
        FROM #TempServicios WHERE ServiciosAgua > 0
        UNION
        SELECT DISTINCT IdConsorcio, NombreConsorcio, 'General', 'Servicios Generales ' + NombreConsorcio 
        FROM #TempServicios WHERE GastosGenerales > 0;
        
        UPDATE pn
        SET pn.IdProveedor = p.id
        FROM #ProveedoresNecesarios pn
        INNER JOIN Proveedor p ON p.id = pn.IdConsorcio
            AND (
                (pn.TipoProveedor = 'Banco' AND (p.razon_social LIKE '%Banco%' OR p.razon_social LIKE '%Galicia%'))
                OR (pn.TipoProveedor = 'Limpieza' AND p.razon_social LIKE '%Limpieza%')
                OR (pn.TipoProveedor = 'Administracion' AND p.razon_social LIKE '%Administra%')
                OR (pn.TipoProveedor = 'Seguro' AND p.razon_social LIKE '%Seguro%')
                OR (pn.TipoProveedor = 'Luz' AND (p.razon_social LIKE '%EDESUR%' OR p.razon_social LIKE '%Electric%'))
                OR (pn.TipoProveedor = 'Agua' AND (p.razon_social LIKE '%AYSA%' OR p.razon_social LIKE '%Agua%'))
                OR (pn.TipoProveedor = 'General' AND p.razon_social LIKE '%General%')
            );
        
        -- Crear proveedores faltantes si está habilitado
        IF @crearProveedores = 1
        BEGIN
            INSERT INTO Proveedor (razon_social, id)
            SELECT pn.RazonSocial, pn.IdConsorcio
            FROM #ProveedoresNecesarios pn
            WHERE pn.IdProveedor IS NULL;

            -- Actualizar IDs de proveedores recién creados
            UPDATE pn
            SET pn.IdProveedor = p.id
            FROM #ProveedoresNecesarios pn
            INNER JOIN Proveedor p ON p.razon_social = pn.RazonSocial 
                                  AND p.id = pn.IdConsorcio
            WHERE pn.IdProveedor IS NULL;
        END

        IF EXISTS (SELECT 1 FROM #ProveedoresNecesarios WHERE IdProveedor IS NULL)
        BEGIN
            PRINT 'ERROR: Proveedores no encontrados:';
            SELECT IdConsorcio, TipoProveedor, RazonSocial
            FROM #ProveedoresNecesarios 
            WHERE IdProveedor IS NULL;
            
            RAISERROR('Existen proveedores sin mapear. Revise los datos.', 16, 1);
            RETURN;
        END
        
        -- =====================================================
        -- PASO 7: Obtener IDs de Tipo_Servicio
        -- =====================================================
        DECLARE @IdServicioBancario INT, @IdServicioLimpieza INT, @IdServicioAdmin INT,
                @IdServicioSeguro INT, @IdServicioPublico INT, @IdServicioGeneral INT;
        
        SELECT @IdServicioBancario = id FROM Tipo_Servicio 
        WHERE descripcion LIKE '%Cuenta Bancaria%' OR descripcion LIKE '%Bancari%';
        
        SELECT @IdServicioLimpieza = id FROM Tipo_Servicio 
        WHERE descripcion LIKE '%Limpieza%';
        
        SELECT @IdServicioAdmin = id FROM Tipo_Servicio 
        WHERE descripcion LIKE '%Administra%';
        
        SELECT @IdServicioSeguro = id FROM Tipo_Servicio 
        WHERE descripcion LIKE '%Seguro%';
        
        SELECT @IdServicioPublico = ts.id 
        FROM Tipo_Servicio ts
        INNER JOIN Tipo_Gasto tg ON ts.id_tipo_gasto = tg.id
        WHERE tg.descripcion LIKE '%Servicios P_blicos%' 
           OR ts.descripcion LIKE '%Luz%' 
           OR ts.descripcion LIKE '%Agua%';
        
        SELECT @IdServicioGeneral = id FROM Tipo_Servicio 
        WHERE descripcion LIKE '%Mantenimiento General%' OR descripcion LIKE '%General%';

        INSERT INTO Expensa (id_consorcio, anio, mes, vence1, vence2)
        SELECT DISTINCT
            t.IdConsorcio,
            t.Anio,
            t.MesNumero,
            DATEFROMPARTS(t.Anio, t.MesNumero, 10),
            DATEFROMPARTS(t.Anio, t.MesNumero, 20)
        FROM #TempServicios t
        WHERE t.IdConsorcio IS NOT NULL
          AND t.MesNumero IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM Expensa e
              WHERE e.id_consorcio = t.IdConsorcio
                AND e.anio = t.Anio
                AND e.mes = t.MesNumero
          );

        UPDATE t
        SET t.IdExpensa = e.id
        FROM #TempServicios t
        INNER JOIN Expensa e ON e.id_consorcio = t.IdConsorcio
                            AND e.anio = t.Anio
                            AND e.mes = t.MesNumero
        WHERE t.IdConsorcio IS NOT NULL;
        
        INSERT INTO Detalle_Expensa (id_expensa, fecha, importe, id_proveedor, id_tipo_servicio, descripcion)
        -- GASTOS BANCARIOS
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 1),
            t.Bancarios,
            pn.IdProveedor,
            @IdServicioBancario,
            'Gastos bancarios ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Banco'
        WHERE t.IdExpensa IS NOT NULL AND t.Bancarios > 0
        
        UNION ALL
        
        -- LIMPIEZA
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 2),
            t.Limpieza,
            pn.IdProveedor,
            @IdServicioLimpieza,
            'Servicio de limpieza ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Limpieza'
        WHERE t.IdExpensa IS NOT NULL AND t.Limpieza > 0
        
        UNION ALL
        
        -- ADMINISTRACIÓN
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 3),
            t.Administracion,
            pn.IdProveedor,
            @IdServicioAdmin,
            'Honorarios administrativos ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Administracion'
        WHERE t.IdExpensa IS NOT NULL AND t.Administracion > 0
        
        UNION ALL
        
        -- SEGUROS
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 5),
            t.Seguros,
            pn.IdProveedor,
            @IdServicioSeguro,
            'Seguro consorcio ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Seguro'
        WHERE t.IdExpensa IS NOT NULL AND t.Seguros > 0
        
        UNION ALL
        
        -- SERVICIOS PÚBLICOS - LUZ
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 8),
            t.ServiciosLuz,
            pn.IdProveedor,
            @IdServicioPublico,
            'EDESUR - Luz ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Luz'
        WHERE t.IdExpensa IS NOT NULL AND t.ServiciosLuz > 0
        
        UNION ALL
        
        -- SERVICIOS PÚBLICOS - AGUA
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 10),
            t.ServiciosAgua,
            pn.IdProveedor,
            @IdServicioPublico,
            'AYSA - Agua ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'Agua'
        WHERE t.IdExpensa IS NOT NULL AND t.ServiciosAgua > 0
        
        UNION ALL
        
        -- GASTOS GENERALES
        SELECT 
            t.IdExpensa,
            DATEFROMPARTS(t.Anio, t.MesNumero, 15),
            t.GastosGenerales,
            pn.IdProveedor,
            @IdServicioGeneral,
            'Gastos generales ' + t.Mes + ' ' + CAST(t.Anio AS VARCHAR(4))
        FROM #TempServicios t
        INNER JOIN #ProveedoresNecesarios pn ON t.IdConsorcio = pn.IdConsorcio AND pn.TipoProveedor = 'General'
        WHERE t.IdExpensa IS NOT NULL AND t.GastosGenerales > 0;
        
        INSERT INTO Gasto_Ordinario (id_gasto, nro_factura)
        SELECT 
            de.id_det_exp,
            'FC-' + FORMAT(de.id_det_exp, '0000') + '-' + FORMAT(YEAR(de.fecha), '0000')
        FROM Detalle_Expensa de
        WHERE de.id_expensa IN (SELECT IdExpensa FROM #TempServicios)
          AND NOT EXISTS (
              SELECT 1 FROM Gasto_Ordinario gastoOrd WHERE gastoOrd.id_gasto = de.id_det_exp
          );


         DROP TABLE #TempServicios;
         DROP TABLE #ProveedoresNecesarios;
        
         COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'ERROR EN LA IMPORTACIÓN:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'SP_ImportarServicios');
        
        THROW;
    END CATCH
END


DECLARE @jsonData NVARCHAR(MAX);
SELECT @jsonData = BulkColumn
FROM OPENROWSET(BULK 'C:\Temp\Consorcios\Servicios.Servicios.json', SINGLE_CLOB) AS j;

EXEC SP_ImportarServicios 
    @json = @jsonData,
    @anio = 2024,
    @crearProveedores = 1;