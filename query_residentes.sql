USE SIM
GO


/*░
--» Nacionalizados ... 
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_nac
;WITH tmp_nac AS
(
	SELECT

		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = (
								SELECT TOP 1 setn.dFechaHoraFin FROM SimEtapaTramiteNac setn 
								WHERE 
									setn.sNumeroTramite = st.sNumeroTramite
									AND setn.nIdEtapa = 6 -- 6 | IMPRESIÓN
									AND setn.bActivo = 1
									AND setn.sEstado = 'F'
								ORDER BY
									setn.dFechaHoraFin DESC
							),
		[Fecha Vencimiento] = NULL,
		[Calidad Migratoria] = scm.sDescripcion,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad,

		--Aux
		[Tipo Calidad] = 'R',
		[Tipo Control] = '',
		[nRow_nac] = NULL

	FROM SimTramite st
	JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SImCalidadMigratoria scm ON sp.nIdCalidad = scm.nIdCalidad
	JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		sp.sIdPaisNacionalidad IN ('CNO', 'CSU')
		AND stn.sEstadoActual IN ('A', 'P')
		-- stn.nIdEtapaActual IN (6, 48, 40, 47, 42, 53, 43, 44)
		AND stt.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79)
		AND EXISTS (
				SELECT 1 FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
					AND setn.bActivo = 1
					AND setn.sEstado = 'F'
		)
		/* AND (
				SELECT 
					TOP 1 
					DATEPART(YYYY, setn.dFechaHoraFin) FROM SimEtapaTramiteNac setn 
				WHERE 
					setn.sNumeroTramite = st.sNumeroTramite
					AND setn.nIdEtapa = 6 -- 6 | IMPRESION
					AND setn.bActivo = 1
					AND setn.sEstado = 'F'
				ORDER BY setn.dFechaHoraFin DESC
		) >= 2016 */
		
) SELECT * INTO #tmp_nac FROM tmp_nac


-- Test: ...

--=============================================================================================================================*/


/*░
--» CCM ... 
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_ccm_vigentes_distinct
;WITH tmp_ccm_vigentes AS(

	SELECT
		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = sccm.dFechaAprobacion,
		[Fecha Vencimiento] = sccm.dFechaVencimiento,
		[Calidad Migratoria] = scm.sDescripcion,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad,

		-- Aux
		[Tipo Calidad] = scm.sTipo

	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		sp.sIdPaisNacionalidad IN ('CNO', 'CSU')
		AND st.nIdTipoTramite = 58 -- CCM
		AND sti.sEstadoActual IN ('A', 'P')
		AND (sccm.dFechaAprobacion IS NOT NULL AND sccm.dFechaAprobacion >= '2016-01-01 00:00:00.000')
		AND scm.sTipo IN ('R', 'I', 'T') -- RESIDENTE
		AND DATEDIFF(DD, GETDATE(), sccm.dFechaVencimiento) > 0 -- Vigentes: No excede fecha de vencimiento ...
	
), tmp_ccm_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,

			-- Aux
			[Tipo Control] = '',
			[nFila_ccm] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_ccm_vigentes

	) ccm
	WHERE ccm.nFila_ccm = 1
)
SELECT * INTO #tmp_ccm_vigentes_distinct FROM tmp_ccm_vigentes_distinct

-- Test: ``
--=============================================================================================================================*/




/*░
--» CPP | 113 | REGULARIZACIÓN DE EXTRANJEROS ... 
--→ CPP es Aprobado en etapa `75 | CONFORMIDAD JEFATURA ZONAL` Finalizada ...
=============================================================================================================================*/
-- SELECT * FROM SimCalidadMigratoria scm WHERE scm.sDescripcion = 'CPP-DS10'
DROP TABLE IF EXISTS #tmp_cpp_vigentes_distinct
;WITH tmp_cpp AS(

	SELECT
		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = seti.dFechaHoraFin,
		[Fecha Vencimiento] = DATEADD(YYYY, 2, seti.dFechaHoraFin), -- Fecha vecimiento ...
		[Calidad Migratoria] = scm.sDescripcion,
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad,

		-- Aux
		[Tipo Calidad] = 'R'
	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimEtapaTramiteInm seti ON seti.sNumeroTramite = st.sNumeroTramite
									AND seti.nIdEtapa = 63 -- 63 | ENTREGA DE CARNÉ P.T.P.
									AND seti.bActivo = 1
									AND seti.sEstado = 'F'
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
	JOIN SimCalidadMigratoria scm ON sccm.nIdCalSolicitada = scm.nIdCalidad
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		sp.sIdPaisNacionalidad IN ('CNO', 'CSU')
		AND st.nIdTipoTramite = 113 -- CPP
		AND sti.sEstadoActual IN ('A', 'P')
		-- AND scm.sTipo = 'R' -- RESIDENTE

), tmp_cpp_vigentes AS (

	SELECT * FROM tmp_cpp cpp
	WHERE
		DATEDIFF(
					DD, 
					GETDATE(), -- Fecha actual ...
					cpp.[Fecha Vencimiento]	-- Fecha vecimiento ...
				) > 0 -- Vigentes: No excede fecha de vencimiento ...

), tmp_cpp_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,

			-- Aux
			[Tipo Control] = '',
			[nFila_cpp] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_cpp_vigentes

	) cpp
	WHERE cpp.nFila_cpp = 1
)
SELECT * INTO #tmp_cpp_vigentes_distinct FROM tmp_cpp_vigentes_distinct

