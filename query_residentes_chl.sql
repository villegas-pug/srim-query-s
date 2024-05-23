USE SIM
GO

SELECT TOP 100 * FROM xTotalExtranjerosPeru e
WHERE
   e.uIdPersona != '00000000-0000-0000-0000-000000000000'
ORDER BY e.dFechaIngreso DESC


-- Aux ...
SELECT * FROM SimPais sp WHERE sp.sNombre LIKE 'Chi%'

/* » ... 
-- ==================================================================================================================================== */

-- 1. Chilenos residentes y su numdoc de viaje en movmigra y documentos en su historial.
-- CHL | CHILE | CHILENA

-- EXEC sp_help SimPersona

DROP TABLE IF EXISTS #tmp_residentes_chl
SELECT 

   sper.uIdPersona,
   sper.sPaterno,
   sper.sMaterno,
   sper.sNombre,
   sper.sSexo,
   sper.dFechaNacimiento,
   sper.sIdPaisNacimiento,
   sper.sIdPaisResidencia,
   sper.sIdPaisNacionalidad,
   [sCalidadMigratoria] = r.CalidadMigratoria,
   [dFechaUltimoMovMigra] = (
                              SELECT TOP 1 smm.dFechaControl FROM SimMovMigra smm
                              WHERE
                                 smm.bAnulado = 0
                                 AND smm.bTemporal = 0
                                 AND smm.uIdPersona = r.uIdPersona
                              ORDER BY
                                 smm.dFechaControl DESC
                           ),
   [sDocumentoViaje] = (
                           SELECT dbo.fn_replace_xml(
                                                (
                                                   SELECT
                                                      smm.sIdDocumento, 
                                                      smm.sNumeroDoc 
                                                   FROM SimMovMigra smm 
                                                   WHERE
                                                      smm.bAnulado = 0
                                                      AND smm.bTemporal = 0
                                                      AND smm.uIdPersona = r.uIdPersona
                                                   GROUP BY
                                                      smm.sIdDocumento,
                                                      smm.sNumeroDoc
                                                   FOR XML PATH('')
                                                )
                                          )

                        ),
   [sHistorialDocumentos] = (
                                 SELECT dbo.fn_replace_xml(
                                                      (
                                                         SELECT
                                                            sdp.sIdDocumento, 
                                                            sdp.sNumero 
                                                         FROM SimDocPersona sdp 
                                                         WHERE
                                                            sdp.bActivo = 1
                                                            AND sdp.uIdPersona = r.uIdPersona
                                                         GROUP BY
                                                            sdp.sIdDocumento,
                                                            sdp.sNumero
                                                         FOR XML PATH('')
                                                      )
                                                )

                           )
   INTO #tmp_residentes_chl
FROM xTotalExtranjerosPeru r
JOIN SimPersona sper ON r.uIdPersona = sper.uIdPersona
WHERE
   r.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND r.Nacionalidad = 'CHILENA'
   AND r.CalidadTipo IN ('N', 'R')

-- Test ...
SELECT TOP 10 * FROM #tmp_residentes_chl
SELECT r_chl.* FROM #tmp_residentes_chl r_chl

-- 2
-- <sIdDocumento>PAS</sIdDocumento><sNumeroDoc>P02148431</sNumeroDoc><sIdDocumento>PAS</sIdDocumento><sNumeroDoc>P12360850</sNumeroDoc>

