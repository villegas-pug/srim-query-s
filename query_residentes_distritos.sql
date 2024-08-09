USE SIM
GO

/* » 1. Extranjeros con calidad migratoria residente y con permiso temporal de permanencia, El distrito donde viven.
-- ==================================================================================================================================== */

-- 1.1. Sim

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
   AND r.CalidadTipo IN ('N', 'R')


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
   2. Bulk: SIM.dbo.xTotalExtranjerosPeru ► BD_SIRIM.dbo.RimTotalExtranjerosPeru
-- ==================================================================================================================================== */

-- 1. SIM.dbo.xTotalExtranjerosPeru to BD_SIRIM.dbo.RimTotalExtranjerosPeru ...
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimTotalExtranjerosPeru
SELECT e.* INTO BD_SIRIM.dbo.RimTotalExtranjerosPeru FROM xTotalExtranjerosPeru e

SELECT COUNT(1)
FROM xTotalExtranjerosPeru x
WHERE x.uIdPersona = '00000000-0000-0000-0000-000000000000'

-- 2: PDA `tmp` ...
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


-- 3: SimPersona `tmp` ...
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
   AND sper.sIdPaisNacionalidad NOT IN ('PER', 'NNN')

-- Index ...
CREATE NONCLUSTERED INDEX IX_tmp_simpersona_uIdPersona 
   ON #tmp_simpersona(uIdPersona);

CREATE NONCLUSTERED INDEX IX_tmp_simpersona_datos 
   ON #tmp_simpersona(sNombre, sPaterno, sMaterno, dFechaNacimiento, sIdPaisNacionalidad);

-- 4: Union de tmp's ...
DROP TABLE IF EXISTS #tmp_simextranjero_final
SELECT 
   r3.*
   INTO #tmp_simextranjero_final
FROM (

   SELECT 
      r2.*,
      [nOrdenAud] = ROW_NUMBER() OVER (PARTITION BY r2.uIdPersonaValido ORDER BY r2.dFechaHoraAud DESC)
   FROM (

      SELECT
         r1.*,
         -- [nOrdenAud] = ROW_NUMBER() OVER (PARTITION BY se1.uIdPersona ORDER BY se1.dFechaHoraAud DESC)
         -- 1. Extranjero en `PDA` con uId `0000-000 ...` y registra uId Valido en SimPersona.
         [uIdPersonaValido] = FIRST_VALUE(r1.uIdPersona) OVER (
                                                                  PARTITION BY
                                                                     r1.sNombre,
                                                                     r1.sPaterno,
                                                                     r1.sMaterno,
                                                                     r1.dFechaNacimiento,
                                                                     r1.sIdPaisNacionalidad
                                                                  ORDER BY 
                                                                     r1.uIdPersona DESC
                                                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                               )

      FROM ( -- Union `tmp's` ...

         SELECT * FROM #tmp_simpersona
         UNION ALL
         SELECT * FROM #tmp_pda p

      ) r1
      WHERE
         r1.sDomicilio != '' AND r1.sDomicilio IS NOT NULL
         -- AND (r1.sIdUbigeoDomicilio != '000000' AND  r1.sIdUbigeoDomicilio IS NOT NULL)

   ) r2
   /* WHERE
      r2.uIdPersonaValido != '00000000-0000-0000-0000-000000000000' */
      -- AND (LEN(r2.sDomicilio) > 4 AND r2.sDomicilio IS NOT NULL)
      -- AND (se1.sIdUbigeoDomicilio != '' AND se1.sIdUbigeoDomicilio IS NOT NULL)

) r3
WHERE
   r3.nOrdenAud = 1

SELECT TOP 10 * 
FROM xTotalExtranjerosPeru

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

SELECT TOP 10  r.Ubigeo FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru r

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



