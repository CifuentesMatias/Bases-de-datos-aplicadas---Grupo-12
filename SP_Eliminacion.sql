use Com2900G12
go;

create or alter procedure sp_EliminarPersona
	@IdPersona int
as
begin
	set nocount on;

	begin try
		begin transaction;

		-- Verificar si existe esa persona
		if not exists(select 1 from Personas.Persona where id_persona = @IdPersona)
		begin
			print('No existe el usuario buscado')
			rollback transaction
			return;
		end

		-- Verificar si la persona es administrador de algún consorcio
		if exists(select 1 from Edificio.Consorcio where id_administrador = @IdPersona)
		begin
			print('No se puede eliminar porque la persona es administrador del consorcio')
			rollback transaction;
			return;
		end

		-- Eliminar las expensas asociadas (relacion 1 a N)
		delete from Expensas.Expensa where id_persona = @IdPersona;

		-- Eliminar la persona
		delete from Persona where Id = @IdPersona

		commit transaction;

		print('Persona eliminada existosamente')
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;

		print('Error: ' + ERROR_MESSAGE());
	end catch
end
go

create or alter sp_EliminarConsorcio
	@IdConsorcio
as
begin
	set nocount on;
	
	begin try
		begin transaction;

		-- Verificar si existe consorcio
		if not exists(select 1 from Edificio.Consorcio where id_consorcio = @IdConsorcio)
		begin
			print('No existe el consorcio buscado')
			rollback transaction;
			return;
		end

		-- Eliminar consorcio de la unidad funcional

	end try
end