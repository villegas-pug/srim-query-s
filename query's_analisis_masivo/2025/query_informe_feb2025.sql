USE SIM
GO

--> 1. Se define como regla de calidad, que la fecha de nacimiento del pasajero no debe ser mayor a la fecha de control migratorio.
-- =====================================================================================================================================================================
-- 1.1

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
   [Dependencia] = d.sNombre,
   [Fecha Control] = mm.dFechaControl,
   [Tipo Movimiento] = mm.sTipo,
   [Pais Mov] = mm.sIdPaisMov,
   [Via Transporte] = mm.sIdViaTransporte

FROM SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND mm.dFechaControl < pe.dFechaNacimiento -- Fecha nacimiento mayor a fecha control.
-- ORDER BY mm.dFechaControl DESC

-- =====================================================================================================================================================================


--> 2. Se define como regla de calidad, que los ciudadanos nacionalizados peruanos no deben iniciar trámites que les otorguen una calidad migratoria o un proceso de regularización tras su nacionalización.
-- ===============================================================================================================================================================================================================

-- 2.1
DROP TABLE IF EXISTS #tmp_tram_nac_aprobados
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   t.nIdTipoTramite,
   tn.sEstadoActual,
   ti.sNumeroTitulo,
   [dFechaTramite] = t.dFechaHora,
   [dFechaEntregaTitulo] = (

                     SELECT f.dFechaHoraFin
                     FROM (

                           SELECT
                              TOP 10
                              etn.dFechaHoraFin,
                              [#] = ROW_NUMBER() OVER (PARTITION BY etn.sNumeroTramite ORDER BY etn.nIdEtapaTramite DESC)
                           FROM SimEtapaTramiteNac etn
                           WHERE
                              etn.sNumeroTramite = t.sNumeroTramite
                              AND etn.bActivo = 1
                              AND etn.nIdEtapa = 42 -- 42 | ENTREGA DE TITULO
                              AND etn.sEstado = 'F'

                     ) f
                     WHERE f.[#] = 1

   )

   INTO #tmp_tram_nac_aprobados
FROM SimTramite t
JOIN SimTramiteNac tn ON t.sNumeroTramite = tn.sNumeroTramite
JOIN SimTituloNacionalidad ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   tn.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (69, 71, 72, 73, 76, 78, 79) -- Trámmites de nacionalización
   AND ti.bAnulado = 0 -- Título válido
   AND ti.bEntregado = 1 -- Título entregado
   

-- 2.2 Trámites de `Inm` posterior a fecha de `Entrega título` .
DROP TABLE IF EXISTS #tmp_tram_nac_aprobados_mas_inm_post
SELECT 

   t.uIdPersona,
   t.sNumeroTramite,
   [dFechaTramite] = t.dFechaHora,
   [sTipoTramite] = tt.sDescripcion,
   ti.sEstadoActual

   INTO #tmp_tram_nac_aprobados_mas_inm_post
FROM #tmp_tram_nac_aprobados tn
JOIN SimTramite t ON tn.uIdPersona = t.uIdPersona
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= tn.dFechaEntregaTitulo -- Trámites posteriores
   AND t.nIdTipoTramite IN (
                              55,  -- SOLICITUD DE CALIDAD MIGRATORIA
                              57,  -- PRORROGA DE RESIDENCIA
                              58,  -- CAMBIO DE CALIDAD MIGRATORIA
                              64,  -- DUPLICADO DE CE
                              111, -- ACTUALIZACIÓN CON EMISIÓN DE DOCUMENTO
                              113, -- REGULARIZACION DE EXTRANJEROS
                              117, -- RENOVACION DE CARNÉ DE EXTRANJERÍA
                              118, -- EXPEDICIÓN DE CARNÉ DE EXTRANJERÍA
                              126  -- PERMISO TEMPORAL DE PERMANENCIA - RS109
   )



-- 2.3 Nacionalizados con trámites `Inm` posterior a fecha de `Entrega título` .

SELECT

   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Numero Trámite] = n.sNumeroTramite,
   [Estado Trámite] = n.sEstadoActual,
   [Tipo Nacionalización] = tt.sDescripcion,
   [Fecha Trámite] = CONVERT(DATE, n.dFechaTramite),
   [Fecha Entrega Título] = CONVERT(DATE, n.dFechaEntregaTitulo),
   [Trámites de Inmigración] = (
                                 SELECT 
                                    [sNumeroTramite] = i.sNumeroTramite,
                                    [dFechaTramite] = i.dFechaTramite,
                                    [sTipoTramite] = i.sTipoTramite,
                                    [sEstadoActual] = i.sEstadoActual
                                 FROM #tmp_tram_nac_aprobados_mas_inm_post i
                                 WHERE i.uIdPersona = n.uIdPersona
                                 FOR XML PATH('')
   )

FROM #tmp_tram_nac_aprobados n
JOIN SimTipoTramite tt ON n.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona pe ON n.uIdPersona = pe.uIdPersona
WHERE
   EXISTS ( -- Registran trámites de `Inm` posterior ...
            SELECT 1
            FROM #tmp_tram_nac_aprobados_mas_inm_post i
            WHERE i.uIdPersona = n.uIdPersona
   )

-- =====================================================================================================================================================================


-- 3. Se establece como regla de calidad que los países asociados al continente europeo no deberán registrar movimientos migratorios a través del transporte Fluvial o Lacustre.
-- =================================================================================================================================================================================

-- 3.1
SELECT 
 
   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   [Tipo Movimiento] = mm.sTipo,
   [Fecha Control] = mm.dFechaControl,
   [Via Transporte] = mm.sIdViaTransporte,
   [Pais Movimiento] = mm.sIdPaisMov,
   [Dependencia] = mm.sIdDependencia

FROM SimMovMigra mm
join SimPais p ON mm.sIdPaisMov = p.sIdPais
join SimPersona pe ON  mm.uIdPersona = pe.uIdPersona
join SimContinente c ON p.nIdContinente = c.nIdContinente
WHERE 
   mm.bAnulado = 0 
   AND mm.bTemporal = 0
   AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
   AND c.nIdContinente = 8 -- EUROPA
   AND mm.sIdViaTransporte IN (
                                 'F', -- F | FLUVIAL
                                 'L' -- L | LACUSTRE
   )


-- =====================================================================================================================================================================






-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      1.  Pasaportes electrónicos con trámite de anulación, pero aún activos en los datos generales.
-- ======================================================================================================================================================================== */


-- 1. Detección:

-- 1.1. Identificar Pasaportes electrónicos ANULADOS.

-- v1
DROP TABLE IF EXISTS #tmp_pase_anulados
SELECT 
   t.uIdPersona,
   pa.*
   INTO #tmp_pase_anulados
FROM SimPasaporte pa
JOIN SimTramite t ON pa.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.nIdTipoTramite = 4 -- 4 | ANULACION DE PASAPORTE
   AND ISNUMERIC(pa.sPasNumero) = 1
   AND LEN(pa.sPasNumero) = 9
   AND pa.sPasNumero LIKE '1[1-2]%'

-- v2
DROP TABLE IF EXISTS #tmp_pase_anulados_v2
SELECT
   t.uIdPersona,
   pa.*
   INTO #tmp_pase_anulados_v2
FROM SimTramitePas pa
JOIN SimTramite t ON pa.sNumeroTramite = t.sNumeroTramite
WHERE
   t.nIdTipoTramite = 4 -- 4 | ANULACION DE PASAPORTE
   AND ISNUMERIC(pa.sPasNumero) = 1
   AND LEN(pa.sPasNumero) = 9
   AND pa.sPasNumero LIKE '1[1-2]%'

CREATE NONCLUSTERED INDEX ix_tmp_pase_anulados_v2 
   ON #tmp_pase_anulados_v2(uIdPersona)


-- 1.2. ...
DROP TABLE IF EXISTS #tmp_pase_anulados_final
SELECT
   a.*
   INTO #tmp_pase_anulados_final
FROM #tmp_pase_anulados a
WHERE
   EXISTS ( -- Documento activo

         SELECT 1
         FROM SimDocPersona dp
         WHERE
            dp.uIdPersona = a.uIdPersona
            AND dp.sIdDocumento = 'PAS'
            AND dp.sNumero = a.sPasNumero
            AND dp.bActivo = 1

   )

SELECT COUNT(1) FROM #tmp_pase_anulados_final

-- 2. Actualización:
BEGIN TRY

   BEGIN TRAN
   UPDATE SimDocPersona
      SET bActivo = 0
   FROM SimDocPersona dp
   JOIN #tmp_pase_anulados_v2 a ON dp.uIdPersona = a.uIdPersona
                                 AND dp.sIdDocumento = 'PAS'
                                 AND dp.sNumero = a.sPasNumero

   COMMIT TRAN
END TRY
BEGIN CATCH
   ROLLBACK TRAN
   SELECT ERROR_NUMBER(), ERROR_LINE(), ERROR_MESSAGE()
END CATCH




-- ======================================================================================================================================================================== */

