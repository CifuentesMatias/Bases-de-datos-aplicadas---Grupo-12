/** Reporte 5 **
	Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
	DNI de los propietarios para que la administración los pueda contactar o remitir el trámite
	al estudio jurídico.

	//quizas me pidan algo asi
	CONSORCIO 		 fCalculo 	DEUDA   NOMBRE 	 		DNI 		TELEFONO 	EMAIL
	altos del oeste  2020-1-5	50mil   Pepe jodido  	20454564  	11-23244    
	altos del oeste  2020-1-5	47mil   Elber galarga  	20454564  				elbergalarga@yahoo.com    
*/
CREATE PROCEDURE sp_reporte5(@nombre_consorcio NVARCHAR(50), @fechaInicio DATE = '2020-1-1', @fechaFin DATE = NULL) AS
BEGIN
	SET NOCOUNT ON;

	IF @fechaFin IS NULL
		SET @fechaFin = GETDATE();

	DECLARE @id_consorcio INT = (SELECT TOP 1 id_consorcio FROM consorcio WHERE razon_social = @nombre_consorcio);

	IF @id_consorcio IS NULL
	BEGIN
		RAISERROR('Ese consorcio no existe', 16, 1);
		RETURN;
	END;
	IF @fechaInicio < '2000-1-1' OR @fechaInicio > @fechaFin 
	BEGIN
		RAISERROR('fecha invalida', 16, 2);
		RETURN;
	END;


	DECLARE @temp TABLE
	(
		deuda NUMERIC(20,2),
		propietario VARCHAR(50),
		prop_dni INT,
		prop_email VARCHAR(255),
		prop_tel CHAR(16)
	); 

	WITH
		-- busco las uf que SOLO deban
		uf_morosa AS (SELECT
					   		id_uf,
					   		anio,
							mes,
					 		saldo_final
					   FROM 
					 		prorateo
					   WHERE 
					 		id_consorcio = @id_consorcio AND
							anio <= YEAR('2025-1-1') AND
							saldo_final > 0),

		-- me piden 3 personas morosas, entonces puede pasar que la misma persona deba dos departamentos
		morosos AS (SELECT
					    ur.propietario,
					    ur.prop_dni,
					    ur.prop_email,
					    ur.prop_tel,
					    SUM(ufm.saldo_final) as deuda
					FROM 
						fn_ultimoResidentes(@id_consorcio, @fechaFin) ur
					JOIN 
						uf_morosa ufm 
						ON ufm.id_uf = ur.id_uf
					GROUP BY 
						ur.propietario,
					    ur.prop_dni,
					    ur.prop_email,
					    ur.prop_tel)
	INSERT INTO @temp(deuda, propietario, prop_dni, prop_email, prop_tel) 
	SELECT TOP 3
		deuda,
		propietario,
		prop_dni,
		prop_email,
		prop_tel
	FROM 
		morosos
	ORDER BY
		deuda DESC;

	SELECT
		@nombre_consorcio AS consorcio,
		@fechaFin AS fCalculo,
		deuda,
		propietario,
		prop_dni,
		prop_email,
		prop_tel
	FROM 
		@temp
	ORDER BY
		deuda DESC;

	SELECT
		@nombre_consorcio AS consorcio,
		@fechaFin AS fCalculo,
		deuda,
		propietario,
		prop_dni,
		prop_email,
		prop_tel
	FROM 
		@temp
	ORDER BY
		deuda DESC
	FOR XML 
		PATH('Moroso'),
		ROOT('Reporte5');
END; 
GO
