-- =====================================================================================================================
-- 
-- =====================================================================================================================
USE SIM
GO

/*» STEP-01: Extraer PAS-E y DOC `NNN` */
-- =====================================================================================================================
-- SELECT * FROM #mm_nacional_pas_nnn
DROP TABLE IF EXISTS #mm_nacional_pas_nnn
SELECT 
	DISTINCT
	mm.uIdPersona,
	mm.sIdDocumento,
	mm.sPasNumero
	INTO #mm_nacional_pas_nnn
FROM (
	SELECT 
		st.uIdPersona,
		spas.sIdDocumento,
		spas.sPasNumero
	FROM SimPasaporte spas
	JOIN SimTramite st ON spas.sNumeroTramite = st.sNumeroTramite
	JOIN SimMovMigra smm ON st.uIdPersona = smm.uIdPersona
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	WHERE
		smm.bAnulado = 0
		AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND smm.dFechaControl >= '2010-01-01 00:00:00'
		AND smm.sTipo IN ('E', 'S')
		AND sper.sIdPaisNacionalidad = 'PER'
		AND spas.sIdDocumento IN ('NN', 'NNN')
) mm

/*► index ...*/
CREATE NONCLUSTERED INDEX mm_nacional_pas_nnn_uIdPersona
ON #mm_nacional_pas_nnn(uIdPersona)

/*► Test... */
SELECT * FROM #mm_nacional_pas_nnn mm WHERE mm.sPasNumero = '0097985'
-- =====================================================================================================================


/*» STEP-02: Final... */
-- =====================================================================================================================
-- SELECT TOP 10 * FROM #mm_nacional_pas_nnn
DROP TABLE IF EXISTS #pas_nnn_final
SELECT 
	pas.uIdPersona,
	per.sNombre,
	per.sPaterno,
	per.sMaterno,
	per.sSexo,
	per.dFechaNacimiento,
	smm.dFechaControl,
	smm.sTipo,
	smm.sIdPaisMov,
	smm.sIdPaisNacimiento,
	smm.sIdPaisNacionalidad,
	pas.sIdDocumento,
	[sPasNumero] = CONCAT('''', pas.sPasNumero),
	smm.sIdDocumento [sIdDocControl],
	[sPasNumeroControl] = CONCAT('''', smm.sNumeroDoc),
	smm.dFechaHoraAud [dFechaDigita],
	su.sLogin [sLoginOpeDigita],
	su.sNombre [sOperadorDigita],
	sd.sNombre [sDendencia]
	INTO #pas_nnn_final
FROM #mm_nacional_pas_nnn pas
JOIN SimMovMigra smm ON pas.uIdPersona = smm.uIdPersona
JOIN SimPersona per ON pas.uIdPersona = per.uIdPersona
JOIN SimUsuario su ON smm.nIdOperadorDigita = su.nIdOperador
JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
ORDER BY
	pas.uIdPersona, smm.dFechaControl DESC


/*► Clean-up ... */
DROP TABLE IF EXISTS #mm_nacional_pas_nnn
DROP TABLE IF EXISTS #pas_nnn_final


/*► Test ... */
SELECT * FROM #pas_nnn_final mm WHERE mm.sPasNumero LIKE '%0097985'

-- =====================================================================================================================












/*» PAS-MEC */
-- =====================================================================================================================
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PERSONAS]
SELECT COUNT(1) FROM DIGEMIN.[dbo].[PERSONAS]
SELECT COUNT(1) FROM DIGEMIN.dbo.PASAPORTES
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[HIST_PASAPORTES]
SELECT COUNT(1) FROM DIGEMIN.[dbo].[HIST_PASAPORTES]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[control_pas]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[HIST_PASAPERU]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[HIST_PASAPORTES]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PASAPERU]
SELECT COUNT(1) FROM DIGEMIN.[dbo].[PASAPERU]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[dgm_tipo_pasaporte]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[APL35_TB_PERS_TRAMITE]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[APL35_TB_TRAMITE]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PAD_NUMPAS]


/*► PAS-MEC  ...Join... */
SELECT TOP 10000 * FROM DIGEMIN.dbo.PASAPORTES
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PASAPERU]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PERSONAS2] per WHERE per.uCodNew IS NOT NULL

/*► SIM */
SELECT * FROM SimTramite st WHERE st.sNumeroTramite = 'LM2099492'

/*► helpers ... */
SELECT TOP 10000 * FROM DIGEMIN.dbo.CLAPAS
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[dgm_estado_Pasaporte]

SELECT TOP 10000 * FROM DIGEMIN.[dbo].[control_pas]

SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PERS_TIPDOC]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PASAPORTES]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[PERUANOS]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[prov_pasaportes]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[TIPDOC]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[TIPO_INSCRIP]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[TIPO_PARENT]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[CONSUL]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[APL19_TA_MOVMIG]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[MOVIMIENTOS_SIN_PERSONA]
SELECT TOP 10000 * FROM DIGEMIN.[dbo].[UnionPersonas]

SELECT * FROM SimPersona sper WHERE sper.uIdPersona = '6752D9DC-953A-490D-BD1C-12CE204F666D'


DROP TABLE IF EXISTS #pas_e_nnn
SELECT 
	*
	INTO #pas_e_nnn
FROM SimPasaporte spas
WHERE
	spas.sIdDocumento IN ('NN', 'NNN')
	AND spas.sEstadoActual IN ('E', 'R') -- Entregado | Revalidado
	AND spas.sIdPaisNacimiento = 'PER'
	-- Caracteristicas de PAS-E ...
	AND LEN(spas.sPasNumero) = 9
	AND spas.sPasNumero NOT LIKE '%[a-zA-Z]%'
	AND (spas.sPasNumero LIKE '11%' OR spas.sPasNumero LIKE '12%')
-- =====================================================================================================================