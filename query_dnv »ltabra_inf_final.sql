USE SIM
GO


/*
   → "ingreso clandestino" y "encontrarse en situacion migratoria irregular"
   [3:08 p. m., 20/12/2023] Lisseth: solo alertas informativas
   [3:08 p. m., 20/12/2023] Lisseth: que esten activas*
   [3:09 p. m., 20/12/2023] Lisseth: oki, gracias

   -- bActivo
	-- 0 → Habilitada
	-- 1 → Inhabilitada
========================================================================================================================================== */

-- 1.1: Alertas informativas ...
DROP TABLE IF EXISTS #dnv_informativas_inhabilitada
SELECT
   [sNumDocInvalidaTmp] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   spna.*,
   [sTipoAlerta] = stt.sDescripcion,
   sdi.sIdInstitucion,
   [sObservaciones(SimDocInvalidacion)] = sdi.sObservaciones
   INTO #dnv_informativas_inhabilitada
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
   spna.bActivo = 1 -- Inhabilitada
   AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'

-- 1.2: `tmp` alertas analizadas ...
DROP TABLE IF EXISTS tmp_dnv_informativas_analizadas
SELECT 
   TOP 0
   dnv.sNombre, dnv.sPaterno, dnv.sMaterno, dnv.sIdPaisNacionalidad, [sDocInvalida] = dnv.sObservaciones
   INTO tmp_dnv_informativas_analizadas
FROM SimPersonaNoAutorizada dnv

-- 1.3: Insert alertas analizadas ...
SELECT COUNT(1) FROM tmp_dnv_informativas_analizadas
-- INSERT INTO tmp_dnv_informativas_analizadas VALUES()

-- 1.4: Eliminar alertas analizadas duplicadas ...
DROP TABLE IF EXISTS #tmp_dnv_informativas_analizadas_v2
SELECT dnv2.* INTO #tmp_dnv_informativas_analizadas_v2 FROM (

   SELECT 
      dnv.*,
      [nFila] = ROW_NUMBER() OVER (PARTITION BY dnv.sNombre, dnv.sPaterno, dnv.sMaterno, dnv.sIdPaisNacionalidad, dnv.sDocInvalida ORDER BY dnv.sNombre)
   FROM tmp_dnv_informativas_analizadas dnv

) dnv2
WHERE dnv2.nFila = 1

