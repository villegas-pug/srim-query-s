USE SIM
GO

/*░
 → Validar unificaciones de ciudadanos de más de 2 identidades ...
==================================================================================================================================*/
-- STEP-01: Crear `tmp` 
-- 1.1: ...
DROP TABLE IF EXISTS #tmp_uId_multi
SELECT 
	TOP 0 
	-- sper.uIdPersona
	-- [dFechaAnalisis] = CONVERT(DATE, sp.dFechaNacimiento)
	-- sper.sNumDocIdentidad
	-- spas.sPasNumero
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad
	INTO #tmp_uId_multi 
FROM SimPersona sper
JOIN SimTramite st ON sper.uIdPersona = st.uIdPersona
JOIN SimPasaporte spas ON st.sNumeroTramite = spas.sNumeroTramite

-- 1.2: Insert ...
INSERT INTO #tmp_uId_multi VALUES('AARON RODRIGO','LOZANO','GOMEZ','M','1999-08-22','PER')

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_uId_multi_uIdPersona
    ON dbo.#tmp_uId_multi(uIdPersona)

CREATE NONCLUSTERED INDEX IX_tmp_uId_multi_sPasNumero
    ON dbo.#tmp_uId_multi(sPasNumero)

CREATE NONCLUSTERED INDEX IX_tmp_uId_multi_sNombre_sPaterno_sMaterno_sSexo_dFechaNacimiento_sIdPaisNacionalidad
    ON dbo.#tmp_uId_multi(sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, sIdPaisNacionalidad)

CREATE NONCLUSTERED INDEX IX_SimUnionAuditoria_uIdPersonaS
    ON dbo.SimUnionAuditoria(uIdPersonaS)
	INCLUDE(nIdAuditoriaUnion)

CREATE NONCLUSTERED INDEX IX_SimUnionAuditoria_uIdPersonaP
    ON dbo.SimUnionAuditoria(uIdPersonaP)
	INCLUDE(nIdAuditoriaUnion)

-- Test ...
SELECT COUNT(1) FROM #tmp_uId_multi 

-- 1.3.1: ...
DROP TABLE IF EXISTS #tmp_uId_multi_join_SimPersona
SELECT sper.uIdPersona, m.sNumDocIdentidad INTO #tmp_uId_multi_join_SimPersona FROM #tmp_uId_multi m
JOIN SimPersona sper ON m.sNumDocIdentidad = sper.sNumDocIdentidad 
                        AND sper.sIdDocIdentidad = 'DNI'
						AND sper.sIdPaisNacionalidad = 'PER'

-- 1.3.2: SimPersona por datos ...
DROP TABLE IF EXISTS #tmp_uId_multi_join_SimPersona
SELECT COUNT(1) FROM #tmp_uId_multi_join_SimPersona 
SELECT 
	DISTINCT sper.uIdPersona 
	INTO #tmp_uId_multi_join_SimPersona 
FROM #tmp_uId_multi m
JOIN SimPersona sper ON m.sNombre = sper.sNombre 
						AND m.sPaterno = sper.sPaterno
						AND m.sMaterno = sper.sMaterno
						AND m.sSexo = sper.sSexo
						AND m.dFechaNacimiento = sper.dFechaNacimiento
						AND m.sIdPaisNacionalidad = 'PER'

-- 1.4: uIdPersona
SET LANGUAGE 'SPANISH'
SELECT 
	dnim2.[¿sUnificado?],
	[nTotal] = COUNT(1)
FROM (

	SELECT 
		dnim1.uIdPersona,
		[¿sUnificado?] = (

			IIF(
					EXISTS (SELECT TOP 1 1 FROM SimUnionAuditoria sua WHERE sua.uIdPersonaP = dnim1.uIdPersona)
					OR 
					EXISTS (SELECT TOP 1 1 FROM SimUnionAuditoria sua WHERE sua.uIdPersonaS = dnim1.uIdPersona),
					'Si',
					'No'
				)
	
		)
	FROM #tmp_uId_multi_join_SimPersona dnim1
	-- FROM #tmp_uId_multi dnim1

) dnim2
GROUP BY
	dnim2.[¿sUnificado?]
ORDER BY
	[nTotal] DESC


-- 1.4: sPasNumero ...
SELECT 
	dnim2.[¿sUnificado?],
	[nTotal] = COUNT(1)
FROM (

	SELECT 
		st.uIdPersona,
		[¿sUnificado?] = (

			IIF(
					EXISTS (SELECT TOP 1 1 FROM SimUnionAuditoria sua WHERE sua.uIdPersonaP = st.uIdPersona)
					OR 
					EXISTS (SELECT TOP 1 1 FROM SimUnionAuditoria sua WHERE sua.uIdPersonaS = st.uIdPersona),
					'Si',
					'No'
				)
	
		)
	-- FROM #tmp_uId_multi_join_SimPersona dnim1
	FROM #tmp_uId_multi dnim1
	JOIN SimPasaporte spas ON dnim1.sPasNumero = spas.sPasNumero
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite

) dnim2
GROUP BY
	dnim2.[¿sUnificado?]
ORDER BY
	[nTotal] DESC

-- ==================================================================================================================================


SELECT 
	[sTipoTramite] = stt.sDescripcion,
	st.*
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
	st.uIdPersona = (

		SELECT st2.uIdPersona FROM SimTramite st2
		WHERE
			st2.sNumeroTramite = 'LM220243539'
	
	)
	AND sti.sEstadoActual = 'P'
ORDER BY
	st.dFechaHoraReg DESC