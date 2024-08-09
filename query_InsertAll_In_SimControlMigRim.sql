/*� CREATE TABLE `SimControlMigRim` ... */
/*==============================================================================*/
--DROP TABLE SimControlMigRim
CREATE TABLE SimControlMigRim2(
	sDependencia VARCHAR(55) NOT NULL,
	sControl VARCHAR(10) NOT NULL,
	sTipoControl VARCHAR(35) NOT NULL,
	sNacionalidad VARCHAR(70) NOT NULL,
	sSexo VARCHAR(20) NOT NULL,
	sRangoEdad VARCHAR(25) NOT NULL,
	sOrigenDestino VARCHAR(70) NOT NULL,
	dFechaControl DATE NOT NULL,
	nTotalCtrlMig SMALLINT NOT NULL
)

/*� INDEX: */
CREATE NONCLUSTERED INDEX ix_SimControlMigRim_dFechaControl
	ON SimControlMigRim(dFechaControl)
/*==============================================================================*/

/*� BULK TO `SimControlMigRim` */
/*==============================================================================================================================================================================*/

-- 1
SELECT TOP 1 mm.* FROM BD_SIRIM.dbo.RimControlMig mm
ORDER BY mm.dFechaControl DESC

SELECT SUM(mm.nTotalCtrlMig) FROM BD_SIRIM.dbo.RimControlMig mm
WHERE mm.dFechaControl >= '2022-01-01'

DELETE FROM BD_SIRIM.dbo.RimControlMig
	WHERE dFechaControl >= '2024-01-01'

SELECT TOP 10 * 
FROM BD_SIRIM.dbo.RimControlMig mm
ORDER BY mm.dFechaControl DESC


-- 2
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimControlMig
SELECT 
		(sd.sNombre)[sDependencia],
		(CASE smm.sTipo
			WHEN 'S' THEN 'SALIDA'
			WHEN 'E' THEN 'ENTRADA'
		END)[sControl],
		(sm.sIdModulo)[sTipoControl],
		(sp.sNacionalidad)[sNacionalidad],
		(sper.sSexo)[sSexo],
		[sCalidad] = cm.sSigla,
		[sEstadoCivil] = ec.sDescripcion,
		[sRangoEdad] = CASE 
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 0 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 9 THEN '0 - 9'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 10 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 19 THEN '10 - 19'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 20 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 29 THEN '20 - 29'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 30 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 39 THEN '30 - 39'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 40 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 49 THEN '40 - 49'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 50 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 59 THEN '50 - 59'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 60 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 69 THEN '60 - 69'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 70 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 79 THEN '70 - 79'
							WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 80 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 89 THEN '80 - 89'
							ELSE '90 a más'
						END,
		(sp2.sNombre)[sOrigenDestino],
		CAST(smm.dFechaControl AS DATE) [dFechaControl],
		svt.sDescripcion sViaTransporte,
		COUNT(smm.sIdMovMigratorio)[nTotalCtrlMig]
		INTO BD_SIRIM.dbo.RimControlMig
	FROM SimMovMigra smm
	JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
	JOIN SimModulo sm ON smm.sIdModuloDigita = sm.sIdModulo
	JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	LEFT JOIN SimCalidadMigratoria cm ON smm.nIdCalidad = cm.nIdCalidad
	JOIN SimPais sp2 ON smm.sIdPaisMov = sp2.sIdPais
	LEFT JOIN SimViaTransporte svt ON smm.sIdViaTransporte = svt.sIdViaTransporte
	LEFT JOIN SimEstadoCivil ec ON sper.sIdEstadoCivil = ec.sIdEstadoCivil
	WHERE 
		smm.bAnulado = 0
		AND smm.bTemporal = 0
		-- AND smm.dFechaControl BETWEEN '2022-01-01 00:00:00.000' AND '2022-05-29 23:59:59.000'
		AND smm.dFechaControl BETWEEN '2020-01-01 00:00:00.000' AND '2024-06-30 23:59:59.999'
		AND smm.sTipo IN ('E', 'S')
	GROUP BY
		sd.sNombre,
		CASE smm.sTipo WHEN 'S' THEN 'SALIDA' WHEN 'E' THEN 'ENTRADA' END,
		sm.sIdModulo,
		sp.sNacionalidad,
		sper.sSexo,
		cm.sSigla,
		ec.sDescripcion,
		CASE 
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 0 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 9 THEN '0 - 9'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 10 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 19 THEN '10 - 19'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 20 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 29 THEN '20 - 29'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 30 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 39 THEN '30 - 39'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 40 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 49 THEN '40 - 49'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 50 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 59 THEN '50 - 59'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 60 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 69 THEN '60 - 69'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 70 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 79 THEN '70 - 79'
			WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 80 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 89 THEN '80 - 89'
			ELSE '90 a más'
		END,
		sp2.sNombre,
		CAST(smm.dFechaControl AS DATE),
		svt.sDescripcion


