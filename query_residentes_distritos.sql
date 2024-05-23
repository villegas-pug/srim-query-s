USE SIM
GO

/* » 1. Extranjeros con calidad migratoria residente y con permiso temporal de permanencia, El distrito donde viven.
-- ==================================================================================================================================== */

-- 1.1
EXEC sp_help xTotalExtranjerosPeru
SELECT TOP 10 * FROM xTotalExtranjerosPeru e ORDER BY e.dFechaIngreso DESC

DROP TABLE IF EXISTS #tmp_residentes
SELECT 

   [Id Persona] = r.uIdPersona,
   /* [Nombre] = r.Nombre,
   [Paterno] = r.Paterno,
   [Materno] = r.Materno, */
   [Sexo] = r.Sexo,
   [Fecha Nacimiento] = r.FechaNacimiento,
   [Pais Nacionalidad] = UPPER(r.Nacionalidad),
   [Calidad Migratoria] = r.CalidadMigratoria,

   -- Dirección
   [Distrito] = su.sNombre
   -- [Distrito Ubigeo] = IIF(se.sIdUbigeoDomicilio LIKE '14%', 'LIMA', su.sNombre)

   INTO #tmp_residentes
FROM xTotalExtranjerosPeru r
JOIN SimExtranjero se ON r.uIdPersona = se.uIdPersona
JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
WHERE
   r.uIdPersona != '00000000-0000-0000-0000-000000000000'
   -- r.uIdPersona = '00000000-0000-0000-0000-000000000000'
   -- AND r.Nacionalidad = 'CHILENA'
   AND r.CalidadTipo IN ('N', 'R')

-- Test ...
-- 1.1.1
SELECT TOP 10 * FROM xTotalExtranjerosPeru r
SELECT

   r.Distrito,
   [Total] = COUNT(1)

FROM xTotalExtranjerosPeru r
GROUP BY r.Distrito
ORDER BY [Total] DESC

SELECT

   [Calidad Migratoria] = r.CalidadMigratoria,
   [Total] = COUNT(1)

FROM xTotalExtranjerosPeru r
WHERE
   -- r.CalidadTipo IN ('N', 'R')
   -- r.CalidadTipo IN ('N')
   r.CalidadTipo IN ('T')
GROUP BY r.CalidadMigratoria
ORDER BY [Total] DESC

-- 2.1: Distritos ...
/* SELECT 
   -- r.Distrito,
   r.[Pais Nacionalidad],
   r.[Distrito],
   [Total] = COUNT(1)
FROM #tmp_residentes r
GROUP BY
   -- r.Distrito,
   r.[Pais Nacionalidad],
   r.[Distrito]
ORDER BY
   [Total] DESC */


-- Test ...
SELECT TOP 10 * FROM xTotalExtranjerosPeru e
SELECT TOP 10 * FROM SimExtranjero se
SELECT TOP 10 * FROM SimPersona


-- Población extranjeros
SELECT 
   su.sNombre,
   COUNT(1)
FROM xTotalExtranjerosPeru e
JOIN SimExtranjero se ON e.uIdPersona = se.uIdPersona
JOIN SimUbigeo su ON se.sIdUbigeoDomicilio = su.sIdUbigeo
GROUP BY
   su.sNombre
ORDER BY 2 DESC

-- Población Nacional
SELECT 
   u.sNombre,
   COUNT(1)
FROM SimPersona p
JOIN SimPeruano pe ON p.uIdPersona = pe.uIdPersona
JOIN SimUbigeo u ON pe.sIdUbigeoDomicilio = u.sIdUbigeo
WHERE
   p.bActivo = 1
   AND p.sIdPaisNacionalidad = 'PER'
GROUP BY
   u.sNombre
ORDER BY 2 DESC

-- ==================================================================================================================================== */


/* 
   2. ...
-- ==================================================================================================================================== */

-- ...
DROP TABLE BD_SIRIM.dbo.RimTotalExtranjerosPeru

