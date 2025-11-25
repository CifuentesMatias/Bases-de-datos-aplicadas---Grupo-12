if db_id('Com2900G12') is null
	create database Com2900G12 collate Modern_Spanish_CI_AS;
go
use Com2900G12
go

CREATE FUNCTION fn_ultimoResidentes(@id_consorcio INT, @fecha_actual DATE) RETURNS TABLE AS RETURN
(
    WITH
        Uf_porConsorcio AS (SELECT id_consorcio, id as id_uf
                            FROM UF
                            WHERE id_consorcio = @id_consorcio),
        ultimo_residentes  AS (SELECT
                                ufc.id_uf,
                                pers.id AS id_persona,
                                pers.id_tipo_relacion
                              FROM
                                Uf_porConsorcio ufc
                              JOIN
                                persona_uf puf
                                ON puf.id_consorcio = ufc.id_consorcio
                                AND puf.id_uf = ufc.id_uf
                              JOIN
                                persona pers
                                ON pers.cvu_cbu = puf.cvu_cbu),
        residentes_actuales AS (SELECT
                                    id_uf,
                                    MAX(CASE WHEN id_tipo_relacion = 1 THEN id_persona END) AS id_persona_prop,
                                    MAX(CASE WHEN id_tipo_relacion = 0 THEN id_persona END) AS id_persona_inq
                                FROM ultimo_residentes 
                                GROUP BY id_uf)
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
        ON prop.id = ra.id_persona_prop
    LEFT JOIN
        persona inq 
        ON inq.id = ra.id_persona_inq
);
GO
