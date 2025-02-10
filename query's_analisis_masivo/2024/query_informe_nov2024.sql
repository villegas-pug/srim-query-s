
-- 1. Se define como regla que, la dependencia de Lima no debe tener registros de Control Migratorio.
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
   [Via Transporte] = mm.sIdViaTransporte

FROM SIM.dbo.SimMovMigra mm
JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDependencia IN ('25') -- Lima
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

-- =====================================================================================================================================================================

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

-- 3. Pasaportes electrónicos entregados en otras dependencias
-- ==============================================================================================================================================================================

-- SimMovMigra
SELECT
   p.sIdDependencia,
   d.sNombre,
   COUNT(1)
FROM SimPasaporte p
JOIN SimDependencia d ON p.sIdDependencia = d.sIdDependencia
WHERE 
	p.sEstadoActual IN ('E', 'R') -- Entregado | Revalidado
	AND LEN(p.sPasNumero) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'
GROUP BY
   p.sIdDependencia,
   d.sNombre
ORDER BY 3 DESC

-- SimTramite
SELECT
   p.sIdDependencia,
   d.sNombre,
   COUNT(1)
FROM SimTramite p
JOIN SimDependencia d ON p.sIdDependencia = d.sIdDependencia
WHERE 
	p.bCancelado = 0
   AND p.bCulminado = 1
   AND p.nIdTipoTramite IN (
                              SELECT tt.nIdTipoTramite 
                              FROM SimTipoTramite tt
                              WHERE
                                 tt.sDescripcion LIKE '%nacion%'
   )
GROUP BY
   p.sIdDependencia,
   d.sNombre
ORDER BY 3 DESC

SELECT tt.sDescripcion, t.dFechaHora, t.bCulminado
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.sIdDependencia = '112'
   AND t.nIdTipoTramite IN (
                           SELECT tt.nIdTipoTramite
                           FROM SimTipoTramite tt
                           WHERE
                              tt.sDescripcion LIKE '%nacion%'
   )



SELECT 
   mm.sIdDependencia,
   d.sNombre,
   COUNT(1) 
FROM SimMovMigra mm
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE
   mm.sIdViaTransporte = 'A'
GROUP BY
   mm.sIdDependencia,
   d.sNombre
ORDER BY 3 DESC


SELECT * FROM SimDependencia

-- =====================================================================================================================================================================


-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      1. Se ha detectado que existen trámites de inmigración como: PRR, CCM, CPP y PTP con etapa actual registrada en `SIM.dbo.SimTramiteInm`, distinta a ultima etapa 
         registrada en `SIM.dbo.SimEtapaTramiteInm`. 
-- ======================================================================================================================================================================== */

-- 1. Detección:
DROP TABLE IF EXISTS #tmp_tram
SELECT
   
   t.sNumeroTramite,
   [sTipoTramite] = tt.sDescripcion,
   [dFechaTramite] = t.dFechaHora,
   [sEstadoTramite] = (
                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),

   --Aux
   [nIdEtapaActual(SimTramiteInm)] = ti.nIdEtapaActual,
   [nIdEtapaUlt(SimEtapaTramiteInm)] = let.[nIdEtapa(Ult)]

   INTO #tmp_tram

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN (

   SELECT 
      f.*
   FROM (

      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
         AND eti.sEstado = 'F'
         
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]

-- 2. Actualización:
BEGIN TRY
   BEGIN TRAN

   UPDATE SimtramiteInm
      SET nIdEtapaActual = e.[nIdEtapaUlt(SimEtapaTramiteInm)]
   FROM SImtramiteInm ti
   JOIN #tmp_tram e ON ti.sNumeroTramite = e.sNumeroTramite
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


EXEC sp_help SimOficioRQ

-- sNumeroOficio, sIdDependencia, sAnio
SELECT TOP 10 * FROM SimMovMigra mm
WHERE mm.sIdMovMigratorio = '2024TJ00000030'

SELECT TOP 10 * FROM SimParametroRQ
SELECT TOP 10 * FROM SimAuditoriaiDENTIDADRQ

SELECT TOP 10 * FROM SimRQAudit

SELECT 
   TOP 10 * 
FROM SImMovMigra

SELECT TOP 10 * FROM SimOficioRQ r
ORDER BY r.sAnio DESC