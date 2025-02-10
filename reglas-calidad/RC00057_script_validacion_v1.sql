-- RC00057

-- 6. Se define como regla, que un documento de identidad (DNI) debe ser utilizado por una sola persona.
-- =====================================================================================================================================================================

-- 6.1
SELECT 

   [Id Persona] = f.uIdPersona,
   [Nombres] = f.sNombre,
   [Apellido 1] = f.sPaterno,
   [Apellido 2] = f.sMaterno,
   [Sexo] = f.sSexo,
   [Fecha Nacimiento] = f.dFechaNacimiento,
   [Nacionalidad] = f.sIdPaisNacionalidad,

   -- Aux
   [Doc Identidad] = f.sIdDocIdentidad,
   [Num Doc Identidad] = f.sNumDocIdentidad

FROM (

   SELECT 
      pe.*,

      [nContarDupliNom] = COUNT(1) OVER (PARTITION BY pe.sNumDocIdentidad, SOUNDEX(pe.sNombre)),
      [nContarDupli1Ape] = COUNT(1) OVER (PARTITION BY pe.sNumDocIdentidad, SOUNDEX(pe.sPaterno)),
      [nContarDupli2Ape] = COUNT(1) OVER (PARTITION BY pe.sNumDocIdentidad, SOUNDEX(pe.sMaterno)),

      [nContarDupliDoc] = COUNT(1) OVER (PARTITION BY pe.sNumDocIdentidad)

   FROM SimPersona pe
   WHERE
      pe.bActivo = 1
      AND pe.sIdPaisNacionalidad = 'PER'
      AND pe.sIdDocIdentidad = 'DNI'
      AND REPLACE(pe.sNumDocIdentidad, ' ', '') NOT IN ('0000000', '00000000', '000000000', '0000000000')
      AND ISNUMERIC(pe.sNumDocIdentidad) = 1
      AND LEN(REPLACE(pe.sNumDocIdentidad, ' ', '')) = 8

) f
WHERE
   f.[nContarDupliDoc] >= 2 -- Documentos duplicados
   AND ( -- Personas distintas
      f.[nContarDupliNom] + f.[nContarDupli1Ape] + f.[nContarDupli2Ape]
   ) <= 3


-- =====================================================================================================================================================================
