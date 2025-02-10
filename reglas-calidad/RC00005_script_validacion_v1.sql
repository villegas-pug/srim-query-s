
-- Caso 6: Eliminar registros duplicados sin imagenes, fotos, trámites, movimientos migratorios, etc.
-- 6.1
DROP TABLE IF EXISTS #tmp_sim_duplext
SELECT 
   [sIdPersona] = REPLACE(CONCAT(SOUNDEX(e.sNombre), e.sPaterno, e.sMaterno, e.sIdPaisNacionalidad, CAST(e.dFechaNacimiento AS FLOAT)), ' ', ''),
   e.*
INTO #tmp_sim_duplext FROM (

   SELECT
      sper.*,
      [nDupl] = COUNT(1) OVER (PARTITION BY SOUNDEX(sper.sNombre), sper.sPaterno, sper.sMaterno, sper.sIdPaisNacionalidad, sper.dFechaNacimiento)
   FROM SimPersona sper
   WHERE
      sper.bActivo = 1
      AND (LEN(sper.sNombre) > 0 AND sper.sNombre LIKE '[a-zA-Z0-9]%' AND sper.sNombre IS NOT NULL)
      AND (LEN(sper.sPaterno) > 0 AND sper.sPaterno LIKE '[a-zA-Z0-9]%' AND sper.sPaterno IS NOT NULL)
      AND sper.sIdPaisNacionalidad != 'PER'

) e
WHERE
   e.nDupl >= 2

-- 6.2: ...
BEGIN 

   -- Global dep's ...
   DECLARE @sIdPersona VARCHAR(MAX) = ''

   -- `tmp`: #tmp_sim_duplext
   DROP TABLE IF EXISTS #tmp_sim_duplext_bak
   SELECT * INTO #tmp_sim_duplext_bak FROM #tmp_sim_duplext

   -- `tmp`: #tmp_sim_duplext_final
   DROP TABLE IF EXISTS #tmp_sim_duplext_final
   SELECT TOP 0 d.*, [sDiligenciaMigra] = REPLICATE(' ', 55) INTO #tmp_sim_duplext_final FROM #tmp_sim_duplext d

   CREATE NONCLUSTERED INDEX ix_tmp_sim_duplext_bak ON #tmp_sim_duplext_bak(sIdPersona)

   WHILE (SELECT COUNT(1) FROM #tmp_sim_duplext_bak) > 0
   BEGIN

      SET @sIdPersona = (SELECT TOP 1 d.sIdPersona FROM #tmp_sim_duplext_bak d ORDER BY d.sIdPersona ASC)
      
      -- 1
      DROP TABLE IF EXISTS #tmp_sim_duplext_record
      SELECT
         d.*,
         [sDiligenciaMigra] = (

                                 CASE
                                    WHEN EXISTS(SELECT TOP 1 1 FROM SimTramite st WHERE st.bCancelado = 0 AND st.uIdPersona = d.uIdPersona) THEN 'Trámites'
                                    WHEN EXISTS(SELECT TOP 1 1 FROM SimMovMigra smm WHERE smm.bAnulado = 0 AND smm.bTemporal = 0 AND smm.uIdPersona = d.uIdPersona) THEN 'Movimientos migratorios'
                                    WHEN EXISTS(SELECT TOP 1 1 FROM SimImagenExtranjero sie WHERE sie.uIdPersona = d.uIdPersona) THEN 'Datos biométricos'
                                    WHEN EXISTS(SELECT TOP 1 1 FROM SimDocPersona sdp WHERE sdp.bActivo = 1 AND sdp.uIdPersona = d.uIdPersona) THEN 'Documentos registrados'
                                    ELSE 'No registra'
                                 END

                              )
         INTO #tmp_sim_duplext_record
      FROM #tmp_sim_duplext_bak d
      WHERE
         d.sIdPersona = @sIdPersona

      -- 2
      IF (
            EXISTS(SELECT TOP 1 1 FROM #tmp_sim_duplext_record d 
                   WHERE d.sDiligenciaMigra != 'No registra') -- Si, por lo menos un registro, tiene diligencias migratorias ...
            AND
            EXISTS(SELECT TOP 1 1 FROM #tmp_sim_duplext_record d 
                   WHERE d.sDiligenciaMigra = 'No registra') -- Si, por lo menos un registro, no tiene diligencias migratorias ...
         )
      BEGIN
         INSERT INTO #tmp_sim_duplext_final
            SELECT * FROM #tmp_sim_duplext_record

         PRINT '---------→ Si, por lo menos un registro, tiene diligencias migratorias ...'
      END
      
      -- Cleanup ...
      DELETE FROM #tmp_sim_duplext_bak
         WHERE sIdPersona = @sIdPersona

   END

END

-- 6.3: Final ...
SELECT * FROM #tmp_sim_duplext_final
SELECT 
   [Id Persona] = d.uIdPersona,
   [Nombres] = d.sNombre,
   [Apellido 1] = d.sPaterno,
   [Apellido 2] = d.sMaterno,
   [Sexo] = d.sSexo,
   [Fecha Nacimiento] = d.dFechaNacimiento,
   [Nacionalidad] = d.sIdPaisNacionalidad,

   -- Aux
   [Total Registros Duplicados] = d.nDupl,
   [Diligencia migratoria] = d.sDiligenciaMigra -- N/R | No registra diligencias migratorias
FROM #tmp_sim_duplext_final d
WHERE
   d.sDiligenciaMigra = 'No registra'