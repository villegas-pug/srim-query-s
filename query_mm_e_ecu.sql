/*► Via Terrestre: ECU

	→ 38 | PCF CABO PANTOJA
	→ 17 | PCF LA BALSA
	→ 77 | PCF ESPINDOLA
	→ 10 | PCF LA TINA
	→ 11 | PCF EL ALAMOR
	→ 33 | PCM AIPC
	→ 81 | CEBAF PERU - ECUADOR
	→ PVM ZARUMILLA
	→ 01 | TUMBES
*/
/*==================================================================================================================================================*/
/*► STEP-01: Ciudadanos ECU, registran `E`; Tipo-Via: Terrestre ... */
DROP TABLE IF EXISTS #mm_ecu_e_terrestre
;WITH cte_mm_ecu_e_terr AS (
	SELECT 
		smm.*
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND smm.sIdPaisNacionalidad = 'ECU'
		AND smm.dFechaControl >= '2016-01-01 00:00:00'
		AND smm.sTipo = 'E'
		AND smm.sIdViaTransporte = 'T'
		AND smm.sIdDependencia IN ('38', '17', '77', '10', '11', '33', '81', '01')
), cte_mm_ecu_ult_e_terr AS (
	SELECT * FROM (
		SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY dFechaControl DESC) nRow_mm
		FROM cte_mm_ecu_e_terr
	) mm
	WHERE mm.nRow_mm = 1
) SELECT mm.* INTO #mm_ecu_e_terrestre FROM cte_mm_ecu_ult_e_terr mm

/*► Add-Index ... */
--SELECT uIdPersona FROM #mm_ecu_e_terrestre
CREATE NONCLUSTERED INDEX ix_mm_ecu_e_terrestre_uIdPersona
ON #mm_ecu_e_terrestre(uIdPersona)

/*
	MEX | MEXICO
	GUA | GUATEMALA
	HON | HONDURAS
	SAL | EL SALVADOR
	NIC | NICARAGUA
	CRI | COSTA RICA
	PAN | PANAMÁ
	SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%PANAM%'
*/
/*► STEP-02: Ciudadanos ECU, registran `E`; Tipo-Via: Terrestre; registran `S`; Destino: 'Centro América' ... */
DROP TABLE IF EXISTS #mm_s_1sal_centroamerica
SELECT * INTO #mm_s_1sal_centroamerica FROM (
	SELECT 
		mm.*,
		ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl)nRow_mm
	FROM SimMovMigra mm
	JOIN #mm_ecu_e_terrestre mmet ON mm.uIdPersona = mmet.uIdPersona
	WHERE 
		mm.sTipo = 'S'
		AND mm.dFechaControl >= mmet.dFechaControl
		AND mm.sIdPaisMov IN ('MEX', 'GUA', 'HON', 'SAL', 'NIC', 'CRI', 'PAN')
) mm_s_1sal_ca
WHERE mm_s_1sal_ca.nRow_mm = 1

/*► index */
CREATE NONCLUSTERED INDEX ix_mm_s_1sal_centroamerica_uIdPersona
ON #mm_s_1sal_centroamerica(uIdPersona)

