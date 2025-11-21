CREATE FUNCTION fn_ultimoResidentes(@id_consorcio INT, @fecha_actual DATE) RETURNS TABLE AS RETURN
(
	/*
	id_uf	id_persona	es_propietario	fecha_alta	
	1		100			1				2023-01-15
	1		101			1				2024-05-20
	1		200			0				2023-06-10
	1		201			0				2024-08-01
	2		300			1				2023-03-12
	2		400			0				2023-07-20
	3		500			1				2024-02-01


	id_uf	id_persona	es_propietario	fecha_alta	rn
	1		101			1				2024-05-20	1 Propietario más reciente UF1
	1		100			1				2023-01-15	2
	1		201			0				2024-08-01	1 Inquilino más reciente UF1
	1		200			0				2023-06-10	2
	2		300			1				2023-03-12	1 Propietario más reciente UF2
	2		400			0				2023-07-20	1 Inquilino más reciente UF2
	3		500			1				2024-02-01	1 Solo propietario UF3
	*/

    WITH
    	Uf_porConsorcio AS (SELECT id_uf
    						FROM unidad_funcional
    						WHERE id_consorcio = @id_consorcio),
		ultimo_residentes AS (SELECT
						        id_uf,
						        id_persona,
						        es_propietario,
						        fecha_alta,
						        ROW_NUMBER() OVER (
						        	PARTITION BY id_uf, es_propietario 
						        	ORDER BY fecha_alta DESC
						        ) AS rn
							  FROM
							    persona_uf 
							  WHERE
							    id_consorcio = @id_consorcio AND
							    fecha_alta <= @fecha_actual),
		residentes_actuales AS (SELECT
							        ufc.id_uf,
							        CASE WHEN ur.es_propietario = 1 THEN ur.id_persona ELSE NULL END AS id_persona_prop,
							        CASE WHEN ur.es_propietario = 0 THEN ur.id_persona ELSE NULL END AS id_persona_inq
							    FROM 
							    	Uf_porConsorcio ufc 
							    LEFT JOIN
							    	ultimo_residentes ur
							    	ON ur.id_uf = ufc.id_uf
							    	AND ur.rn = 1)
	SELECT
	    ra.id_uf,

	    COALESCE(prop.nombre + ' ' + prop.apellido, '-') AS propietario,
	    COALESCE(CAST(prop.dni AS VARCHAR(10)), '-') AS prop_dni,
	    COALESCE(prop.telefono, '') AS prop_tel,
	    COALESCE(prop.email, '') AS prop_email,

	    COALESCE(inq.nombre + ' ' + inq.apellido, '-') AS inquilino,
	    COALESCE(CAST(inq.dni AS VARCHAR(10)), '-') AS inq_dni,
	    COALESCE(inq.telefono, '') AS inq_tel,
	    COALESCE(inq.email, '') AS inq_email
	FROM
	    residentes_actuales ra
	LEFT JOIN
	    persona prop 
	    ON prop.id_persona = ra.id_persona_prop
	LEFT JOIN
	    persona inq 
	    ON inq.id_persona = ra.id_persona_inq
);
GO
