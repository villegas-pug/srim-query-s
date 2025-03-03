USE SIM
GO

-- EXEC sp_help SimImagenExtranjero
/*
   Caso 1:
   -	WILMER JHONGLY PARISCA PEREZ, CIP N° 31222521
   -	VICTOR DAVID SERRANO ALFONZO, CIP 24922247 

   Caso 2:
   1. LAYME TAMAYO JAVIER | 43164873
   2. APOLINARIO REYMUNDO FRANKLIN | 45248800
   3. RICCE TORRES ESPERANZA FELICITA | 45248799
   4. APOLINARIO REYMUNDO FLORI DIANA | 47963280
   5. LAYME TAMAYO MOISES | 47370678
   6. LAYME TAMAYO PRINCESA BEATRIZ | 71234099

   '51de7f95-f411-4507-85e5-6f185b8c36b5',
   '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
   '83599bf3-e722-4171-a4c5-0d58e1afcb3c'

   -- 01Abr2024
      → RANGEL CARLOS MANUEL , PASAPORTE 087363922
      → CHARLES OSWALDO CHAVEZ

   -- 12Nov2024
      → ELI THOMAS HARRY con Pasaporte PB5870950
      → WILMER ENRIQUE CHOURIO GUTIÉRREZ CEE 001948610.

   
   */
SELECT
   p.uIdPersona,
   p.sNombre, 
   p.sPaterno, 
   p.sMaterno, 
   p.dFechaNacimiento, 
   p.sIdPaisNacionalidad,
   dp.sIdDocumento,
   dp.sNumero,
   ie.dFechaHoraAud,
   ie.nIdImagen,
   ie.sTipo,
   ie.xImagen,
   [sDedo] = de.sNombre,
   ie.sNumeroCarnet,
   ie.bUltimo,
   ie.bIrregular
FROM SimPersona p
LEFT JOIN SimDocPersona dp ON p.uIdPersona = dp.uIdPersona
LEFT JOIN SimImagenExtranjero ie ON p.uIdPersona = ie.uIdPersona
LEFT JOIN SimDedo de ON ie.sIdDedo = de.sIdDedo
WHERE
   p.sNombre LIKE 'ELI%'
   AND p.sPaterno LIKE 'HARRY'
   -- AND p.sMaterno LIKE 'GAÑA'
   /* dp.sIdDocumento = 'PAS'
   AND dp.sNumero LIKE 'PB5670950' */
   /* dp.sNumero IN (
      '43164873',
      '45248800',
      '45248799',
      '47963280',
      '47370678',
      '71234099'
   ) */
   AND ie.bUltimo = 1


-- Buscar datos adicionales: `PERUANO` ...
EXEC sp_help SimPeruano
SELECT
   [Nombre] = p.sNombre,
   [Paterno] = p.sPaterno,
   [Materno] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Calidad] = cm.sDescripcion,
   [Pais Nacimiento] = p.sIdPaisNacimiento,
   [Pais Residencia] = p.sIdPaisResidencia,
   [Pais Nacionalidad] = p.sIdPaisNacionalidad,
   [Estado Civil] = p.sIdEstadoCivil,
   [Profesion] = pr.sDescripcion,
   [Doc Identidad] = p.sIdDocIdentidad,
   [Num Doc Identidad] = p.sNumDocIdentidad,

   -- Datos adicional 
   [Nombre Padre] = pe.sNombrePadre,
   [Nombre Madre] = pe.sNombreMadre,
   [Estatura] = pe.nEstatura,
   [Telefono] = pe.sTelefono,
   [Color Ojos] = fo.sDescripcion,
   [Color Cabello] = fc.sDescripcion,

   [Distrito Domicilio] = ud.sNombre,
   [Distrito Nacimiento] = un.sNombre,
   [Domicilio] = pe.sDomicilio

