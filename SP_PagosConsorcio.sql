use Com2900G12

/*
create procedure or alter sp_ImportarPagoConsorcio
	@RutaArchivo nvarchar(500),
	@NombreTabla nvarchar(500),
	@TieneEncabezado BIT = 1,
	@Resultado INT output,
	@Mensaje nvarchar(500) output
as
begin
	set nocount on;

	begin try
		declare @sql nvarchar(max);
		declare @PrimeraFila int = case when @TieneEncabezado = 1 then 2 else 1 end;

		-- Verificar que el archivo existe
		declare @ArchivoExiste int;
		exec master.dbo.xp_fileexist @RutaArchivo, @ArchivoExiste output;

		if @ArchivoExiste = 0
		begin
			set @Resultado = 0;
			print('El archivo no existe');
			return;
		end

		set @sql = '
			bulk insert ' + @NombreTabla + '
			from ''' + @RutaArchivo + '''
			with (
				FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                FIRSTROW = ' + CAST(@PrimeraFila AS NVARCHAR(10)) + ',
                CODEPAGE = ''65001'',
                TABLOCK,
                ERRORFILE = ''C:\Logs\errores_carga.txt''
			)';
		
		exec sp_executesql @sql;

		set @Resultado = 1;
		print('Archivo cargado exitosamente');

	end try
	begin catch
		set @Resultado = 0;
		print('Error');
	end catch
end
go
*/