-- Test: ...
SELECT * FROM #tmp_cpp_vigentes_distinct
--=============================================================================================================================*/

/*░
--» PRR ... 
-- 57 | PRORROGA DE RESIDENCIA
-- Fecha Aprobación → Etapa: 24 | PAGOS, FECHA Y NRO RD.
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_prr_vigentes_distinct
;WITH tmp_prr AS
(
	SELECT

		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = CONVERT(DATE, seti.dFechaHoraFin),
		[Fecha Vencimiento] = CONVERT(DATE, spr.dFechaVencimiento),
		[Calidad Migratoria] = '',
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad,

		-- Aux ...
		[Tipo Calidad] = 'R'

	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimProrroga spr ON sti.sNumeroTramite = spr.sNumeroTramite
	JOIN SimEtapaTramiteInm seti ON seti.sNumeroTramite = st.sNumeroTramite
									AND seti.nIdEtapa = 24 -- 24 | PAGOS, FECHA Y NRO RD. → Etapa final
									AND seti.sEstado = 'F'
									AND seti.bActivo = 1
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		sp.sIdPaisNacionalidad IN ('CNO', 'CSU')
		AND st.nIdTipoTramite = 57 -- PRR
		AND sti.sEstadoActual IN ('A', 'P')
		AND seti.dFechaHoraFin >= '2016-01-01 00:00:00.000'
	
), tmp_prr_vigentes AS (

	SELECT * FROM tmp_prr prr
	WHERE
		DATEDIFF(
					DD, 
					GETDATE(), -- Fecha actual ...
					prr.[Fecha Vencimiento]	-- Fecha vecimiento ...
				) > 0 -- Vigentes: No excede fecha de vencimiento ...

), tmp_prr_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,

			-- Aux
			[Tipo Control] = '',
			[nFila_prr] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_prr_vigentes

	) cpp
	WHERE cpp.nFila_prr = 1

) SELECT * INTO #tmp_prr_vigentes_distinct FROM tmp_prr_vigentes_distinct

-- Test: ...
SELECT COUNT(1) FROM #tmp_prr_vigentes_distinct

--=============================================================================================================================*/




/*░
--» PRR ... 
-- 101 | PRORROGA VISA MRE(Humanitaria)
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_prrhum_vigentes_distinct
;WITH tmp_prrhum AS
(
	SELECT

		st.uIdPersona,
		[Numero Tramite] = st.sNumeroTramite,
		[Fecha Tramite] = CONVERT(DATE, st.dFechaHoraReg),
		[Fecha Aprobación] = CONVERT(DATE, sph.dFechaProrroga),
		[Fecha Vencimiento] = CONVERT(DATE, sph.dVencimiento),
		[Calidad Migratoria] = '',
		[Tipo Trámite] = stt.sDescripcion,
		[Nombre] = sp.sNombre,
		[Ape Pat] = sp.sPaterno,
		[Ape Mat] = sp.sMaterno,
		[Sexo] = sp.sSexo,
		[Fec Nac] = sp.dFechaNacimiento,
		[Nacionalidad] = sp.sIdPaisNacionalidad,

		-- Aux ...
		[Tipo Calidad] = 'R'

	FROM SimTramite st
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	JOIN SimVmreProrrogaHum sph ON st.sNumeroTramite = sph.sNumeroTramite
	JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacimiento = spa.sIdPais
	WHERE
		sp.sIdPaisNacionalidad IN ('CNO', 'CSU')
		-- st.nIdTipoTramite = 101 -- PMR | PRORROGA VISA MRE
		AND sti.sEstadoActual = 'A'
		AND sph.dFechaProrroga >= '2016-01-01 00:00:00.000'
	
), tmp_prrhum_vigentes AS (

	SELECT * FROM tmp_prrhum prrh
	WHERE
		DATEDIFF(
					DD, 
					GETDATE(), -- Fecha actual ...
					prrh.[Fecha Vencimiento]	-- Fecha vecimiento ...
				) > 0 -- Vigentes: No excede fecha de vencimiento ...

), tmp_prrhum_vigentes_distinct AS (

	SELECT * FROM (

		SELECT 
			*,

			-- Aux
			[Tipo Control] = '',
			[nFila_prr] = ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY [Fecha Aprobación] DESC)
		FROM tmp_prrhum_vigentes

	) cpp
	WHERE cpp.nFila_prr = 1

) SELECT * INTO #tmp_prrhum_vigentes_distinct FROM tmp_prrhum_vigentes_distinct

-- Test: ...
--=============================================================================================================================*/




