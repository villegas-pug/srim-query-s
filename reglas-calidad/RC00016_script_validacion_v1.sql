-- RC00016
-- 5. Prefijo de número de trámite no corresponde a prefijo de trámite de dependencia.
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

   -- Aux
   [Número Tramite] = t.sNumeroTramite,
   [Fecha Trámite] = CAST(t.dFechaHora AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Dependencia] = d.sNombre,
   [Prefijo Trámite Dependencia] = d.sPrefijoTramite
   /* [Dependencia Número Trámite (Prefijo)] = (
                                                SELECT d2.sNombre 
                                                FROM SimDependencia d2 
                                                WHERE 
                                                   d2.bActivo = 1
                                                   AND d2.nIdTipoDependencia = 2 -- 2 | JEFATURA DE MIGRACIONES
                                                   AND d2.sPrefijoTramite = LEFT(LTRIM(t.sNumeroTramite), 2)
   ) */
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   -- AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ISNUMERIC(LEFT(LTRIM(t.sNumeroTramite), 2)) = 0 -- Prefijo únicamente letras
   AND (

      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND LEFT(LTRIM(t.sNumeroTramite), 2)  NOT IN (d.sPrefijoTramite, 'SW')

   )

-- ======================================================================================================================================================================== */