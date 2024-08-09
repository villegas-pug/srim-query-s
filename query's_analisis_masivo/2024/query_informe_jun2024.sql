USE SIM
GO

--> ░ 1. Tipo de movimiento migratorio en `SIM.dbo.SimMovMigra`, distinto a tipo de movimiento registrado en `SIM.dbo.SimItinerario`.
-- ========================================================================================================================================================================


-- 1.1
DROP TABLE IF EXISTS #tmp_i_tmm
SELECT
   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.sTipo,
   [dFechaControl] = CAST(mm.dFechaControl AS DATE),
   [dFechaProgramada(SimItinerario)] = CAST(i.dFechaProgramada AS DATE),
   [sNumeroNave(SimItinerario)] = i.sNumeroNave,
   [nIdTransportista(SimItinerario)] = i.nIdTransportista,
   [sTipo(SimItinerario)] = i.sTipoMovimiento

   INTO #tmp_i_tmm
FROM SimMovMigra mm
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sTipo IN ('E', 'S') AND i.sTipoMovimiento IN ('E', 'S'))
   AND mm.sTipo != i.sTipoMovimiento -- Distinto tipo de movimiento (SIM.dbo.SimMovMigra.sTipo != SIM.dbo.SimItinerario.sTipoMovimiento)


-- 1.2
SELECT * 
FROM (

   SELECT
      ie.*,

      -- Aux
      [#] = (
               SELECT COUNT(1) 
               FROM SimItinerario i
               WHERE
                  i.dFechaProgramada = ie.[dFechaProgramada(SimItinerario)]
                  AND i.sNumeroNave = ie.[sNumeroNave(SimItinerario)]
                  AND i.nIdTransportista = ie.[nIdTransportista(SimItinerario)]
      )
   FROM #tmp_i_tmm ie

) ie2
WHERE
   ie2.[#] = 1


-- 2019-01-13 | 00007391 | 13
-- 2019-01-14 | 00007388 | 13
-- 2023-09-06	00000535	31

SELECT *
FROM SimItinerario i
WHERE
   -- i.sIdItinerario = '2019AI003302'
   CAST(i.dFechaProgramada AS DATE) = '2023-09-06'
   AND i.sNumeroNave = '00000535'
   AND i.nIdTransportista = 31


-- Test
-- 2017-12-03 10:50:19.000 | 00000536 | 72
-- 2014-07-27 05:25:00.000 | 00006655 | 29
-- 2014AI035123
SELECT
   TOP 10
   s.sIdModulo,
   i.* 
FROM SimItinerario i
JOIN SimSesion s ON i.nIdSesion = s.nIdSesion
WHERE 
   -- i.sIdItinerario = '2014AI035123'
   -- i.dFechaProgramada BETWEEN '2017-12-03 00:00:00.000' AND '2017-12-03 23:59:59.999'
   -- 2014-07-27
   i.dFechaProgramada BETWEEN '2014-07-26 00:00:00.000' AND '2014-07-28 23:59:59.999'
   AND i.sNumeroNave = '00006655'
   AND i.nIdTransportista = 29

-- Top 10 aerolineas
SELECT
   TOP 10
   i.nIdTransportista,
   COUNT(1)
FROM SimMovMigra mm
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
GROUP BY
   i.nIdTransportista
ORDER BY
   2 DESC

--> SIM.dbo.sNumeroNave: Identificador compuesto entre # de nave y tipo de movimiento
/*
nIdTransportista | nTotal(MovMigra)
72 | 18114611
31	| 15911746
13	| 9706765
20	| 7140822
2	| 6241213
50	| 5955165
29	| 4132102
30	| 3880143
60	| 2874494
24	| 2805831  */

--> Nave 1
-- 00002456	S
-- 00002457	E

--> Nave 2
-- 00002484	S
-- 00002459	E

-- 00002472	S	1909
-- 00002393	E	1882

-- 00000530	E
-- 00002370	E

SELECT
   i.nIdTransportista,
   i.sTipoMovimiento,
   COUNT(1) 
FROM SimItinerario i
WHERE
   i.sNumeroNave = '00000530'
GROUP BY
   i.nIdTransportista,
   i.sTipoMovimiento


SELECT
   i.sNumeroNave,
   i.sTipoMovimiento,
   COUNT(1)
FROM SimItinerario i
WHERE
   -- i.sNumeroNave = '00000536'
   i.nIdTransportista = 72
GROUP BY
   i.sNumeroNave,
   i.sTipoMovimiento
ORDER BY
   3 DESC
   -- 2
   -- 1 ASC

EXEC sp_help SimItinerario
/*
sIdItinerario
sTipoMovimiento
dFechaProgramada
sNumeroNave
nIdTransportista
nCodigoLan
*/

--> Motivo inconsistencia: Pasajeros de paso, eorolinea y número de vuelo igual
-- 1. Ampliar la busqueda en -1 y +1 día partiendo de la fecha de control.
-- 2. 





-- ========================================================================================================================================================================


--> ░ 2. Pais de procedencia o destino en `SIM.dbo.SimMovMigra`, distinto a Pais de procedencia o destino en `SIM.dbo.SimItinerario`.
-- ========================================================================================================================================================================

-- 2.1
SELECT

   [Id Persona] = pe.uIdPersona,
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
   [Pais Movimiento(SimItinerario)] = i.sIdPais
   
FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 ↔ A.I.J.CH.
   AND (mm.sIdPaisMov != 'NNN' AND i.sTipoMovimiento != 'NNN')
   AND mm.sIdPaisMov != i.sIdPais -- Distinto pais de Proc/Dest (SIM.dbo.SimMovMigra.sTipo != SIM.dbo.SimItinerario.sTipoMovimiento)

-- ========================================================================================================================================================================


--> ░ 3. Distintos ciudadanos peruanos, registran igual número de pasaporte electrónico en Control Migratorio.
-- ========================================================================================================================================================================

--3.1
DROP TABLE IF EXISTS #tmp_pas
SELECT
   p.*,
   t.uIdPersona
	INTO #tmp_pas
FROM SimPasaporte p
JOIN SimTramite t ON t.sNumeroTramite = p.sNumeroTramite
WHERE
   t.bCancelado = 0
	AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
	AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pas_sPasNumero_uIdPersona
   ON #tmp_pas(uIdPersona, sPasNumero)

-- 3.2
DROP TABLE IF EXISTS #tmp_mm_pase
SELECT
   mm.*
   INTO #tmp_mm_pase
FROM SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'PAS'
   AND ( -- PAS electrónico
            ISNUMERIC(mm.sNumeroDoc) = 1
            AND LEN(mm.sNumeroDoc) = 9
            AND mm.sNumeroDoc LIKE '1[1-2]%'
         )
   AND EXISTS ( -- Pasaporte válido
                  SELECT 1 
                  FROM #tmp_pas p
                  WHERE
                     p.sPasNumero = mm.sNumeroDoc
   )

-- 3.3 Final:
-- 3.3.1
DROP TABLE IF EXISTS #tmp_mm_pase_f
SELECT 
   f.*
   INTO #tmp_mm_pase_f
FROM (

   SELECT
      mm.*,
      [sNombre(SimPersona)] = pe.sNombre,
      [sPaterno(SimPersona)] = pe.sPaterno,
      [sMaterno(SimPersona)] = pe.sMaterno,
      [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl),
      [nTotalPase] = COUNT(1) OVER (PARTITION BY mm.sNumeroDoc)
   FROM #tmp_mm_pase mm
   JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   
) f
WHERE
   f.[#] = 1 -- Personas
   AND f.nTotalPase > 1 -- Total pase usados

-- 3.3.2
DROP TABLE IF EXISTS tmp_jun2024_h3
SELECT

   [Id Persona] = f1.uIdPersona,
   [Nombres] = f1.[sNombre(SimPersona)],
   [Apellido 1] = f1.[sPaterno(SimPersona)],
   [Apellido 2] = f1.[sMaterno(SimPersona)],
   [Sexo] = '',
   [Fecha de Nacimiento] = f1.[dFechaNacimiento(SimPersona)],
   [Nacionalidad ] = f1.sIdPaisNacionalidad,

   [Id Mov Migratorio] = f1.sIdMovMigratorio,
   [Fecha Control] = f1.dFechaControl,
   [Tipo Movimiento] = f1.sTipo,
   [Documento Viaje] = f1.sIdDocumento,
   [Número Documeno Viaje] = f1.sNumeroDoc

   INTO tmp_jun2024_h3

FROM #tmp_mm_pase_f f1
WHERE
   EXISTS (
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
ORDER BY f1.sNumeroDoc

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