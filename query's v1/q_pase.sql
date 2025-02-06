USE SIM
GO

/*

	*NUMERO DE ULTIMO  PASAPORTE TRAMITADO
	*FECHA DE ULTIMO  PASAPORTE TRAMITADO
	*ESTADO DE TRAMITE

	*ULTIMO MOVIMIENTO
	*OBSERVACIONES
	*RUTA

	*SEXO
	*FECHA DE NACIMIENTO 

*/

-- STEP-01: Tabla temporal ...
DROP TABLE IF EXISTS tmp_pas
CREATE TABLE #tmp_pas
(
	nId INT PRIMARY KEY NOT NULL,
	sNumeroDoc CHAR(8) NULL,
	sNumeroPas VARCHAR(55) NULL
)


-- STEP-02: Bulk ...
-- INSERT INTO tmp_pas(nId, sNumeroDoc, sNumeroPas) VALUES(
-- SELECT COUNT(1) FROM #tmp_pas
-- SELECT * FROM tmp_pas


-- STEP-03: cte
;WITH cte_tmppas_j_movmig AS (

	SELECT 
		cte.nId,
		cte.sNumeroDoc_tmppas,
		cte.sNumeroPas_tmppas,
		[dFechaMovMigra] = cte.dFechaControl,
		[sTipoMovMigra] = cte.sTipo,
		[sRuta] = CASE
						WHEN cte.sTipo = 'E' THEN CONCAT(cte.sIdPaisMov, '-', 'PER')
						WHEN cte.sTipo = 'S' THEN CONCAT('PER', '-', cte.sIdPaisMov)
				  END,
		[sObservaciones_rcm] = cte.sObservaciones

	FROM(

		SELECT 
			pas.nId,
			[sNumeroDoc_tmppas] = pas.sNumeroDoc,
			[sNumeroPas_tmppas] = pas.sNumeroPas,
			smm.*,
			[nRow_mm] = CASE
							WHEN smm.uIdPersona IS NULL THEN 1
							ELSE ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
						END
		FROM #tmp_pas pas
		LEFT JOIN SimMovMigra smm ON pas.sNumeroPas = smm.sNumeroDoc AND smm.sIdPaisNacionalidad = 'PER'

	) cte
	WHERE cte.nRow_mm = 1

), cte_tmppas_entregados AS (

	SELECT 
		tmp.nId,
		[dFechaRegistro_Pas] = rp.dFechaRegistro,
		rp.sNumeroPasaporte,
		rp.sNombre,
		rp.sApePat,
		rp.sApeMat,
		rp.sEstado,
		rp.sSexo,
		rp.dFechaNac,
		tmp.dFechaMovMigra,
		tmp.sTipoMovMigra,
		tmp.sRuta,
		tmp.sObservaciones_rcm
	FROM cte_tmppas_j_movmig tmp
	JOIN BD_SIRIM.dbo.RimPasaporte rp ON tmp.sNumeroPas_tmppas = rp.sNumeroPasaporte

), cte_tmppas_produccion AS (

	SELECT 
		tmp.nId,
		[dFechaRegistro_Pas] = tmp.dFechaRegistro,
		tmp.sNumeroPasaporte,
		tmp.sNombre,
		tmp.sApePat,
		tmp.sApeMat,
		tmp.sEstado,
		tmp.sSexo,
		tmp.dFechaNac,
		tmp.dFechaMovMigra,
		tmp.sTipoMovMigra,
		tmp.sRuta,
		tmp.sObservaciones_rcm
	FROM (

		SELECT 
			tmp.*,
			rp.*,
			[nRow_pas] = ROW_NUMBER() OVER (PARTITION BY rp.sNumeroDNI ORDER BY rp.dFechaRegistro DESC)
		FROM cte_tmppas_j_movmig tmp
		JOIN BD_SIRIM.dbo.RimPasaporte rp ON tmp.sNumeroDoc_tmppas = rp.sNumeroDNI
	
	) tmp
	WHERE
		tmp.nRow_pas = 1

), cte_entregados_union_produccion AS (

	SELECT * FROM cte_tmppas_entregados
	UNION
	SELECT * FROM cte_tmppas_produccion

) SELECT 
		tmp.*
	FROM cte_entregados_union_produccion tmp
	ORDER BY 
		tmp.nId,
		tmp.dFechaRegistro_Pas DESC


