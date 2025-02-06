-- 1. Se define como regla que, todos los vuelos registrados en el A.I.J.C.H., deben tener un itinerario asociado y registrado en el sistema.
-- ================================================================================================================================================

-- 1.1 
SELECT
   TOP 10
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
   [Dependencia] = d.sNombre,
   [Pais Origen/Destino] = mm.sIdPaisMov,
   [Id Itinerario] = mm.sIdItinerario,
   [Via Transporte] = mm.sIdViaTransporte

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia IN (
                              '27', -- 27 | A.I.J.CH.
                              '24'  -- 24 | A.I.J.CH. DIA
                           )
   -- AND mm.sIdViaTransporte = 'A' -- A | AEREO
   AND mm.dFechaControl >= '2019-01-01 00:00:00.000'
   AND mm.sIdItinerario IS NULL
ORDER BY mm.dFechaControl DESC

-- =========================================================================================================================================================

-- 2. Se define como regla que, las dependencias de Puesto de Control Fronterizo, deben excluir el transporte marítimo  de sus registros de movimientos.
-- ==============================================================================================================================================================================

-- 2.1 `tmp`
SELECT * INTO #tmp_pcf
FROM BD_SIRIM_DEV.dbo.RimRNJefaturaZonal j
WHERE j.sTipoDependencia = 'PUESTO DE CONTROL FRONTERIZO'


-- 2.2
/*
   sIdViaTransporte | nTotal
   TERRESTRE   → T : 11,158,348
   FLUVIAL     → F :	379,577
   AEREO       → A :	3,216
   MARITIMO    → M :	649
   LACUSTREL   → L :	11                                  */

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
   [Dependencia] = d.sNombre,
   [Via Transporte] = vt.sDescripcion

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SIM.dbo.SimViaTransporte vt ON mm.sIdViaTransporte = vt.sIdViaTransporte
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia IN ( -- PCF
                                 SELECT f.sIdDependencia
                                 FROM #tmp_pcf f
   )
   -- AND mm.sIdViaTransporte NOT IN ('T', 'F', 'L')
   AND mm.sIdViaTransporte = 'M'
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'
   

-- =====================================================================================================================================================================


-- 3. Se define como regla que, los registros de control migratorio deben registrar explícitamente una dependencia.
-- =====================================================================================================================================================================


-- 3.1 Modulo digita NULL
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
   [Dependencia] = d.sNombre

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia = 'NNN'

-- =====================================================================================================================================================================


/* 
   4. Se define como regla que, solo los vuelos internacionales deben registrar un itinerario completo, 
      que incluya información sobre la ruta de vuelo, pasajeros, carga y tripulación.
-- ===================================================================================================================================================================== */


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
   [Dependencia] = d.sNombre,
   [Id Itinerario] = mm.sIdItinerario,
   [Fecha Programada] = i.dFechaProgramada,
   [Número Nave] = i.sNumeroNave,
   [Cantidad Pasajeros] = i.nCantidadMov,
   [Aerolinea] = et.sNombreRazon

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
JOIN SIM.dbo.SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdViaTransporte = 'A' -- A | AEREO
   -- AND mm.sIdItinerario IS NOT NULL
   AND mm.sIdDependencia NOT IN ( -- Dependencias para vuelos internaciones
                                    '27', -- 27 | A.I.J.CH.
                                    '24'  -- 24 | A.I.J.CH. DIA
   )
   

-- =====================================================================================================================================================================

-- 5. Se define como regla que, las dependencias de puertos deben excluir el transporte aéreo de sus registros de movimientos.
-- =====================================================================================================================================================================


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
   [Dependencia] = d.sNombre,
   [Id Itinerario] = mm.sIdItinerario,
   [Fecha Programada] = i.dFechaProgramada,
   [Número Nave] = i.sNumeroNave,
   [Cantidad Pasajeros] = i.nCantidadMov,
   [Aerolinea] = et.sNombreRazon

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
JOIN SIM.dbo.SimEmpTransporte et ON mm.nIdTransportista = et.nIdTransportista
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdViaTransporte = 'A' -- A | AEREO
   -- AND mm.sIdItinerario IS NOT NULL
   AND mm.sIdDependencia IN ( -- Dependencias para vuelos internaciones
                                 '27', -- 27 | A.I.J.CH.
                                 '24'  -- 24 | A.I.J.CH. DIA
   )
   

-- =====================================================================================================================================================================



--  EGATES <> `PER`
SELECT
   mm.sIdPaisNacionalidad,
   COUNT(1)
FROM SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sIdDependencia = '27' -- A.I.J.C.H
   AND mm.sIdModuloDigita = 'EGATES'
GROUP BY
   mm.sIdPaisNacionalidad

   