-- 1.5: Final ...
SELECT

   [Num Doc Invalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   [Nombre] = dnv.sNombre,
   [Paterno] = dnv.sPaterno,
   [Materno] = dnv.sMaterno,
   [Sexo] = dnv.sSexo,
   [Documento] = dnv.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', dnv.sNumDocIdentidad),
   [Fecha Nacimiento] = dnv.dFechaNacimiento,
   [Pais Nacionalidad] = dnv.sIdPaisNacionalidad,
   [Fecha Inicio Medida] = dnv.dFechaInicioMedida,
   [Fecha Emisión] = sdi.dFechaEmision,
   [Fecha Recepción] = sdi.dFechaRecepcion,
   [Fecha Cancelación DNV] = dnv.dFechaCancelacion,
   [Motivo] = smi.sDescripcion,
   [Tipo Alerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones] = dnv.sObservaciones,
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado')

FROM #dnv_informativas_inhabilitada dnv
JOIN SimDocInvalidacion sdi ON dnv.nIdDocInvalidacion = sdi.nIdDocInvalidacion
JOIN SimMotivoInvalidacion smi ON dnv.sIdMotivoInv = smi.sIdMotivoInv
JOIN SimTablaTipo stt ON dnv.sIdAlertaInv = stt.strequivalente
WHERE
   NOT EXISTS (

      SELECT 1 FROM #tmp_dnv_informativas_analizadas_v2 v2
      WHERE
         v2.sNombre = dnv.sNombre
         AND v2.sPaterno = dnv.sPaterno
         AND v2.sMaterno = dnv.sMaterno
         AND v2.sIdPaisNacionalidad = dnv.sIdPaisNacionalidad
         AND v2.sDocInvalida = dnv.sNumDocInvalidaTmp

   )


-- Test ...
SELECT
   (SELECT COUNT(1) FROM #dnv_informativas_inhabilitada) 
   -
   (SELECT COUNT(1) FROM #tmp_dnv_informativas_analizadas_v2)

SELECT COUNT(1) FROM #dnv_informativas_inhabilitada
SELECT COUNT(1) FROM #tmp_dnv_informativas_analizadas_v2


-- CREATE TABLE #NewTable AS (SELECT TOP 0 [@nId] = 0 FROM SimPais);







-- 2.1: ...
SELECT dnv2.* FROM (

   SELECT 

      -- [Num Doc Invalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
      [Num Doc Invalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
      [Nombre] = spna.sNombre,
      [Paterno] = spna.sPaterno,
      [Materno] = spna.sMaterno,
      [Sexo] = spna.sSexo,
      [Documento] = spna.sIdDocumento,
      [Num Doc Identidad] = CONCAT('''', spna.sNumDocIdentidad),
      [Fecha Nacimiento] = spna.dFechaNacimiento,
      [Pais Nacionalidad] = spna.sIdPaisNacionalidad,
      [Fecha Inicio Medida] = spna.dFechaInicioMedida,
      [Fecha Emisión] = sdi.dFechaEmision,
      [Fecha Recepción] = sdi.dFechaRecepcion,
      [Fecha Cancelación DNV] = spna.dFechaCancelacion,
      [Motivo] = smi.sDescripcion,
      [Tipo Alerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
      [Observaciones] = spna.sObservaciones,
      [Estado] = IIF(spna.bActivo = 1, 'Inhabilitado', 'Habilitado'),

      -- Aux
      -- INPE – Antecedentes Penales; Antecedentes Interpol; Antecedentes Interpol e Ingreso Clandestino; Falsificación de Documentos/Antecedentes Interpol
      [Motivo Observaciones] = (

                           CASE
                              -- 22-12-2023
                              WHEN (
                                       spna.sObservaciones LIKE '%INPE%'
                                       OR spna.sObservaciones LIKE '%Antecedente%Penal%' 
                                    )
                                    THEN 'INPE – Antecedentes Penales' --
                              WHEN (
                                       -- spna.sObservaciones LIKE '%Antecedente%Interpol%' 
                                       spna.sObservaciones LIKE '%Ingreso%Clandestino%'
                                    )
                                    THEN 'Antecedentes Interpol e Ingreso Clandestino'
                              WHEN (
                                       spna.sObservaciones LIKE '%Falsificaci%Documento%' 
                                       -- AND spna.sObservaciones LIKE '%Antecedente%Interpol%'
                                    )
                                    THEN 'Falsificación de Documentos/Antecedentes Interpol' -- 
                              WHEN (
                                       spna.sObservaciones LIKE '%Antecedente%Interpol%'
                                    )
                                    THEN 'Antecedentes Interpol'
                              
                              /* 22-12-2023 ...
                                 → Proceso Judicial
                                 → Persona Desaparecida
                                 → Antecedentes Penales/Encontrarse Migratoriamente Irregular 
                                 → Proceso Judicial/Encontrarse Migratoriamente Irregular
                                 → Falsificación de Documentos
                                 → Menores
                                 → Antecedentes Policiales
                                 → Orden de Salida / Expulsión */
                              WHEN (
                                       spna.sObservaciones LIKE '%Proceso%Judicial%'
                                    )
                                    THEN 'Proceso Judicial'
                              WHEN (
                                       spna.sObservaciones LIKE '%Persona%Desaparecida%'
                                    )
                                    THEN 'Persona Desaparecida'
                              WHEN (
                                       spna.sObservaciones LIKE '%Encontrar%Migratoria%Irregula%'
                                    )
                                    THEN 'Antecedentes Penales/Encontrarse Migratoriamente Irregular'
                              WHEN (
                                       spna.sObservaciones LIKE '%Proceso%Judicial%Encontrar%Migratoria%Irregula%'
                                    )
                                    THEN 'Proceso Judicial/Encontrarse Migratoriamente Irregular'
                              WHEN (
                                       spna.sObservaciones LIKE '%Falsifica%Documento%'
                                    )
                                    THEN 'Falsificación de Documentos'
                              WHEN (
                                       spna.sObservaciones LIKE '%Menores%'
                                    )
                                    THEN 'Menores'
                              WHEN (
                                       spna.sObservaciones LIKE '%Anteceden%Policial%'
                                    )
                                    THEN 'Antecedentes Policiales'
                              WHEN (
                                       spna.sObservaciones LIKE '%Orden%Salida%Expulsi%' OR spna.sObservaciones LIKE '%Orden%Salida%'
                                    )
                                    THEN 'Orden de Salida / Expulsión'
                              ELSE 'Otros'
                           END

                        )

      /* [¿Alerta Restrictiva Posterior?] = (
                                             IIF(
                                                EXISTS (
                                                   SELECT TOP 1 1 FROM SimPersonaNoAutorizada spna2
                                                   JOIN SimDocInvalidacion sdi2 ON spna2.nIdDocInvalidacion = sdi2.nIdDocInvalidacion
                                                   WHERE
                                                      spna2.bActivo = 1
                                                      AND DIFFERENCE(spna2.sNombre, spna.sNombre) >= 3
                                                      AND DIFFERENCE(spna2.sPaterno, spna.sPaterno) >= 3
                                                      AND DIFFERENCE(spna2.sMaterno, spna.sMaterno) >= 3
                                                      AND spna2.sIdPaisNacionalidad = spna.sIdPaisNacionalidad
                                                      -- AND spna2.dFechaNacimiento = spna.dFechaNacimiento
                                                      AND spna2.sIdAlertaInv = 'A2' -- A2 ↔ ALERTA ES RESTRICTIVA ...
                                                      AND sdi2.dFechaEmision > sdi.dFechaEmision -- Posterior alerta INFORMATIVA ...
                                                ),
                                                'Si',
                                                'No'
                                             )
                                          
                                          )
   */

   FROM SimPersonaNoAutorizada spna
   RIGHT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
   LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
   LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
   WHERE
      spna.bActivo = 1 -- Inhabilitada
      AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'

) dnv2
WHERE dnv2.[Motivo Observaciones] != 'Otros'

SELECT dnv.sObservaciones FROM SimPersonaNoAutorizada dnv
WHERE 
   dnv.bActivo = 1 -- Inhabilitada
   AND dnv.sIdAlertaInv = 'A1'
   -- dnv.sObservaciones LIKE '%[interpol|antencedente]%'
   AND dnv.sObservaciones LIKE '%Antecedente%Interpol%'

   -- Caso 1: 21-12-2023
   -- ICLAN ↔ INGRESO CLANDESTINO | MIRRE	↔ ENCONTRARSE MIGRATORIAMENTE IRREGULAR
   -- AND spna.sIdMotivoInv IN ('ICLAN', 'MIRRE')

   -- Caso 2: 22-12-2023
   -- ANPEN ↔ ANTECEDENTES PENALES; ANINT	↔ ANTECEDENTES INTERPOL; FALDO ↔ FALSIFICACION DE DOCUMENTOS
   -- INPE – Antecedentes Penales; Antecedentes Interpol; Antecedentes Interpol e Ingreso Clandestino; Falsificación de Documentos/Antecedentes Interpol
   -- AND spna.sIdMotivoInv IN ('ANPEN', 'ANINT', 'FALDO')
   -- AND sdi.sNumDocInvalida LIKE '%MEDIO%COMUNICA%'

   -- Caso 3: 22-12-2023; S/N (MEDIOS DE COMUNICACIÓN)
   -- AND UPPER(sdi.sNumDocInvalida) LIKE '%MEDIO%COMUNICA%'

-- Test ...
-- SELECT * FROM SimTablaTipo stt WHERE stt.
SELECT DIFFERENCE('Jose', 'Josés')

SELECT * FROM SimMotivoInvalidacion smi WHERE smi.sDescripcion LIKE '%Falsificacion%'
SELECT TOP 10 * FROM SimPersonaNoAutorizada

SELECT TOP 10 * FROM SimDocInvalidacion sdi
WHERE
   sdi.sNumDocInvalida LIKE '%COMUNICACI[OÓ]N%'

-- Enrique Roman Uribe Taboada, Comandante PNP, Jefe de Departamento Internacional de Procesamiento, pone en conocimiento la lista de veintinueve (29) ciudadanos 
-- venezolanos, que cuentan con antecedentes policiales en su país, entre los cuales se encuentra LUIS JONAS CABAÑA LOPEZ , con CIP. N° V13634256. REG.POR SGMM.Actualización 
-- de la alerta migratoria en consideración al  Oficio N° 12001-10-2021-SUBCOMGEMPNPDIRASINT/OCN-INTERPOL-LIMA/DEPFCI, de fecha 16/10/2021, que en su contenido indica que el 
-- ciudadano VEN si tiene antecedentes en su país.


--========================================================================================================================================== */



--> Casos de alertas con error de digitación en nombres ...
-- ========================================================================================================================================== */
-- bActivo
-- 0 → Habilitada
-- 1 → Inhabilitada

-- 1. ...
DROP TABLE IF EXISTS #tmp_dnv
SELECT 

   [Num Doc Invalida] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   [Nombre] = spna.sNombre,
   [Paterno] = spna.sPaterno,
   [Materno] = spna.sMaterno,
   [Sexo] = spna.sSexo,
   [Documento] = spna.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', spna.sNumDocIdentidad),
   [Fecha Nacimiento] = spna.dFechaNacimiento,
   [Pais Nacionalidad] = spna.sIdPaisNacionalidad,
   [Fecha Emisión] = sdi.dFechaEmision,
   [Motivo] = smi.sDescripcion,
   [Tipo Alerta] = COALESCE(stt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones] = spna.sObservaciones,
   [Estado] = IIF(spna.bActivo = 1, 'Inhabilitado', 'Habilitado'),

   -- Index
   [#] = ROW_NUMBER() OVER (ORDER BY sdi.dFechaEmision ASC)

   INTO #tmp_dnv
FROM SimPersonaNoAutorizada spna
RIGHT JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimMotivoInvalidacion smi ON spna.sIdMotivoInv = smi.sIdMotivoInv
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
   spna.bActivo = 1 -- Inhabilitada
   AND stt.sDescripcion = 'ALERTA ES INFORMATIVA'
   AND (spna.sIdPaisNacionalidad != 'NNN' AND spna.sIdPaisNacionalidad IS NOT NULL)
   AND (spna.dFechaNacimiento != '1900-01-01 00:00:00.000' AND spna.dFechaNacimiento IS NOT NULL)


-- 2. Final: Self Join `tmp` ...
SELECT TOP 10 t1.*, t2.*
FROM #tmp_dnv t1
JOIN #tmp_dnv t2 ON t1.[Paterno] = t2.[Paterno]
                    AND t1.[Materno] = t2.[Materno]
                    AND CAST(t1.[Fecha Nacimiento] AS DATE) = CAST(t2.[Fecha Nacimiento] AS DATE)
                    AND t1.[Pais Nacionalidad] = t2.[Pais Nacionalidad]
                    AND DIFFERENCE(t1.Nombre, t2.Nombre) = 3
WHERE
   t1.[#] != t2.[#]
   

-- test 
-- ==========================================================================================================================================

/* 
   → Alertas inhabilitadas que corresponda a impedimentos de salida por institución.
-- ========================================================================================================================================== */

-- bActivo
-- 0 → Habilitada
-- 1 → Inhabilitada

-- 1
DROP TABLE IF EXISTS #dnv_informativas_inhabilitada
SELECT
   [sNumDocInvalidaTmp] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   spna.*,
   sdi.sIdDocInvalida,
   sdi.sNumDocInvalida,
   sdi.dFechaEmision,
   sdi.dFechaRecepcion,
   [sTipoAlerta] = stt.sDescripcion,
   sdi.sIdInstitucion,
   [sObservaciones(SimDocInvalidacion)] = sdi.sObservaciones
   INTO #dnv_informativas_inhabilitada
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
   spna.bActivo = 1 -- Inhabilitada

-- 2. Final ...
-- EXEC sp_help SimPersonaNoAutorizada
-- DECLARE @obs VARCHAR(55) = '%impedimento%salida%'
DECLARE @obs VARCHAR(55) = '%orden%captura%'
SELECT

   [Num Doc Invalida] = CONCAT(dnv.sIdDocInvalida, ' N° ', dnv.sNumDocInvalida),
   [Nombre] = dnv.sNombre,
   [Paterno] = dnv.sPaterno,
   [Materno] = dnv.sMaterno,
   [Sexo] = dnv.sSexo,
   [Documento] = dnv.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', dnv.sNumDocIdentidad),
   [Fecha Nacimiento] = dnv.dFechaNacimiento,
   [Pais Nacionalidad] = dnv.sIdPaisNacionalidad,
   [Fecha Inicio Medida] = dnv.dFechaInicioMedida,
   [Fecha Emisión] = dnv.dFechaEmision,
   [Fecha Recepción] = dnv.dFechaRecepcion,
   [Fecha Cancelación DNV] = dnv.dFechaCancelacion,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones1] = dnv.sObservaciones,
   [Observaciones2] = dnv.[sObservaciones(SimDocInvalidacion)],
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [Institucion] = i.sNombre

FROM #dnv_informativas_inhabilitada dnv
-- JOIN SimDocInvalidacion di ON dnv.nIdDocInvalidacion = di.nIdDocInvalidacion
JOIN SimMotivoInvalidacion mi ON dnv.sIdMotivoInv = mi.sIdMotivoInv
JOIN SimTablaTipo tt ON dnv.sIdAlertaInv = tt.strequivalente
LEFT JOIN SimInstitucion i ON dnv.sIdInstitucion = i.sIdInstitucion
WHERE
   dnv.sObservaciones LIKE @obs OR dnv.[sObservaciones(SimDocInvalidacion)] LIKE @obs



/* kquispet: Alertas por `RQ`
*
*  → RQ: Orden captura.
*  → Emisión de alertas fueron antes de la calidad.
*  → Si calidad fue declarada nula por la alerta.           */
DECLARE @rq VARCHAR(55) = '%orden%captura%'
DROP TABLE IF EXISTS #tmp_rq
SELECT

   [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Nombre] = dnv.sNombre,
   [Paterno] = dnv.sPaterno,
   [Materno] = dnv.sMaterno,
   [Sexo] = dnv.sSexo,
   [Documento] = dnv.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', dnv.sNumDocIdentidad),
   [Fecha Nacimiento] = dnv.dFechaNacimiento,
   [Pais Nacionalidad] = dnv.sIdPaisNacionalidad,
   [Fecha Inicio Medida] = dnv.dFechaInicioMedida,
   [Fecha Emisión] = di.dFechaEmision,
   [Fecha Recepción] = di.dFechaRecepcion,
   [Fecha Cancelación DNV] = dnv.dFechaCancelacion,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones1] = dnv.sObservaciones,
   [Observaciones2] = di.sObservaciones,
   [Estado] = IIF(dnv.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [Institucion] = i.sNombre

   INTO #tmp_rq
FROM SimPersonaNoAutorizada dnv
JOIN SimDocInvalidacion di ON dnv.nIdDocInvalidacion = di.nIdDocInvalidacion
JOIN SimMotivoInvalidacion mi ON dnv.sIdMotivoInv = mi.sIdMotivoInv
JOIN SimTablaTipo tt ON dnv.sIdAlertaInv = tt.strequivalente
LEFT JOIN SimInstitucion i ON di.sIdInstitucion = i.sIdInstitucion
WHERE
   dnv.bActivo = 1-- Inhabilitada
   AND (dnv.sObservaciones LIKE @rq OR di.sObservaciones LIKE @rq)

-- Test ...
SELECT TOP 10 * FROM #tmp_rq

SELECT TOP 10 * FROM BD_SIRIM.dbo.RimUltimaCalidadExtranjero

-- ==========================================================================================================================================

