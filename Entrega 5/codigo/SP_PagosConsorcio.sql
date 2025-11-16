use Com2900G12
go

sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'AllowInProcess', 1;
    
EXEC master.dbo.sp_MSset_oledb_prop 
    N'Microsoft.ACE.OLEDB.16.0', 
    N'DynamicParameters', 1;

GO
-------- IMPORTACION DE PAGOS (pagos_consorcios.csv) --------
create or alter procedure Pagos.sp_ImportarPagosConsorcios
	@RutaArchivo nvarchar(500)
as
begin
	begin try
		set nocount on;

        -- Tabla temporal para recibir datos en crudo (todo como VARCHAR)
        CREATE TABLE #tmpPagoRaw(
            id int not null,
            fecha_pago VARCHAR(20) not null,
            cbu_cvu VARCHAR(30) not null,
            monto VARCHAR(20) not null
        );
        
        -- Cargar archivo CSV usando BULK INSERT dinámico
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 
        N'BULK INSERT #tmpPagoRaw
        FROM '''+@RutaArchivo+'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            TABLOCK,
            CODEPAGE = ''65001''
        );';
        
        PRINT @SQL;
        EXEC sp_executesql @SQL;
        
        -- Insertar limpiando y transformando los datos
        INSERT INTO Pagos.Pago(id_pago, fecha_pago, cbu_cvu, monto)
        SELECT 
            CAST(LTRIM(RTRIM(id)) AS INT),
            CONVERT(DATE, LTRIM(RTRIM(fecha_pago)), 103), -- Convierte el varchar a DATE en formato dd/mm/yyyy
            LTRIM(RTRIM(cbu_cvu)), -- Esto limpia si tiene espacios a derecha o izquierda
            CAST(REPLACE(
                    REPLACE(monto, '$', ''),
                    ',', '.'
                ) AS DECIMAL(10,3))
        FROM #tmpPagoRaw;
        
        -- Mostrar los datos finales
        SELECT * FROM Pagos.Pago;
        
        PRINT 'Importación completada';
        
        -- Limpiar tablas temporales
        DROP TABLE #tmpPagoRaw;
	end try
	begin catch
		print 'Error en la imporacion';
		PRINT ERROR_MESSAGE();
	end catch
end


exec Pagos.sp_ImportarPagosConsorcios @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\consorcios\pagos_consorcios.csv';