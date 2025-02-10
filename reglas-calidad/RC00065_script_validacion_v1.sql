-- RC00065

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
   
-- =====================================================================================================================================================================