FROM SimPersona p
JOIN SimPeruano pe ON p.uIdPersona = pe.uIdPersona
JOIN SimCalidadMigratoria cm ON p.nIdCalidad = cm.nIdCalidad
JOIN SimProfesion pr ON p.sIdProfesion = pr.sIdProfesion
JOIN SimUbigeo ud ON pe.sIdUbigeoDomicilio = ud.sIdUbigeo
JOIN SimUbigeo un ON pe.sIdUbigeoNacimiento = un.sIdUbigeo
JOIN SimFisonomia fo ON pe.nIdColorOjos = fo.nIdFisonomia
JOIN SimFisonomia fc ON pe.nIdColorCabello = fc.nIdFisonomia
WHERE
   p.bActivo = 1
   AND p.uIdPersona IN (
                           '51de7f95-f411-4507-85e5-6f185b8c36b5',
                           '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
                           '83599bf3-e722-4171-a4c5-0d58e1afcb3c'
                        )



SELECT * FROM SimImagen ie
WHERE
   ie.uIdPersona IN (
      '51de7f95-f411-4507-85e5-6f185b8c36b5',
      '2072ba3f-3340-4b19-8ad1-cc2df9869e98',
      '83599bf3-e722-4171-a4c5-0d58e1afcb3c'
   )

--
SELECT * 
FROM SimDocPersona dp
WHERE
   dp.sNumero = '001948610'

-- SSIS Buscar imagen
DECLARE @uId UNIQUEIDENTIFIER = '20a78cce-fa53-45d2-be0f-b9c1a5608c3a'
      
IF EXISTS(SELECT TOP 1 1 FROM SimImagenExtranjero ie WHERE ie.uIdPersona = @uId)
BEGIN
   SELECT i.*
   FROM (
      SELECT 
         -- [sPath] = CONCAT('D:\img\', REPLACE(p.sNombre, ' ', ''), RTRIM(CONCAT(p.sPaterno, p.sMaterno)), '\', COALESCE(ie.sIdDedo, ie.sTipo), '.png'),
         [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').jpg'),
         [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
      FROM SIM.dbo.[SimImagenExtranjero] ie
      LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
      RIGHT JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
      WHERE
         ie.bUltimo = 1
         AND p.uIdPersona = @uId
   ) i
   ORDER BY
      LEN(i.sPath) DESC
END
ELSE
BEGIN
   SELECT i.*
   FROM (
      SELECT 
         [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.strNombre, i.sTipoImagen), ').jpg'),
         -- [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, p.sMaterno))),
         [xImagen] = CAST(i.xImagen AS VARBINARY(MAX))
      FROM SIM.dbo.[SimImagen] i
      LEFT JOIN SimDedoBio d ON i.sTipoImagen = d.strDedoBio
      RIGHT JOIN SimPersona p ON i.uIdPersona = p.uIdPersona
      WHERE
         i.bUltimo = 1
         AND p.uIdPersona = @uId
   ) i
   ORDER BY
      LEN(i.sPath) DESC
END


-- Buscar imagen de varias personas.

-- 1
DECLARE @uId UNIQUEIDENTIFIER;
DECLARE imagen_cursor CURSOR 
   FOR SELECT uIdPersona FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra;

OPEN imagen_cursor;

FETCH NEXT FROM imagen_cursor INTO @uId