DROP TABLE IF EXISTS BD_SIRIM.dbo.RimTotalExtranjerosPeru
SELECT e.* INTO BD_SIRIM.dbo.RimTotalExtranjerosPeru FROM xTotalExtranjerosPeru e


-- Dep's ...
/* 
   → CREATE SYNONYM xTotalExtranjerosPeru
     FOR BD_SIRIM.dbo.RimTotalExtranjerosPeru 

   → DROP SYNONYM xTotalExtranjerosPeru
   → SELECT COUNT(1) FROM xTotalExtranjerosPeru e
   → SELECT TOP 100 e.* FROM xTotalExtranjerosPeru e
*/


-- ...
-- 1: Crear tablas `tmp's` ...
DROP TABLE IF EXISTS #tmp_pda
SELECT 
   sapda.uIdPersona,
   sapda.sNomBeneficiario,
   sapda.sPriApeBeneficiario,
   sapda.sSegApeBeneficiario,
   sapda.dFecNacBeneficiario,
   sapda.sIdPaisDocBeneficiario,
   sdpda.sIdUbigeoBeneficiario,
   sdpda.sDireccionBeneficiario,
   sapda.dFechaHoraAud
   INTO #tmp_pda
FROM [dbo].[SimSistPersonaDatosAdicionalPDA] sapda
JOIN [dbo].[SimDireccionPDA] sdpda ON sapda.nIdCitaVerifica = sdpda.nIdCitaVerifica
                                      AND sapda.nIdTipoTramite = sdpda.nIdTipoTramite

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_pda_uIdPersona
   ON #tmp_pda(uIdPersona);

CREATE NONCLUSTERED INDEX IX_tmp_pda_datos
   ON #tmp_pda(sNomBeneficiario, sPriApeBeneficiario, sSegApeBeneficiario, dFecNacBeneficiario, sIdPaisDocBeneficiario);

CREATE NONCLUSTERED INDEX IX_tmp_pda_datos2
   ON #tmp_pda(sNomBeneficiario, sPriApeBeneficiario, sSegApeBeneficiario);


DROP TABLE IF EXISTS #tmp_simpersona
SELECT 
   sper.uIdPersona,
   sper.sNombre,
   sper.sPaterno,
   sper.sMaterno,
   sper.dFechaNacimiento,
   sper.sIdPaisNacionalidad,
   se.sIdUbigeoDomicilio,
   se.sDomicilio,
   sper.dFechaHoraAud
   INTO #tmp_simpersona
FROM SimPersona sper
LEFT JOIN SimExtranjero se ON sper.uIdPersona = se.uIdPersona
WHERE
   sper.bActivo = 1
   AND sper.sIdPaisNacionalidad != 'PER'

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_simpersona_uIdPersona 
   ON #tmp_simpersona(uIdPersona);

CREATE NONCLUSTERED INDEX IX_tmp_simpersona_datos 
   ON #tmp_simpersona(sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad);

-- Test ...

-- 2: Union de tmp's ...
DROP TABLE IF EXISTS #tmp_simextranjero_final
SELECT 
   se3.*
   INTO #tmp_simextranjero_final