--  EGATES <> `AIJCH`
SELECT
   mm.sIdDependencia,
   COUNT(1)
FROM SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sIdDependencia = '27' -- A.I.J.C.H
   AND mm.sIdModuloDigita = 'EGATES'
GROUP BY
   mm.sIdDependencia

-- Fecha programada de itinerario inconsistente.








-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      1. Se ha detectado que algunos movimientos de peruanos no siguen un patrón secuencial en el tipo de movimiento. 
         Esto podría estar relacionado con un itinerario incorrecto, ya que al realizar una búsqueda adicional con: 
         La fecha de control, número de nave y aerolínea, se encontró un itinerario alternativo que registra el tipo de movimiento correcto.

      Regla de Calidad de Datos:

         Se define como regla que, los registros de control migratorio de ciudadanos peruanos deben seguir un patrón secuencial en el tipo de movimiento, para garantizar la exactitud y coherencia de la información.

         Se ha detectado que algunos movimientos de peruanos no siguen un patrón secuencial en el tipo de movimiento. 
         Esto podría estar relacionado con un itinerario incorrecto, ya que al realizar una búsqueda adicional con: 
         La fecha de control, número de nave y aerolínea, se encontró un itinerario alternativo que registra el tipo de movimiento correcto.

         Se ha detectado que algunos movimientos de peruanos no siguen un patrón secuencial en el tipo de movimiento. 
         Tipos de movimienots migratorios registros en las Egates son distintos al tipo de movimiento registrado en el Itinerario asociado.
         Discrepancia en los tipos de movimientos migratorios registrados en los Egates respecto a los consignados en el itinerario asociado
*/


/*

   1. Identifica los tipos de movimiento distintos registrados tanto en EGATES como en el ITINERARIO.
   2. Identifica los registros de control migratorio anteriores y posteriores que tengan una secuencia lógica en el tipo de movimiento.
   3. Identifica el itinerario que coincida con la fecha programada, el número de nave, el transportista y la dependencia. Además, el tipo de movimiento debe ser diferente al actual.

*/


-- 1.1 Identifica registros de control migratorio `EGATES`.
DROP TABLE IF EXISTS #tmp_egates
SELECT mm.* INTO #tmp_egates
FROM SimMovMigra mm
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdModuloDigita = 'EGATES'

CREATE NONCLUSTERED INDEX ix_tmp_egates
   ON #tmp_egates(sIdItinerario)

