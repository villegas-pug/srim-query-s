CREATE OR ALTER PROCEDURE usp_Rim_RN_CalcularTiempoEjecucionScriptsValidacion
AS
BEGIN

   DECLARE @idTipoScript INT = 1,
           @idRNCtrlAux INT,
           @idProcesoAux INT,
           @startTime DATETIME,
           @endTime DATETIME,
           @runtime INT = 0

   DROP TABLE IF EXISTS #tmp_controlcambios
   SELECT 
      c.nIdRNControlCambio,
      p.nIdProceso
      INTO #tmp_controlcambios
   FROM RimRNControlCambios c
   JOIN RimReglaNegocio r ON c.sIdRN = r.sIdRN
   JOIN RimRNProceso p ON r.nIdProceso = p.nIdProceso
   WHERE
      c.bActivo = 1
      AND c.nIdTipoScript = @idTipoScript

   WHILE (SELECT COUNT(1) FROM #tmp_controlcambios) > 0
   BEGIN

      SET @idRNCtrlAux = (SELECT TOP 1 t.nIdRNControlCambio FROM #tmp_controlcambios t ORDER BY t.nIdRNControlCambio)
      SET @idProcesoAux = (SELECT t.nIdProceso FROM #tmp_controlcambios t WHERE t.nIdRNControlCambio = @idRNCtrlAux)

      SET @startTime = GETDATE()
      EXEC usp_Rim_RN_InsertaRegistroEjecucionScript @idProcesoAux, @idRNCtrlAux
      SET @endTime = GETDATE()

      SET @runtime = DATEDIFF(SECOND, @startTime, @endTime)

      UPDATE RimRNControlCambios
         SET nRuntime = @runtime
      WHERE nIdRNControlCambio = @idRNCtrlAux

      -- Cleanup
      DELETE FROM #tmp_controlcambios WHERE nIdRNControlCambio = @idRNCtrlAux

   END

END

-- Test
EXEC usp_Rim_RN_CalcularTiempoEjecucionScriptsValidacion

TRUNCATE TABLE RimRNAuditoriaControlMigratorio
SELECT TOP 10 * FROM RimRNAuditoriaControlMigratorio

SELECT DATEDIFF(SECOND, '2024-09-18 14:40:00.000', GETDATE())

SELECT COUNT(1) FROM BD_SIRIM.dbo.RimRNAuditoriaControlMigratorio
SELECT TOP 10 * FROM BD_SIRIM.dbo.RimRNAuditoriaControlMigratorio


