USE SIM
GO

/*
   → 57	22	CONFORMIDAD SUB-DIREC.INMGRA.
   → 58	22	CONFORMIDAD SUB-DIREC.INMGRA.
   → 113	75	CONFORMIDAD JEFATURA ZONAL
   → 126	75	CONFORMIDAD JEFATURA ZONAL */


-- Caso 1: Trámites con estado diferente a aprobado en pre-aprobación y con estado de trámite en `A` ...
-- SELECT * FROM SimPreTramiteInm spti WHERE spti.sNumeroTramite = 'CS230007675'
SELECT * FROM SimTipoTramite stt WHERE stt.sDescripcion LIKE '%prorr%'
SELECT 

   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux
   [Id Persona] = t.uIdPersona,
   [Fecha Expendiente] = t.dFechaHora,
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Estado Trámite Actual] = (

                        CASE t.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END

                     ),
   [Estado Pre-aprobación] = (
                     CASE t.sEstadoPre 
                        WHEN 'A' THEN 'APROBADO'
                        WHEN 'B' THEN 'ABANDONADO'
                        WHEN 'D' THEN 'DENEGADO'
                        WHEN 'E' THEN 'DESISTIDO'
                        WHEN 'N' THEN 'NO PRESENTADO'
                        WHEN 'P' THEN 'PENDIENTE'
                     END
                  )

FROM (

   SELECT
      st.uIdPersona,
      st.nIdTipoTramite,
      st.dFechaHora,
      st.sNumeroTramite,
      sti.sEstadoActual,
      spti.sEstadoPre,
      [nFila_Pre] = ROW_NUMBER() OVER (PARTITION BY spti.sNumeroTramite ORDER BY spti.dFechaPre DESC)
   FROM SimTramite st
   JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
   JOIN SimPreTramiteInm spti ON st.sNumeroTramite = spti.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND sti.sEstadoActual = 'A'
      AND NOT EXISTS (

         SELECT 
            TOP 1 1
         FROM SimEtapaTramiteInm seti
         WHERE
            seti.sNumeroTramite = st.sNumeroTramite 
            AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
            -- AND seti.sEstado = 'F'
            AND seti.bActivo = 1
            
      )

) t
JOIN SimPersona sper ON t.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON t.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   t.nFila_Pre = 1
   AND t.sEstadoPre != 'A'

-- Test ...
SELECT * FROM SimPreTramiteInm spti WHERE spti.sNumeroTramite = 'LM220074267'

-- Caso 2: Más de 2 Citas de PAS-E mismo año, mes y direferente número de recibo ...
-- Caso 2: Más de 2 Citas de PAS-E mismo año, mes y direferente número de recibo ...

-- 4. Títulos de nacionalidad entregados con estado de trámite diferente a `A` ...
-- 4.1
SELECT
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Nacionalidad] = sper.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = stn.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Título Impreso] = IIF(
                           (
                              SELECT stin.bImpreso FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [Título Entregado] = IIF(
                           (
                              SELECT stin.bEntregado FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [sEstadoActual] = (
                        CASE stn.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     )
                  
FROM SimTramiteNac stn
JOIN SimTramite st ON stn.sNumeroTramite = st.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE 
   stn.sEstadoActual != 'A'
   AND EXISTS (

               SELECT 1 FROM SimTituloNacionalidad stin
               WHERE
                  stin.bAnulado = 0
                  AND stin.bImpreso = 1
                  AND stin.bEntregado = 1
                  AND stin.sNumeroTramite = stn.sNumeroTramite

            )

-- 4.2
-- 42 | ENTREGA DE TITULO
SELECT * FROM SimEtapa se WHERE se.sDescripcion LIKE '%entrega%'

SELECT 
   
   [Id Persona] = sper.uIdPersona,
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sper.dFechaNacimiento,
   [Nacionalidad] = sper.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = stn.sNumeroTramite,
   [Tipo Trámite] = stt.sDescripcion,
   [Título Impreso] = IIF(
                           (
                              SELECT stin.bImpreso FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [Título Entregado] = IIF(
                           (
                              SELECT stin.bEntregado FROM SimTituloNacionalidad stin
                              WHERE
                                 stin.sNumeroTramite = stn.sNumeroTramite
                           ) = 1,
                           'Si',
                           'No'
                     ),
   [sEstadoActual] = (
                        CASE stn.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     )

FROM SimTramiteNac stn
JOIN SimTramite st ON stn.sNumeroTramite = st.sNumeroTramite
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
WHERE
   stn.sEstadoActual = 'P'
   AND EXISTS (

      SELECT 1 FROM SimEtapaTramiteNac setn
      WHERE
         setn.sNumeroTramite = stn.sNumeroTramite
         AND setn.bActivo = 1
         AND setn.nIdEtapa = 42 -- ENTREGA DE TITULO
         AND setn.sEstado = 'F'

   )

-- Test ...
SELECT se.sDescripcion, setn.sEstado FROM SimEtapaTramiteNac setn 
JOIN SimEtapa se ON setn.nIdEtapa = se.nIdEtapa
WHERE setn.sNumeroTramite = 'LM120071640'

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

-- Test ...
SELECT TOP 10 * FROM #tmp_sim_duplext d
WHERE d.sIdPersona LIKE '%[ ]%'

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


-- Test ...
-- 1
