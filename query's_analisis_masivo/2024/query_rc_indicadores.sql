
USE SIM
GO

/*
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper});
*/

-- RC00025
SELECT
   mm.nIdOperadorDigita,
   mm.dFechaControl
FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona p ON mm.uIdPersona = p.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento = 'PNA' -- PNA | PARTIDA DE NACIMIENTO
   AND DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl) >= 18 -- Mayores de edad
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})


-- RC00026
SELECT
   mm.nIdOperadorDigita,
   mm.dFechaControl
FROM SimMovMigra mm
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sTipo IN ('E', 'S') AND i.sTipoMovimiento IN ('E', 'S'))
   AND mm.sTipo != i.sTipoMovimiento -- Tipos distintos
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})


-- RC00028

--1. Pasaporte electrónicos
;WITH cte_pas AS (
   SELECT
      p.*,
      t.uIdPersona
   FROM SIM.dbo.SimPasaporte p
   JOIN SIM.dbo.SimTramite t ON t.sNumeroTramite = p.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
      AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
      AND ISNUMERIC(p.sPasNumero) = 1
      AND p.sPasNumero LIKE '1[1-2]%'
), cte_mm_pase AS ( -- 2. Pasaportes como documentos de viaje
   
   SELECT
      mm.*,
      [sNombre(SimPersona)] = pe.sNombre,
      [sPaterno(SimPersona)] = pe.sPaterno,
      [sMaterno(SimPersona)] = pe.sMaterno,
      [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento

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
                  SELECT 1 FROM cte_pas p
                  WHERE p.sPasNumero = mm.sNumeroDoc
      )
      AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
      AND mm.nIdOperadorDigita in ({list_Oper})

), cte_mm_pase_f AS ( -- 3.

   SELECT f2.*
   FROM (

      SELECT
         f.*,
         [nTotalPase] = COUNT(1) OVER (PARTITION BY f.sNumeroDoc)
      FROM (

         SELECT
            mm.*,
            -- Aux
            [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl)

         FROM cte_mm_pase mm

      ) f
      WHERE
         f.[#] = 1 -- Personas

   ) f2
   WHERE
      f2.nTotalPase > 1 -- Total pase usados

) SELECT
   f1.nIdOperadorDigita,
   f1.dFechaControl
FROM cte_mm_pase_f f1
WHERE
   EXISTS ( -- Valida personas distintas
            SELECT TOP 1 1
            FROM cte_mm_pase_f f2
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

               SELECT 1 FROM cte_pas e
               WHERE 
                  e.sPasNumero = f1.sNumeroDoc -- Pas
                  AND DIFFERENCE(e.[sNombre], f1.[sNombre(SimPersona)]) >= 3
                  AND DIFFERENCE(e.[sPaterno], f1.[sPaterno(SimPersona)]) >= 3
                  AND DIFFERENCE(e.[sMaterno], f1.[sMaterno(SimPersona)]) >= 3

   )


-- RC00035
SELECT 
   mm.nIdOperador, 
   mm.dFechaControl
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND DATEDIFF(YYYY, pe.dFechaNacimiento, mm.dFechaControl) < 18 -- Menores
   AND mm.nIdCalidad IN ( -- 'OFICIAL', 'ARTISTA', 'TRIPULANTE', 'NEGOCIOS', 'TRABAJADOR', 'DIPLOMATICA'
         '58', '191', '212', '245', '246', '247', '266', '267', '292', '300', '316'
   )
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})


-- RC00039
-- 1. 90 | Expedición de Pasaporte Electrónico
;WITH tmp_pas_e AS (

   SELECT 
      t.uIdPersona, 
      p.*
   FROM SIM.dbo.SimPasaporte p
   JOIN SIM.dbo.SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
      AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
      AND ISNUMERIC(p.sPasNumero) = 1
      AND p.sPasNumero LIKE '1[1-2]%'

) SELECT
      mm.nIdOperadorDigita,
      mm.dFechaControl
FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND (ISNUMERIC(mm.sNumeroDoc) = 1 AND LEN(mm.sNumeroDoc) = 9 AND mm.sNumeroDoc LIKE '1[1-2]%')
   AND mm.sTipo = 'S'
   AND EXISTS ( -- Pas-e vencidos o por vencer(6 meses) realizaron control migratorio
                  SELECT 1
                  FROM tmp_pas_e e
                  WHERE
                     e.uIdPersona = mm.uIdPersona
                     AND e.sPasNumero = mm.sNumeroDoc
                     AND (
                        -- e.dFechaExpiracion <= mm.dFechaControl -- Venció
                        DATEDIFF(DD, mm.dFechaControl, e.dFechaExpiracion) <= 0 -- Venció
                        OR DATEDIFF(MM, mm.dFechaControl, e.dFechaExpiracion) <= 6 -- Por vencer
                     )
   )
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})


-- RC00041
-- 1.1 
SELECT 
   mm.nIdOperadorDigita,
   mm.dFechaControl
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 | A.I.J.CH.
   AND mm.sIdViaTransporte != 'A'  -- A | AEREO
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})

-- RC00042
-- 1.
SELECT 
   mm.nIdOperadorDigita,
   mm.dFechaControl
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND mm.sIdPaisMov = 'PER'
   AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
   AND mm.nIdOperadorDigita in ({list_Oper})

-- RC00053
-- 1.
;WITH cte_mm_dif_nac
AS  (
   SELECT f.*
   FROM (
      SELECT
         mm.nIdOperadorDigita,
         mm.dFechaControl,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
         [nContarMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona),
         [nContarNacionalidadMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sIdPaisNacionalidad)

      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.dFechaControl BETWEEN '{ini}' AND '{fin}'
         AND mm.nIdOperadorDigita in ({list_Oper})
   ) f
   WHERE
      f.[#] = 1
      AND f.[nContarNacionalidadMM] < f.[nContarMM]

)
SELECT 
   d.nIdOperadorDigita,
   d.dFechaControl
FROM cte_mm_dif_nac d

