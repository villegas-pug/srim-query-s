-- RC00001
-- Caso 1: Trámites con estado diferente a aprobado en pre-aprobación y con estado de trámite en `A` ...
-- Se establece como regla de calidad que los trámites CCM, CPP y RS109, cuyo estado sea diferente de APROBADO en la etapa de pre-aprobación, no deben tener un estado de trámite APROBADO.

SELECT

   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   [Id Persona] = t.uIdPersona,
   [Fecha Expendiente] = t.dFechaHora,
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Estado Trámite Actual] = (

                        CASE t.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END

                     ),
   [Estado Pre-aprobación] = (
                     CASE t.sEstadoPre 
                        WHEN 'A' THEN 'APROBADO'
                        WHEN 'B' THEN 'ABANDONADO'
                        WHEN 'D' THEN 'DENEGADO'
                        WHEN 'E' THEN 'DESISTIDO'
                        WHEN 'N' THEN 'NO PRESENTADO'
                        WHEN 'P' THEN 'PENDIENTE'
                     END
                  )

FROM (

   SELECT
      st.uIdPersona,
      st.nIdTipoTramite,
      st.dFechaHora,
      st.sNumeroTramite,
      sti.sEstadoActual,
      spti.sEstadoPre,
      [nFilaPre] = ROW_NUMBER() OVER (PARTITION BY spti.sNumeroTramite ORDER BY spti.dFechaPre DESC)
   FROM SimTramite st
   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
   JOIN SimPreTramiteInm spti ON st.sNumeroTramite = spti.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND spti.bActivo = 1
      AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sti.sEstadoActual = 'A'
      AND NOT EXISTS ( -- No registra RECONSIDERACION o APELACION.

         SELECT 
            TOP 1 1
         FROM SimEtapaTramiteInm seti
         WHERE
            seti.sNumeroTramite = st.sNumeroTramite 
            AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
            -- AND seti.sEstado = 'F'
            AND seti.bActivo = 1
            
      )

) t
JOIN SimPersona sper ON t.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON t.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   t.nFilaPre = 1
   AND t.sEstadoPre != 'A'