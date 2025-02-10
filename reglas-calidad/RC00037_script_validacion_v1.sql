-- RC00037

-- 2. Se define como regla, que la fecha de nacimiento de los ciudadanos registrados en la base de datos SIM debe ser anterior a la fecha actual.
-- =========================================================================================================================================================

-- 2.1
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Login Operador Digita] = u.sLogin,
   [Nombre Operador Digita] = u.sNombre,
   [Id Módulo Digita] = m.sIdModulo,
   [Nombre Módulo Digita] = m.sNombre

FROM SimPersona pe
JOIN SimSesion s ON pe.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
JOIN SimModulo m ON s.sIdModulo = m.sIdModulo
WHERE 
   pe.bActivo = 1
   AND pe.dFechaNacimiento >= GETDATE()

-- =========================================================================================================================================================