-- TIP: podriamos poner TOP 1 en cada DECLARE

/** DESCRIP **
    calcula el estado de cuenta de cada uf, como se pide en el enunciado, por un solo consorcio.
    para varios consorcio se puede usar un sp wrapper que itere por todos los consorcios
*/
/** REQUIERE **
  fn_CANT_COCHERAS
  fn_CANT_BAULERAS
*/
/** PARAMS **
  @anio            between(2000, 3000)  -
  @mes             between(1, 12)       -
  @id_consorcio    gt(1)                -
  @porc_venc1      gte(1)               - porcentaje de vencimiento 1
  @porc_venc2      gte(1)               - porcentaje de vencimiento 2
  @precio_cochera  gte(0)               - 
  @precio_baulera  gte(0)               -
*/

CREATE PROCEDURE sp_estadoCuenta(@anio INT,
                                 @mes INT,
                                 @id_consorcio INT,
                                 @porc_venc1 INT,
                                 @porc_venc2 INT,
                                 @precio_cochera NUMERIC(7,2),
                                 @precio_baulera NUMERIC(7,2)) AS
BEGIN
  SET NOCOUNT ON;
  
	DECLARE @anio_anterior INT = @anio;
	DECLARE @mes_anterior INT = @mes - 1;
	IF @mes_anterior = 0
	BEGIN
	    SET @mes_anterior = 12;
	    SET @anio_anterior = @anio - 1;
	END;

	DECLARE @id_expensa_actual INT = (SELECT id_expensa FROM Expensa WHERE anio = @anio AND mes = @mes);
	DECLARE @id_expensa_anterior INT = (SELECT id_expensa FROM Expensa WHERE anio = @anio_anterior AND mes = @mes_anterior);

	DECLARE @saldo_anterior NUMERIC(9,2) = (SELECT COALESCE(SUM(importe), 0) FROM detalle_expensa WHERE id_expensa = @id_expensa_anterior);
	DECLARE @pagos_recibidos NUMERIC(9,2) = (SELECT COALESCE(SUM(monto), 0) FROM pago WHERE id_consorcio = @id_consorcio AND id_expensa = @id_expensa_anterior);
	DECLARE @deuda NUMERIC(9,2) = @saldo_anterior - @pagos_recibidos;
	DECLARE @interes NUMERIC(9,2) = (SELECT (CASE WHEN GETDATE() BETWEEN vencimiento1 AND vencimiento2 THEN @porc_venc1/100 * @deuda
	            								  WHEN GETDATE() > vencimiento2 THEN @porc_venc2/100 * @deuda
	            							 ELSE 0 END)
	            					 FROM Expensa WHERE id_expensa = @id_expensa_actual);

	DECLARE @total_gastos_ord NUMERIC(9,2) = (SELECT COALESCE(SUM(importe), 0) FROM detalle_expensa WHERE tipo_gasto = 'Gastos Ordinarios' AND id_expensa = @id_expensa_actual);
	DECLARE @total_gastos_extr NUMERIC(9,2) = (SELECT COALESCE(SUM(importe), 0) FROM detalle_expensa WHERE tipo_gasto = 'Gastos Extraordinarios' AND id_expensa = @id_expensa_actual);


	SELECT 
		uf.id_uf as [Uf], 
		uf.porc as [%],
		(CASE uf.piso WHEN 0 THEN 'PB' ELSE CAST(uf.piso as VARCHAR(2)) END) + '-' + uf.departamento as [Piso-Depto],
		(p.nombre + ' ' + p.apellido) as [Propietario],
		@saldo_anterior as [Saldo anterior],
		@pagos_recibidos as [Pagos recibidos],
		@deuda as [Deuda],
		@interes as [Interés por mora],
		@total_gastos_ord as [expensas ordinarias],
		(@precio_cochera * fn_CANT_COCHERAS(uf.uf_id)) as [Cocheras],
		(@precio_baulera * fn_CANT_BAULERAS(uf.uf_id)) as [Bauleras],
		@total_gastos_extr as [expensas extraordinarias],
		(@deuda + @interes + @total_gastos_ord + [Cocheras] + [Bauleras] + @total_gastos_extr) as [Total a Pagar] 
	FROM unidad_funcional uf
	JOIN persona_uf puf ON puf.id_uf = uf.id_uf
	JOIN persona p ON p.id_persona = puf.id_persona
	WHERE uf.id_consorcio = @id_consorcio;
END;

