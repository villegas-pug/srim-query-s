USE BD_SIRIM
GO

--> 1. ...
-- =================================================================================================================================

-- DROP PROCEDURE up_Rim_RN_InsertaRegistroEjecucionScript
CREATE OR ALTER PROCEDURE up_Rim_RN_InsertaRegistroEjecucionScript
(
   @idProceso INT,
	@idRNControlCambio INT
)
AS
BEGIN
	BEGIN TRY

		-- Gloabl dep's
      DECLARE @sqlRegla NVARCHAR(4000),
              @sqlAdicional NVARCHAR(4000),
              @sqlFinal NVARCHAR(4000),
              @tmp_of_sql_regla VARCHAR(55) = 'tmp_of_sql_regla',
              @tmp_of_sql_adicional VARCHAR(55) = 'tmp_of_sql_adicional',
				  @nTotal BIGINT = 0,
              @sql_drop_tmps NVARCHAR(255)
		

      -- Clean-up
      SET @sql_drop_tmps = FORMATMESSAGE(N'DROP TABLE IF EXISTS %s DROP TABLE IF EXISTS %s', @tmp_of_sql_regla, @tmp_of_sql_adicional)
      EXEC sp_executesql @sql_drop_tmps

		SET @sqlRegla = (SELECT c.sScript FROM RimRNControlCambios c WHERE c.nIdRNControlCambio = @idRNControlCambio)

      IF @idProceso = 1 -- Control Migratorio
      BEGIN

         -- Crea tabla `tmp` en consulta de la regla
         SET @sqlRegla = STUFF(@sqlRegla, CHARINDEX('FROM', @sqlRegla), 0, CONCAT(' INTO ', @tmp_of_sql_regla, ' '))
         EXEC sp_executesql @sqlRegla

         -- Adiciona datos de control migratorio a la consulta de la regla
         SET @sqlAdicional = N'
                                 
                                 SELECT

                                    -- Control
                                    [Id Persona] = dmm.uIdPersona,
                                    [Id Mov Migratorio(Control)] = dmm.sIdMovMigratorio,
                                    [Fecha(Control)] = dmm.dFechaControl,
                                    [Tipo(Control)] = dmm.sTipo,
                                    [Calidad(Control)] = dcm.sDescripcion,
                                    [Nacionalidad(Control)] = dmm.sIdPaisNacionalidad,
                                    [Numero Doc(Control)] = dmm.sNumeroDoc,
                                    [Pais Mov(Control)] = dmm.sIdPaisMov,
                                    [Permanencia(Control)] = dmm.nPermanencia,


                                    -- Persona
                                    [Nombre(Persona)] = dpe.sNombre,
                                    [Primer Ape(Persona)] = dpe.sPaterno,
                                    [Segundo Ape(Persona)] = dpe.sMaterno,
                                    [Sexo(Persona)] = dpe.sMaterno,
                                    [Fecha Nacimiento(Persona)] = dpe.dFechaNacimiento,

                                    -- Operador digita
                                    [Login(Operador)] = du.sLogin,
                                    [Nombre(Operador)] = du.sNombre,

                                    -- Dep
                                    [Id Dependencia] = dmm.sIdDependencia

                                    INTO ' + @tmp_of_sql_adicional +
                                 ' FROM SIM.dbo.SimMovMigra dmm
                                 JOIN ' + @tmp_of_sql_regla + ' r ON r.sIdMovMigratorio = dmm.sIdMovMigratorio
                                 JOIN SIM.dbo.SimPersona dpe ON dmm.uIdPersona = dpe.uIdPersona
                                 JOIN SIM.dbo.SimCalidadMigratoria dcm ON dmm.nIdCalidad = dcm.nIdCalidad
                                 LEFT JOIN SIM.dbo.SimSesion ds ON dmm.nIdSesion = ds.nIdSesion
                                 LEFT JOIN SIM.dbo.SimUsuario du ON ds.nIdOperador = du.nIdOperador

         '

         EXEC sp_executesql @sqlAdicional 
         
      END   

		BEGIN TRAN

      -- Actualiza result-set:
      UPDATE RimRNControlCambios
         SET jResultSet = (
            (
               SELECT TOP 5 * FROM tmp_of_sql_adicional
               FOR JSON PATH
            )
         )
         WHERE
            nIdRNControlCambio = @idRNControlCambio

      -- Nuevo registro ejecución de script:
      SET @nTotal = (SELECT COUNT(1) FROM tmp_of_sql_adicional)
		INSERT INTO RimRNRegistroEjecucionScript(bActivo, dFechaEjecucion, nResultado, nIdRNControlCambio)
			VALUES(1, GETDATE(), @nTotal, @idRNControlCambio)

		COMMIT TRAN

      -- Clean-up
      SET @sql_drop_tmps = FORMATMESSAGE('DROP TABLE IF EXISTS %s; DROP TABLE IF EXISTS %s;', @tmp_of_sql_regla, @tmp_of_sql_adicional)
      EXEC sp_executesql @sql_drop_tmps

      SELECT 1

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN

      -- Clean-up
      SET @sql_drop_tmps = FORMATMESSAGE('DROP TABLE IF EXISTS %s; DROP TABLE IF EXISTS %s;', @tmp_of_sql_regla, @tmp_of_sql_adicional)
      EXEC sp_executesql @sql_drop_tmps

      SELECT
         [Error Procedure] = ERROR_PROCEDURE(),
         [Error Line] = ERROR_LINE(),
         [Error Message] = ERROR_MESSAGE()

	END CATCH

END

-- Test
EXEC up_Rim_RN_InsertaRegistroEjecucionScript 1, 2



-- ================================================================================================================================================


SELECT TOP 10 * FROM Sim.dbo.SimMovMigra
		
SELECT 
   TOP 1
   mm.sIdMovMigratorio, 
   mm.dFechaControl 
FROM SIM.dbo.SimMovMigra mm
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND YEAR(mm.dFechaControl) = 1900



-- RN0007
		
SELECT 
   smm.sIdMovMigratorio
FROM SIM.dbo.SimMovMigra smm
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND smm.nIdCalidad = 21 -- 21 | PERUANO | N
   AND (smm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND smm.sIdPaisNacionalidad IS NOT NULL)  AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND (smm.sNumeroDoc != '' AND smm.sNumeroDoc IS NOT NULL)