;WITH cte_mm_ecu_e_terrestre_join_mm_s_1sal_centroamerica AS (
	SELECT * FROM #mm_ecu_e_terrestre
	UNION ALL
	SELECT * FROM #mm_s_1sal_centroamerica
), cte_mm_ecu_final AS (
	SELECT 
		*
	FROM cte_mm_ecu_e_terrestre_join_mm_s_1sal_centroamerica mm
	WHERE
		mm.uIdPersona IN (SELECT uIdPersona FROM #mm_s_1sal_centroamerica)
) SELECT 
	mm.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad,
	mm.dFechaControl,
	mm.sTipo [sTipoMov],
	mm.sIdPaisMov [sPaisProDest],
	mm.sIdDocumento [sTipoDocViaje],
	mm.sNumeroDoc [sDocViaje],
	stran.sDescripcion [sTipoTransporte],
	sd.sNombre [sDendencia]
FROM cte_mm_ecu_final mm 
JOIN SimPersona sp ON mm.uIdPersona = sp.uIdPersona
JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte stran ON mm.sIdViaTransporte = stran.sIdViaTransporte
ORDER BY mm.uIdPersona, mm.dFechaControl
/*===================================================================================================================================================*/


/*► Via Aereo: DOM
	→ 15 CHICLAYO | 54 PCM CHICLAYO AIJAQ
	→ SELECT * FROM SimDependencia sd WHERE sd.sNombre LIKE '%itine%'
	→ SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%domin%'
	→ SELECT * FROM SimViaTransporte
*/
/*==================================================================================================================================================*/
/*► STEP-01: Ciudadanos DOM, registran `E`; Tipo-Via: Aereo ... */
DROP TABLE IF EXISTS #mm_dominic_e_aer
;WITH cte_mm_dominic_e_aer AS (
	SELECT 
		smm.*
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND smm.sIdPaisNacionalidad IN ('DOM', 'RDO')
		--AND smm.dFechaControl >= '2016-01-01 00:00:00'
		AND smm.sTipo = 'E'
		--AND smm.sIdPaisMov IN ('DOM', 'RDO')
		AND smm.sIdViaTransporte = 'A'
		AND smm.sIdDependencia IN ('15', '54') -- 15 CHICLAYO | 54 PCM CHICLAYO AIJAQ
), cte_mm_dominic_ult_e_aer AS (
	SELECT * FROM (
		SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY dFechaControl DESC) nRow_mm
		FROM cte_mm_dominic_e_aer
	) mm
	WHERE mm.nRow_mm = 1
) SELECT mm.* INTO #mm_dominic_e_aer FROM cte_mm_dominic_ult_e_aer mm

/*► Add-Index ... */
--SELECT uIdPersona FROM #mm_ecu_e_terrestre
CREATE NONCLUSTERED INDEX ix_mm_dominic_e_aer_uIdPersona
ON #mm_dominic_e_aer(uIdPersona)


/*► STEP-02: Ciudadanos DOM, registran `E`; Tipo-Via: A; registran `S`; Destino: Cualquiera ... */
DROP TABLE IF EXISTS #mm_s_1sal_variosdest
SELECT * INTO #mm_s_1sal_variosdest FROM (
	SELECT 
		mm.*,
		ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl)nRow_mm
	FROM SimMovMigra mm
	JOIN #mm_dominic_e_aer mmea ON mm.uIdPersona = mmea.uIdPersona
	WHERE 
		mm.sTipo = 'S'
		AND mm.dFechaControl >= mmea.dFechaControl
		--AND mm.sIdPaisMov IN ('MEX', 'GUA', 'HON', 'SAL', 'NIC', 'CRI', 'PAN')
) mm_s_1sal_varios
WHERE mm_s_1sal_varios.nRow_mm = 1

/*► index */
CREATE NONCLUSTERED INDEX ix_mm_s_1sal_variosdest_uIdPersona
ON #mm_s_1sal_variosdest(uIdPersona)

;WITH cte_mm_dom_e_aerea_join_mm_s_1sal_varios AS (
	SELECT * FROM #mm_dominic_e_aer
	UNION ALL
	SELECT * FROM #mm_s_1sal_variosdest
), cte_mm_dominic_final AS (
	SELECT 
		*
	FROM cte_mm_dom_e_aerea_join_mm_s_1sal_varios mm
	WHERE
		mm.uIdPersona IN (SELECT uIdPersona FROM #mm_s_1sal_variosdest)
) SELECT 
	mm.uIdPersona,
	sp.sNombre,
	sp.sPaterno,
	sp.sMaterno,
	sp.sSexo,
	sp.dFechaNacimiento,
	sp.sIdPaisNacimiento,
	sp.sIdPaisNacionalidad,
	mm.dFechaControl,
	mm.sTipo [sTipoMov],
	mm.sIdPaisMov [sPaisProDest],
	mm.sIdDocumento [sTipoDocViaje],
	mm.sNumeroDoc [sDocViaje],
	stran.sDescripcion [sTipoTransporte],
	sd.sNombre [sDendencia]
FROM cte_mm_dominic_final mm 
JOIN SimPersona sp ON mm.uIdPersona = sp.uIdPersona
JOIN SimDependencia sd ON mm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte stran ON mm.sIdViaTransporte = stran.sIdViaTransporte
ORDER BY mm.uIdPersona, mm.dFechaControl



SELECT COUNT(1) FROM SimMovMigra smm 
WHERE
	smm.bAnulado = 0
	AND smm.dFechaControl BETWEEN '2022-05-01 00:00:00.000' AND '2022-05-31 23:59:59.000'
	AND smm.sIdPaisNacimiento = 'MAR'

SELECT * FROM SimPais sp WHERE sp.sNombre LIKE '%marr%'



