USE SIM
GO

-- 07184038
SELECT spna.bActivo, sdi.* FROM SimPersonaNoAutorizada spna
LEFT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
WHERE
	spna.sNumDocIdentidad = '07184038'

-- Aux: DNV ...
SELECT COUNT(1) FROM SimPersonaNoAutorizada

-- bActivo
-- 0 → Habilitada
-- 1 → Inhabilitada

DROP TABLE IF EXISTS #tmp_dnv
SELECT 
	spna.*,
	sdi.dFechaEmision
	INTO #tmp_dnv
FROM SimPersonaNoAutorizada spna
LEFT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion

-- Index
CREATE INDEX IX_tmp_dnv_sIdDocIdentidad_sNumDocIdentidad_sIdPaisNacionalidad_dFechaRegistro
    ON dbo.#tmp_dnv(sIdPaisNacionalidad, sIdDocumento, sNumDocIdentidad, dFechaEmision)

CREATE INDEX IX_tmp_dnv_sPaterno_sMaterno_sNombre_sSexo_dFechaNacimiento_sIdPaisNacionalidad
    -- ON dbo.#tmp_dnv(sPaterno, sMaterno, sNombre, sSexo, dFechaNacimiento, sIdPaisNacionalidad, dFechaEmision)
	ON dbo.#tmp_dnv(sPaterno, sMaterno, sNombre, dFechaNacimiento, sIdPaisNacionalidad)

-- 1: Alerta con número de documento ...
DROP TABLE IF EXISTS #tmp_dnv_npastor_condoc
SELECT 
	TOP 0
	[nId] = 0,
	sper.sPaterno,
	sper.sMaterno,
	sper.sNombre,
	-- sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad,
	-- sper.sIdDocIdentidad,
	-- sper.sNumDocIdentidad,
	[dFechaRegistro] = sper.dFechaHoraAud
	INTO #tmp_dnv_npastor_condoc
FROM SimPersona sper

-- 1.1.1: Bulk ...
-- INSERT INTO #tmp_dnv_npastor VALUES(3,'MIRIAM ESTEFANI','PALOMINO','CRUZ','F','PER','2021-02-15')

