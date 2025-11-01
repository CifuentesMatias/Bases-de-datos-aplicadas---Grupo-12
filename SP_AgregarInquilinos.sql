use Com2900G12
go

create or alter procedure sp_ImportarInquilinos
as
begin
	set nocount on;

	begin try
		bulk insert Persons.Persona
		from 'C:\SQL2022\Inquilino-propietarios-datos.csv'
		with (
			FORMAT = 'CSV',
			FIELDTERMINATOR = ';', 
			ROWTERMINATOR = '\n', 
			FIRSTROW = 2,
			CODEPAGE = '65001'  -- UTF-8, útil si hay acentos
		);

		print 'Importación completada';
	end try
	begin catch
		print 'Error en la imporacion: ' + ERROR_MESSAGE();
	end catch
end
go

exec sp_ImportarInquilinos;
EXEC xp_fileexist 'C:\Users\Admin\Downloads\consorcios\Inquilino-propietarios-datos.csv';
SELECT @@VERSION;