
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

-- 2. Se define como regla, que cada persona debe registrar únicamente una nacionalidad en sus movimientos migratorios.
-- =====================================================================================================================================================================
-- 2.1
;WITH cte_mm_dif_nac
AS  (
   SELECT f.*
   FROM (
      SELECT

         mm.uIdPersona,
         mm.sIdDocumento,
         mm.sNumeroDoc,
         mm.sNombres,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC),
         [nContarMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona),
         [nContarNacionalidadMM] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sIdPaisNacionalidad)

      FROM SimMovMigra mm
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         -- AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
         AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   ) f
   WHERE
      f.[#] = 1
      AND f.[nContarNacionalidadMM] < f.[nContarMM]

) 
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Cantidad Nacionalidades] = (
                                 SELECT COUNT(DISTINCT(mm.sIdPaisNacionalidad))
                                 FROM SimMovMigra mm
                                 WHERE mm.uIdPersona = d.uIdPersona
   ),
   [Nacionalidades] = (
                        SELECT DISTINCT mm.sIdPaisNacionalidad
                        FROM SimMovMigra mm
                        WHERE mm.uIdPersona = d.uIdPersona
                        FOR XML PATH('')
   )
FROM cte_mm_dif_nac d
JOIN SimPersona pe ON d.uIdPersona = pe.uIdPersona


-- =====================================================================================================================================================================

-- 3. Se define como regla que cada ciudadano debe tener un único registro de control migratorio en una sola dependencia.
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
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Dependencia] = d.sNombre
   
FROM (
   SELECT
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdDependencia,

      -- Aux
      [uid-yyyyMMd-HH-Tip] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo),
      [uid-yyyyMMd-HH-Tip-dep] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo, mm.sIdDependencia)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
) f
JOIN SImPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON f.sIdDependencia = d.sIdDependencia
WHERE
   f.[uid-yyyyMMd-HH-Tip] >= 2 -- Duplicados
   AND [uid-yyyyMMd-HH-Tip-dep] = 1 -- Dependencias distintas

-- =====================================================================================================================================================================


-- 4. Se define como regla que cada ciudadano debe tener un único registro de control migratorio en una solo módulo.
-- =====================================================================================================================================================================

-- 4.1
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Módulo Digita] = f.sIdModuloDigita
   
FROM (
   SELECT
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdModuloDigita,

      -- Aux
      [uid-yyyyMMd-HH-Tip] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo),
      [uid-yyyyMMd-HH-Tip-mod] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo, mm.sIdModuloDigita)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
) f
JOIN SImPersona pe ON f.uIdPersona = pe.uIdPersona
WHERE
   f.[uid-yyyyMMd-HH-Tip] >= 2 -- Duplicados
   AND [uid-yyyyMMd-HH-Tip-mod] = 1 -- Módulos distintos


-- =====================================================================================================================================================================




-- 5. Se define como regla, que cada ciudadano debe tener un único registro de control migratorio asociado a una sola vía de transporte.
-- =====================================================================================================================================================================

-- 5.1
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Via Transporte] = t.sDescripcion
   
FROM (
   SELECT
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdViaTransporte,

      -- Aux
      [uid-yyyyMMd-HH-Tip] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo),
      [uid-yyyyMMd-HH-Tip-via] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo, mm.sIdViaTransporte)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimViaTransporte t ON f.sIdViaTransporte = t.sIdViaTransporte
WHERE
   f.[uid-yyyyMMd-HH-Tip] >= 2 -- Duplicados
   AND [uid-yyyyMMd-HH-Tip-via] = 1 -- Transportistas distintos


-- =====================================================================================================================================================================


-- 6. Se define como regla, que un documento de identidad (DNI) debe ser utilizado por una sola persona.
-- 6. Se define como regla, que el uso del DNI como documento de viaje para ciudadanos peruanos en el control migratorio debe ser estrictamente personal.
-- =====================================================================================================================================================================

-- v1
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

-- v2

