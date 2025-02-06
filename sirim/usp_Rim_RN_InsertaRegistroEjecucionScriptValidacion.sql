
/*░
   --> usp_Rim_RN_InsertaRegistroEjecucionScriptValidacion 
-- ========================================================================================================================================== */
CREATE OR ALTER PROCEDURE usp_Rim_RN_InsertaRegistroEjecucionScriptValidacion
(
	@idRNControlCambio INT
)
AS
BEGIN
	BEGIN TRY

		-- Global dep's
      DECLARE @sql_validacion NVARCHAR(MAX),
              @total_records BIGINT

      DROP TABLE IF EXISTS #tmp_table_sql_validacion
      CREATE TABLE #tmp_table_sql_validacion (
         nTotal BIGINT
      )

      -- Campos auxiliares
		SELECT  
         @sql_validacion = c.sScript
      FROM RimRNControlCambios c 
      JOIN RimReglaNegocio r ON c.sIdRN = r.sIdRN
      WHERE 
         c.nIdRNControlCambio = @idRNControlCambio

      INSERT INTO #tmp_table_sql_validacion
         EXEC sp_executesql @sql_validacion

      BEGIN TRAN

      SET @total_records = (SELECT v.nTotal FROM #tmp_table_sql_validacion v)

      -- Nuevo registro ejecución de script:
		INSERT INTO RimRNRegistroEjecucionScript(bActivo, dFechaEjecucion, nResultado, nIdRNControlCambio)
			VALUES(1, GETDATE(), @total_records, @idRNControlCambio)

		COMMIT TRAN

      -- Clean-up
      DROP TABLE IF EXISTS #tmp_table_sql_validacion

      SELECT [status] = 1 -- Succesfully

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN

      -- Clean-up
      DROP TABLE IF EXISTS #tmp_table_sql_validacion

      -- SELECT [status] = 0 -- Failed
      SELECT
         [Error Procedure] = ERROR_PROCEDURE(),
         [Error Line] = ERROR_LINE(),
         [Error Message] = ERROR_MESSAGE()

	END CATCH

END

-- Test:
EXEC usp_Rim_RN_InsertaRegistroEjecucionScriptValidacion 61

SELECT * FROM RimRNControlCambios c
WHERE 
   c.nIdTipoScript = 2
   AND c.sIdRN = 'RN00002'


SELECT 
   COUNT(1)
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sIdDocumento != 'NNN'

-- ========================================================================================================================================== */