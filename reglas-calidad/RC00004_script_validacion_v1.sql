
-- RC00004
-- Se establece como regla de calidad que los títulos de nacionalidad entregados deben registrar el estado de trámite Aprobado.
-- 4. Títulos de nacionalidad entregados con estado de trámite diferente a `A` ...
-- 4.1
SELECT
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Nacionalidad] = sper.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = stn.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Título Impreso] = IIF(
                           (
                              SELECT stin.bImpreso FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [Título Entregado] = IIF(
                           (
                              SELECT stin.bEntregado FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [sEstadoActual] = (
                        CASE stn.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     )
                  
FROM SimTramiteNac stn
JOIN SimTramite st ON stn.sNumeroTramite = st.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE 
   stn.sEstadoActual != 'A'
   AND EXISTS (

               SELECT 1 FROM SimTituloNacionalidad stin
               WHERE
                  stin.bAnulado = 0
                  AND stin.bImpreso = 1
                  AND stin.bEntregado = 1
                  AND stin.sNumeroTramite = stn.sNumeroTramite

            )