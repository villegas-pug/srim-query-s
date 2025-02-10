-- RC00030

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