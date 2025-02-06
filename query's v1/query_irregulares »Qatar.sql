USE SIM
GO


/*░
-- Irregulares ciudadanos de Qatar ...
sIdPais	| sNombre | sNacionalidad
  QAT		QATAR	  DE KATAR
*/

-- » 1.1: Extrae ciudadanos extranjeros permanecen en terririo nacional ...
DROP TABLE IF EXISTS #tmp_ctrlmig_permanecen
SELECT * INTO #tmp_ctrlmig_permanecen FROM (

	SELECT 
		smm.uIdPersona,
		sp.sNombre,
		sp.sPaterno,
		sp.sMaterno,
		sp.sSexo,
		sp.dFechaNacimiento,
		[sCalidadPersona] = cmp.sDescripcion,
		sp.sNumDocIdentidad,
		sp.sIdPaisNacionalidad,
		sp.sIdPaisNacimiento,

		-- MovMig
		[sTipoControl] = smm.sTipo,
		smm.sIdDocumento,
		smm.sNumeroDoc,
		smm.dFechaControl,
		[sCalidadControl] = cmc.sDescripcion,
		[sProcDest] = smm.sIdPaisMov,

		-- Aux
		[nRow_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)

	FROM SimMovMigra smm
	JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona
	JOIN SimCalidadMigratoria cmc ON smm.nIdCalidad = cmc.nIdCalidad
	JOIN SimCalidadMigratoria cmp ON sp.nIdCalidad = cmp.nIdCalidad
	WHERE
		smm.bAnulado = 0
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad = 'QAT' -- ...
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'

) mm
WHERE
	mm.nRow_mm = 1
	AND mm.sTipoControl = 'E'

-- Test ...
SELECT * FROM #tmp_ctrlmig_permanecen
SELECT * FROM SimTipoTramite stt WHERE stt.nIdTipoTramite = 99

/*
	-- » STEP-2: CCM, CPP, PTP, Prórrogas ...
	→ CCM: 58; CPP: 113; PRR: 56 | 57; SOL: 55 */

-- » 2.1: Que no hayan realizado trámites:
SELECT * FROM #tmp_ctrlmig_permanecen cm
WHERE NOT EXISTS(
	SELECT 1 FROM SimTramite st 
	WHERE st.uIdPersona = cm.uIdPersona
)

-- » 2.1: Que no hayan realizado:
-- » 2.1: Que no hayan realizado trámites:
SELECT sv.* FROM #tmp_ctrlmig_permanecen cm
JOIN SimTramite st ON cm.uIdPersona = st.uIdPersona
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimVisa sv ON st.sNumeroTramite = sv.sNumeroTramite
WHERE
	DATEDIFF(DD, GETDATE(), sv.dFechaVencimiento) < 0

SELECT TOP 10 * FROM [dbo].[SimCondicionMigraPDA]
SELECT TOP 10 * FROM SimVerificaPDA
SELECT TOP 10 * FROM [dbo].[SimDatosPersonalesPDA]
-- Test ..
SELECT DATEDIFF(DD, GETDATE(), '2023-02-01')