FROM (

   SELECT 
      se2.*,
      [nOrdenAud] = ROW_NUMBER() OVER (PARTITION BY se2.uIdPersonaValido ORDER BY se2.dFechaHoraAud DESC)
   FROM (

      SELECT
         se1.*,
         -- [nOrdenAud] = ROW_NUMBER() OVER (PARTITION BY se1.uIdPersona ORDER BY se1.dFechaHoraAud DESC)
         -- 1. Extranjero en `PDA` con uId 0000-000... y en SimPersona, tiene uId Valido.
         [uIdPersonaValido] = FIRST_VALUE(se1.uIdPersona) OVER (PARTITION BY
                                                                se1.sNombre,
                                                                se1.sPaterno,
                                                                se1.sMaterno,
                                                                se1.dFechaNacimiento,
                                                                se1.sIdPaisNacionalidad
                                                                ORDER BY se1.uIdPersona DESC)

      FROM (

         SELECT * FROM #tmp_simpersona
         UNION ALL
         SELECT * FROM #tmp_pda

      ) se1

   ) se2
   WHERE
      se2.uIdPersonaValido != '00000000-0000-0000-0000-000000000000'
      -- AND (se1.sDomicilio != '' AND se1.sDomicilio IS NOT NULL)
      AND (LEN(se2.sDomicilio) > 4 AND se2.sDomicilio IS NOT NULL)
      -- AND (se1.sIdUbigeoDomicilio != '' AND se1.sIdUbigeoDomicilio IS NOT NULL)

) se3
WHERE
   se3.nOrdenAud = 1

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_simextranjero_final
   ON #tmp_simextranjero_final(uIdPersonaValido);

-- 3: Inserta nueva columna en `xTotalExtranjerosPeru` ...
ALTER TABLE BD_SIRIM.dbo.RimTotalExtranjerosPeru
   ADD sDireccion VARCHAR(MAX) NULL

-- 4: ...
/* 
   → UPDATE BD_SIRIM.dbo.RimTotalExtranjerosPeru
     SET sDireccion = ''
*/

UPDATE BD_SIRIM.dbo.RimTotalExtranjerosPeru
   SET sDireccion = (
                        CASE 
                           WHEN (e2.sIdUbigeoDomicilio != '000000' 
                                 AND e2.sIdUbigeoDomicilio != '' 
                                 AND e2.sIdUbigeoDomicilio IS NOT NULL) 
                              THEN CONCAT(e2.sDomicilio, ', ', su.sNombre)
                           ELSE e2.sDomicilio
                        END
                     )
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e1
JOIN #tmp_simextranjero_final e2 ON e1.uIdPersona = e2.uIdPersonaValido
LEFT JOIN SimUbigeo su ON e2.sIdUbigeoDomicilio = su.sIdUbigeo

-- Test ...
SELECT TOP 100 e.* FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e

SELECT COUNT(1) FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e
WHERE 
   -- LEN(e.sDireccion) > 0
   e.sDireccion IS NULL

SELECT TOP 100 e.* FROM #tmp_simextranjero_final e

SELECT e.* FROM #tmp_simextranjero_final e
WHERE e.sIdUbigeoDomicilio = '000000'


/* 
   2910b5fa-4b83-4ff7-a763-f573e2c23e54
   2505d2a8-e40b-4deb-83f7-c96a22ee0945
   6d379161-c1a6-4c19-9b8f-341510f0b80b
   f7bd18ef-c232-44b8-8184-6fc910f531d0
  */

  SELECT * FROM SimPersona se
  WHERE se.uIdPersona = '2910b5fa-4b83-4ff7-a763-f573e2c23e54'

  SELECT * FROM SimExtranjero se
  WHERE se.uIdPersona = '2910b5fa-4b83-4ff7-a763-f573e2c23e54'

  SELECT * FROM #tmp_pda se
  WHERE se.uIdPersona = '2910b5fa-4b83-4ff7-a763-f573e2c23e54'

-- 
SELECT 
   e.uIdPersona, 
   e.sDireccion 
   /* e.CalidadMigratoria,
   [nTotal] = COUNT(1) */
FROM xTotalExtranjerosPeru e
-- JOIN SimPersona sper ON e.uIdPersona = sper.uIdPersona
-- JOIN SimCalidadMigratoria scm ON sper.nIdCalidad = scm.nIdCalidad
WHERE 
   LEN(e.sDireccion) <= '2'
   -- e.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND e.CalidadMigratoria IN ('CPP-DS10', 'PTP-RS109')
GROUP BY
   e.CalidadMigratoria
ORDER BY 2 DESC