CREATE OR ALTER FUNCTION fn_replace_xml(
   @xmlField AS XML
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
   
   DECLARE @strField VARCHAR(MAX)

   -- 1: ...
   -- sNumero
   SET @strField = REPLACE(CAST(@xmlField AS VARCHAR(MAX)), '<sIdDocumento>', '')
   SET @strField = REPLACE(@strField, '<sNumeroDoc>', '')
   SET @strField = REPLACE(@strField, '<sNumero>', '')

   -- 2: ...
   -- </sIdDocumento> → -
   -- </sNumeroDoc> → ;
   SET @strField = REPLACE(@strField, '</sIdDocumento>', '-')
   SET @strField = REPLACE(@strField, '</sNumeroDoc>', ';')
   SET @strField = REPLACE(@strField, '</sNumero>', ';')

   -- 3: Final ...
   SET @strField = SUBSTRING(@strField, 1, LEN(@strField) - 2)
   SET @strField = REPLACE(@strField, ' ', '')

   RETURN @strField

END

-- Test ... 
SELECT dbo.fn_replace_xml('<sIdDocumento>PAS</sIdDocumento><sNumeroDoc>P02148431</sNumeroDoc><sIdDocumento>PAS</sIdDocumento><sNumeroDoc>P12360850</sNumeroDoc>')


-- 2. Chilenos que tiene como doc de a¿viaje 8 digitos, año >=2022.

SELECT mm2.* FROM (

   SELECT
      sper.uIdPersona,
      sper.sNombre,
      sper.sPaterno,
      sper.sMaterno,
      sper.sSexo,
      sper.dFechaNacimiento,
      sper.sIdPaisNacimiento,
      sper.sIdPaisResidencia,
      sper.sIdPaisNacionalidad,
      [sDocumentoViaje] = smm.sIdDocumento,
      [sNumDocViaje] = CONCAT('''', smm.sNumeroDoc),
      smm.dFechaControl,
      [nFila_cm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona, smm.sNumeroDoc ORDER BY smm.dFechaControl DESC)
   FROM SimMovMigra smm
   JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
   WHERE
      smm.bAnulado = 0
      AND smm.bTemporal = 0
      AND sper.sIdPaisNacionalidad = 'CHL'
      AND smm.dFechaControl BETWEEN '2022-11-01 00:00:00.000' AND '2023-11-01 23:59:59.999'
      AND LEN(REPLACE(smm.sNumeroDoc, ' ', '')) = 8

) mm2
WHERE
   mm2.nFila_cm = 1
ORDER BY
   mm2.uIdPersona

-- 3. Chilenos que tiene como doc de a¿viaje 9 digitos, año >=2022.

SELECT mm2.* FROM (

   SELECT
      sper.uIdPersona,
      sper.sNombre,
      sper.sPaterno,
      sper.sMaterno,
      sper.sSexo,
      sper.dFechaNacimiento,
      sper.sIdPaisNacimiento,
      sper.sIdPaisResidencia,
      sper.sIdPaisNacionalidad,
      [sDocumentoViaje] = smm.sIdDocumento,
      [sNumDocViaje] = smm.sNumeroDoc,
      smm.dFechaControl,
      [nFila_cm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
   FROM SimMovMigra smm
   JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
   WHERE
      smm.bAnulado = 0
      AND smm.bTemporal = 0
      AND sper.sIdPaisNacionalidad = 'CHL'
      AND smm.dFechaControl BETWEEN '2022-11-01 00:00:00.000' AND '2023-11-01 23:59:59.999'
      AND LEN(REPLACE(smm.sNumeroDoc, ' ', '')) = 9

) mm2
WHERE
   mm2.nFila_cm = 1

-- 4: Final: Registros duplicados por datos ...

SELECT mm3.* FROM (

   SELECT 
      mm2.*,

      -- Aux 1
      [nDuplicado] = COUNT(1) OVER (PARTITION BY mm2.sNombre_dx, mm2.sPaterno_dx, mm2.sMaterno_dx, mm2.dFechaNacimiento),

      -- Aux 2
      [sDocumentosViaje] = (
                              SELECT dbo.fn_replace_xml(
                                                   (
                                                      SELECT
                                                         smm.sIdDocumento, 
                                                         smm.sNumeroDoc 
                                                      FROM SimMovMigra smm
                                                      WHERE
                                                         smm.bAnulado = 0
                                                         AND smm.bTemporal = 0
                                                         AND smm.uIdPersona = mm2.uIdPersona
                                                      GROUP BY
                                                         smm.sIdDocumento,
                                                         smm.sNumeroDoc
                                                      FOR XML PATH('')
                                                   )
                                             )

                        ),
   [sHistorialDocumentos] = (
                                 SELECT dbo.fn_replace_xml(
                                                      (
                                                         SELECT
                                                            sdp.sIdDocumento, 
                                                            sdp.sNumero 
                                                         FROM SimDocPersona sdp 
                                                         WHERE
                                                            sdp.bActivo = 1
                                                            AND sdp.uIdPersona = mm2.uIdPersona
                                                         GROUP BY
                                                            sdp.sIdDocumento,
                                                            sdp.sNumero
                                                         FOR XML PATH('')
                                                      )
                                                )

                           )
   FROM (

      SELECT
      
         sper.uIdPersona,
         sper.sNombre,
         sper.sPaterno,
         sper.sMaterno,
         sper.sSexo,
         sper.dFechaNacimiento,
         sper.sIdPaisNacimiento,
         sper.sIdPaisResidencia,
         sper.sIdPaisNacionalidad,
         [sUltimoDocumentoViaje] = smm.sIdDocumento,
         [sUltimoNumDocViaje] = CONCAT('''', smm.sNumeroDoc),
         [dUltimaFechaControl] = smm.dFechaControl,

         -- Aux 1
         [nFila_cm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC),

         -- Aux 2
         [sNombre_dx] = SOUNDEX(sper.sNombre),
         [sPaterno_dx] = SOUNDEX(sper.sPaterno),
         [sMaterno_dx] = SOUNDEX(sper.sMaterno)

      FROM SimMovMigra smm
      JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
      WHERE
         smm.bAnulado = 0
         AND smm.bTemporal = 0
         AND sper.sIdPaisNacionalidad = 'CHL'
         AND smm.dFechaControl BETWEEN '2022-11-01 00:00:00.000' AND '2023-11-01 23:59:59.999'
         -- AND smm.sIdDocumento NOT IN ('NNN', 'OTROS')
         AND LEN(REPLACE(smm.sNumeroDoc, ' ', '')) = 8
         -- AND LEN(REPLACE(smm.sNumeroDoc, ' ', '')) = 9

   ) mm2
   WHERE
      mm2.nFila_cm = 1

) mm3
ORDER BY
   mm3.sNombre, mm3.sPaterno, mm3.sMaterno, mm3.dFechaNacimiento

-- Test ...

-- =========================================================================================================================================================================== */