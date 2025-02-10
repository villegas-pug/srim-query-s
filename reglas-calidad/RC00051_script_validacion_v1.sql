-- RC00051

-- 2. Se define como regla que, las dependencias de Puesto de Control Fronterizo, deben excluir el transporte aéreo de sus registros de movimientos.
-- =====================================================================================================================================================================

/*

   ░ Tipo Dependencia:
      → JEFATURA DE MIGRACIONES
      → PUESTO DE CONTROL FRONTERIZO
      → PUESTO DE CONTROL MIGRATORIO
      → SEDE ITINERANTE
      → SEDE ITINERANTE ACNUR                                                                                        */

DROP TABLE IF EXISTS #tmp_f
SELECT 
   f.* 
   INTO #tmp_f
FROM BD_SIRIM_DEV.dbo.RimRNJefaturaZonal f
WHERE f.sTipoDependencia = 'PUESTO DE CONTROL FRONTERIZO'

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
   [Via Transporte] = mm.sIdViaTransporte

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdViaTransporte = 'A'
   AND mm.sIdDependencia IN ( -- PUESTO DE CONTROL FRONTERIZO
                              SELECT f.sIdDependencia
                              FROM #tmp_f f
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- =====================================================================================================================================================================