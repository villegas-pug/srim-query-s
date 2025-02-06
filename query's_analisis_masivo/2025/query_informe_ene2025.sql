

-- 1. Se define como regla de calidad que los países sin límites marítimos no podrán realizar movimientos migratorios de entradas o salidas a través de via transporte marítimo.
-- =======================================================================================================================================================================================

-- 1.
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Tipo Movimiento] = sm.sTipo,
   [Fecha Control] = sm.dFechaControl,
   [Via Transporte] = sm.sIdViaTransporte,
   [Pais Movimiento] = sm.sIdPaisMov,
   [Dependencia] = sm.sIdDependencia

FROM SimMovMigra sm
JOIN SimPersona pe ON sm.uIdPersona = pe.uIdPersona
WHERE
      sm.[bAnulado] = 0 
      AND sm.[bTemporal] = 0
      AND sm.[sIdViaTransporte] = 'M' -- Via de transporte
      AND sm.[sIdPaisMov] IN ('BOL', 'PAR') -- Sin límites marítimos
      AND sm.[dFechaControl] >= '2010-01-01 00:00:00.000'

-- =======================================================================================================================================================================================


-- 2. Se define como regla de calidad que los países asociados al continente europeo no deberán registrar movimientos migratorios a través del transporte terrestre.
-- =======================================================================================================================================================================================

-- 2
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Tipo Movimiento] = mm.sTipo,
   [Fecha Control] = mm.dFechaControl,
   [Via Transporte] = mm.sIdViaTransporte,
   [Pais Movimiento] = mm.sIdPaisMov,
   [Dependencia] = mm.sIdDependencia

FROM SimMovMigra mm
JOIN SimPais ps on mm.sIdPaisMov = ps.sIdPais
JOIN SimPersona pe on  mm.uIdPersona = pe.uIdPersona
JOIN SimContinente con on ps.nIdContinente = con.nIdContinente
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND con.nIdContinente = 8
   AND mm.sIdViaTransporte = 'T'
   AND mm.[dFechaControl] >= '2016-01-01 00:00:00.000'

-- ======================================================================================================================================================================================= */


-- 3. Se define como regla de calidad que la fecha programada del itinerario debe ser coherente y no debe exceder significativamente la fecha actual.
-- =====================================================================================================================================================================

-- 2.1
/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

SELECT

   [Id Persona] = '',
   [Nombres] = '',
   [Apellido 1] = '',
   [Apellido 2] = '',
   [Sexo] = '',
   [Fecha Nacimiento] = '',
   [Nacionalidad] = '',

   -- Aux
   [Id Itinerario] = i.sIdItinerario,
   [Fecha Programada] = i.dFechaProgramada,
   [Estado] = CASE
                  WHEN i.sEstado = 'C' THEN 'Cerrado'
                  WHEN i.sEstado = 'A' THEN 'Programado'
              END,
   [Tipo Movimiento] = i.sTipoMovimiento,
   [Cantidad Movimiento] = i.nCantidadMov
   
FROM SIM.dbo.SimItinerario i 
WHERE
   i.sEstado IN ('A', 'C')
   AND i.dFechaProgramada > GETDATE()
   /* AND EXISTS ( -- Registros de control asociados
               SELECT TOP 1 1
               FROM SimMovMigra mm
               WHERE 
                  mm.bAnulado = 0
                  AND mm.bTemporal = 0
                  AND mm.sIdItinerario = i.sIdItinerario
   ) */


-- =====================================================================================================================================================================


-- 4. Se define como regla de calidad que los trámites que otorguen una calidad migratoria deben actualizar dicha calidad en los datos generales.
-- =====================================================================================================================================================================

-- 4.1. Calidad migratoria para: `Solicitud de Calidad Migratoria`.
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Número Trámite] = v.sNumeroTramite,
   [Fecha Inicio Vigencia] = v.dFechaAprobacion,
   [Fecha Fin Vigencia] = v.dFechaVencimiento,
   [Tipo Tiempo Otorgado] = v.sTipoTiempo,
   [Tiempo Otorgado] = v.nTiempo

FROM SimVisa v
JOIN SimTramite t ON v.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND 55 = ALL ( -- Únicamente `Solicitud de Visa`.
                  SELECT t2.nIdTipoTramite
                  FROM SimTramite t2
                  JOIN SimTramiteInm ti2 ON t2.sNumeroTramite = ti2.sNumeroTramite
                  WHERE
                     t2.bCancelado = 0
                     AND ti2.sEstadoActual = 'A'
                     AND t2.uIdPersona = t.uIdPersona
                  GROUP BY t2.nIdTipoTramite
   ) -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND v.dFechaVencimiento > GETDATE() -- Vigente
   AND ( -- Calidad actual distinta a solicitada
         SELECT pe.nIdCalidad 
         FROM SimPersona pe
         WHERE pe.uIdPersona = t.uIdPersona
   ) != v.nIdCalSolicitada

-- =====================================================================================================================================================================

-- 5. Se define como regla de calidad que al obtener un carnet nuevo(CE, CPP), los anteriores deben ser anulados.
-- =====================================================================================================================================================================

