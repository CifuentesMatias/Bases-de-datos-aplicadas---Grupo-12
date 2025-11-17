IF OBJECT_ID('SP_DatosVarios') IS NOT NULL
    DROP PROCEDURE SP_DatosVarios;
GO

CREATE PROCEDURE SP_DatosVarios
    -- Parámetros para las rutas de los archivos
    @RutaConsorcios NVARCHAR(255) = 'C:\Ruta\Completa\datos varios.xlsx - Consorcios.csv',
    @RutaProveedores NVARCHAR(255) = 'C:\Ruta\Completa\datos varios.xlsx - Proveedores.csv'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
      
        IF OBJECT_ID('tempdb..#TempConsorcios') IS NOT NULL DROP TABLE #TempConsorcios;
        CREATE TABLE #TempConsorcios (
            Id_Consorcio_Ref NVARCHAR(50), 
            Nombre_Consorcio NVARCHAR(100), 
            Domicilio NVARCHAR(255), 
            Cant_Unidades_Funcionales INT, 
            M2_Totales DECIMAL(10, 2)
        );
        
        DECLARE @SQLConsorcios NVARCHAR(MAX);
        SET @SQLConsorcios = '
            BULK INSERT #TempConsorcios
            FROM ''' + @RutaConsorcios + ''' 
            WITH (
                FIELDTERMINATOR = '','',     
                ROWTERMINATOR = ''0x0a'',      
                FIRSTROW = 2
            );';
        EXEC sp_executesql @SQLConsorcios;

        INSERT INTO Consorcio (razon_social, direccion, m2)
        SELECT 
            t.Nombre_Consorcio, t.Domicilio, t.M2_Totales
        FROM 
            #TempConsorcios t
        WHERE 
            NOT EXISTS (
                SELECT 1 FROM Consorcio c WHERE c.razon_social = t.Nombre_Consorcio);

        IF OBJECT_ID('tempdb..#TempProveedores') IS NOT NULL DROP TABLE #TempProveedores;
        CREATE TABLE #TempProveedores (
            Columna_Vacia NVARCHAR(255),
            Tipo_Gasto NVARCHAR(255),
            Nombre_Detalle NVARCHAR(255), 
            Referencia NVARCHAR(255),    
            Nombre_Consorcio NVARCHAR(100)
        );

        DECLARE @SQLProveedores NVARCHAR(MAX);
        SET @SQLProveedores = '
            BULK INSERT #TempProveedores
            FROM ''' + @RutaProveedores + ''' 
            WITH (
                FIELDTERMINATOR = '','',     
                ROWTERMINATOR = ''0x0a'',      
                FIRSTROW = 3
            );';
        EXEC sp_executesql @SQLProveedores;

        INSERT INTO Proveedor (razon_social, cuenta)
        SELECT 
            t.Nombre_Detalle, t.Referencia
        FROM 
            #TempProveedores t
        WHERE 
            NOT EXISTS (
                SELECT 1 FROM Proveedor p WHERE p.razon_social = t.Nombre_Detalle);

        INSERT INTO Proveedor_Consorcio (id_consorcio, id_proveedor)
        SELECT DISTINCT 
            c.id,
            p.id
        FROM 
            #TempProveedores t
        JOIN Consorcio c ON c.razon_social = t.Nombre_Consorcio
        JOIN Proveedor p ON p.razon_social = t.Nombre_Detalle;
        
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
    END CATCH
    
END
GO