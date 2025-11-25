CREATE VIEW vw_servicioTipoGasto AS
	SELECT 
		ts.id as id_tipo_servicio,
		ts.descripcion AS descripcion_servicio,
		tg.id as id_tipo_gasto,
		tg.descripcion AS descripcion_gasto
	FROM 
		tipo_servicio ts
	JOIN 
		tipo_gasto tg
		ON tg.id = ts.id_tipo_gasto;
GO
