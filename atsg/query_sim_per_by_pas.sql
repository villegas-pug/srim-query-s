USE BD_SIRIM
GO

-- 1
DROP TABLE IF EXISTS RimPassengerByPasaportePE
CREATE TABLE RimPassengerByPasaportePE
(
   FlightDate DATE,
   FlightNumber NVARCHAR(16) NULL,
   ETD DATETIME2 NULL,
   ETA DATETIME2 NULL,
   OriginCountry NVARCHAR(6) NULL,
   Origin NVARCHAR(8) NULL,
   DestinationCountry NVARCHAR(6) NULL,
   Destination	NVARCHAR(8) NULL,
   PassengerId	BIGINT NULL,
   DocumentType NVARCHAR(4) NULL,
   Document	NVARCHAR(200) NULL,
   FirstName NVARCHAR(100) NULL,
   MiddleName NVARCHAR(100) NULL,
   LastName NVARCHAR(100) NULL,
   Gender NVARCHAR(4) NULL,
   DOB DATE NULL,
   CitizenshipCountry NVARCHAR(6) NULL,
   Age INT NULL,
   TypeControl	VARCHAR(1) NULL
   
)

UPDATE RimPassengerByPasaportePE
   SET Document = LTRIM(RTRIM(Document))

SELECT COUNT(1) FROM RimPassengerByPasaportePE

-- 2. `tmp`s

