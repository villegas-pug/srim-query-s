--> 1. usp_Rim_RN_InsertaRegistroEjecucionScript
-- =================================================================================================================================

CREATE OR ALTER PROCEDURE usp_Rim_RN_InsertaRegistroEjecucionScript
(
   @idProceso INT,
	@idRNControlCambio INT
)
AS
BEGIN
	BEGIN TRY

		-- Global dep's
      DECLARE @sql_regla NVARCHAR(MAX),
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
         jDatosDuplicados NVARCHAR(MAX) NULL
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

      -- Si consulta base, tiene datos auxiliares
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

      CREATE INDEX ix_#tmp_table_sql_regla_sIdMovMigratorio
         ON #tmp_table_sql_regla(sIdMovMigratorio)

      BEGIN TRAN

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

               mm.sIdModuloDigita,
               mm.sIdViaTransporte,
               mm.nIdTransportista,
               mm.sIdProfesion,

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

               [nIdTransportistaItinerario] = i.nIdTransportista,
               [sIdPaisMovItinerario] = i.sIdPais,

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
                                             WHEN (ISNULL(d.jDatosDuplicados, '') != '' AND ISNULL(f.jDatosDuplicados, '') != '') THEN (
                                                CASE
                                                   WHEN (CHARINDEX('Documento Vinculado(DNI)', f.jDatosDuplicados) > 0) THEN (
                                                      JSON_MODIFY(
                                                            d.jDatosDuplicados,
                                                            '$."Documento Vinculado(DNI)"',
                                                            JSON_QUERY(f.jDatosDuplicados, '$."Documento Vinculado(DNI)"')
                                                         )
                                                   )
                                                   WHEN (CHARINDEX('Documento Vinculado(PAS)', f.jDatosDuplicados) > 0) THEN (
                                                      JSON_MODIFY(
                                                            d.jDatosDuplicados,
                                                            '$."Documento Vinculado(PAS)"',
                                                            JSON_QUERY(f.jDatosDuplicados, '$."Documento Vinculado(PAS)"')
                                                         )
                                                   )
                                                   WHEN (CHARINDEX('Persona Duplicada', f.jDatosDuplicados) > 0) THEN (
                                                      JSON_MODIFY(
                                                         d.jDatosDuplicados, 
                                                         '$."Persona Duplicada"',
                                                         JSON_QUERY(f.jDatosDuplicados, '$."Persona Duplicada"')
                                                      )
                                                   )
                                                   WHEN (CHARINDEX('Movimiento Duplicado', f.jDatosDuplicados) > 0) THEN
                                                      JSON_MODIFY(
                                                            d.jDatosDuplicados, 
                                                            '$."Movimiento Duplicado"',
                                                            JSON_QUERY(f.jDatosDuplicados, '$."Movimiento Duplicado"')
                                                         )
                                                END
                                             )
                                             WHEN (ISNULL(f.jDatosDuplicados, '') != '' AND ISNULL(d.jDatosDuplicados, '') = '') THEN (
                                                f.jDatosDuplicados
                                             )
                                             ELSE d.jDatosDuplicados -- Nuevo
                                          END
                  )
         WHEN NOT MATCHED /*BY TARGET*/ -- one clause allowed
            THEN INSERT(
               uIdPersona, sIdMovMigratorio, dFechaControl, sNombres, sTipo, nIdCalidad, 
               sCalidad, sIdPaisNacionalidad, sIdDocumento, sNumeroDoc, sIdPaisMov, 
               nPermanencia, sNombre, sPaterno, sMaterno, sSexo, dFechaNacimiento, 
               sIdItinerario, dFechaProgramada, sTipoMovimiento, nCantidadMov, sNumeroNave, 
               sLoginOpeDigita, sNombreOpeDigita, sIdDependencia, sIdJefatura, 
               sIdModuloDigita, sIdViaTransporte, nIdTransportista, sIdProfesion, nIdTransportistaItinerario, sIdPaisMovItinerario,
               sDimension, sCamposErrCsv, sTabla, nIdProceso, jDatosDuplicados
            )
            VALUES(
               f.uIdPersona, f.sIdMovMigratorio, f.dFechaControl, f.sNombres, f.sTipo, f.nIdCalidad, 
               f.sCalidad, f.sIdPaisNacionalidad, f.sIdDocumento, f.sNumeroDoc, f.sIdPaisMov, 
               f.nPermanencia, f.sNombre, f.sPaterno, f.sMaterno, f.sSexo, f.dFechaNacimiento, 
               f.sIdItinerario, f.dFechaProgramada, f.sTipoMovimiento, f.nCantidadMov, f.sNumeroNave, 
               f.sLoginOpeDigita, f.sNombreOpeDigita, f.sIdDependencia, f.sIdJefatura,
               f.sIdModuloDigita, f.sIdViaTransporte, f.nIdTransportista, f.sIdProfesion, f.nIdTransportistaItinerario, f.sIdPaisMovItinerario,
               @dimension, CONCAT(@id_rn, ';', @fields_error), @tabla, @idProceso, f.jDatosDuplicados
            );
         /* WHEN NOT MATCHED BY SOURCE THEN -- Si no hay registros invalidos, entonces elimina de la tabla auditoria
            DELETE; */

      END   

      SET @total_records = (SELECT COUNT(1) FROM #tmp_table_sql_regla)

      -- Actualiza RimReglaNegocio:
      UPDATE RimReglaNegocio
         SET nIdStatusRegla = IIF(@total_records > 0, 2, 1)
      WHERE sIdRN = @id_rn

      -- Actualiza RimRNControlCambios:
      UPDATE RimRNControlCambios
         SET jResultSet = (
            (
               SELECT TOP 1 a.* FROM #tmp_table_sql_regla r
               JOIN RimRNAuditoriaControlMigratorio a ON r.sIdMovMigratorio = a.sIdMovMigratorio
               FOR JSON PATH
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

-- Test:

EXEC sp_help 

SELECT COUNT(1) FROM RimRNAuditoriaControlMigratorio a WHERE a.sIdJefatura IS NOT NULL
SELECT TOP 1 * FROM RimRNAuditoriaControlMigratorio
EXEC sp_help RimRNAuditoriaControlMigratorio

SELECT TOP 10 * FROM BD_SIRIM.dbo.RimRNAuditoriaControlMigratorio

SELECT LEN(a.jDatosDuplicados) 
FROM RimRNAuditoriaControlMigratorio a
GROUP BY LEN(a.jDatosDuplicados)
ORDER BY 1 DESC

-- TRUNCATE TABLE RimRNAuditoriaControlMigratorio
SELECT * FROM RimRNAuditoriaControlMigratorio



-- 1
-- 02Set2024: RN00190 | RN00191
-- Error: 
--   → JSON text is not properly formatted. Unexpected character '' is found at position 3998.
-- RN00196;[uIdPersona]|RN00154;[sIdMovMigratorio]
EXEC usp_Rim_RN_InsertaRegistroEjecucionScript 1, 36 -- RN00196
EXEC usp_Rim_RN_InsertaRegistroEjecucionScript 1, 32 -- RN00193
EXEC usp_Rim_RN_InsertaRegistroEjecucionScript 1, 28 -- RN00189
EXEC usp_Rim_RN_InsertaRegistroEjecucionScript 1, 25 -- RN00154

EXEC sp_help RimRNControlCambios
-- RimRNAuditoriaControlMigratorio
-- Rebuild index's
/* CREATE NONCLUSTERED INDEX ix_RNAuditoriaControlMigratorio_sIdMovMigra 
   ON RimRNAuditoriaControlMigratorio(sIdMovMigratorio) */

-- 2024AI03927483
-- 2023AI06509393
EXEC sp_help RimRNAuditoriaControlMigratorio


ALTER INDEX ALL ON RimRNAuditoriaControlMigratorio REBUILD

SELECT 
   -- LEN(c.sScript)
   c.*
FROM RimRNControlCambios c
WHERE 
   c.sIdRN = 'RN00189'
   AND c.nIdTipoScript = 1

SELECT 
   TOP 10
   -- TOP 100 *
   -- COUNT(1)
   a.sCamposErrCsv,
   a.jDatosDuplicados
   -- [i] = CHARINDEX('Persona Duplicada', a.jDatosDuplicados)
FROM RimRNAuditoriaControlMigratorio a
WHERE
   a.sCamposErrCsv LIKE '%RN00196%'
   -- a.sCamposErrCsv LIKE '%RN00196%'
   AND a.jDatosDuplicados IS NOT NULL

SELECT 
   LEN(a.jDatosDuplicados)
   -- a.*
FROM RimRNAuditoriaControlMigratorio a
GROUP BY
   LEN(a.jDatosDuplicados)
ORDER BY 1 DESC


UPDATE RimRNControlCambios
   SET sScript = '

   '
WHERE
   sIdRN = 'RN00193'


/* 
DELETE FROM RimRNAuditoriaControlMigratorio
   WHERE 
      sCamposErrCsv LIKE '%RN00196%' 
      OR sCamposErrCsv LIKE '%RN00193%' 
      OR sCamposErrCsv LIKE '%RN00189%' 
   
*/

-- ================================================================================================================================================


-- Script
-- 1
DROP TABLE IF EXISTS #tmp_dupl_personas_mm
SELECT 
   p3.*
   INTO #tmp_dupl_personas_mm
FROM (
   SELECT
      p2.*,
      -- Aux
      [nContarDupli] = COUNT(1) OVER (PARTITION BY p2.sIdPersona)
   FROM (

      SELECT
         [sIdPersona] = REPLACE(CONCAT(pe.sNombre, pe.sPaterno, pe.sMaterno, pe.sSexo, CAST(pe.dFechaNacimiento AS FLOAT), pe.sIdPaisNacionalidad), ' ', ''),
         [uIdPersona] = pe.uIdPersona,
         [sNombre] = COALESCE(pe.sNombre, '-'),
         [sPaterno] = COALESCE(pe.sPaterno, '-'),
         [sMaterno] = COALESCE(pe.sMaterno, '-'),
         [sSexo] = COALESCE(pe.sSexo, '-'),
         [dFechaNacimiento] = COALESCE(pe.dFechaNacimiento, '-'),
         [sIdPaisNacionalidad] = COALESCE(pe.sIdPaisNacionalidad, '-'),
         [sIdDocIdentidad] = COALESCE(pe.sIdDocIdentidad, '-'),
         [sNumDocIdentidad] = COALESCE(pe.sNumDocIdentidad, '-'),
         [sCalidad] = cm.sDescripcion,
         [sLogin] = COALESCE(u.sLogin, '-'),
         [sOperadorDigita] = COALESCE(u.sNombre, '-')
      FROM SIM.dbo.SimPersona pe
      JOIN SIM.dbo.SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
      LEFT JOIN SIM.dbo.SimSesion s ON pe.nIdSesion = s.nIdSesion
      LEFT JOIN SIM.dbo.SimUsuario u ON s.nIdOperador = u.nIdOperador
      WHERE
         pe.bActivo = 1
         AND EXISTS ( -- Registre control
                        SELECT TOP 1 1 FROM 
                        SIM.dbo.SimMovMigra mm
                        WHERE 
                           mm.bAnulado = 0
                           AND mm.bTemporal = 0
                           AND mm.uIdPersona = pe.uIdPersona
            )
   ) p2
) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE INDEX ix_tmp_dupl_personas_mm ON #tmp_dupl_personas_mm(uIdPersona)
CREATE INDEX ix_tmp_dupl_personas_mm_sIdPersona ON #tmp_dupl_personas_mm(sIdPersona)

-- 2. Personas únicas
DROP TABLE IF EXISTS #tmp_dupl_personas_mm_per_uniq
SELECT f.* INTO #tmp_dupl_personas_mm_per_uniq
FROM (
   SELECT
      mm.sIdMovMigratorio,
      d.uIdPersona,
      d.sIdPersona,
      [##] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
   FROM #tmp_dupl_personas_mm d
   JOIN SIM.dbo.SimMovMigra mm ON d.uIdPersona = mm.uIdPersona

) f
WHERE f.[##] = 1

-- 4. Final
SELECT 
   f.sIdMovMigratorio,
   [jDatosDuplicados] = (
         SELECT 
               [Id Persona] = d.uIdPersona,
               [Nombre] = d.sNombre,
               [Primer Ape] = d.sPaterno,
               [Segundo Ape] = d.sMaterno,
               [Sexo] = d.sSexo,
               [Fecha Nacimiento] = d.dFechaNacimiento,
               [Pais Nacionalidad] = d.sIdPaisNacionalidad,
               [Doc Identidad] = d.sIdDocIdentidad,
               [Num Doc Identidad] = d.sNumDocIdentidad,
               [Calidad] = d.sCalidad,
               [Login Operador Digita] = d.sLogin,
               [Operador Digita] = d.sOperadorDigita
         FROM #tmp_dupl_personas_mm d
         WHERE 
            d.uIdPersona != f.uIdPersona
            AND d.sIdPersona = f.sIdPersona
         FOR JSON PATH, ROOT('Persona Duplicada')
   )
FROM #tmp_dupl_personas_mm_per_uniq f

-- v2
-- 1
DROP TABLE IF EXISTS #tmp_dupl_personas_mm
SELECT 
   p3.*
   INTO #tmp_dupl_personas_mm
FROM (
   SELECT
      p2.*,
      -- Aux
      [nContarDupli] = COUNT(1) OVER (PARTITION BY p2.sIdPersona)
   FROM (

      SELECT
         mm.sIdMovMigratorio,
         [sIdPersona] = REPLACE(CONCAT(pe.sNombre, pe.sPaterno, pe.sMaterno, pe.sSexo, CAST(pe.dFechaNacimiento AS FLOAT), pe.sIdPaisNacionalidad), ' ', ''),
         [uIdPersona] = pe.uIdPersona,
         [sNombre] = COALESCE(pe.sNombre, '-'),
         [sPaterno] = COALESCE(pe.sPaterno, '-'),
         [sMaterno] = COALESCE(pe.sMaterno, '-'),
         [sSexo] = COALESCE(pe.sSexo, '-'),
         [dFechaNacimiento] = COALESCE(pe.dFechaNacimiento, '-'),
         [sIdPaisNacionalidad] = COALESCE(pe.sIdPaisNacionalidad, '-'),
         [sIdDocIdentidad] = COALESCE(pe.sIdDocIdentidad, '-'),
         [sNumDocIdentidad] = COALESCE(pe.sNumDocIdentidad, '-'),
         [sCalidad] = cm.sDescripcion,
         mm.nIdOperadorDigita,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)
      FROM SIM.dbo.SimMovMigra mm
      JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
      JOIN SIM.dbo.SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
      WHERE
         mm.bAnulado = 0
         AND mm.bTemporal = 0
   ) p2
   WHERE 
      p2.[#] = 1
) p3
WHERE
   p3.[nContarDupli] >= 2

CREATE INDEX ix_tmp_dupl_personas_mm ON #tmp_dupl_personas_mm(uIdPersona)
CREATE INDEX ix_tmp_dupl_personas_mm_sIdPersona ON #tmp_dupl_personas_mm(sIdPersona)

-- 2. Ultimo control migratorio por `sId`
DROP TABLE IF EXISTS #tmp_dupl_personas_ult_mm_by_sid
SELECT f.* INTO #tmp_dupl_personas_ult_mm_by_sid
FROM (
   SELECT
      d.sIdMovMigratorio,
      d.uIdPersona,
      d.sIdPersona,
      [#] = ROW_NUMBER() OVER (PARTITION BY d.sIdPersona ORDER BY d.sIdMovMigratorio DESC)
   FROM #tmp_dupl_personas_mm d
) f
WHERE f.[#] = 1

-- 3. Final
SELECT 
   f.sIdMovMigratorio,
   [jDatosDuplicados] = (
         SELECT        
            TOP 5
            [Id Persona] = d.uIdPersona,
            [Nombre] = d.sNombre,
            [Primer Ape] = d.sPaterno,
            [Segundo Ape] = d.sMaterno,
            [Sexo] = d.sSexo,
            [Fecha Nacimiento] = d.dFechaNacimiento,
            [Pais Nacionalidad] = d.sIdPaisNacionalidad,
            [Doc Identidad] = d.sIdDocIdentidad,
            [Num Doc Identidad] = d.sNumDocIdentidad,
            [Calidad] = d.sCalidad,
            [Login Operador Digita] = u.sLogin,
            [Operador Digita] = u.sNombre
         FROM #tmp_dupl_personas_mm d
         /* LEFT JOIN SIM.dbo.SimSesion s ON d.nIdSesion = s.nIdSesion */
         LEFT JOIN SIM.dbo.SimUsuario u ON d.nIdOperadorDigita = u.nIdOperador
         WHERE 
            d.uIdPersona != f.uIdPersona
            AND d.sIdPersona = f.sIdPersona
         FOR JSON PATH, ROOT('Persona Duplicada')
   )
FROM #tmp_dupl_personas_ult_mm_by_sid f


-- Script
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_1
SELECT p2.* INTO #tmp_mm_dni_vinculado_1
FROM (
   SELECT
      [Id Persona] = pe.uIdPersona,
      [Nombres] = pe.sNombre,
      [Apellido 1] = pe.sPaterno,
      [Apellido 2] = pe.sMaterno,
      [Sexo] = pe.sSexo,
      [Fecha de Nacimiento] = pe.dFechaNacimiento,
      [Nacionalidad] = pe.sIdPaisNacionalidad,
      -- Aux
      mm.sIdMovMigratorio,
      mm.sIdDocumento,
      mm.sNumeroDoc,
      mm.nIdOperadorDigita,
      [#(uId, NumDoc)] = ROW_NUMBER() OVER (
                                             PARTITION BY
                                                   mm.uIdPersona,
                                                   mm.sNumeroDoc
                                             ORDER BY mm.dFechaControl DESC
                                          )
   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   WHERE 
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
      AND pe.sIdPaisNacionalidad = 'PER'
      AND mm.sIdDocumento = 'DNI'
      AND ISNUMERIC(mm.sNumeroDoc) = 1
      AND LEN(mm.sNumeroDoc) = 8

) p2
WHERE
   p2.[#(uId, NumDoc)] = 1

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_mm_dni_vinculado_1 ON #tmp_mm_dni_vinculado_1(sNumeroDoc)

-- `tmp` Conteo por dni.
DROP TABLE IF EXISTS #tmp_mm_dni_vinculado_2
SELECT * INTO #tmp_mm_dni_vinculado_2
FROM (
   SELECT 
      v.*,
      [nCant(NumDoc)(2)] = COUNT(1) OVER (PARTITION BY v.sNumeroDoc)
   FROM #tmp_mm_dni_vinculado_1 v
) f
WHERE f.[nCant(NumDoc)(2)] >= 2

-- Documentos de viaje vinculados recientes únicos 
SELECT f.* INTO #tmp_mm_dni_vinculado_uniq
FROM (
   SELECT
      *,
      [#] = ROW_NUMBER() OVER (PARTITION BY v.sNumeroDoc ORDER BY v.sIdMovMigratorio DESC)
   FROM #tmp_mm_dni_vinculado_2 v
) f
WHERE f.[#] = 1

-- Final
SELECT 
   vu.sIdMovMigratorio,
   [jDatosDuplicados] = (
      SELECT 
      TOP 5
         [Id Mov Migratorio] = v.sIdMovMigratorio,
         v.[Id Persona],
         v.[Nombres],
         v.[Apellido 1],
         v.[Apellido 2],
         v.[Sexo],
         [Fecha Nacimiento] = CAST(v.[Fecha de Nacimiento] AS DATE),
         v.[Nacionalidad],
         [Documento] = v.sIdDocumento,
         [Numero Doc] = v.sNumeroDoc,
         [Login Operador Digita] = COALESCE(u.sLogin, '-'),
         [Operador Digita] = COALESCE(u.sNombre, '-')
      FROM #tmp_mm_dni_vinculado_2 v
      LEFT JOIN SIM.dbo.SimUsuario u ON v.nIdOperadorDigita = u.nIdOperador
      WHERE
         v.[Id Persona] != vu.[Id Persona]
         AND v.sNumeroDoc = vu.sNumeroDoc
      FOR JSON PATH, ROOT('Documento Vinculado(DNI)')
   )
FROM #tmp_mm_dni_vinculado_uniq vu






