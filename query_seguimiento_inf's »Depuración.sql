USE SIM
GO

/*»
→ INFORME-000214-2021-SRIM	
=======================================================================================================================================*/

-- 1 SimPasaporte ...

-- 1.1: tmp
DROP TABLE IF EXISTS #tmp_INF000214_2021_SRIM 
SELECT 
	TOP 0 
	-- st.uIdPersona
	-- spas.sNumeroTramite, 
	spas.sPasNumero
	-- spas.sEstadoActual, 
	-- sVencido = 'No' 
	INTO #tmp_INF000214_2021_SRIM 
FROM SimPasaporte spas
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite

-- Test ...
SELECT pas.sEstadoActual FROM #tmp_INF000214_2021_SRIM pas GROUP BY pas.sEstadoActual
SELECT pas.sVencido FROM #tmp_INF000214_2021_SRIM pas GROUP BY pas.sVencido
SELECT COUNT(1) FROM #tmp_INF000214_2021_SRIM pas_i
WHERE
	pas_i.sEstadoActual = 'E'
	AND pas_i.sVencido = 'SÍ'

-- 1.2: Insert ...
INSERT INTO #tmp_INF000214_2021_SRIM VALUES('116497312')

-- Index ...
CREATE INDEX IX_tmp_INF000214_2021_SRIM_sPasNumero
    -- ON dbo.#tmp_INF000214_2021_SRIM(uIdPersona)
	ON dbo.#tmp_INF000214_2021_SRIM(sPasNumero)

-- 1.3: Final ...

-- 1.1.1
SELECT COUNT(1) FROM #tmp_INF000214_2021_SRIM
SELECT 
	-- [sEstadoActual_SimPasaporte] = spas.sEstadoActual,
	-- [uIdPersona] = st.uIdPersona,
	-- spas.sPasNumero
	spas.sIdDocumento,
	[nTotal_SimPasaporte] = COUNT(1)
FROM SimPasaporte spas
RIGHT JOIN #tmp_INF000214_2021_SRIM pas_i ON spas.sPasNumero = pas_i.sPasNumero
-- JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
-- RIGHT JOIN #tmp_INF000214_2021_SRIM pas_i ON st.uIdPersona = pas_i.uIdPersona
-- WHERE
	/*pas_i.sEstadoActual = 'E'
	AND pas_i.sVencido = 'SÍ'*/
	-- spas.sEstadoActual = 'E'
GROUP BY
	-- spas.sEstadoActual
	-- st.uIdPersona
	spas.sIdDocumento
/*HAVING
	COUNT(1) >= 2*/
ORDER BY
	[nTotal_SimPasaporte] DESC

-- 1.3.2: NNN | <NO DEFINIDO> | Pais Nacimiento ...
-- SELECT COUNT(1) FROM #tmp_INF000214_2021_SRIM pas_i
SELECT 
	SUM(tmp_i.nContar_NNN)
FROM (

	SELECT 
		-- TOP 10
		-- spas.*
		-- smm.sIdDocumento,
		-- spas.sEstadoActual,
		[nContar_NNN] = (
							SELECT TOP 1 1 FROM SimMovMigra smm
							  WHERE 
									smm.sNumeroDoc = pas_i.sPasNumero
									AND smm.sIdPaisNacionalidad = 'PER'
									-- AND smm.sIdDocumento = 'NNN'
									AND smm.sIdPaisNacimiento = 'NNN'
						)
	FROM #tmp_INF000214_2021_SRIM pas_i

) tmp_i

SELECT * FROM SimMovMigra smm
WHERE 
	smm.sNumeroDoc = '0366462'
	AND smm.sIdPaisNacionalidad = 'PER'

-- 1.3.3: NNN | <NO DEFINIDO> | Pais Nacimiento ...
SELECT 
	-- TOP 10
	-- spas.*
	smm.sIdDocumento,
	-- spas.sEstadoActual,
	[nContar] = COUNT(1)
