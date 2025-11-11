CREATE FUNCTION fn_CONSORCIO_ID(@nombre_consorcio NVARCHAR(50)) RETURNS INT AS
BEGIN
	RETURN (SELECT COALESCE(id_consorcio, 0) FROM consorcio WHERE nombre = @nombre_consorcio);
END; GO
CREATE FUNCTION fn_NROSEMANA_MES(@fecha DATE) RETURNS INT AS
BEGIN
	/*
						     DAY(fecha)	→ 	DAY('2025-11-15') = 15
						 1 - DAY(fecha) → 	1 - 15 = -14
		DATEADD(DAY, -14, '2025-11-15') → 	'2025-11-01'
	*/
    RETURN (DATEPART(WEEK, @fecha) - DATEPART(WEEK, DATEADD(DAY, 1 - DAY(@fecha), @fecha)) + 1);
END; GO
CREATE FUNCTION fn_DATE_CORTO(@anio INT, @mes INT) RETURNS CHAR(7) AS
BEGIN
    RETURN (FORMAT(DATEFROMPARTS(@anio, @mes, 1), 'yyyy-MM'));
END; GO

/** COMMENTS **
	se usa tecnica de enum como en C, para mapear una string a valor
*/
/** DESCRIP **
    calcula cantidad y m2 totales de cocheras/bauleras
    retorna 0 para ambos casos si no encuentra nada
*/
/** REQUIERE **
  table Adicionales
*/
/** PARAMS **
  @id_consorcio    gte(1)               -
  @id_uf           gte(1)               - 
*/

CREATE FUNCTION fn_CANT_COCHERAS(@id_consorcio INT, @id_uf INT) RETURNS INT AS
BEGIN
	DECLARE @id_cochera INT = (SELECT id_tipo FROM tipo_adicional WHERE descripcion = 'Cochera');

	RETURN (SELECT COALESCE(COUNT(*), 0) 
			    FROM adicionales a 
			    WHERE id_consorcio = @id_consorcio AND id_uf = @id_uf AND a.tipo = @id_cochera);
END; GO
CREATE FUNCTION fn_M2TOTAL_COCHERAS(@id_consorcio INT, @id_uf INT) RETURNS NUMERIC(5,2) AS
BEGIN
	DECLARE @id_cochera INT = (SELECT id_tipo FROM tipo_adicional WHERE descripcion = 'Cochera');

	RETURN (SELECT COALESCE(SUM(m2), 0) 
			    FROM adicionales a 
			    WHERE id_consorcio = @id_consorcio AND id_uf = @id_uf AND a.tipo = @id_cochera);
END; GO


  
CREATE FUNCTION fn_CANT_BAULERAS(@id_consorcio INT, @id_uf INT) RETURNS INT AS
BEGIN
	DECLARE @id_baulera INT = (SELECT id_tipo FROM tipo_adicional WHERE descripcion = 'Baulera');

	RETURN (SELECT COALESCE(COUNT(*), 0) 
			    FROM adicionales a 
			    WHERE id_consorcio = @id_consorcio AND id_uf = @id_uf AND a.tipo = @id_baulera);
END; GO
CREATE FUNCTION fn_M2TOTAL_BAULERAS(@id_consorcio INT, @id_uf INT) RETURNS NUMERIC(5,2)  AS
BEGIN
	DECLARE @id_baulera INT = (SELECT id_tipo FROM tipo_adicional WHERE descripcion = 'Baulera');

	RETURN (SELECT COALESCE(SUM(m2), 0) 
			    FROM adicionales a 
			    WHERE id_consorcio = @id_consorcio AND id_uf = @id_uf AND a.tipo = @id_baulera);
END; GO
