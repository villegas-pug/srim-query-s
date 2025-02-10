-- 
-- 5. Trámites de inmigración con estado de trámite `APROBADOS` en etapa `ASOCIACIÓN BENEFICIARIO` ...
-- ======================================================================================================================================================================== */

-- 5.1

SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ti.nIdEtapaActual = 12 -- 12 | ASOCIACION BENEFICIARIO
   AND (
            SELECT COUNT(1)
               FROM (
                  SELECT 
                     et.nIdEtapa,
                     [#] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite)
                  FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite
                     AND et.bActivo = 1

               ) et2
               WHERE
                  et2.[#] = 2
                  AND et2.nIdEtapa IN (11, 12) -- 12 | ASOCIACION BENEFICIARIO; 11 | RECEPCIÓN DINM
            ) = 2
   ORDER BY t.dFechaHora DESC