
/** NOTAS IMPORTANTES **
   esta deshabilitado por defecto sp_OACreate.
   Ejecutar como administrador:
   
   EXEC sp_configure 'show advanced options', 1;
   RECONFIGURE;
   EXEC sp_configure 'Ole Automation Procedures', 1;
   RECONFIGURE;
*/

/** TESTING **
  DECLARE @cot_venta DECIMAL(10,2), @cot_compra DECIMAL(10,2);
  EXEC sp_actualizarCotizacionDolar NULL, @cot_venta OUTPUT, @cot_compra OUTPUT;
  PRINT 'cotizacion_venta:  ' + CAST(@cot_venta  AS VARCHAR(20));
  PRINT 'cotizacion_compra: ' + CAST(@cot_compra AS VARCHAR(20));
  
  SELECT * FROM ##cotizacion_dolar
*/

CREATE PROCEDURE sp_actualizarCotizacionDolar(@fechaActual DATE = NULL, @cot_venta DECIMAL(10,2) OUTPUT, @cot_compra DECIMAL(10,2) OUTPUT) AS
BEGIN
    SET NOCOUNT ON;
    
    -- fecha por defecto
    IF @fechaActual IS NULL SET @fechaActual = GETDATE();

    -- crear tabla temporal global si no existe
    IF OBJECT_ID('tempdb..##cotizacion_dolar') IS NULL
    BEGIN
        CREATE TABLE ##cotizacion_dolar
        (
            fecha DATE PRIMARY KEY,
            valor_compra DECIMAL(10, 2),
            valor_venta DECIMAL(10, 2)
        );
    END;


    SELECT @cot_venta = valor_venta, @cot_compra = valor_compra
    FROM ##cotizacion_dolar
    WHERE fecha = @fechaActual;


    IF @cot_venta IS NULL
    BEGIN
        DECLARE @url NVARCHAR(256) = 'https://dolarapi.com/v1/dolares/oficial';
        DECLARE @respuesta NVARCHAR(MAX);
		    DECLARE @json TABLE(respuesta NVARCHAR(MAX))	
        DECLARE @obj INT;
        
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @obj OUTPUT;
        EXEC sp_OAMethod @obj, 'OPEN', NULL, 'GET', @url, false;
        EXEC sp_OAMethod @obj, 'SEND';
		    EXEC sp_OAMethod @obj, 'RESPONSETEXT', @respuesta OUTPUT

        INSERT @json EXEC sp_OAGetProperty @obj, 'RESPONSETEXT';
		    --SELECT respuesta FROM @json

        DECLARE @datos NVARCHAR(MAX) = (SELECT * FROM @json);
    		INSERT INTO ##cotizacion_dolar (fecha, valor_compra, valor_venta)
    		SELECT
    			GETDATE(),
    			compra,
    			venta
    		FROM 
    			OPENJSON(@datos)
    		WITH
    		(
    			compra DECIMAL(10,2) '$.compra',
    			venta DECIMAL(10,2) '$.venta'
    		);

    		--SELECT * FROM ##cotizacion_dolar
    
    		SELECT
    			@cot_compra = valor_compra,
    			@cot_venta = valor_venta
    		FROM
    			##cotizacion_dolar

        EXEC sp_OADestroy @obj;
    END;
END;
GO
