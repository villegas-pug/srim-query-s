USE BD_SIRIM
GO

--> 1. ...
-- =================================================================================================================================
CREATE OR ALTER PROCEDURE usp_Rim_RN_MetricasResumenJefeZonal
(
   @idJefatura VARCHAR(15)
)
AS
BEGIN

   -- Global dep's
   DECLARE @totalRegistros INT,
           @totalIncumplen INT

   -- Total registros
   DROP TABLE IF EXISTS #tmp_registros_por_proceso

   SELECT
      f.[sTabla],
      [sEstado] = '',
      [nTotal] = SUM(f.[nTotalRegistros])
      INTO #tmp_registros_por_proceso
   FROM (
      SELECT
         r.sTabla,
         [sEstado] = '',
         r.nTotalRegistros
      FROM RimRNRegistrosPorDependencia r
      WHERE 
         r.sIdDependencia IN (
                              SELECT j.sIdDependencia 
                              FROM RimRNJefaturaZonal j
                              WHERE
                                 j.bActivo = 1
                                 AND j.sIdJefatura = @idJefatura
         )
   ) f
   GROUP BY
      f.[sTabla]

   -- Total registros incumplen
   DROP TABLE IF EXISTS #tmp_registros_por_proceso_incumplen
   SELECT 
      a.sTabla,
      [sEstado] = 'Incumplen',
      [nTotal] = COUNT(1)
      INTO #tmp_registros_por_proceso_incumplen
   FROM RimRNAuditoriaControlMigratorio a
   WHERE 
      a.sIdDependencia IN (
                              SELECT j.sIdDependencia 
                              FROM RimRNJefaturaZonal j
                              WHERE
                                 j.bActivo = 1
                                 AND j.sIdJefatura = @idJefatura
      )
   GROUP BY
      a.sTabla

   -- Final:
   SELECT 
      [tabla] = c.sTabla,
      [estado] = 'Cumplen',
      [total] = COALESCE(
                           c.nTotal -
                           (
                              SELECT i.nTotal
                              FROM #tmp_registros_por_proceso_incumplen i
                              WHERE i.sTabla = c.sTabla
                           )
               , 0) 
   FROM #tmp_registros_por_proceso c
   UNION ALL
   SELECT * FROM #tmp_registros_por_proceso_incumplen i

   -- Cleanup
   DROP TABLE IF EXISTS #tmp_registros_por_proceso
   DROP TABLE IF EXISTS #tmp_registros_por_proceso_incumplen

END

-- Test
EXEC usp_Rim_RN_MetricasResumenJefeZonal 'JZCALL'

CREATE NONCLUSTERED INDEX ix_RimRNAuditoriaControlMigratorio_sIdDependencia_sDimension
   ON RimRNAuditoriaControlMigratorio(sIdDependencia, sDimension);
-- =======================================================================================================================================


--> 3. ...
-- =================================================================================================================================

-- CREATE OR ALTER PROCEDURE up_Rim_RN_MetricasReglasNegocioJefeZonal
CREATE OR ALTER PROCEDURE usp_Rim_RN_MetricasOperadorJefeZonal
(
   @idProceso INT,
   @idJefatura VARCHAR(15)
)
AS
BEGIN

   -- Final
   SELECT
      [tabla] = a.sTabla,
      [loginOpeDigita] = a.sLoginOpeDigita,
      [nombreOpeDigita] = a.sNombreOpeDigita,
      [total] = COUNT(1)
   FROM RimRNAuditoriaControlMigratorio a
   WHERE
      a.nIdProceso = @idProceso
      AND a.sIdDependencia IN (
                                 SELECT j.sIdDependencia 
                                 FROM RimRNJefaturaZonal j
                                 WHERE
                                    j.bActivo = 1
                                    AND j.sIdJefatura = @idJefatura
      )
      AND a.sLoginOpeDigita IS NOT NULL
   GROUP BY
      a.sTabla,
      a.sLoginOpeDigita,
      a.sNombreOpeDigita
   ORDER BY 4 DESC

END

-- Test
EXEC usp_Rim_RN_MetricasOperadorJefeZonal 1, 'JZCALL'

-- =================================================================================================================================


--> 4. ...
-- =================================================================================================================================

-- CREATE OR ALTER PROCEDURE up_Rim_RN_MetricasReglasNegocioJefeZonal
CREATE OR ALTER PROCEDURE usp_Rim_RN_MetricasDependenciaJefeZonal
(
   @idProceso INT,
   @idJefatura VARCHAR(15)
)
AS
BEGIN

   -- Final
   SELECT
      [dependencia] = UPPER(d.sNombre),
      [sigla] = UPPER(d.sSigla),
      [total] = COUNT(1)
   FROM RimRNAuditoriaControlMigratorio a
   JOIN SIM.dbo.SimDependencia d ON a.sIdDependencia = d.sIdDependencia
   WHERE
      a.nIdProceso = @idProceso
      AND a.sIdDependencia IN (
                                 SELECT j.sIdDependencia 
                                 FROM RimRNJefaturaZonal j
                                 WHERE
                                    j.bActivo = 1
                                    AND j.sIdJefatura = @idJefatura
      )
   GROUP BY
      d.sNombre,
      d.sSigla
   ORDER BY 2 DESC

END

-- Test
EXEC usp_Rim_RN_MetricasDependenciaJefeZonal 1, 'JZCALL'

-- =================================================================================================================================

--> 5. ...
-- =================================================================================================================================
CREATE OR ALTER PROCEDURE usp_Rim_RN_MetricasDatosInvalidosJefeZonal
(
   @idProceso INT,
   @idJefatura VARCHAR(15)
)
AS
BEGIN

   -- Final
   SELECT
      [camposErrCsv] = a.sCamposErrCsv,
      [total] = COUNT(1)
   FROM RimRNAuditoriaControlMigratorio a
   WHERE
      a.nIdProceso = @idProceso
      AND a.sIdDependencia IN (
                                 SELECT j.sIdDependencia
                                 FROM RimRNJefaturaZonal j
                                 WHERE
                                    j.bActivo = 1
                                    AND j.sIdJefatura = @idJefatura
      )
   GROUP BY
      a.sCamposErrCsv

END

-- Test
EXEC usp_Rim_RN_MetricasDatosInvalidosJefeZonal 1, 'JZCALL'

-- =================================================================================================================================




