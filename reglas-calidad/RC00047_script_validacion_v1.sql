-- RC00047

-- 2. Se define como regla que, las dependencias de Puesto de Control Fronterizo, deben excluir el transporte marítimo  de sus registros de movimientos.
-- ==============================================================================================================================================================================

-- 2.1
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