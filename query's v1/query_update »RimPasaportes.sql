USE SIM
GO

SELECT 
	[nDia] = DATEPART(DD, rp.dFechaEntrega),
	[nCant] = COUNT(1)
FROM BD_SIRIM.dbo.RimPasaporte rp
WHERE rp.dFechaEntrega BETWEEN '2022-12-01 00:00:00.000' AND '2022-12-31 23:59:59.999'
GROUP BY
	DATEPART(DD, rp.dFechaEntrega)

ORDER BY rp.dFechaEntrega DESC


/*░
► Pas-e entregados 2022 2023
→ Nombres | Dependencia | usó pas | dni | tubo cita 
===========================================================================================================*/

-- SELECT TOP 100 * FROM BD_SIRIM.dbo.RimPasaporte

SELECT TOP 100 * FROM BD_SIRIM.dbo.RimPasaporte p
WHERE 
	-- p.sNumeroDNI = '47609992'
	p.sNumeroDNI = '08886978'
	
SELECT 
	p.sEstado,
	[nTotal] = COUNT(1)
FROM BD_SIRIM.dbo.RimPasaporte p
GROUP BY p.sEstado
ORDER BY [nTotal] DESC


SELECT * FROM BD_SIRIM.dbo.RimPasaporte p WHERE p.sEstado = 'FINALIZADA'

-- STEP-1: Add field's ...
ALTER TABLE BD_SIRIM.dbo.RimPasaporte
	ADD sUsoPas CHAR(2) NULL

ALTER TABLE BD_SIRIM.dbo.RimPasaporte
	ADD sSolicitoCita CHAR(2) NULL

-- STEP-2: Actualizar tabla `RimPasaportes` → `usoPasaporte`
UPDATE BD_SIRIM.dbo.RimPasaporte
	SET sUsoPas = IIF(EXISTS(SELECT 1 FROM SIM.dbo.SimMovMigra smm 
								WHERE 
									smm.bAnulado = 0
									AND smm.sIdPaisNacionalidad = 'PER'
									AND smm.sIdDocumento = 'PAS'
									AND smm.sNumeroDoc = sNumeroPasaporte
							)
					, 'Si', 'No')
WHERE
	dFechaEntrega >= '2022-01-01 00:00:00.000'

-- STEP-Final: Solo entregados ...
-- Test ...
-- uIdPersona | 00000000-0000-0000-0000-000000000000
UPDATE BD_SIRIM.dbo.RimPasaporte
	SET sSolicitoCita = IIF(EXISTS(
								SELECT 1 FROM SIM.dbo.SimCitaWebNacional cwn
								WHERE 
									DATEPART(YYYY, cwn.dFechaCita) = DATEPART(YYYY, dFechaRegistro)
									AND cwn.nIdTipoTramite = 90 -- Pas-e
									AND cwn.sIdDocBeneficiario = 'DNI'
									AND cwn.sNumDocBeneficiario = sNumeroDNI 
									AND cwn.sNomBeneficiario = sNombre
									AND cwn.sPriApeBeneficiario = sApePat
									AND cwn.sSegApeBeneficiario = sApeMat
									-- AND dFechaNac = cwn.dFecNacBeneficiario
							)
					, 'Si', 'No')
WHERE 
	sEstado = 'ENTREGADA'
	AND dFechaEntrega >= '2022-01-01 00:00:00.000'

-- Test ...
SELECT * FROM BD_SIRIM.dbo.RimPasaporte p
WHERE 
	p.sEstado = 'ENTREGADA'
	AND p.dFechaEntrega >= '2022-01-01 00:00:00.000'
-- ===========================================================================================================