SELECT e.* FROM (

   SELECT * FROM #tmp_simpersona
   UNION ALL
   SELECT * FROM #tmp_pda

) e 
WHERE
   e.sNombre = 'NORMELY YIMILYN'
   AND e.sPaterno = 'CASTILLO'
   AND e.sMaterno = 'DE BELLO'

SELECT * FROM #tmp_simpersona se WHERE se.uIdPersona = '4f451221-eb30-437f-91cb-a05748ed9cf8'
SELECT * FROM #tmp_pda pda WHERE pda.uIdPersona = '4f451221-eb30-437f-91cb-a05748ed9cf8'
SELECT * FROM #tmp_simextranjero_final pda WHERE pda.uIdPersona = '4f451221-eb30-437f-91cb-a05748ed9cf8'

SELECT * FROM #tmp_simextranjero_final pda WHERE pda.uIdPersonaValido = '2146b663-fa60-4e83-b9fb-e3db28f1e65b'

SELECT COUNT(1) FROM SimPersonaDatosAdicional
SELECT TOP 100 * FROM SimPersonaDatosAdicional

/* 
ec4e50e9-be8b-42ea-af53-a15c80811a1a
1edc6fa3-064b-4b90-b212-0a5f13e3c77e
8a1ac177-9349-4015-97e5-6cfc9c96c436 */


SELECT * FROM #tmp_pda st
WHERE
   -- st.uIdPersona = 'ec4e50e9-be8b-42ea-af53-a15c80811a1a'
   st.sNomBeneficiario = 'MERCEDES GUILLERMINA'
   AND st.sPriApeBeneficiario = 'CANDELO'

-- 1edc6fa3-064b-4b90-b212-0a5f13e3c77e
SELECT pda.* FROM SimPersona sper
JOIN #tmp_pda pda ON sper.sNombre = pda.sNomBeneficiario
                     AND sper.sPaterno = pda.sPriApeBeneficiario
                     AND sper.sMaterno = pda.sSegApeBeneficiario
                     AND sper.dFechaNacimiento = pda.dFecNacBeneficiario
                     AND sper.sIdPaisNacionalidad = pda.sIdPaisDocBeneficiario
WHERE
   sper.sNombre = 'MERCEDES GUILLERMINA'
   AND sper.sPaterno = 'CANDELO'

SELECT TOP 100 * FROM xTotalExtranjerosPeru se
WHERE
   se.uIdPersona = 'ec4e50e9-be8b-42ea-af53-a15c80811a1a'

SELECT * FROM #tmp_simextranjero_final se
WHERE
   se.uIdPersonaValido = 'ec4e50e9-be8b-42ea-af53-a15c80811a1a'

SELECT * FROM SimExtranjero se
WHERE
   se.uIdPersona = 'ec4e50e9-be8b-42ea-af53-a15c80811a1a'


-- ...
SELECT TOP 0 [nId] = 0, [uId] = sper.uIdPersona INTO #tmp FROM SimPersona sper
INSERT INTO #tmp
   VALUES
      (1, '00000000-0000-0000-0000-000000000000'),
      (1, 'ec4e50e9-be8b-42ea-af53-a15c80811a1a')

SELECT 
   tbl.uId,
   [uIdValido] = FIRST_VALUE(tbl.uId) OVER (PARTITION BY tbl.nId ORDER BY tbl.uId DESC)
FROM #tmp tbl
-- ORDER BY tbl.uId ASC

-- ====================================================================================================================================

SELECT * FROM SimPersona sper WHERE sper.sNumDocIdentidad = '09361458'

SELECT 
   sper.sNombre, 
   sper.sPaterno, 
   sper.sMaterno, 
   spe.sDomicilio,
   spe.sTelefono
FROM SimPersona sper 
JOIN SimPeruano spe ON sper.uIdPersona = spe.uIdPersona
WHERE 
   sper.sPaterno = 'CARDENAS'
   AND sper.sMaterno = 'ALMONACID'
   AND sper.sIdPaisNacionalidad = 'PER'