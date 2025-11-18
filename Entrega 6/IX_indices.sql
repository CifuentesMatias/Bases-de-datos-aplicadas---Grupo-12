
/*
	-- tabla persona NO ES NECESARIO por UNIQUE (--busqueda por DNI --busqueda por cbu_cvu)
	-- prorateo PK en (id_consorcio, id_uf, anio, mes)
	-- expensa PK en (id_consorcio, anio, mes)
	-- caja PK en (id_consorcio, anio, mes)
	-- unidad_funcional PK en (id_consorcio, id_uf)
*/
/*
	-- uso de indices
	   SELECT * FROM sys.dm_db_index_usage_stats 
	   WHERE database_id = DB_ID();

	-- mantenimiento
	-- NOTA: [tabla] es el nombre de la tabla a optimizar
	   ALTER INDEX ALL ON [tabla] REORGANIZE;
	   UPDATE STATISTICS [tabla];
 */

-- tabla pago
CREATE NONCLUSTERED INDEX --busqueda por consorcio, rango de fechas
	IX_pago_consorcio_fecha ON
	pago(id_consorcio, fecha_pago) INCLUDE
	(id_uf, monto);
GO
CREATE NONCLUSTERED INDEX -- Filtrado por consorcio y fecha, agrupado por UF
	IX_pago_consorcio_uf_fecha ON
	pago(id_consorcio, id_uf, fecha_pago);
GO
-- tabla prorateo 			
CREATE NONCLUSTERED INDEX --busqueda por consorcio y periodo
	IX_prorateo_consorcio_periodo ON
	prorateo(id_consorcio, anio, mes) INCLUDE
	(id_uf, pagos_recibidos);
GO
CREATE NONCLUSTERED INDEX ---busqueda por consorcio y periodo, agrupado por UF
	IX_prorateo_consorcio_anio_mes_uf ON
	prorateo(id_consorcio, anio, mes, id_uf) INCLUDE
	(saldo_final, monto_coc, monto_bau, monto_ord, monto_ext, pagos_recibidos);
GO
-- tabla consorcio
CREATE NONCLUSTERED INDEX --asociar nombre a pk
	IX_consorcio_razon_social ON
	consorcio(razon_social) INCLUDE
	(id_consorcio);
GO
-- tabla persona_uf
CREATE NONCLUSTERED INDEX --para fn_ultimoResidentes 
	IX_persona_uf_consorcio_fecha ON
	persona_uf(id_consorcio, id_uf, fecha_alta) INCLUDE
	(id_persona, es_propietario);
GO
