USE BD_SIRIM
GO

-- 1
DROP TABLE IF EXISTS ResultadoConsultaGeocoder
CREATE TABLE ResultadoConsultaGeocoder(
  nIdResutado INT IDENTITY PRIMARY KEY,
  uIdPersona UNIQUEIDENTIFIER,
  sDireccion VARCHAR(MAX),
  sEstado VARCHAR(MAX),
  dLatitud VARCHAR(MAX),
  dLongitud VARCHAR(MAX),
  sResultado VARCHAR(MAX),
  sError VARCHAR(MAX)
)

-- 2: Bulk ...
INSERT INTO ResultadoConsultaGeocoder(uIdPersona, sDireccion, sEstado, dLatitud, dLongitud, sResultado, sError)
   SELECT
      e.uIdPersona,
      e.sDireccion,
      [sEstado] = 'P',
      [dLatitud] = '',
      [dLongitud] = '',
      [sResultado] = '',
      [sError] = ''
   FROM RimTotalExtranjerosPeru e 
   WHERE 
      e.Distrito = 'SAN MARTIN DE PORRES'
      AND (LEN(e.sDireccion) > 0 AND e.sDireccion IS NOT NULL)


SELECT
   COUNT(1)
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru e 
WHERE 
   e.Distrito = 'SAN MARTIN DE PORRES'


-- 2.1: Update → Concatener `Peru`  a sDireccion ...
/* UPDATE ResultadoConsultaGeocoder
   SET sDireccion = CONCAT(sDireccion, ', Perú') */

/* UPDATE ResultadoConsultaGeocoder
   SET sDireccion = REPLACE(sDireccion, ', Perú', ', Peru') */

-- Test ...
-- 1
SELECT TOP 10 eg.* FROM ResultadoConsultaGeocoder eg
WHERE (eg.dLatitud IS NOT NULL AND eg.dLatitud != '')

-- ...
SELECT TOP 10 eg.* FROM ResultadoConsultaGeocoder eg

-- Contar registros actualizados ...
SELECT COUNT(1) FROM ResultadoConsultaGeocoder eg
SELECT TOP 1000 eg.* FROM ResultadoConsultaGeocoder eg
WHERE eg.sEstado = 'C'


-- Población por distritos ...
SELECT 
   e.Distrito,
   COUNT(1) 
FROM RimTotalExtranjerosPeru e
GROUP BY
   e.Distrito
ORDER BY
   2 DESC

-- Por cordenadad ...
SELECT 
   TOP 10
   e.*
   -- COUNT(1) 
FROM ResultadoConsultaGeocoder e
WHERE
   (e.dLatitud BETWEEN -11.9999999 AND -11)

   AND (e.dLongitud >= 77 AND e.dLongitud <= 77.9999999)

-- lat: -11.9814397	| Long: -77.09697179999999
SELECT CAST('-11.9814397' AS DECIMAL(17, 15))
SELECT CAST('-77.09697179999999' AS DECIMAL(17, 15))

/* SELECT TOP 10 eg.* FROM xTo eg */

-- 2
/*
   → UPDATE ResultadoConsultaGeocoder
     SET sResultado = '' 
*/