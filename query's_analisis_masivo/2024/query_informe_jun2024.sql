USE SIM
GO

--> 1. Se define como regla, que el tipo de movimiento migratorio registrado en el Control Migratorio debe coincidir con el tipo de movimiento registrado en el Itinerario.
-- ========================================================================================================================================================================

-- 1.1 `tmp` Registros de control migratorio de A.I.J.C.H
SELECT
   /* TOP 1
   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.sTipo,
   mm.sIdModuloDigita,
   [dFechaControl] = CAST(mm.dFechaControl AS DATE),
   [dFechaProgramada(SimItinerario)] = CAST(i.dFechaProgramada AS DATE),
   [sNumeroNave(SimItinerario)] = i.sNumeroNave,
   [nIdTransportista(SimItinerario)] = i.nIdTransportista,
   [sTipo(SimItinerario)] = i.sTipoMovimiento */

   COUNT(1)

FROM SimMovMigra mm
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sTipo IN ('E', 'S') AND i.sTipoMovimiento IN ('E', 'S'))
   AND mm.sTipo != i.sTipoMovimiento -- Tipos distintos
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'


-- ========================================================================================================================================================================


--> ░ 2. Pais de procedencia o destino en `SIM.dbo.SimMovMigra`, distinto a Pais de procedencia o destino en `SIM.dbo.SimItinerario`.
-- ========================================================================================================================================================================

-- 2.1
SELECT

   /* [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha de Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad ] = pe.sIdPaisNacionalidad,

   -- Aux
   mm.sIdMovMigratorio,
   mm.dFechaControl,
   mm.sTipo,
   [Itinerario(SimMovMigra)] = mm.sIdItinerario,
   [Pais Movimiento(SimMovMigra)] = mm.sIdPaisMov,
   [Itinerario(SimItinerario)] = i.sIdItinerario,
   [Pais Movimiento(SimItinerario)] = i.sIdPais */
   COUNT(1)
   
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sIdPaisMov != 'NNN' AND i.sTipoMovimiento != 'NNN')
   AND mm.sIdPaisMov != i.sIdPais -- Distinto pais de Proc/Dest
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- ========================================================================================================================================================================


--> ░ 3. Se define como regla, que el uso del documento de viaje PAS de ciudadanos peruanos en el control migratorio, debe ser exclusivamente personal.
-- ========================================================================================================================================================================

--3.1
DROP TABLE IF EXISTS #tmp_pas
SELECT
   p.*,
   t.uIdPersona
	INTO #tmp_pas
FROM SIM.dbo.SimPasaporte p
JOIN SIM.dbo.SimTramite t ON t.sNumeroTramite = p.sNumeroTramite
WHERE
   t.bCancelado = 0
	AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
	AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pas_sPasNumero_uIdPersona ON #tmp_pas(uIdPersona, sPasNumero)