-- 1.2 Identificar 2 itinerarios registrados con la igual dFechaProgramada, sNumeroNave, nIdTransportista, sIdDependenciam, ademas el tipo debe ser distinto.
DROP TABLE IF EXISTS #tmp_itinerario
SELECT f.* INTO #tmp_itinerario
FROM (
   SELECT
      i2.*,
      [#] = COUNT(1) OVER (PARTITION BY i2.sIdItinerarioAux), -- Contar `IdAux`
      [##] = COUNT(i2.sTipoMovimiento) OVER (PARTITION BY i2.sIdItinerarioAux, i2.sTipoMovimiento) -- Contar `Tipo Mov`
   FROM (
      SELECT
         i.*,
         [sIdItinerarioAux] = REPLACE(CONCAT(FORMAT([i].[dFechaProgramada], 'yyyyMMdd'), [i].[sNumeroNave], [i].[nIdTransportista], [i].[sIdDependencia]), ' ', '')
      FROM SimItinerario i
   ) i2
) f
WHERE 
   f.[#] = 2
   AND f.[##] = 1

CREATE NONCLUSTERED INDEX ix_tmp_itinerario
   ON #tmp_itinerario(sIdItinerario)

-- 1.3 Identifica patrones de diferencia en el tipo de movimiento registrado en EGATES y en el Itinerario.
DROP TABLE IF EXISTS #tmp_egates_tmm_dif_tmm_itin
SELECT

   -- Control
   [mm].[sIdMovMigratorio],
   [mm].[dFechaControl],
   [mm].[sTipo],
   [mm].[sIdItinerario],
   [mm].[sIdPaisNacionalidad],
   [mm].[uIdPersona],
   [mm].[sIdDependencia],
   [mm].[sIdModuloDigita],
   [mm].[sIdPaisMov],

   -- Itinerario
   i.sIdItinerarioAux

   INTO #tmp_egates_tmm_dif_tmm_itin

FROM #tmp_egates mm
JOIN #tmp_itinerario i ON mm.sIdItinerario = i.sIdItinerario
WHERE 
   mm.sTipo != i.sTipoMovimiento -- Tipo EGATES distinto a tipo itinerario.

CREATE NONCLUSTERED INDEX ix_tmp_egates_tmm_dif_tmm_itin
   ON #tmp_egates_tmm_dif_tmm_itin(uIdPersona)


-- 1.4 ...

-- 1.4.1
DROP TABLE IF EXISTS #tmp_egates_tmm_dif_tmm_itin_with_isseq
SELECT f.* INTO #tmp_egates_tmm_dif_tmm_itin_with_isseq
FROM (

   SELECT 
      e.*,
      [bIsSequential] = (
                           SELECT mm3.[bIsSequential] 
                           FROM (
                              SELECT 
                                 mm2.*,
                                 [bIsSequential] = (
                                       CASE
                                          WHEN (LAG(mm2.sIdMovMigratorio) OVER (ORDER BY mm2.dFechaControl ASC) IS NULL) THEN ( -- Primer movimiento
                                             CASE
                                                WHEN LEAD(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) = mm2.sTipo THEN 0
                                                ELSE 1
                                             END
                                          )
                                          WHEN (LEAD(mm2.sIdMovMigratorio) OVER (ORDER BY mm2.dFechaControl ASC) IS NULL) THEN (-- Ultimo movimiento
                                             CASE
                                                WHEN LAG(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) = mm2.sTipo THEN 0
                                                ELSE 1
                                             END
                                          )
                                          ELSE ( --  != Primero y ultimo
                                             CASE
                                                WHEN ( -- Si existe secuencia anterior o posterior.
                                                   (
                                                      LAG(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) = mm2.sTipo -- Anterior
                                                   )
                                                   OR
                                                   (
                                                      LEAD(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) = mm2.sTipo -- Siguiente
                                                   )
                                                ) THEN 0
                                                WHEN ( -- Si existe secuencia anterior y posterior.
                                                   (
                                                      LAG(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) != mm2.sTipo -- Anterior
                                                   )
                                                   AND
                                                   (
                                                      LEAD(mm2.sTipo) OVER (ORDER BY mm2.dFechaControl ASC) != mm2.sTipo -- Siguiente
                                                   )
                                                ) THEN 1
                                             END
                                          )
                                       END
                              )
                              FROM (
                                 SELECT mm.sIdMovMigratorio, mm.uIdPersona, mm.sTipo, mm.dFechaControl
                                 FROM SIM.dbo.SimMovMigra mm
                                 WHERE
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = e.uIdPersona
                              ) mm2
                           ) mm3
                           WHERE 
                              mm3.sIdMovMigratorio = e.sIdMovMigratorio
      )
   FROM #tmp_egates_tmm_dif_tmm_itin e
) f
WHERE f.bIsSequential = 1 -- Secuenciales

-- 1.4.2
DROP TABLE IF EXISTS #tmp_egates_isseq_join_itiner
SELECT 
   s.sIdMovMigratorio,
   i.sIdItinerario,
   [sIdPaisMov] = i.sIdPais
   INTO #tmp_egates_isseq_join_itiner
FROM #tmp_egates_tmm_dif_tmm_itin_with_isseq s
JOIN #tmp_itinerario i ON s.sIdItinerarioAux = i.sIdItinerarioAux
                       AND s.sTipo = i.sTipoMovimiento

CREATE NONCLUSTERED INDEX ix_tmp_egates_isseq_join_itiner 
   ON #tmp_egates_isseq_join_itiner(sIdMovMigratorio)

-- 1.5 Final
BEGIN TRY
   
BEGIN TRAN

UPDATE mm
   SET sIdItinerario = i.sIdItinerario,
       sIdPaisMov = i.sIdPaisMov
FROM SimMovMigra mm
JOIN #tmp_egates_isseq_join_itiner i ON mm.sIdMovMigratorio = i.sIdMovMigratorio

-- COMMIT TRAN
ROLLBACK TRAN

END TRY
BEGIN CATCH

   ROLLBACK TRAN
   SELECT
      -- [PROCEDURE] = ERROR_PROCEDURE(),
      [LINE] = ERROR_LINE(),
      [MESSAGE] = ERROR_MESSAGE()

END CATCH



-- =========================================================================================================================================================




/*

SELECT dblink_connect('conexion_origen', 'host=172.27.0.242 dbname=SIM user=udesa password=DESARROLLO2006');

-- Crear la tabla en la base de datos destino (si aún no existe)
SELECT * FROM dblink('conexion_origen', 'SELECT * FROM SimPais')

-- Desconectar
SELECT dblink_disconnect('conexion_origen');

EXEC sp_addlinkedserver 
    @server = 'SIM', 
    @srvproduct = '',
    @provider = 'SQLNCLI', 
    @datasrc = '172.27.0.124'

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'SIM22', 
    @useself = 'FALSE', 
    @rmtuser = 'userestadistica', 
    @rmtpassword = '$Us3R_3sT4d1sTic4$';
    
*/