-- 1.1
DROP TABLE IF EXISTS #tmp_mm_dni
SELECT
   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.dFechaControl,
   mm.sTipo,
   mm.sIdDocumento,
   mm.sNumeroDoc,
   [sNombre(SimPersona)] = pe.sNombre,
   [sPaterno(SimPersona)] = pe.sPaterno,
   [sMaterno(SimPersona)] = pe.sMaterno,
   [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento

   INTO #tmp_mm_dni
FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'DNI'
   AND ( -- DNI
         ISNUMERIC(mm.sNumeroDoc) = 1
         AND LEN(mm.sNumeroDoc) = 8
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

CREATE NONCLUSTERED INDEX ix_tmp_mm_pase ON #tmp_mm_dni(uIdPersona, sNumeroDoc, dFechaControl)

-- 1.2 Final:
-- 1.2.1
DROP TABLE IF EXISTS #tmp_mm_dni_f
SELECT f2.* INTO #tmp_mm_dni_f
FROM (
   SELECT
      f.*,
      [nTotalDNI] = COUNT(1) OVER (PARTITION BY f.sNumeroDoc)
   FROM (

      SELECT
         mm.*,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl)
      FROM #tmp_mm_dni mm
   ) f
   WHERE
      f.[#] = 1 -- Personas
) f2
WHERE
   f2.nTotalDNI > 1 -- Total DNI usados

CREATE NONCLUSTERED INDEX ix_#tmp_mm_dni_f
   ON #tmp_mm_dni_f(uIdPersona, sNumeroDoc, [sNombre(SimPersona)], [sPaterno(SimPersona)], [sMaterno(SimPersona)])

-- 1.2.1
SELECT
   f1.*
FROM #tmp_mm_dni_f f1
WHERE
   EXISTS (
            SELECT TOP 1 1
            FROM #tmp_mm_dni_f f2
            WHERE
               f1.uIdPersona != f2.uIdPersona -- Personas distintas ...
               AND f1.sNumeroDoc = f2.sNumeroDoc -- `DNI` iguales ...
               AND (
                     DIFFERENCE(f1.[sNombre(SimPersona)], f2.[sNombre(SimPersona)]) <= 3
                     AND DIFFERENCE(f1.[sPaterno(SimPersona)], f2.[sPaterno(SimPersona)]) <= 2
                     AND DIFFERENCE(f1.[sMaterno(SimPersona)], f2.[sMaterno(SimPersona)]) <= 2
               )
   )

-- =====================================================================================================================================================================


-- 7. Se define como regla, que un operador no debe realizar el registro de control migratorio en más de una dependencia en la misma fecha, hora y minuto.
-- =====================================================================================================================================================================

-- 7.1
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Dependencia] = d.sNombre,
   [Operador Digita] = u.sLogin
   
FROM (

   SELECT

      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.nIdOperadorDigita,
      mm.sIdDependencia,

      -- Aux
      [nIdOpe-yyyyMMddHHmm] = COUNT(1) OVER (PARTITION BY 
                                                   mm.nIdOperadorDigita, 
                                                   -- FORMAT(mm.dFechaControl, 'yyyyMMddHHmm')
                                                   DATEADD(MINUTE, DATEDIFF(MINUTE, 0, mm.dFechaControl), 0)
                                             ),
      [nIdOpe-yyyyMMddHHmm-dep] = COUNT(1) OVER (PARTITION BY 
                                                      mm.nIdOperadorDigita, 
                                                      -- FORMAT(mm.dFechaControl, 'yyyyMMddHHmm'), 
                                                      DATEADD(MINUTE, DATEDIFF(MINUTE, 0, mm.dFechaControl), 0),
                                                      mm.sIdDependencia
                                                )

   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'

) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON f.sIdDependencia = d.sIdDependencia
JOIN SimUsuario u ON f.nIdOperadorDigita = u.nIdOperador
WHERE
   f.[nIdOpe-yyyyMMddHHmm] = 2 -- Duplicados por operador
   AND f.[nIdOpe-yyyyMMddHHmm-dep] = 1 -- Dependencias distintas

-- =====================================================================================================================================================================


-- 8. Se define como regla, que todos los itinerarios en estado cerrado o programado deben tener al menos un pasajero.
-- =====================================================================================================================================================================

SELECT TOP 10 * FROM SimMovMigra mm
ORDER BY mm.dFechaControl DESC

/*
   X  : Cancelado
   N  : Anulado
   Z  : Cancelado Automático

   Activos:
   C  : Cerrado
   A  : Programado
*/

-- 8.1
SELECT

   [Id Itinerario] = i.sIdItinerario,
   [Fecha Control] = i.dFechaProgramada,
   [Número Nave] = i.sNumeroNave,
   [Empresa Transporte] = e.sNombreRazon,
   [Tipo Movimiento] = i.sTipoMovimiento,
   [Estado Itinerario] = (
                              CASE
                                 WHEN (i.sEstado = 'X') THEN 'Cancelado'
                                 WHEN (i.sEstado = 'N') THEN 'Anulado'
                                 WHEN (i.sEstado = 'Z') THEN 'Cancelado Automático'
                                 WHEN (i.sEstado = 'C') THEN 'Cerrado'
                                 WHEN (i.sEstado = 'A') THEN 'Programado'
                              END
                        ),
   [Cantidad Mov] = i.nCantidadMov

FROM SimItinerario i
JOIN SimEmpTransporte e ON i.nIdTransportista = e.nIdTransportista
WHERE
   i.sEstado IN ('C', 'A')
   AND i.dFechaProgramada >= '2016-01-01 00:00:00.000'
   AND i.nCantidadMov = 0


-- =====================================================================================================================================================================

-- 9. Se define como regla, que cada ciudadano debe tener un único registro de control migratorio asociado a una sola Aerolinea.
-- =====================================================================================================================================================================

-- 9.1
SELECT
   
   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = f.sIdMovMigratorio,
   [Fecha Control] = f.dFechaControl,
   [Tipo Movimiento] = f.sTipo,
   [Via Transporte] = t.sDescripcion
   
FROM (
   SELECT
      mm.uIdPersona,
      mm.sIdMovMigratorio,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdViaTransporte,

      -- Aux
      [uid-yyyyMMd-HH-Tip] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo),
      [uid-yyyyMMd-HH-Tip-Tran] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, CAST(mm.dFechaControl AS DATE), DATEPART(HH, mm.dFechaControl), mm.sTipo, mm.sIdTransportista)
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
) f
JOIN SimPersona pe ON f.uIdPersona = pe.uIdPersona
JOIN SimViaTransporte t ON f.sIdViaTransporte = t.sIdViaTransporte
WHERE
   f.[uid-yyyyMMd-HH-Tip] >= 2 -- Duplicados
   AND [uid-yyyyMMd-HH-Tip-Tran] = 1 -- Transportistas distintos


