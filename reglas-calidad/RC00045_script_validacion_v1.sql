-- RC00045

-- 5. Se define como regla de calidad que, los datos de la persona asociados al trámite en la base central de pasaportes deben ser iguales a los datos de la persona asociados al trámite en el Sistema Integral de Migraciones.
-- =====================================================================================================================================================================

-- 5.1 `tmp`

-- 5,208,097
DROP TABLE IF EXISTS #tmp_base_central
SELECT
   s.FECHA_RECEPCION,
   s.TRAMIT_ID,
   r.NOMBRE,
   r.APELLIDO_PATERNO,
   r.APELLIDO_MATERNO,
   r.FECHA_NACIMIENTO

   -- Aux
   -- [ID_PERSONA] = REPLACE(CONCAT(r.NOMBRE, r.APELLIDO_PATERNO, r.APELLIDO_MATERNO, FORMAT(r.FECHA_NACIMIENTO, 'yyyyMMdd')), ' ', '')

   INTO #tmp_base_central
FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
JOIN CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC r ON s.DATOS_RENIEC = r.ID

-- Index
CREATE NONCLUSTERED INDEX tmp_base_central
   ON #tmp_base_central(TRAMIT_ID)

-- 5.2
DROP TABLE IF EXISTS #tmp_base_central_j_simtramite
SELECT
   t.sNumeroTramite,
   t.uIdPersona,
   c.*
   INTO #tmp_base_central_j_simtramite
FROM SimTramite t
JOIN #tmp_base_central c ON t.sNumeroTramite = c.TRAMIT_ID

-- Index
CREATE NONCLUSTERED INDEX tmp_base_central_j_simtramite_uIdPersona
   ON #tmp_base_central_j_simtramite(uIdPersona)

CREATE NONCLUSTERED INDEX tmp_base_central_j_simtramite_datos
   ON #tmp_base_central_j_simtramite(APELLIDO_PATERNO, APELLIDO_MATERNO)

-- 5.3 Final
SELECT 
   [Id Persona] = c.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite(SIM)] = c.sNumeroTramite,
   [Número Trámite(Base Central)] = c.TRAMIT_ID,
   [Nombre (Base Central)] = c.NOMBRE,
   [Apellido 1 (Base Central)] = c.APELLIDO_PATERNO,
   [Apellido 2 (Base Central)] = c.APELLIDO_MATERNO,
   [Fecha Nacimiento (Base Central)] = c.FECHA_NACIMIENTO,
   [Año Emisión (Base Central)] = c.FECHA_RECEPCION

FROM #tmp_base_central_j_simtramite c
JOIN SimPersona p ON c.uIdPersona = p.uIdPersona
WHERE
   -- 1 Ape central
   DIFFERENCE(c.APELLIDO_PATERNO, p.sPaterno) <= 3
   AND DIFFERENCE(c.APELLIDO_PATERNO, p.sMaterno) <= 3

   -- 2 Ape central
   AND DIFFERENCE(c.APELLIDO_MATERNO, p.sMaterno) <= 3
   AND DIFFERENCE(c.APELLIDO_MATERNO, p.sPaterno) <= 3

   -- nombres
   AND DIFFERENCE(c.NOMBRE, p.sNombre) <= 3

-- =====================================================================================================================================================================