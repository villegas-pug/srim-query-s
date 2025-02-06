-- 1. Se define como regla que, la dependencia A.I.J.C.H. únicamente debe registrar transporte aéreo.
-- =====================================================================================================================================================================

-- 1.1 
SELECT 

   /* [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Via Transporte] = t.sDescripcion,
   [Dependencia] = d.sNombre */
   COUNT(1)

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimViaTransporte t ON mm.sIdViaTransporte = t.sIdViaTransporte
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = '27' -- 27 | A.I.J.CH.
   AND mm.sIdViaTransporte != 'A'  -- A | AEREO
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   AND mm.bMigrado = 0


-- =========================================================================================================================================================


-- 2. Se define como regla que, el país de origen del movimiento migratorio de entrada debe ser diferente a Perú.
-- =====================================================================================================================================================================

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
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Pais Movimiento] = mm.sIdPaisMov

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND mm.sIdPaisMov = 'PER'
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- 2.2 Script detección:
SELECT 
   mm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND mm.sIdPaisMov = 'PER'

-- =====================================================================================================================================================================

-- 3. Se define como regla que, el país de destino del movimiento migratorio de salida debe ser diferente a Perú.
-- =====================================================================================================================================================================

-- 3.1
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Pais Movimiento] = mm.sIdPaisMov

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'S'
   AND mm.sIdPaisMov = 'PER'
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- 3.2 Script detección.
SELECT 
   mm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'S'
   AND mm.sIdPaisMov = 'PER'

-- =====================================================================================================================================================================


-- 4. Se define como regla que, si el control migratorio está activo, el itinerario no debe estar cancelado.
-- =====================================================================================================================================================================

-- 4.1
/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Estado Movimiento] = IIF(mm.bAnulado = 0, 'Activo', 'Anulado'),
   [Estado Itinerario] = (
                              CASE
                                 WHEN (i.sEstado = 'X') THEN 'Cancelado'
                                 WHEN (i.sEstado = 'N') THEN 'Anulado'
                                 WHEN (i.sEstado = 'Z') THEN 'Cancelado Automático'
                              END
                        )
FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND i.sEstado IN ('X', 'N', 'Z')

-- 4.2 Script detección:
SELECT
   mm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND i.sEstado IN ('X', 'N', 'Z')

-- =====================================================================================================================================================================


-- 5. Se define como regla que, los datos de la persona asociados al trámite en la base central de pasaportes deben ser iguales a los datos de la persona asociados 
--    al trámite en el Sistema Integral de Migraciones (SIM).
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


-- Test:

SELECT * 
FROM SimPersona p
WHERE 
   p.sNombre LIKE 'Roxana%'
   AND p.sPaterno = 'Morales'
   AND p.sMaterno = 'Villegas'


SELECT * INTO SIM.dbo.RimRNJefaturaZonal FROM BD_SIRIM.dbo.RimRNJefaturaZonal
SELECT * FROM SIM.dbo.RimRNJefaturaZonal
-- =====================================================================================================================================================================