-- =====================================================================================================================================================================




















-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      - Se ha detectado una inconsistencia en el tipo de trámite asociado a los Pasaportes Electrónicos, ya que algunos están registrados con un tipo de trámite incorrecto. 
-- ======================================================================================================================================================================== */

-- 1. Detección:

-- 1.1
DROP TABLE IF EXISTS #tmp_pase
SELECT
   p.sPasNumero,
   p.sNumeroTramite
   INTO #tmp_pase
FROM SimPasaporte p
WHERE
   ISNUMERIC(p.sPasNumero) = 1
   AND LEN(p.sPasNumero) = 9
   AND p.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pas_sNumeroTramite 
   ON #tmp_pas(sNumeroTramite)

-- 1.2
DROP TABLE IF EXISTS #tmp_pase_mec
SELECT
   *
   INTO #tmp_pase_mec
FROM #tmp_pas p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
WHERE 
   t.nIdTipoTramite = 2 -- Pasaportes Mecanizados

-- 1.2
DROP TABLE IF EXISTS #tmp_pase_mec_valida_central
SELECT
   *
   INTO #tmp_pase_mec_valida_central
FROM #tmp_pase_mec p
WHERE 
   EXISTS(
            SELECT 1
            FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
            WHERE
               s.NUMERO_DOC = p.sPasNumero
   )

-- 2. Actualización:
BEGIN TRY

   BEGIN TRAN

   UPDATE simTramite
      SET nIdTipoTramite = 90
   FROM SimTramite t
   JOIN #tmp_pase_mec_valida_central m ON t.sNumeroTramite = m.sNumeroTramite

   COMMIT TRAN

END TRY
BEGIN CATCH
   ROLLBACK TRAN
END CATCH

-- ======================================================================================================================================================================== */




-- Test
SELECT TOP 10 * FROM SimEtapaTramiteInm

SELECT TOP 10 * FROM SimEtapa e
WHERE e.nIdEtapa IN (63, 80) 

-- ======================================================================================================================================================================== */


-- ...

SELECT 
   f.*
FROM (

   SELECT 
      mm.*,
      [uid-yyyyMMdd-HH-Tip] = COUNT(1) OVER (
                                                PARTITION BY 
                                                   mm.uIdPersona, 
                                                   CAST(mm.dFechaControl AS DATE), 
                                                   DATEPART(HH, mm.dFechaControl),
                                                   mm.sTipo  
                                             )

   FROM SimMovMIgra mm
   WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
         AND mm.dFechaControl >= '2016-01-01 00:00:00.000'

) f
WHERE
   f.[uid-yyyyMMdd-HH-Tip] >= 2

EXEC sp_help Sim

SELECT TOP 10 * 
FROM SimEtapaSolicitudCUE

SELECT 
   TOP 500 *
FROM SimMovMIgra mm
/* WHERE 
   mm.dFechaControl BETWEEN '2025-02-05 00:00:00.000' AND '2025-02-05 23:59:59.998' */
ORDER BY mm.dFechaControl DESC