if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go

use Com2900G12
go

create or alter procedure SP_ImportarPagosConsorcios
	@RutaArchivo nvarchar(1000)
as
begin
	SET NOCOUNT ON;
    
    DECLARE @ErrorState INT;

	begin try
        BEGIN TRANSACTION;
        IF OBJECT_ID('tempdb..#tmpPagoRaw') IS NOT NULL DROP TABLE #tmpPagoRaw;

        SET IDENTITY_INSERT Pago ON;

        CREATE TABLE #tmpPagoRaw(
            id varchar(10) not null,
            fecha_pago VARCHAR(20) not null,
            cbu_cvu VARCHAR(30) not null,
            monto VARCHAR(20) not null
        );

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
        

        EXEC sp_executesql @SQL;
        
        INSERT INTO Pago(id_pago, fecha_pago, cbu_cvu, monto)
        SELECT 
            CAST(TRIM(T.id) AS INT),
            CONVERT(DATE, TRIM(T.fecha_pago), 103),
            TRIM(T.cbu_cvu),
            CAST(M.MontoLimpio AS DECIMAL(10,3))
        FROM #tmpPagoRaw T
        CROSS APPLY (
            SELECT TRIM(REPLACE(REPLACE(REPLACE(T.monto, '$', ''),'.', ''), ',', '.')) AS MontoLimpio
        ) AS M
        WHERE 
            TRIM(T.id) <> ''
            AND ISNUMERIC(M.MontoLimpio) = 1 
            AND M.MontoLimpio <> ''
            AND NOT EXISTS (SELECT 1 FROM Pago p WHERE p.id_pago = CAST(TRIM(T.id) AS INT));

        COMMIT TRANSACTION;
        
        SET IDENTITY_INSERT Pago OFF;
        
        SELECT * FROM Pago;
        
        DROP TABLE #tmpPagoRaw;
	end try
	begin catch
        SET @ErrorState = XACT_STATE();

        IF @ErrorState <> 0 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
		print 'Error en la imporacion';
		PRINT 'Mensaje Detallado: ' + ERROR_MESSAGE();
        PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
	end catch
end
go

exec SP_ImportarPagosConsorcios
@RutaArchivo = 'C:\Users\botta\Documents\GitHub\BaseDatosAplicadaGrupo12\Bases-de-datos-aplicadas---Grupo-12\Entrega 5\Archivos_para_importar\pagos_consorcios.csv';