-- 3.2 Pasaportes como documentos de viaje
DROP TABLE IF EXISTS #tmp_mm_pase
SELECT
   mm.*,
   [sNombre(SimPersona)] = pe.sNombre,
   [sPaterno(SimPersona)] = pe.sPaterno,
   [sMaterno(SimPersona)] = pe.sMaterno,
   [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento

   INTO #tmp_mm_pase
FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND ( -- PAS electrónico
         ISNUMERIC(mm.sNumeroDoc) = 1
         AND LEN(mm.sNumeroDoc) = 9
         AND mm.sNumeroDoc LIKE '1[1-2]%'
   )
   AND EXISTS ( -- Pasaporte válido
               SELECT 1 FROM #tmp_pas p
               WHERE p.sPasNumero = mm.sNumeroDoc
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

CREATE NONCLUSTERED INDEX ix_tmp_mm_pase
   ON #tmp_mm_pase(uIdPersona, sNumeroDoc, dFechaControl)

-- 3.3
DROP TABLE IF EXISTS #tmp_mm_pase_f
SELECT f2.* INTO #tmp_mm_pase_f
FROM (

   SELECT
      f.*,
      [nTotalPase] = COUNT(1) OVER (PARTITION BY f.sNumeroDoc)
   FROM (

      SELECT
         mm.*,
         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl)

      FROM #tmp_mm_pase mm

   ) f
   WHERE
      f.[#] = 1 -- Personas

) f2
WHERE
   f2.nTotalPase > 1 -- Total pase usados

-- 3 Final:
-- 3.1
SELECT
   f1.sIdMovMigratorio,
   f1.uIdPersona,
   f1.sNumeroDoc,
   f1.nIdOperadorDigita
FROM #tmp_mm_pase_f f1
WHERE
   EXISTS ( -- Valida personas distintas
            SELECT TOP 1 1
            FROM #tmp_mm_pase_f f2
            WHERE
               f1.uIdPersona != f2.uIdPersona -- Personas distintas ...
               AND f1.sNumeroDoc = f2.sNumeroDoc -- `PAS` iguales ...
               AND (
                     DIFFERENCE(f1.[sNombre(SimPersona)], f2.[sNombre(SimPersona)]) <= 3
                     AND DIFFERENCE(f1.[sPaterno(SimPersona)], f2.[sPaterno(SimPersona)]) <= 2
                     AND DIFFERENCE(f1.[sMaterno(SimPersona)], f2.[sMaterno(SimPersona)]) <= 2
               )
   )

-- 3.2 Operador responsable del error
SELECT
   -- f1.uIdPersona,
   -- f1.sNombres,
   /* f1.[sNombre(SimPersona)],
   f1.[sPaterno(SimPersona)],
   f1.[sMaterno(SimPersona)],
   f1.sNumeroDoc, */
   f1.nIdOperadorDigita
FROM #tmp_mm_pase_f f1
WHERE
   EXISTS ( -- Valida personas distintas
            SELECT TOP 1 1
            FROM #tmp_mm_pase_f f2
            WHERE
               f1.uIdPersona != f2.uIdPersona -- Personas distintas ...
               AND f1.sNumeroDoc = f2.sNumeroDoc -- `PAS` iguales ...
               AND (
                     DIFFERENCE(f1.[sNombre(SimPersona)], f2.[sNombre(SimPersona)]) <= 3
                     AND DIFFERENCE(f1.[sPaterno(SimPersona)], f2.[sPaterno(SimPersona)]) <= 2
                     AND DIFFERENCE(f1.[sMaterno(SimPersona)], f2.[sMaterno(SimPersona)]) <= 2
               )
   )
   AND NOT EXISTS (  -- `uId` control migratorio no corresponde a `uId` PAS-E ...

               SELECT 1 FROM #tmp_pas e
               WHERE 
                  -- e.uIdPersona = f1.uIdPersona
                  e.sPasNumero = f1.sNumeroDoc -- Pas
                  AND DIFFERENCE(e.[sNombre], f1.[sNombre(SimPersona)]) >= 3
                  AND DIFFERENCE(e.[sPaterno], f1.[sPaterno(SimPersona)]) >= 3
                  AND DIFFERENCE(e.[sMaterno], f1.[sMaterno(SimPersona)]) >= 3

   )

-- Test
SELECT * 
FROM SimPersona pe
WHERE
   pe.uIdPersona IN (
      'c00d3eba-8427-4233-a037-536f14787c3d',
      '7781566e-b676-48dc-b614-ec33d5f58359'
   )

SELECT p.sPasNumero, p.sNombre, p.sPaterno, p.sMaterno
FROM SimPasaporte p
WHERE 
   p.sPasNumero = '123366963'
   

-- ========================================================================================================================================================================


--> ░ 4. Distintos ciudadanos extranjeros, registran igual número de C.E en `SIM.dbo.SimCarnetExtranjeria`.
-- ========================================================================================================================================================================

-- 4.1
DROP TABLE IF EXISTS #tmp_dupl_ce
SELECT 
   f.*
   INTO #tmp_dupl_ce
FROM (

   SELECT

      ce.*,
      [sNombre(SimPersona)] = pe.sNombre,
      [sPaterno(SimPersona)] = pe.sPaterno,
      [sMaterno(SimPersona)] = pe.sMaterno,
      [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento,
      [sIdPaisNacionalidad(SimPersona)] = pe.sIdPaisNacionalidad,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY ce.uIdPersona, ce.sNumeroCarnet ORDER BY ce.dFechaEmision DESC),
      [nTotalCE] = COUNT(1) OVER (PARTITION BY ce.sNumeroCarnet)

   FROM SimCarnetExtranjeria ce
   JOIN SimTramite t ON t.sNumeroTramite = ce.sNumeroTramite
   JOIN SimPersona pe ON ce.uIdPersona = pe.uIdPersona
   WHERE
      t.bCancelado = 0
      AND (
            ISNUMERIC(ce.sNumeroCarnet) = 1
            AND LEN(ce.sNumeroCarnet) = 9
         )
   
) f
WHERE
   f.[#] = 1 -- Personas
   AND f.[nTotalCE] > 1 -- Total `CE`

-- 4.2. Final ...
SELECT COUNT(1)
FROM #tmp_dupl_ce
SELECT 

   [Id Persona] = f1.uIdPersona,
   [Nombres] = f1.[sNombre(SimPersona)],
   [Apellido 1] = f1.[sPaterno(SimPersona)],
   [Apellido 2] = f1.[sMaterno(SimPersona)],
   [Sexo] = '',
   [Fecha de Nacimiento] = f1.[dFechaNacimiento(SimPersona)],
   [Nacionalidad ] = f1.[sIdPaisNacionalidad(SimPersona)],

   -- Aux
   [Número Trámite] = f1.sNumeroTramite,
   [Fecha Emisión] = f1.dFechaEmision,
   [Número Carnet] = f1.sNumeroCarnet

FROM #tmp_dupl_ce f1
WHERE
   EXISTS (
            SELECT TOP 1 1
            FROM #tmp_dupl_ce f2
            WHERE
               f1.sNumeroCarnet = f2.sNumeroCarnet -- `CE` iguales ...
               AND f1.uIdPersona != f2.uIdPersona -- Persona distintas ...
   )
ORDER BY f1.sNumeroCarnet

-- ========================================================================================================================================================================


--> ░ 5. Ciudadanos de nacionalidad `PERUANA` con más de 1 pasaporte, no registran trámite de `ANULACIÓN DE PASAPORTE` en relación al pasaporte anterior.
-- 5. Se define como regla, que los ciudadanos de nacionalidad peruana que posean más de un pasaporte, deben registrar un trámite de anulación de pasaporte correspondiente al pasaporte anterior.
-- ========================================================================================================================================================================

-- Aux
-- 60,789,717
DROP TABLE IF EXISTS #tmp_dp
SELECT 
   dp.uIdPersona,
   [nTotal] = COUNT(1)
   INTO #tmp_dp
FROM SimDocPersona dp
WHERE 
   dp.sIdDocumento = 'PAS'
GROUP BY dp.uIdPersona

CREATE NONCLUSTERED INDEX ix_tmp_dp_uIdPersona
   ON #tmp_dp(uIdPersona)

-- 5.1: 
DROP TABLE IF EXISTS #tmp_e_pas
SELECT f.* INTO #tmp_e_pas
FROM (

   SELECT 
      t.uIdPersona,
      t.sNumeroTramite,
      t.nIdMotivoTramite,
      t.dFechaHora,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY t.dFechaHora DESC),
      [nTotal(E)] = COUNT(1) OVER (PARTITION BY t.uIdPersona)
   FROM SimTramite t
   WHERE
      t.bCancelado = 0
      AND t.bCulminado = 1
      AND t.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | EXPEDICIÓN DE PASAPORTE ELECTRÓNICO

) f
WHERE
   f.[#] = 1
   AND f.[nTotal(E)] > 1

-- 5.2: 4 | ANULACION DE PASAPORTE
DROP TABLE IF EXISTS #tmp_a_pas
SELECT
   f.* 
   INTO #tmp_a_pas
FROM (
   
   SELECT 
      t.uIdPersona,
      t.sNumeroTramite,
      t.nIdMotivoTramite,
      t.dFechaHora,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY t.uIdPersona ORDER BY t.dFechaHora DESC),
      [nTotal(A)] = COUNT(1) OVER (PARTITION BY t.uIdPersona)

   FROM SimTramite t
   WHERE
      t.bCancelado = 0
      -- AND t.bCulminado = 1
      AND t.nIdTipoTramite = 4 -- ANULACION DE PASAPORTE

) f
WHERE
   f.[#] = 1

-- 5.3
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha de Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad ] = pe.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite Referencial] = e.sNumeroTramite,
   [Pasaportes] = (
                     SELECT
                        p.sPasNumero
                     FROM SimTramitePas p 
                     JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
                     WHERE
                        t.uIdPersona = e.uIdPersona
                        AND t.bCancelado = 0
                        AND t.bCulminado = 1
                        AND t.nIdTipoTramite IN (2, 90)
                     FOR XML PATH('')
                  ),

   -- Aux
   [Total Pasaportes Expedidos] = e.[nTotal(E)],
   [Total Pasaportes Anulados] = a.[nTotal(A)]

FROM #tmp_e_pas e
JOIN #tmp_a_pas a ON e.uIdPersona = a.uIdPersona
JOIN SimPersona pe ON e.uIdPersona = pe.uIdPersona
WHERE
   a.[nTotal(A)] < e.[nTotal(E)] - 1 -- Total PAS anulados inferior (-2), respecto al total de PAS emitidos.
   AND e.[nTotal(E)] = ( -- PAS válidos
                           SELECT dp.nTotal
                           FROM #tmp_dp dp
                           WHERE dp.uIdPersona = e.uIdPersona
                        )

-- ========================================================================================================================================================================


SELECT * FROM SimSolicitudCUE s WHERE s.nIdSolicitudCue = 1


WITH CTE_SimMovMigra AS (
    SELECT 
        smm.sIdMovMigratorio, 
        smm.bTemporal, 
        smm.bAnulado,
        smm.sIdModuloDigita, 
        smm.nIdEstacionDigita,
        smm.sTipo,
        smm.dFechaControl, 
        smm.sIdPaisMov,
        smm.sIdViaTransporte,
        smm.uIdPersona,
        smm.sIdItinerario,
        smm.nIdTransportista,
        smm.nIdSesion
    FROM SIM.dbo.SimMovMigra smm WITH(INDEX (IX_SimMovMigra_21))
    WHERE smm.sIdViaTransporte = 'A' 
      AND smm.dFechaControl BETWEEN DATEADD(MINUTE, -10, GETDATE()) AND GETDATE()
      AND smm.sIdDependencia = '27'
)
SELECT 
       smm.sIdMovMigratorio, 
       smm.bTemporal, 
       smm.bAnulado,
       smm.sIdModuloDigita, 
       smm.nIdEstacionDigita,
       smm.nIdSesion,
       se.sNombre AS nombreEstacionDigita,
       smm.sTipo,
       smm.dFechaControl, 
       smm.sIdPaisMov,
       si.sIdCiudad as sIdCiudadMov, 
       smm.sIdViaTransporte, 
       set2.sSigla,
       set2.sNombreRazon, 
       si.sNumeroNave,
       si.nCantidadMov,
       si.dFechaProgramada, 
       smm.uIdPersona,
       sp.sNombre,
       sp.sPaterno,
       sp.sMaterno,
       sp.sSexo, 
       sp.dFechaNacimiento,
       sp.sIdPaisNacionalidad, 
       smm.sIdItinerario,
       sei.sIdEstadoItinerario, 
       sei.sNombre as sNombreEstadoItinerario
FROM CTE_SimMovMigra smm
LEFT JOIN SIM.dbo.SimEmpTransporte set2 ON smm.nIdTransportista = set2.nIdTransportista
LEFT JOIN SIM.dbo.SimItinerario si ON smm.sIdItinerario = si.sIdItinerario  
LEFT JOIN SIM.dbo.SimEstadoItinerario sei ON sei.sIdEstadoItinerario = si.sEstado 
LEFT JOIN SIM.dbo.SimPersona sp ON smm.uIdPersona = sp.uIdPersona
LEFT JOIN SIM.dbo.SimEstacion se ON smm.nIdEstacionDigita = se.nIdEstacion


DROP TABLE IF EXISTS DashSimMovMigra

SELECT 
   [dFechaControl] = CAST(mm.dFechaControl AS DATE),
   mm.sTipo,
   [sDependencia] = d.sNombre,
   [nTotal] = COUNT(1)
FROM SimMovMigra mm
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.dFechaControl BETWEEN '2024-11-01 00:00:00.000' AND '2024-12-31 23:59:59.998'
GROUP BY
   CAST(mm.dFechaControl AS DATE),
   mm.sTipo,
   d.sNombre
ORDER BY 1



 