/*░
--» Control Migratorio ... 
=============================================================================================================================*/

DROP TABLE IF EXISTS #tmp_ctrlmig_permanentes
;WITH tmp_ctrlmig AS (

	SELECT 

		smm.uIdPersona,
		[Numero Tramite] = smm.sIdMovMigratorio,
		[Fecha Tramite] = CONVERT(DATE, smm.dFechaControl),
		[Fecha Aprobación] = smm.dFechaControl,
		[Fecha Vencimiento] = NULL,
		[Calidad Migratoria] = scm.sDescripcion,
		[Tipo Trámite] = 'Control Migratorio',
		[Nombre] = sper.sNombre,
		[Ape Pat] = sper.sPaterno,
		[Ape Mat] = sper.sMaterno,
		[Sexo] = sper.sSexo,
		[Fec Nac] = sper.dFechaNacimiento,
		[Nacionalidad] = sper.sIdPaisNacionalidad,

		-- Aux
		[Tipo Calidad] = scm.sTipo,
		[Tipo Control] = smm.sTipo
		
	FROM SimMovMigra smm
	JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
	JOIN SimCalidadMigratoria scm ON smm.nIdCalidad = scm.nIdCalidad
	JOIN SimPais sp ON smm.sIdPaisNacionalidad = sp.sIdPais
	WHERE
		smm.bAnulado = 0
		AND smm.sTipo IN ('E', 'S')
		--AND smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') -- Solo extranjeros ...
		AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
		-- AND scm.sTipo IN ('R', 'I', 'T') -- RESIDENTE
		AND sper.sIdPaisNacionalidad IN ('CNO', 'CSU')

), tmp_ctrlmig_permanentes AS (

	SELECT * FROM (

		SELECT 
			mm.*,

			-- Aux
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.[Fecha Aprobación] DESC)
		FROM tmp_ctrlmig mm

	) mm
	WHERE
		mm.nFila_mm = 1
		AND mm.[Tipo Control] = 'E'

) SELECT * INTO #tmp_ctrlmig_permanentes FROM tmp_ctrlmig_permanentes

-- Test ...

--=============================================================================================================================*/




/*░
-- » FINAL
--=============================================================================================================================*/

DROP TABLE IF EXISTS calidades_vigentes_final
SELECT * INTO calidades_vigentes_final FROM (

	SELECT 
		calidades_vigentes.*,

		-- Aux
		[nRow_final] = ROW_NUMBER() OVER (PARTITION BY calidades_vigentes.uIdPersona ORDER BY calidades_vigentes.[Fecha Aprobación] DESC)
	FROM (

		-- SELECT * FROM #tmp_nac
		-- UNION ALL
		SELECT * FROM #tmp_ccm_vigentes_distinct
		UNION ALL
		SELECT * FROM #tmp_cpp_vigentes_distinct
		UNION ALL
		SELECT * FROM #tmp_prr_vigentes_distinct
		UNION ALL
		SELECT * FROM #tmp_prrhum_vigentes_distinct
		UNION ALL
		SELECT * FROM #tmp_ctrlmig_permanentes cm 
		-- WHERE cm.[Tipo Calidad] != 'N'

	) calidades_vigentes

) calidades_vigentes_final
WHERE
	calidades_vigentes_final.nRow_final = 1

-- Index ...
CREATE INDEX IX_calidades_vigentes_final_uIdPersona
    ON dbo.calidades_vigentes_final(uIdPersona)

-- Clean-Up:
DROP TABLE IF EXISTS #tmp_nac
DROP TABLE IF EXISTS #tmp_ccm_vigentes_distinct
DROP TABLE IF EXISTS #tmp_cpp_vigentes_distinct
DROP TABLE IF EXISTS #tmp_prr_vigentes_distinct
DROP TABLE IF EXISTS #tmp_prrhum_vigentes_distinct
DROP TABLE IF EXISTS #tmp_ctrlmig_permanentes

-- Test: Residentes: 483,203
--=============================================================================================================================*/

