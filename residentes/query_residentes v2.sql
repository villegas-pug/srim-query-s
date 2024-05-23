USE BD_SIRIM
GO

/*»
	→ Población extranjera en territrio nacional ...
==============================================================================================================================================================*/
-- DROP TABLE RimTotalExtranjerosPeru
-- SELECT * INTO RimTotalExtranjerosPeru FROM SIM.dbo.xTotalExtranjerosPeru
-- SELECT COUNT(1) FROM SIM.dbo.xTotalExtranjerosPeru → 1,625,454

-- Index: `RimTotalExtranjerosPeru` → uIdPersona
CREATE NONCLUSTERED INDEX IX_RimTotalExtranjerosPeru_uIdPersona
    ON dbo.RimTotalExtranjerosPeru(uIdPersona)

-- Index: `RimTotalExtranjerosPeru` → uIdPersona
CREATE NONCLUSTERED INDEX IX_RimTotalExtranjerosPeru_sCodCitaWeb
    ON dbo.RimTotalExtranjerosPeru(sCodCitaWeb)

-- Index: `SimMovMigra`
CREATE NONCLUSTERED INDEX IX_SimMovMigra_uIdPersona
    ON SIM.dbo.SimMovMigra(uIdPersona)

CREATE NONCLUSTERED INDEX IX_SimMovMigra_uIdPersona_dFechaControl
    ON SIM.dbo.SimMovMigra(uIdPersona, dFechaControl)

-- 1. `tmp` Ultimo movimiento migratorio ...
DROP TABLE IF EXISTS #tmp_extranjeros_ultimo_mm
SELECT * INTO #tmp_extranjeros_ultimo_mm FROM (

	SELECT 
		e.uIdPersona,
		[sTipoControl] = smm.sTipo,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM RimTotalExtranjerosPeru e
	JOIN SIM.dbo.SimMovMigra smm ON e.uIdPersona = smm.uIdPersona
	WHERE
		smm.bAnulado = 0
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'

) emm
WHERE emm.nFila_mm = 1

-- Index:
CREATE CLUSTERED INDEX IX_tmp_extranjeros_ultimo_mm_uIdPersona
    ON dbo.#tmp_extranjeros_ultimo_mm(uIdPersona)

-- 2. Población dentro del territorio nacional: 1,625,919 ...

-- Index 
/* CREATE NONCLUSTERED INDEX IX_SimSistPersonaDatosAdicionalPDA_sCodCitaWeb
    ON SIM.dbo.SimSistPersonaDatosAdicionalPDA(sCodCitaWeb) */

DROP TABLE IF EXISTS #tmp_extranjeros
SELECT
	r.uIdPersona,
	r.sCodCitaWeb,
	[sNombre] = r.Nombre,
	[sPaterno] = r.Paterno,
	[sMaterno] = r.Materno,
	[sSexo] = r.Sexo,
	[dFechaNacimiento] = r.FechaNacimiento,
	[sDocIdentidad] = r.TipoDocumento,
	[sNumDocIdentidad] = r.NumDocumento,
	[Departamento] = r.Departamento,
	[Provincia] = r.Provincia,
	[Distrito] = r.Distrito,
	[Dirección Domiciliaria] = (
											COALESCE(
															(
																SELECT se.sDomicilio FROM SIM.dbo.SimPersona sper 
																JOIN SIM.dbo.SimExtranjero se ON sper.uIdPersona = se.uIdPersona
																WHERE
																	sper.bActivo = 1
																	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
																	AND sper.uIdPersona = r.uIdPersona
															), (
																SELECT TOP 1 dpda.sDireccionBeneficiario FROM SIM.dbo.SimSistPersonaDatosAdicionalPDA spda
																JOIN SIM.dbo.SimDireccionPDA dpda ON spda.nIdCitaVerifica = dpda.nIdCitaVerifica
																											 AND spda.nIdTipoTramite = dpda.nIdTipoTramite
																WHERE
																	spda.sCodCitaWeb IS NOT NULL
																	AND spda.sCodCitaWeb = r.sCodCitaWeb
																ORDER BY
																	spda.dFechaHoraAud DESC
															)

											)



										
	),
	[sCalidadMigratoria] = r.CalidadMigratoria,
	[sCalidadTipo] = r.CalidadTipo,
	[sTipoCalidad] = CASE 
								WHEN r.CalidadMigratoria = 'Permanente' OR r.CalidadMigratoria = 'Inmigrante' THEN 'Permanente'
								WHEN r.CalidadTipo = 'R' AND (r.CalidadMigratoria != 'Permanente' AND r.CalidadMigratoria != 'Inmigrante') THEN 'Residente'
								WHEN r.CalidadMigratoria = 'Turista' THEN 'Turista'
								ELSE 'Otras calidades temporales'
							END,
	[sSituacionMigratoria] = r.EstadoR3,
	[sNacionalidad] = r.Nacionalidad
	/* [¿Dentro del Perú?] = (
							CASE (SELECT lmm.sTipoControl FROM #tmp_extranjeros_ultimo_mm lmm WHERE lmm.uIdPersona = r.uIdPersona)
									WHEN 'E' THEN 'Si'
									WHEN 'S' THEN 'No'
									ELSE 'No registra C.M.'
							END
						) */

	INTO #tmp_extranjeros
FROM SIM.dbo.xTotalExtranjerosPeru r
WHERE
	r.Departamento = 'Arequipa'