-- 2.1 Personas por años ...
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimControlMigPersonas
SELECT

	[nAñoControl] = DATEPART(YYYY, smm.dFechaControl),
	[sControl] = (
						CASE smm.sTipo
							WHEN 'S' THEN 'SALIDA'
							WHEN 'E' THEN 'ENTRADA'
						END
	),
	[nTotal(Personas)] = COUNT( DISTINCT smm.uIdPersona)
	INTO BD_SIRIM.dbo.RimControlMigPersonas
FROM SimMovMigra smm
WHERE 
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.dFechaControl BETWEEN '2020-01-01 00:00:00.000' AND '2024-06-10 23:59:59.999'
	AND smm.sTipo IN ('E', 'S')
GROUP BY
	DATEPART(YYYY, smm.dFechaControl),
	CASE smm.sTipo
		WHEN 'S' THEN 'SALIDA'
		WHEN 'E' THEN 'ENTRADA'
	END
/*==============================================================================================================================================================================*/

-- 115 | CEBAF LA TINA - MACARA
SELECT * 
FROM SimDependencia d
WHERE d.sNombre LIKE '%ceba%'

SELECT COUNT(1) 
FROM SimMovMigra mm
WHERE
	mm.sIdDependencia = '115'

/*� PROGRESSIVE UPDATE TODAY INTO `SimControlMigRim` */
/*==============================================================================================================================================================================*/
DECLARE @fecini VARCHAR(19) = CONCAT(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), ' 00:00:00'),
		@fecfin VARCHAR(19) = CONCAT(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), ' 23:59:59')

SELECT 
	(sd.sNombre)[sDependencia],
	(CASE smm.sTipo
		WHEN 'S' THEN 'SALIDA'
		WHEN 'E' THEN 'ENTRADA'
	END)[sControl],
	(sm.sIdModulo)[sTipoControl],
	(sp.sNacionalidad)[sNacionalidad],
	(sper.sSexo)[sSexo],
	[sRangoEdad] = CASE 
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 0 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 9 THEN '0 - 9'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 10 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 19 THEN '10 - 19'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 20 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 29 THEN '20 - 29'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 30 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 39 THEN '30 - 39'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 40 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 49 THEN '40 - 49'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 50 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 59 THEN '50 - 59'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 60 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 69 THEN '60 - 69'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 70 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 79 THEN '70 - 79'
						WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 80 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 89 THEN '80 - 89'
						ELSE '90 a m�s'
					END,
	(sp2.sNombre)[sOrigenDestino],
	CAST(smm.dFechaControl AS DATE) [dFechaControl],
	svt.sDescripcion sViaTransporte,
	COUNT(smm.sIdMovMigratorio)[nTotalCtrlMig]
FROM SimMovMigra smm
JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
JOIN SimModulo sm ON smm.sIdModuloDigita = sm.sIdModulo
JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
JOIN SimPais sp2 ON smm.sIdPaisMov = sp2.sIdPais
LEFT JOIN SimViaTransporte svt ON smm.sIdViaTransporte = svt.sIdViaTransporte
WHERE 
	smm.dFechaControl BETWEEN @fecini AND @fecfin
	AND smm.sTipo IN ('E', 'S')
GROUP BY
	sd.sNombre,
	CASE smm.sTipo WHEN 'S' THEN 'SALIDA' WHEN 'E' THEN 'ENTRADA' END,
	sm.sIdModulo,
	sp.sNacionalidad,
	sper.sSexo,
	CASE 
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 0 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 9 THEN '0 - 9'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 10 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 19 THEN '10 - 19'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 20 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 29 THEN '20 - 29'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 30 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 39 THEN '30 - 39'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 40 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 49 THEN '40 - 49'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 50 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 59 THEN '50 - 59'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 60 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 69 THEN '60 - 69'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 70 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 79 THEN '70 - 79'
		WHEN DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) >= 80 AND DATEDIFF(YYYY, sper.dFechaNacimiento, smm.dFechaControl) <= 89 THEN '80 - 89'
		ELSE '90 a m�s'
	END,
	sp2.sNombre,
	CAST(smm.dFechaControl AS DATE),
	svt.sDescripcion
/*==============================================================================================================================================================================*/


SELECT 
	sd.sNombre sDependencia,
	svt.sDescripcion sViaTransporte
FROM SimMovMigra smm
JOIN SimDependencia sd ON smm.sIdDependencia = sd.sIdDependencia
JOIN SimViaTransporte svt ON smm.sIdViaTransporte = svt.sIdViaTransporte
WHERE
	smm.dFechaControl >= '2016-01-01 00:00:00'
GROUP BY 
	sd.sNombre,
	svt.sDescripcion

SELECT TOP 1 * FROM SimTramite st

SELECT * 
FROM SimItinerario i
WHERE i.sIdItinerario = '2024AI001570'

SELECT * 
FROM SimMovMigra i
WHERE i.sIdItinerario = '2024AI001570'

SELECT * 
FROM SimPais p
WHERE p.sIdPais IN ('PBA', 'HOL')
