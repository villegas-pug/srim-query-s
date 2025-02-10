-- RC00012
-- 2. Extranjeros con CE, registran direcciones incongruentes ...
-- ======================================================================================================================================================================== */

-- 2.1
-- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 58 ↔ CAMBIO DE CALIDAD MIGRATORIA
DROP TABLE IF EXISTS tmp_ce
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   ce.sNumeroCarnet,
   [Calidad Migratoria] = 'Residente',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  )
   INTO tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND ti.sEstadoActual IN ('A')
   AND t.nIdTipoTramite IN (58, 62) -- CE: 62 ↔ INSCR.REG.CENTRAL EXTRANJERÍA; 
                                    --     58 ↔ CAMBIO DE CALIDAD MIGRATORIA

-- 2.2
-- CPP; 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 113 ↔ REGULARIZACION DE EXTRANJEROS; 126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109
DROP TABLE IF EXISTS tmp_ptp
SELECT
   t.uIdPersona,
   ce.dFechaEmision,
   ce.sNumeroCarnet,
   [Calidad Migratoria] = 'CPP/PTP',
   [sEstadoCE] = (
                     CASE
                        WHEN ti.sEstadoActual = 'P' THEN 'En Proceso'
                        ELSE -- `A`
                           CASE
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) <= 0 THEN 'No vigente'
                              WHEN DATEDIFF(dd, GETDATE(), ce.dFechaCaducidad) > 0 THEN 'Vigente'
                           END
                     END

                  )
   INTO tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti On t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND ti.sEstadoActual IN ('A')
   AND t.nIdTipoTramite IN (92, 113, 126) -- CPP: 92 ↔ Permiso Temporal de Permanencia - Venezolanos; 
                                          --      113 ↔ REGULARIZACION DE EXTRANJEROS; 
                                          --      126 ↔ PERMISO TEMPORAL DE PERMANENCIA - RS109

-- 2.3: Final ...
SELECT
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [nÜmero Carnet] = e3.sNumeroCarnet,
   [Calidad Migratoria] = cm.sDescripcion,
   [sDireccion] = se.sDomicilio 
FROM (

   SELECT e2.*
   FROM (

      SELECT
         e.*,
         [nReciente] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC)
      FROM (
         SELECT * FROM tmp_ce
         UNION ALL
         SELECT * FROM tmp_ptp
      ) e

   ) e2
   WHERE e2.nReciente = 1

) e3
JOIN SimPersona p ON e3.uIdPersona = p.uIdPersona
JOIN SimExtranjero se ON p.uIdPersona = se.uIdPersona
JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad

-- ======================================================================================================================================================================== */