-- 5.1. CE
DROP TABLE IF EXISTS #tmp_ce
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   [dFechaVencRes] = COALESCE(ce.dFechaVencRes, ce.dFechaCaducidad),
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 1.2. CPP
DROP TABLE IF EXISTS #tmp_ptp
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   [dFechaVencRes] = COALESCE(ce.dFechaVenc, ce.dFechaCaducidad),
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 2.3: Final ...
-- 2.3.1 Filtar si ultimo CE esta vigente.
DROP TABLE IF EXISTS #tmp_ult_ce_vigente
SELECT v.* INTO #tmp_ult_ce_vigente
FROM (
   SELECT 
      ce.*,
      [bUltiCEVigente] = (
                              CASE
                                 WHEN ( -- CE vigente
                                          FIRST_VALUE(ce.dFechaVencRes) OVER (
                                                                                 PARTITION BY ce.uIdPersona 
                                                                                 ORDER BY ce.dFechaEmision DESC
                                                                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                              )
                                       ) > GETDATE()
                                 THEN 1
                                 ELSE 0
                              END
      )
   FROM (
         SELECT * FROM #tmp_ce
         UNION ALL
         SELECT * FROM #tmp_ptp
   ) ce
) v
WHERE
   v.[bUltiCEVigente] = 1


-- 2.3.1 Resumen:
DROP TABLE IF EXISTS #tmp_ce_final
SELECT
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Número Trámite] = f.sNumeroTramite,
   [Número Carnet] = f.sNumeroCarnet,
   [Fecha Inicio Vigencia] = f.dFechaEmision,
   [Fecha Fin Vigencia] = f.dFechaVencRes

   INTO #tmp_ce_final
FROM (

   SELECT
      e.*,
      [nOrdenCE(Desc)] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC), -- >=2, para `ANULAR`
      [nTotalCE] = COUNT(1) OVER (PARTITION BY e.uIdPersona),
      [nTotalCE(A)] = SUM(CAST(e.bAnulado AS INT)) OVER (PARTITION BY e.uIdPersona)
   FROM #tmp_ult_ce_vigente e

) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
WHERE
   f.[nTotalCE] > f.[nTotalCE(A)] -- Total CE debe estar por debajo de los anulados.
   AND f.[nTotalCE] != f.[nTotalCE(A)] + 1 -- Total anulados deben estar -2 por debajo del total CE.
   AND f.[nOrdenCE(Desc)] >= 2 -- Anteriores al ultimos CE emitido

-- Test
SELECT * FROM #tmp_ce_final
-- =====================================================================================================================================================================











-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      1. Se ha detectado trámites de carnet nuevos(CE, CPP), que no anularon al trámite de carnet anterior.
-- ======================================================================================================================================================================== */


-- 1. Detección:

-- 1.1. CE
DROP TABLE IF EXISTS #tmp_ce
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 1.2. CPP
DROP TABLE IF EXISTS #tmp_ptp
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 2.3: Final ...

-- 2.3.1 Resumen:
DROP TABLE IF EXISTS #tmp_ce_final
SELECT 

   f.*
   INTO #tmp_ce_final

FROM (

   SELECT 
      e.*,
      [nOrdenCE(Desc)] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC), -- >=2, para `ANULAR`
      [nTotalCE] = COUNT(1) OVER (PARTITION BY e.uIdPersona),
      [nTotalCE(A)] = SUM(CAST(e.bAnulado AS INT)) OVER (PARTITION BY e.uIdPersona)
   FROM (
      SELECT * FROM #tmp_ce
      UNION ALL
      SELECT * FROM #tmp_ptp
   ) e

) f
WHERE
   f.[nTotalCE] > f.[nTotalCE(A)] -- Total CE debe ser mayor a anulados
   AND f.[nTotalCE] != f.[nTotalCE(A)] + 1 -- Total CE igaul a total anulados o distintos


-- 3.4: Final
SELECT TOP 100 *
FROM #tmp_ce_final f
ORDER BY 
   -- f.dFechaEmision DESC
   f.uIdPersona
   -- f.[nOrdenCE(Desc)]


-- ======================================================================================================================================================================== */

SELECT * 
FROM SimDocPersona dp
WHERE dp.sNumero = '000577602'

SELECT * 
FROM SimPersona pe
WHERE 
   pe.uIdPersona = '89041468-1dc0-4444-8aaf-23ed29c7cce5'

SELECT TOP 10 * FROM [dbo].[SimCarnetExtranjeriaAntiguoHabilitadoWeb] ce
WHERE ce.sNumeroCarnet = '000577602'

EXEC sp_help SimCarnetExtranjeria

SELECT TOP 10 * FROM SimCarnetExtranjeria ce
WHERE
   ce.sNumeroCarnet = '000577602'

SELECT TOP 10 * FROM SimTramite
WHERE sNumeroTramite IN (
      'LM090125435',
   'SW190113901',
   'LM240352369'
)

SELECT TOP 10 * FROM SimTramiteInm
WHERE sNumeroTramite IN (
   'LM090125435',
   'SW190113901',
   'LM240352369'
)


SELECT TOP 10 * 
FROM SIM.dbo.SimInscripcionRCE r
WHERE 
   r.sNumeroTramite IN (
      'LM090125435',
      'SW190113901',
      'LM240352369'
   )

SELECT TOP 10 * 
FROM SIM.dbo.SimFichaInscripcion r
WHERE 
   r.sNumeroFicha = '000577602'
   
SELECT TOP 10 * 
FROM [dbo].[SimRegExtCampaniaRecojoCarnet]
   
SELECT
   t.*
FROM INFORMATION_SCHEMA.COLUMNS t 
WHERE 
   t.TABLE_CATALOG = 'SIM'
   AND t.COLUMN_NAME LIKE '%cod%veri%'

