-- RC00022
-- 7. La última etapa registrada en el registro de etapas es diferente de la etapa actual asociada al trámite.
-- ======================================================================================================================================================================== */

-- 7.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
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
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre,

   --Aux
   [Id Etapa (SimTramiteInm)] = ti.nIdEtapaActual,
   [Id Etapa (SimEtapaTramiteInm)] = let.[nIdEtapa(Ult)],
   [Estado Etapa (SimEtapaTramiteInm)] = let.[sEstado(Ult)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]