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
-- SELECT TOP 10 * FROM SimPersonaNoAutorizada
DROP TABLE IF EXISTS #dnv_informativas_inhabilitada
SELECT
   [sNumDocInvalidaTmp] = CONCAT(sdi.sIdDocInvalida, ' N° ', sdi.sNumDocInvalida),
   spna.*,
   [nIdSesion_sdi] = sdi.nIdSesion
   INTO #dnv_informativas_inhabilitada
FROM SimPersonaNoAutorizada spna
JOIN SimDocInvalidacion sdi ON spna.nIdDocInvalidacion = sdi.nIdDocInvalidacion
LEFT JOIN SimTablaTipo stt ON spna.sIdAlertaInv = stt.strequivalente
WHERE
   spna.bActivo = 1 -- Inhabilitada
   -- stt.sDescripcion = 'ALERTA ES INFORMATIVA'
   -- A1 ↔ ALERTA ES INFORMATIVA | A2 ↔ ALERTA ES RESTRICTIVA
   AND spna.sIdAlertaInv IN ('A1', 'A2')

-- 1.2: `tmp` alertas analizadas ...
-- SELECT * FROM tmp_dnv_informativas_analizadas
DROP TABLE IF EXISTS tmp_dnv_informativas_analizadas
SELECT 
   TOP 0
   [nId] = REPLICATE('0', 6) ,dnv.sNombre, dnv.sPaterno, dnv.sMaterno, dnv.sIdPaisNacionalidad, [sDocInvalida] = dnv.sObservaciones
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

-- 1.6: Extrae dependencia origen  de alertas ...
SELECT

   dnv_i.nId,
   [Dependencia] = (
                        SELECT 
                           TOP 1 
                           --sd.sNombre 
                           dnv.nIdSesion_sdi
                        FROM #dnv_informativas_inhabilitada dnv
                        LEFT JOIN SimSesion ss ON dnv.nIdSesion_sdi = ss.nIdSesion
                        LEFT JOIN SimDependencia sd ON ss.sIdDependencia = sd.sIdDependencia
                        WHERE
                           dnv.sNombre = dnv_i.sNombre
                           AND dnv.sPaterno = dnv_i.sPaterno
                           AND dnv.sMaterno = dnv_i.sMaterno
                           -- AND dnv.sIdPaisNacionalidad = dnv_i.sIdPaisNacionalidad
                           AND dnv.sNumDocInvalidaTmp = dnv_i.sDocInvalida
                  )

FROM tmp_dnv_informativas_analizadas dnv_i


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

-- 3: Buscar expulsiones ...
SELECT dnv2.* FROM (

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

) dnv2
WHERE
   dnv2.Observaciones LIKE '%expu%'



--========================================================================================================================================== */

-- ALVAREZ OTERO, DANYELVIS ALEXANDER, Cedula de identidad 25545088
SELECT TOP 10 * FROM SimPersonaNoAutorizada dnv
WHERE
   -- dnv.sNumDocIdentidad = '25545088'
   -- dnv.sNombre LIKE 'DANYELVIS%'
   /* dnv.sPaterno LIKE 'ALV%'
   AND dnv.sMaterno LIKE 'OTE%' */

   dnv.sMaterno LIKE 'ALV%'
   AND dnv.sPaterno LIKE 'OTE%'

-- Doc
SELECT * FROM SimDocPersona sdp WHERE sdp.sNumero = '25545088'