WHILE @@FETCH_STATUS = 0
BEGIN

   IF EXISTS(SELECT TOP 1 1 FROM SimImagenExtranjero ie WHERE ie.uIdPersona = @uId)
   BEGIN
      SELECT i.*
      FROM (
         SELECT 
            -- [sPath] = CONCAT('D:\img\', REPLACE(p.sNombre, ' ', ''), RTRIM(CONCAT(p.sPaterno, p.sMaterno)), '\', COALESCE(ie.sIdDedo, ie.sTipo), '.png'),
            [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').jpg'),
            [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
         FROM SIM.dbo.[SimImagenExtranjero] ie
         LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
         RIGHT JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
         WHERE
            ie.bUltimo = 1
            AND p.uIdPersona = @uId
      ) i
      ORDER BY
         LEN(i.sPath) DESC
   END
   ELSE
   BEGIN
      SELECT i.*
      FROM (
         SELECT 
            [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.strNombre, i.sTipoImagen), ').jpg'),
            -- [sPath] = CONCAT('D:\img\', p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, p.sMaterno))),
            [xImagen] = CAST(i.xImagen AS VARBINARY(MAX))
         FROM SIM.dbo.[SimImagen] i
         LEFT JOIN SimDedoBio d ON i.sTipoImagen = d.strDedoBio
         RIGHT JOIN SimPersona p ON i.uIdPersona = p.uIdPersona
         WHERE
            i.bUltimo = 1
            AND p.uIdPersona = @uId
      ) i
      ORDER BY
         LEN(i.sPath) DESC
   END    

   FETCH NEXT FROM imagen_cursor INTO @uId

END;

CLOSE imagen_cursor;
DEALLOCATE imagen_cursor;


-- 2
SELECT
   [sFileName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno))),
   [sImageName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').jpg'),
   [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
   INTO SimImagenVen411
FROM SIM.dbo.[SimImagenExtranjero] ie
LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
RIGHT JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
WHERE
   ie.bUltimo = 1
   AND EXISTS ( -- VEN
                  SELECT 1
                  FROM BD_SIRIM_DEV.dbo.RimVenDiligenciasMigra v
                  WHERE v.uIdPersona = ie.uIdPersona
         )
 
SELECT TOP 10 * FROM SimImagenVen411


SELECT TOP 10 * FROM SimImagen i
WHERE 
   i.sTipoImagen = 'H'
ORDER BY i.nIdImagen DESC

SELECT TOP 10 * FROM SimImagen
SELECT TOP 10 * FROM SimImagenExtranjero

-- 3
SELECT
   [sFileName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno))),
   [sImageName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').jpg'),
   [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
FROM SIM.dbo.[SimImagen] ie
JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
WHERE
   ie.uIdPersona = 'e91351ac-054d-4f1b-9c65-8bcced9f6112'

SELECT * 
FROM SimPersona pe
WHERE 
   pe.uIdPersona = '962071df-6e5c-44a8-bdc3-d94563e5205f'

-- Juana Yanela Fernández Sánchez con DNI N° 71591003
SELECT * 
FROM SimDocPersona dp
WHERE 
   dp.sIdDocumento = 'DNI'
   AND dp.sNumero = '71591003'
   

DECLARE @idPer UNIQUEIDENTIFIER = 'e91351ac-054d-4f1b-9c65-8bcced9f6112'
IF EXISTS(SELECT TOP 1 1 FROM SimImagenExtranjero ie WHERE ie.uIdPersona = @idPer)
BEGIN
   SELECT i.*
   FROM (
      SELECT
         [sFileName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno))),
         [sImageName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.sNombre, ie.sTipo), ').jpg'),
         [xImagen] = CAST(ie.xImagen AS VARBINARY(MAX))
      FROM SIM.dbo.[SimImagenExtranjero] ie
      LEFT JOIN SimDedo d ON ie.sIdDedo = d.sIdDedo
      RIGHT JOIN SimPersona p ON ie.uIdPersona = p.uIdPersona
      WHERE
         ie.bUltimo = 1
         AND p.uIdPersona = @idPer
   ) i
   ORDER BY
      LEN(i.sFileName) DESC
END
ELSE
BEGIN
   SELECT i.*
   FROM (
      SELECT 
         [sFileName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno))),
         [sImageName] = CONCAT(p.sNombre, ', ', RTRIM(CONCAT(p.sPaterno, ' ', p.sMaterno)), '(', COALESCE(d.strNombre, i.sTipoImagen), ').jpg'),
         [xImagen] = CAST(i.xImagen AS VARBINARY(MAX))
      FROM SIM.dbo.[SimImagen] i
      LEFT JOIN SimDedoBio d ON i.sTipoImagen = d.strDedoBio
      RIGHT JOIN SimPersona p ON i.uIdPersona = p.uIdPersona
      WHERE
         i.bUltimo = 1
         AND p.uIdPersona = @idPer
   ) i
   ORDER BY
      LEN(i.sFileName) DESC
END

SELECT * 
FROM SimDedoBio ;