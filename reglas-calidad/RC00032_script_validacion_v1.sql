-- RC00032

--> ░ 2. Se define como regla, que los trámites de `Cambio de Clase de Visa` Aprobados, deben tener sus etapas `Finalizadas` ...
-- ========================================================================================================================================================================

SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
   [Fecha Trámite] = t.dFechaHora,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado] = ti.sEstadoActual

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.nIdTipoTramite = 55 -- 55 | SOLICITUD DE CALIDAD MIGRATORIA
   AND ti.sEstadoActual = 'A'
   AND EXISTS ( -- Registro de etapas únicas y en estado `I` ...

         SELECT 1
         FROM (

            SELECT
               e2.*,
               [nTotalReg(Fin)] = COUNT(1) OVER (PARTITION BY e2.sNumeroTramite) -- Total registros en sub-consulta final
            FROM (

               SELECT 
                  et.*,
                  [nTotalReg(Ini)] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite), -- Total registros en sub-consulta inicial
                  [nTotalEtapas(Ini)] = COUNT(1) OVER (PARTITION BY et.nIdEtapa)
               FROM SimEtapaTramiteInm et
               WHERE
                  et.sNumeroTramite = t.sNumeroTramite 
                  AND et.bActivo = 1

            ) e2
            WHERE
               e2.[nTotalEtapas(Ini)] = 1 -- etapas únicas

         ) e3
         WHERE
            e3.[nTotalReg(Ini)] = e3.[nTotalReg(Fin)]
            AND e3.sEstado = 'I'

   )

-- ========================================================================================================================================================================