FROM SimPasaporte spas ON pas_i.sPasNumero = spas.sPasNumero
JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
JOIN SimMovMigra smm ON st.uIdPersona = smm.uIdPersona
-- JOIN SimPersona sper ON pas_i.uIdPersona = sper.uIdPersona
WHERE
	smm.sIdDocumento = 'NNN'
	EXISTS (
		SELECT 1
	)
GROUP BY
	-- spas.sIdPaisNacimiento
	smm.sIdDocumento
ORDER BY [nContar] DESC

-- Test ...
SELECT * FROM SimPasaporte spas WHERE spas.sPasNumero = '122069440'
SELECT * FROM SimTramitePas stpas WHERE stpas.sPasNumero = '122069440'
SELECT * FROM BD_SIRIM.dbo.RimPasaporte pas WHERE pas.sNumeroPasaporte = '120440270'
-- =======================================================================================================================================*/


/*»
	→ Control Migratorio ...
=======================================================================================================================================*/

-- 1.1: tmp
DROP TABLE IF EXISTS #tmp_INF_000205_2022_SRIM_MIGRACIONES
SELECT TOP 0 spas.sPasNumero INTO #tmp_INF_000205_2022_SRIM_MIGRACIONES FROM SimPasaporte spas

-- 1.2: Insert ...
INSERT INTO #tmp_INF_000205_2022_SRIM_MIGRACIONES VALUES('E015041')

-- Index ...
CREATE INDEX IX_tmp_INF_000205_2022_SRIM_MIGRACIONES_sPasNumero
    ON dbo.#tmp_INF_000205_2022_SRIM_MIGRACIONES(sPasNumero)

-- 1.3: Final ...
SELECT 
	pas_i.sPasNumero,
	[bExiste_SimMovMigra] = (
		IIF(
			EXISTS(
				SELECT TOP 1 1 FROM SimMovMigra smm 
				WHERE 
					smm.bAnulado = 0
					AND smm.sIdPaisNacionalidad = 'PER'
					AND smm.sIdDocumento = 'PAS'
					AND smm.sNumeroDoc = pas_i.sPasNumero
			)
			, 'Si'
			, 'No'
		)
	)
	INTO #tmp_INF_000205_2022_SRIM_MIGRACIONES_final
FROM #tmp_INF_000205_2022_SRIM_MIGRACIONES pas_i

-- 1.2
SELECT 
	p_f.bExiste_SimMovMigra,
	[nTotal] = COUNT(1)
FROM #tmp_INF_000205_2022_SRIM_MIGRACIONES_final p_f
GROUP BY 
	p_f.bExiste_SimMovMigra
ORDER BY
	[nTotal] DESC


-- Test ...

-- 1
SELECT * FROM BD_SIRIM.dbo.RimPasaporte pas
WHERE
	pas.sNumeroPasaporte = '116651047'

SELECT * FROM SimMovMigra smm WHERE smm.sNumeroDoc = '116651O47'

-- 2
SELECT 
	* 
FROM SimMovMigra smm 
WHERE 
	smm.sNumeroDoc = '116651O47'

-- 3
SELECT TOP 10 * FROM SimPasaporte spas
WHERE 
	LEN(spas.sPasNumero) = 9
	AND spas.sPasNumero LIKE '%[a-zA-Z]%'
-- =======================================================================================================================================*/



-- ANGELO JUNIOR RIOS CHOQUECAHUA

SELECT * FROM SimPersona sper 
WHERE 
	-- sper.sNumDocIdentidad = '120274469'
	sper.sNombre LIKE '%ANGELO%'
	AND sper.sPaterno = 'RIOS'
	AND sper.sMaterno = 'CHOQUECAHUA'


-- 4EF7EA06-E3C2-40EB-A888-BF84D2FF4CBE
SELECT * FROM SimUnionAuditoria sua
WHERE
	sua.uIdPersonaP = '4EF7EA06-E3C2-40EB-A888-BF84D2FF4CBE'