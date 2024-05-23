--==================================================================================================================================================================
-- Extraer datos de análisis: Base India
--==================================================================================================================================================================

USE SIM
GO

--STEP-01: Crear tabla física.
DROP TABLE IF EXISTS tmp_ctrlmig_india
CREATE TABLE tmp_ctrlmig_india
(
	uIdPersona UNIQUEIDENTIFIER PRIMARY KEY NOT NULL
)

-- SELECT COUNT(1) FROM tmp_ctrlmig_india

--STEP-02: Crear tabla temporal de control migratorio de ciudadanos indios ...
SELECT * INTO #tmp_ctrlmig_india FROM SimMovMigra smm
WHERE smm.uIdPersona IN (SELECT uIdPersona FROM tmp_ctrlmig_india)


--STEP-03: ...
SELECT 
	tmp.uIdPersona,
	[NUMERO REGISTROS] = (SELECT COUNT(1) FROM #tmp_ctrlmig_india WHERE uIdPersona = tmp.uIdPersona),
	[MENOR 10 DIAS] = (
							SELECT 
								TOP 1
								DATEDIFF(DD,
										 LEAD(dFechaControl) OVER (ORDER BY dFechaControl DESC),
										 FIRST_VALUE(dFechaControl) OVER (ORDER BY dFechaControl DESC))
								
							FROM #tmp_ctrlmig_india
							WHERE uIdPersona = tmp.uIdPersona
						
					 ),
	[RUTA] = (
					SELECT 
						TOP 1
						COALESCE(LEAD(sIdPaisMov) OVER (ORDER BY dFechaControl DESC), 'SIN ENTRADA') + '/' + FIRST_VALUE(sIdPaisMov) OVER (ORDER BY dFechaControl DESC)
					FROM #tmp_ctrlmig_india
					WHERE uIdPersona = tmp.uIdPersona
			),
	[CALIDAD MIGRATORIA] = (

								SELECT 
									TOP 1
									FIRST_VALUE(scm.sDescripcion) OVER (ORDER BY dFechaControl DESC)
								FROM #tmp_ctrlmig_india
								JOIN SimCalidadMigratoria scm ON #tmp_ctrlmig_india.nIdCalidad = scm.nIdCalidad
								WHERE uIdPersona = tmp.uIdPersona
	
						   ),
	[FECHA VENCIMIENTO RESIDENCIA] = (
											SELECT 
												TOP 1
												DATEADD(DD,
														LEAD(nPermanencia) OVER (ORDER BY dFechaControl DESC),
														LEAD(dFechaControl) OVER (ORDER BY dFechaControl DESC))
											FROM #tmp_ctrlmig_india
											WHERE uIdPersona = tmp.uIdPersona
								     ),
	[ULTIMO MOVIMIENTO] = (
								SELECT 
									TOP 1
									FIRST_VALUE(sTipo) OVER (ORDER BY dFechaControl DESC)
								FROM #tmp_ctrlmig_india
								WHERE uIdPersona = tmp.uIdPersona
							),
	[FECHA ULTIMO MOVIMIENTO] = (
									SELECT 
									TOP 1
									FIRST_VALUE(dFechaControl) OVER (ORDER BY dFechaControl DESC)
									FROM #tmp_ctrlmig_india
									WHERE uIdPersona = tmp.uIdPersona
								)
	FROM tmp_ctrlmig_india tmp

-- Test ...
SELECT [sCalidad] = scm.sDescripcion, smm.* FROM SimMovMigra smm
JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
WHERE smm.uIdPersona = '86F33E95-9106-46E0-B635-13CEFF56B411'
ORDER BY smm.dFechaControl DESC

SELECT DATEADD(DD, 90, '2021-12-21 01:30:27.447')

--==================================================================================================================================================================

SELECT * FROM SimTipoDocumento
SELECT * FROM SimDocumento WHERE sIdDocumento LIKE 'L%'

SELECT NULLIF('5', 5)