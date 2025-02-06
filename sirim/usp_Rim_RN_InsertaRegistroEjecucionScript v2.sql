--> 1. ...
-- =================================================================================================================================

-- DROP PROCEDURE up_Rim_RN_InsertaRegistroEjecucionScript
CREATE OR ALTER PROCEDURE usp_Rim_RN_InsertaRegistroEjecucionScript
(
   @idProceso INT,
	@idRNControlCambio INT
)
AS
BEGIN
	BEGIN TRY

		-- Global dep's
      DECLARE @sql_regla NVARCHAR(4000),
              @sql_drop_tmps NVARCHAR(255),
              @id_rn CHAR(7),
              @fields_error VARCHAR(255) = '',
              @dimension VARCHAR(255),
              @tabla VARCHAR(100),
				  @total_records BIGINT = 0,
              @field_name_datos_dupli VARCHAR(25) = 'jDatosDuplicados'

      DROP TABLE IF EXISTS #tmp_table_sql_regla
      CREATE TABLE #tmp_table_sql_regla (
         sIdMovMigratorio CHAR(14) NULL,
         jDatosDuplicados VARCHAR(8000) NULL
      )

      -- Campos auxiliares
		SELECT  
         @id_rn = c.sIdRN,
         @fields_error = r.sCampos,
         @dimension = (SELECT d.sNombre FROM RimRNDimension d WHERE d.nIdDimension = r.nIdDimensionRegla),
         @tabla = r.sTablas,
         @sql_regla = c.sScript
      FROM RimRNControlCambios c 
      JOIN RimReglaNegocio r ON c.sIdRN = r.sIdRN
      WHERE 
         c.nIdRNControlCambio = @idRNControlCambio

      -- Inyecta nombre tabla `tmp` y campos auxiliares
      IF (CHARINDEX(@field_name_datos_dupli, @sql_regla) > 0)
      BEGIN
         INSERT INTO #tmp_table_sql_regla
            EXEC sp_executesql @sql_regla
      END
      ELSE
      BEGIN
         INSERT INTO #tmp_table_sql_regla(sIdMovMigratorio)
            EXEC sp_executesql @sql_regla
      END

      CREATE NONCLUSTERED INDEX ix_#tmp_table_sql_regla_sIdMovMigratorio
         ON #tmp_table_sql_regla(sIdMovMigratorio)

      IF @idProceso = 1 -- Control Migratorio
      BEGIN

         -- 1.1 Adiciona datos de control migratorio a la consulta de la regla
         MERGE INTO RimRNAuditoriaControlMigratorio AS d
         USING (

            SELECT
               -- Control
               mm.sIdMovMigratorio,
               mm.uIdPersona,
               mm.dFechaControl,
               mm.sNombres,
               mm.sTipo,
               mm.nIdCalidad,
               [sCalidad] = cm.sDescripcion,
               mm.sIdPaisNacionalidad,
               mm.sIdDocumento,
               mm.sNumeroDoc,
               mm.sIdPaisMov,
               mm.nPermanencia,

               -- Persona
               pe.sNombre,
               pe.sPaterno,
               pe.sMaterno,
               pe.sSexo,
               pe.dFechaNacimiento,

               -- Itinerario
               i.sIdItinerario,
               i.dFechaProgramada,
               i.sTipoMovimiento,
               i.nCantidadMov,
               i.sNumeroNave,

               -- Operador digita
               [sLoginOpeDigita] = u.sLogin,
               [sNombreOpeDigita] = u.sNombre,

               -- Dep
               mm.sIdDependencia,
               d.sIdJefatura,
               r.jDatosDuplicados

               -- Aux
               -- [sDimension],
               -- [sCamposErrCsv] -- Conveción: RN1; field1, field2 | RN2; field1, field2

            FROM #tmp_table_sql_regla r
            JOIN SIM.dbo.SimMovMigra mm ON r.sIdMovMigratorio = mm.sIdMovMigratorio
            JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
            JOIN SIM.dbo.SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
            LEFT JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
            LEFT JOIN SIM.dbo.SimUsuario u ON mm.nIdOperadorDigita = u.nIdOperador
            LEFT JOIN SIM.dbo.SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
            
         ) as f
         ON f.sIdMovMigratorio = d.sIdMovMigratorio
         WHEN MATCHED
            THEN UPDATE -- Conveción: RN1; field1, field2 | RN2; field1, field2
               SET 
                  -- SELECT CHARINDEX('a', 'abc')
                  d.sCamposErrCsv = (
                                       CASE
                                          WHEN (CHARINDEX(@id_rn, d.sCamposErrCsv) > 0) THEN d.sCamposErrCsv
                                          ELSE CONCAT(d.sCamposErrCsv, '|', CONCAT(@id_rn, ';', @fields_error))
                                       END
                  ),
                  d.sDimension = (
                                    CASE
                                       WHEN (CHARINDEX(@dimension, d.sDimension) > 0) THEN d.sDimension
                                       ELSE CONCAT(d.sDimension, ', ', @dimension)
                                    END

                  ),
                  d.jDatosDuplicados = (
                                          CASE
                                             WHEN (d.jDatosDuplicados != '' AND f.jDatosDuplicados != '') THEN (
                                                CASE
                                                   WHEN (JSON_QUERY(d.jDatosDuplicados, '$.SimMovMigra') IS NOT NULL) THEN (
                                                      JSON_MODIFY(d.jDatosDuplicados, '$.SimMovMigra', f.jDatosDuplicados)
                                                   )
                                                   WHEN (JSON_QUERY(d.jDatosDuplicados, '$.SimPersona') IS NOT NULL) THEN
                                                      JSON_MODIFY(d.jDatosDuplicados, '$.SimPersona', f.jDatosDuplicados)
                                                END
                                             )
                                             WHEN (d.jDatosDuplicados != '' AND f.jDatosDuplicados = '') THEN (
                                                d.jDatosDuplicados
                                             )
                                             ELSE f.jDatosDuplicados
                                          END
                  )
         WHEN NOT MATCHED /*BY TARGET*/ -- one clause allowed
            THEN INSERT
            VALUES(
               f.uIdPersona, f.sIdMovMigratorio, f.dFechaControl, f.sNombres, f.sTipo, f.nIdCalidad, 
               f.sCalidad, f.sIdPaisNacionalidad, f.sIdDocumento, f.sNumeroDoc, f.sIdPaisMov, 
               f.nPermanencia, f.sNombre, f.sPaterno, f.sMaterno, f.sSexo, f.dFechaNacimiento, 
               f.sIdItinerario, f.dFechaProgramada, f.sTipoMovimiento, f.nCantidadMov, f.sNumeroNave, 
               f.sLoginOpeDigita, f.sNombreOpeDigita, f.sIdDependencia, f.sIdJefatura,
               @dimension, CONCAT(@id_rn, ';', @fields_error), @tabla, @idProceso, f.jDatosDuplicados
            );
         /* WHEN NOT MATCHED BY SOURCE THEN -- Si no hay registros invalidos, entonces elimina de la tabla auditoria
            DELETE; */

      END   

		BEGIN TRAN

      SET @total_records = (SELECT COUNT(1) FROM #tmp_table_sql_regla)

      -- Actualiza RimReglaNegocio:
      UPDATE RimReglaNegocio
         SET nIdStatusRegla = IIF(@total_records > 0, 2, 1)
      WHERE sIdRN = @id_rn

      -- Actualiza RimRNControlCambios:
      UPDATE RimRNControlCambios
         SET jResultSet = (
            (
               SELECT TOP 5 a.* FROM #tmp_table_sql_regla r
               JOIN RimRNAuditoriaControlMigratorio a ON r.sIdMovMigratorio = a.sIdMovMigratorio
               FOR JSON PATH, ROOT('Muestra')
            )
         )
         WHERE
            nIdRNControlCambio = @idRNControlCambio

      -- Nuevo registro ejecución de script:
		INSERT INTO RimRNRegistroEjecucionScript(bActivo, dFechaEjecucion, nResultado, nIdRNControlCambio)
			VALUES(1, GETDATE(), @total_records, @idRNControlCambio)

		COMMIT TRAN

      -- Clean-up
      EXEC sp_executesql @sql_drop_tmps

      SELECT [status] = 1 -- Succesfully

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN

      -- Clean-up
      EXEC sp_executesql @sql_drop_tmps

      -- SELECT [status] = 0 -- Failed

      SELECT
         [Error Procedure] = ERROR_PROCEDURE(),
         [Error Line] = ERROR_LINE(),
         [Error Message] = ERROR_MESSAGE()

	END CATCH

END



-- Test
-- RN00006
-- 2012PS03925317
EXEC usp_Rim_RN_InsertaRegistroEjecucionScript 1, 28

SELECT * FROM RimReglaNegocio
SELECT * FROM RimRNControlCambios c
WHERE 
   c.sIdRN = 'RN00189'
   -- c.sIdRN = 'RN00002'

SELECT TOP 10 * FROM SIM.dbo.SimPersona
EXEC sp_help RimRNAuditoriaControlMigratorio
SELECT
   -- TOP 100 * 
   COUNT(1)
FROM RimRNAuditoriaControlMigratorio a
WHERE 
   -- a.jDatosDuplicados IS NOT NULL
   -- a.jDatosDuplicados LIKE '%SimMovMigra%' 
   a.jDatosDuplicados LIKE '%SimPersona%'

   -- a.sTabla = 'SimPersona'
   -- a.sIdMovMigratorio = '2020PS00266491'



-- ================================================================================================================================================