-- 1.1.2: Update `sNumeroDocumento` ...
-- SELECT * FROM #tmp_dnv_npastor_condoc
UPDATE #tmp_dnv_npastor_condoc
	SET sNumDocIdentidad = REPLACE(sNumDocIdentidad, '''', '')

-- 1.2: Alerta sin número de documento ...
DROP TABLE IF EXISTS #tmp_dnv_npastor_sindoc
SELECT 
	TOP 0
	[nId] = 0,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	-- sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacionalidad
	-- [dFechaEmision] = sper.dFechaHoraAud
	INTO #tmp_dnv_npastor_sindoc
FROM SimPersona sper

-- 1.2.1: Bulk ...
-- INSERT INTO #tmp_dnv_npastor_sindoc VALUES(3,'MIRIAM ESTEFANI','PALOMINO','CRUZ','F','PER','2021-02-15')

-- Test ...
SELECT COUNT(1) FROM #tmp_dnv_npastor_condoc
SELECT COUNT(1) FROM #tmp_dnv_npastor_sindoc

-- 2: Filtrar por Número Documento ...
DROP TABLE IF EXISTS #tmp_final_1
SELECT 
	spna.sNombre,
	spna.sPaterno,
	spna.sMaterno,
	spna.sSexo,
	spna.sIdDocumento,
	[sNumDocIdentidad] = CONCAT('''', spna.sNumDocIdentidad),
	spna.dFechaNacimiento,
	spna.sIdPaisNacionalidad,
	spna.dFechaInicioMedida,
	spna.dFechaEmision,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO')
	INTO #tmp_final_1
FROM #tmp_dnv_npastor_condoc dnv 
LEFT JOIN #tmp_dnv spna ON spna.sIdDocumento = dnv.sIdDocIdentidad
							AND spna.sNumDocIdentidad = dnv.sNumDocIdentidad
							AND spna.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
							AND spna.dFechaEmision >= dnv.dFechaRegistro
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
	spna.bActivo = 1

-- 3: Filtrar con datos personales ...
DROP TABLE IF EXISTS #tmp_final_2
SELECT 
	dnvp.nId,
	dnvp.sNombre,
	dnvp.sPaterno,
	dnvp.sMaterno,
	dnv.dFechaNacimiento,
	dnvp.sIdPaisNacionalidad,
	-- [dFechaEmision_epastor] = dnvp.dFechaRegistro,
	[dFechaEmision_DNV] = dnv.dFechaEmision,
	[sMotivo] = smi.sDescripcion,
	[sTipoAlerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
	[sEstado] = IIF(dnv.bActivo = 1, 'INHABILITADO', 'HABILITADO')
	INTO #tmp_final_2
FROM #tmp_dnv_npastor_sindoc dnvp
LEFT JOIN #tmp_dnv dnv ON dnvp.sNombre = dnv.sNombre
							AND dnvp.sPaterno = dnv.sPaterno 
							AND dnvp.sMaterno = dnv.sMaterno 
							-- AND dnvp.sSexo = dnv.sSexo
							AND dnvp.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
							AND dnvp.dFechaNacimiento = dnv.dFechaNacimiento
							-- AND dnv.dFechaEmision > dnvp.dFechaRegistro

							-- Aux ...
							-- AND dnv.dFechaEmision = dnvp.dFechaRegistro
							-- A1 | ALERTA ES INFORMATIVA
							-- A2 |	ALERTA ES RESTRICTIVA
							-- AND dnv.sIdAlertaInv = 'A1'

LEFT JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
WHERE
	dnv.bActivo = 1
	AND stt.sDescripcion = 'ALERTA ES RESTRICTIVA'
ORDER BY
	dnvp.nId
	

SELECT * FROM #tmp_final_2 f ORDER BY f.nId

-- 3.1: Filtrar ultima alerta RESTRICTIVA ...
SELECT * FROM (

	SELECT 
		*,
		[nUltima(A)] = ROW_NUMBER() OVER (PARTITION BY f.nId ORDER BY f.dFechaEmision_DNV DESC)
	FROM #tmp_final_2 f

) f2
WHERE
	f2.[nUltima(A)] = 1

-- Test ...
SELECT * FROM #tmp_final_2


/*░
	-> Extrae CCM de Alerta ...
=================================================================================================================================*/

-- 1: `tmp`
DROP TABLE IF EXISTS #tmp_alerta_persona
SELECT TOP 0 sper.uIdPersona INTO #tmp_alerta_persona FROM SimPersona sper

-- 2: Bulk ...
-- INSERT INTO #tmp_alerta_persona VALUES(
INSERT INTO #tmp_alerta_persona VALUES('316C6AF8-F81D-4300-A272-E6B09A38A908')
SELECT COUNT(1) FROM #tmp_alerta_persona

-- 3: ...
SELECT 
	ap.uIdPersona,
	[dFechaCM] = (
						CASE 
							WHEN (

								SELECT 
									TOP 1
									st.nIdTipoTramite
								FROM SimTramite st
								JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
								JOIN SimCambioCalMig sccm ON sti.sNumeroTramite = sccm.sNumeroTramite
								WHERE
									st.bCancelado = 0
									AND st.uIdPersona = ap.uIdPersona
									AND sti.sEstadoActual = 'A'
								ORDER BY
									sccm.dFechaAprobacion DESC
							
							) = 113 THEN -- CPP
							(
								-- CONFORMIDAD JEFATURA ZONAL | 75
								-- IMPRESION | 6
								SELECT seti.dFechaHoraFin FROM SimEtapaTramiteInm seti 
								WHERE seti.sNumeroTramite = (
									SELECT 
										TOP 1
										st.sNumeroTramite
									FROM SimTramite st
									JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
									JOIN SimCambioCalMig sccm ON sti.sNumeroTramite = sccm.sNumeroTramite
									WHERE
										st.bCancelado = 0
										AND st.uIdPersona = ap.uIdPersona
										AND sti.sEstadoActual = 'A'
									ORDER BY
										st.dFechaHoraReg DESC -- CPP, no tiene fecha de APROBACIÓN ...
								)
								AND seti.nIdEtapa = 75 AND seti.sEstado = 'F'

							)
							ELSE (
								SELECT 
									TOP 1
									sccm.dFechaAprobacion
								FROM SimTramite st
								JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
								JOIN SimCambioCalMig sccm ON sti.sNumeroTramite = sccm.sNumeroTramite
								WHERE
									st.bCancelado = 0
									AND st.uIdPersona = ap.uIdPersona
									AND sti.sEstadoActual = 'A'
								ORDER BY
									sccm.dFechaAprobacion DESC
							)
						END
	
				)
FROM #tmp_alerta_persona ap


-- Test ...

SELECT * FROM SimEtapaTramiteInm seti 
WHERE seti.sNumeroTramite = 'LM210606318'
									

SELECT TOP 10 * FROM [dbo].[SimEtapaTramiteInm]
SELECT * FROM SimTipoTramite stt
WHERE
	stt.sDescripcion LIKE '%regul%'

-- 113 | REGULARIZACION DE EXTRANJEROS

-- 2
SELECT 
	[sEtapa] = se.sDescripcion,
	sett.* 
FROM SimEtapaTipoTramite sett
JOIN SimEtapa se ON sett.nIdEtapa = se.nIdEtapa
WHERE
	sett.nIdTipoTramite = 113
ORDER BY
	sett.nSecuencia


-- 1
SELECT 
	stt.sSigla,
	stt.sDescripcion,
	[nTotal] = COUNT(1)
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimCambioCalMig sccm ON sti.sNumeroTramite = sccm.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
GROUP BY
	stt.sSigla,
	stt.sDescripcion



DROP TABLE IF EXISTS #tmp
SELECT TOP 0 sper.sObservaciones, dFechaNacimiento INTO #tmp FROM SimPersona sper
INSERT INTO #tmp VALUES('abc', GETDATE())
INSERT INTO #tmp VALUES('bca', '2023-01-12')
INSERT INTO #tmp VALUES(NULL, NULL)

SELECT * FROM #tmp t
ORDER BY
	t.dFechaNacimiento DESC




--=================================================================================================================================*/

-- PAA760782
SELECT sdi.* FROM SimPersonaNoAutorizada dnv 
LEFT JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
WHERE 
	dnv.bActivo = 1
	AND dnv.sNumDocIdentidad = 'PAA760782'