-- 2.1
DROP TABLE IF EXISTS #tmp_passenger_by_pasaporte_PE
SELECT f.* INTO #tmp_passenger_by_pasaporte_PE
FROM (

   SELECT
      atsg.*,
      [sId] = REPLACE(CONCAT(atsg.FirstName, atsg.MiddleName, atsg.LastName, atsg.Gender, CAST(CAST(atsg.DOB AS DATETIME) AS INT)), ' ', ''),
      [#] = ROW_NUMBER() OVER (PARTITION BY atsg.Document ORDER BY atsg.FlightDate DESC)
   FROM RimPassengerByPasaportePE atsg
   WHERE
      ISNUMERIC(atsg.Document) = 1
      AND LEN(atsg.Document) = 9
      AND atsg.Document LIKE '1[1-2]%'

) f
WHERE f.[#] = 1

-- Index
CREATE NONCLUSTERED INDEX ix_#tmp_passenger_by_pasaporte_PE_Document
   ON #tmp_passenger_by_pasaporte_PE(Document)

-- 2.2 SimPasaporte
DROP TABLE IF EXISTS #tmp_pas_e
SELECT 
   pas.*,
   [sId] = REPLACE(CONCAT(pas.sNombre, pas.sPaterno, pas.sMaterno, pas.sSexo, CAST(CAST(pas.dFechaNacimiento AS DATETIME) AS INT)), ' ', '')
   INTO #tmp_pas_e
FROM SIM.dbo.SimPasaporte pas
WHERE
   ISNUMERIC(pas.sPasNumero) = 1
   AND LEN(pas.sPasNumero) = 9
   AND pas.sPasNumero LIKE '1[1-2]%'

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_pas_e 
   ON #tmp_pas_e(sPasNumero)

-- 2.3 SimDocPersona(Opcional)
DROP TABLE IF EXISTS #tmp_doc_per
SELECT 
   dp.* 
   INTO #tmp_doc_per
FROM SIM.dbo.SimDocPersona dp
JOIN SIM.dbo.SimPersona pe ON dp.uIdPersona = pe.uIdPersona
WHERE
   dp.sIdDocumento = 'PAS'
   AND pe.sIdPaisNacionalidad = 'PER'
   AND ISNUMERIC(dp.sNumero) = 1
   AND LEN(dp.sNumero) = 9
   AND dp.sNumero LIKE '1[1-2]%'

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_doc_per
   ON #tmp_doc_per(sNumero)

-- 2.4 Base Central
DROP TABLE IF EXISTS #tmp_base_central
SELECT f.* INTO #tmp_base_central
FROM (
   SELECT
      [PASAPORTE] = s.NUMERO_DOC,
      r.DNI,
      r.NOMBRE,
      r.APELLIDO_PATERNO,
      r.APELLIDO_MATERNO,
      r.FECHA_NACIMIENTO,
      r.SEXO,
      [sId] = REPLACE(CONCAT(r.NOMBRE, r.APELLIDO_PATERNO, r.APELLIDO_MATERNO, r.SEXO, CAST(CAST(r.FECHA_NACIMIENTO AS DATETIME) AS INT)), ' ', ''),
      [#] = ROW_NUMBER() OVER (PARTITION BY s.NUMERO_DOC ORDER BY s.FECHA_PRODUCCION DESC)
   FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
   -- JOIN CENTRAL_DB.CNT_SCHEMA.DOCUMENTO d ON s.DOCUMENTO_ID = d.ID
   JOIN CENTRAL_DB.CNT_SCHEMA.PERSONA p ON s.PERSONA_ID = p.ID
   JOIN CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC r ON p.DNI = r.DNI
   WHERE
      s.PILOTO = 0
      AND s.ESTADO = 'ENTREGADA'
) f
WHERE f.[#] = 1

-- Index
CREATE NONCLUSTERED INDEX ix_tmp_base_central 
   ON #tmp_base_central(PASAPORTE)

-- 3.1: Por documento:
--> Peruanos con PAS registrados en ATSG, pero no en SIM.
SELECT
   atsg.*
FROM #tmp_passenger_by_pasaporte_PE atsg
WHERE NOT EXISTS ( -- Base central
                     SELECT TOP 1 1
                     FROM #tmp_base_central c
                     WHERE
                        c.PASAPORTE = atsg.Document
            )
AND atsg.Document != '111111111'


-- 3.2: Por documento:
--> Peruanos con PAS registrados en ATSG, tambienen SIM, pero nombres distintos.

SELECT 
   pass.*,
   c.sId,
   [sNombre(Central)] = c.NOMBRE,
   [sApellidoPaterno(Central)] = c.APELLIDO_PATERNO,
   [sApellidoMaterno(Central)] = c.APELLIDO_MATERNO,
   [sFechaNacimiento(Central)] = c.FECHA_NACIMIENTO,
   [sPasaporte(Central)] = c.PASAPORTE,
   [sSexo(Central)] = c.SEXO
FROM #tmp_passenger_by_pasaporte_PE pass
JOIN #tmp_base_central c ON c.PASAPORTE = pass.Document
                         AND DIFFERENCE(c.sId, pass.sId) <= 2
   

-- Test

-- SIM
-- f7398c32-e7e7-4041-92d1-b764b0d83331
SELECT p.sPasNumero, tt.sDescripcion, t.* 
FROM SimTramite t 
JOIN SimPasaporte p ON t.sNumeroTramite = p.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE 
   -- t.sNumeroTramite = 'RE230108328'
   t.uIdPersona = 'f7398c32-e7e7-4041-92d1-b764b0d83331'
ORDER BY t.dFechaHora DESC

SELECT * 
FROM SIM.dbo.SimPasaporte pas
WHERE pas.sPasNumero = '118743869'

-- Base central

SELECT
   p.ID,
   [PASAPORTE] = s.NUMERO_DOC,
   s.FECHA_PRODUCCION,
   r.DNI,
   r.NOMBRE,
   r.APELLIDO_PATERNO,
   r.APELLIDO_MATERNO,
   r.FECHA_NACIMIENTO,
   r.SEXO
FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
LEFT JOIN CENTRAL_DB.CNT_SCHEMA.DOCUMENTO d ON s.DOCUMENTO_ID = d.ID
LEFT JOIN CENTRAL_DB.CNT_SCHEMA.PERSONA p ON s.PERSONA_ID = p.ID
LEFT JOIN CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC r ON p.DNI = r.DNI
WHERE
   s.PILOTO = 0
   AND r.DNI = '73520837'
ORDER BY s.FECHA_PRODUCCION DESC


SELECT
   TOP 10 
   s.*
FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
WHERE s.PERSONA_ID = 1405939