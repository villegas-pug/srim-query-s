-- RC00052

-- 1. Se define como regla, que el tipo de trámite para pasaportes electrónicos debe ser `Expedición de Pasaportes Electrónicos`,
--    para garantizar la correcta gestión de los documentos de viaje.
-- 1. Se define como regla de calidad, que el tipo de trámite para pasaporte electrónico debe ser Expedición de Pasaportes Electrónicos, para garantizar la correcta gestión de los documentos de viaje.
-- =====================================================================================================================================================================


-- 1.1
DROP TABLE IF EXISTS #tmp_pas
SELECT
   p.*
   INTO #tmp_pas
FROM SimPasaporte p
WHERE
   ISNUMERIC(p.sPasNumero) = 1
   AND LEN(p.sPasNumero) = 9
   AND p.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pas_sNumeroTramite 
   ON #tmp_pas(sNumeroTramite)

-- 1.2
SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Número Pasaporte] = p.sPasNumero,
   [Fecha Emisión] = p.dFechaEmision,
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion
   
FROM #tmp_pas p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE 
   t.nIdTipoTramite = 2 -- Pasaportes Mecanizados


-- =====================================================================================================================================================================