-- Test ...
-- Total extranjeros `AREQUIPA`
SELECT COUNT(1) FROM #tmp_extranjeros e -- 27512
SELECT COUNT(1) FROM SIM.dbo.xTotalExtranjerosPeru e WHERE e.Departamento = 'Arequipa' -- 33527
SELECT e.* FROM #tmp_extranjeros e -- 27512

SELECT TOP 1000 e.* FROM #tmp_extranjeros e

-- T3UR06F945 | Sharain Carolina	Gavidia	Hernandez	Mujer	1995-07-20 00:00:00.000
EXEC sp_help SimSistPersonaDatosAdicionalPDA

-- Buscar en Actualización de datos por Código Cita ...
SELECT su.sNombre, spda.sNomBeneficiario , dpda.* FROM SIM.dbo.SimSistPersonaDatosAdicionalPDA spda 
LEFT JOIN SIM.dbo.SimDireccionPDA dpda ON spda.nIdCitaVerifica = dpda.nIdCitaVerifica
														AND spda.nIdTipoTramite = dpda.nIdTipoTramite
LEFT JOIN SIM.dbo.SimUbigeo su ON dpda.sIdUbigeoBeneficiario = su.sIdUbigeo
WHERE
	spda.sCodCitaWeb = '19LQ34MK13'



-- Final
-- SELECT e.* INTO RimExtranjeros FROM #tmp_extranjeros e

SELECT TOP 10 * FROM RimExtranjeros

-- 3: ...
SELECT 
	tmp2.[¿Dentro del Perú?],
	COUNT(1)
FROM (

	SELECT 
		TOP 100
		-- tmp.*,
		[¿Dentro del Perú?] = 
									(
										SELECT 
											TOP 1 
											FIRST_VALUE(smm.sTipo) OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
										FROM SIM.dbo.SimMovMigra smm 
										WHERE smm.uIdPersona = tmp.uIdPersona
									)
	FROM #tmp_reniec tmp

) tmp2
GROUP BY tmp2.[¿Dentro del Perú?]


-- 2: ...
-- 1.3: Trámites `A` de CCM, CPP, PTP-RS109 ...
DROP TABLE IF EXISTS #tmp_inm_ccm_vigentes_A
SELECT * INTO #tmp_inm_ccm_vigentes_A FROM (

	SELECT 
		t_inm1.*,
		[nFilaInm] = ROW_NUMBER() OVER (PARTITION BY t_inm1.uIdPersona ORDER BY t_inm1.dFechaAprobacion DESC)

	FROM (

		SELECT 
			st.uIdPersona,
			st.sNumeroTramite,
			[sTipoTramite] = stt.sDescripcion,
			sti.sEstadoActual,
			[dFechaAprobacion] = (
			
				CASE 
					WHEN st.nIdTipoTramite = 58 THEN ( -- CCM
				
						COALESCE(
							sccm.dFechaAprobacion,
							(
								SELECT TOP 1 seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
								WHERE 
									seti.sNumeroTramite = st.sNumeroTramite
									AND seti.nIdEtapa = 23 -- 23 | CONFORMIDAD DIREC.INMGRACION.
									AND seti.bActivo = 1
									AND seti.sEstado = 'F'
								ORDER BY
									seti.dFechaHoraFin DESC
							),
							'1900-01-01 00:00:00.000'
						)
				
					)
					WHEN st.nIdTipoTramite = 113 OR st.nIdTipoTramite = 126 THEN ( -- CPP

						SELECT TOP 1 seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
						WHERE 
							seti.sNumeroTramite = st.sNumeroTramite
							AND seti.nIdEtapa = 75 -- 75 | CONFORMIDAD JEFATURA ZONAL
							AND seti.bActivo = 1
							AND seti.sEstado = 'F'
						ORDER BY
							seti.dFechaHoraFin DESC

					)

				END
		
			)
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
		JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
		WHERE
			st.bCancelado = 0
			AND sti.sEstadoActual = 'A'
			AND st.nIdTipoTramite IN (58, 113, 126)
			AND EXISTS (
					SELECT 1 FROM #tmp_uId_distinct uIdDnv WHERE uIdDnv.uIdPersona = st.uIdPersona
			)

	) t_inm1

)  t_inm2 
WHERE
	t_inm2.nFilaInm = 1



--==============================================================================================================================================================*/

SELECT TOP 10 * FROM SIM.dbo.SimPersonaNoAutorizada dnv
WHERE dnv.dFechaFinMedida IS NOT NULL

SELECT COUNT(1) FROM SIM.[dbo].[SimVerificaPDA]

SELECT TOP 10 * FROM SIM.dbo.SimPersona sper
WHERE
	sper.uIdPersona IN (
		'0F4A0684-FCA1-44C0-B03B-14C17241CDFB',
		'E0884FCF-461E-485D-950C-1873D7E792B0'
	)


-- sNombre, sPaterno, sMaterno, sNumDocIdentidad, dFechaNacimiento, sIdPaisNacionalidad


-- lvilchex

-- 1. Total extranjeros ...
SELECT COUNT(1) FROM xTotalExtranjerosPeru e

-- 1. Total extranjeros por departamento y distrito ...
SELECT 
	[Departamento] = UPPER(e.Departamento),
	[Distrito] = UPPER(e.Distrito),
	[Total] = COUNT(1)
FROM xTotalExtranjerosPeru e
GROUP BY
	UPPER(e.Departamento), UPPER(e.Distrito)
ORDER BY
	3 DESC

SELECT * FROM Sim