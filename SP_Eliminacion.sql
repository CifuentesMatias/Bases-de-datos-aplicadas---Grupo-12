use Com2900G12
go;

create or alter procedure Personas.BorrarPersona
	@idPersona int
AS
BEGIN
	SET NOCOUNT ON

	begin
		try
			begin transaction
				if exists(select 1 from Personas.Persona where id_persona = @idPersona)
				begin
					if exists(select 1 from Edificio.Consorcio where id_administrador = @idPersona)
					begin
						delete from Edificio.Consorcio
						where id_administrador = @idPersona
					end

					if exists(select 1 from Expensas.Expensa where id_pagador = @idPersona)
					begin
						delete from Expensas.Expensa
						where id_pagador = @idPersona
					end	
						
					end

					else
					begin
						print('No se pudo borrar a la persona deseada')
						raiserror('No se pudo borrar a la persona deseada porque es administrador del consorcio', 16, 1)
					end
				end
				else
				begin
					print('No existe la persona')
					raiserror('No existe la persona')
				end
		end try
		begin catch
			if ERROR_SEVERITY() > 10
			begin
				raiserror('Ocurrio algo en el borrado de la persona', 16, 1)
				if @@TRANCOUNT > 0
				begin
					rollback transaction
				end
				return;
			end
			if ERROR_SEVERITY() = 10
			begin
				commit transaction
				return;
			end
		end catch
		commit transaction
	end

END
GO