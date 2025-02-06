
/* Estados:

      ENTREGADA   | 5064611
      ANULADA     | 115901
      FINALIZADA  | 2114
      PRODUCCION  | 76
      VALIDADA 	| 4               */

-- 1. Solicitud
SELECT COUNT(1) FROM [CNT_SCHEMA].[SOLICITUD] s -- 5,000,000

SELECT 
   TOP 10 * 
   -- s.ESTADO,
   -- s.TRAMIT_ID,
   -- s.PILOTO,
   -- COUNT(1)
FROM [CNT_SCHEMA].[SOLICITUD] s
WHERE
   s.PILOTO = 0 -- Solicitides de producción
GROUP BY
   s.ESTADO
   -- s.TRAMIT_ID
   -- s.PILOTO
ORDER BY 2 DESC


-- Buscar persona por número pasaporte:

-- 1.	cuantos pasaportes por persona  (ROY)

-- 1.1 Cetral
SELECT 
   d.*,
   r.NOMBRE,
   r.APELLIDO_PATERNO,
   r.APELLIDO_MATERNO
FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
JOIN CENTRAL_DB.CNT_SCHEMA.DOCUMENTO d ON s.NUMERO_DOC = d.DOCUMENTO_NUMERO
JOIN CENTRAL_DB.CNT_SCHEMA.PERSONA p ON s.PERSONA_ID = p.ID
JOIN CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC r ON p.DNI = r.DNI
WHERE
   -- s.PILOTO = 0
   -- AND s.ESTADO = 'ENTREGADA'
   -- AND d.FECHA_EMISION BETWEEN '2019-01-01 00:00:00.000' AND '2024-09-26 23:59:59.999' 
   s.NUMERO_DOC = '116000033'
   
SELECT TOP 10 * 
FROM CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC

SELECT 
   -- COUNT(1)
   -- TOP 10 d.*
   d.ESTADO,
   COUNT(1)
FROM [CNT_SCHEMA].[DOCUMENTO] d
GROUP BY
   d.ESTADO
ORDER  BY 2 DESC

SELECT TOP 10 d.* FROM [CNT_SCHEMA].[DOCUMENTO] d


SELECT TOP 10 * FROM [CNT_SCHEMA].[DOCUMENTO_HISTORIA]
SELECT
   -- TOP 100 * 
   h.VALOR_PROP,
   COUNT(1)
FROM [CNT_SCHEMA].[DOCUMENTO_HISTORIA] h
GROUP BY
   h.VALOR_PROP
ORDER BY
   2 DESC

-- [CNT_SCHEMA].[SOLICITUD_HISTORIA]
SELECT TOP 10 * FROM [CNT_SCHEMA].[SOLICITUD_HISTORIA] h

SELECT
   -- TOP 100 * 
   h.VALOR_PROP,
   COUNT(1)
FROM [CNT_SCHEMA].[SOLICITUD_HISTORIA] h
GROUP BY
   h.VALOR_PROP
ORDER BY
   2 DESC


-- 2. Datos persona:

-- 2.1. Base Central

SELECT TOP 10 * FROM [CNT_SCHEMA].[SOLICITUD]
SELECT TOP 10 * FROM [CNT_SCHEMA].[DOCUMENTO]

SELECT TOP 10 * FROM [CNT_SCHEMA].[PERSONA]
SELECT TOP 10 * FROM [CNT_SCHEMA].[DATOS_RENIEC]
SELECT TOP 10 * FROM [CNT_SCHEMA].[DATOS_BIOMETRICOS]
SELECT TOP 10 * FROM [CNT_SCHEMA].[HUELLAS_DACTILARES]
SELECT TOP 10 * FROM [CNT_SCHEMA].[DATOS_DINAMICOS]
SELECT TOP 10 * FROM [CNT_SCHEMA].[REF_FISONOMIA]


-- 2.2 Reniec
SELECT TOP 10 * FROM [CNT_SCHEMA].[DATOS_RENIEC]


-- Entregados

-- 1
SELECT TOP 1 * FROM CNT_SCHEMA.SOLICITUD
SELECT TOP 1 * FROM CNT_SCHEMA.DOCUMENTO

SELECT pv.* 
FROM (

   SELECT 
      [nMesEntrega] = DATEPART(MM, d.FECHA_ENTREGA),
      [nAñoEntrega] = DATEPART(YYYY, d.FECHA_ENTREGA),
      [sPasNumero] = s.NUMERO_DOC
   FROM CNT_SCHEMA.SOLICITUD s
   JOIN CNT_SCHEMA.DOCUMENTO d ON s.DOCUMENTO_ID = d.ID
   WHERE
      -- s.PILOTO = 1
      s.ESTADO = 'ENTREGADA'

) f
PIVOT (
   COUNT(f.sPasNumero) FOR f.nMesEntrega IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv
WHERE
   pv.nAñoEntrega IS NOT NULL

-- 2
SELECT pv.* 
FROM (

   SELECT 
      [dFechaEntrega] = CAST(d.FECHA_ENTREGA AS DATE),
      [nAñoEntrega] = DATEPART(YYYY, d.FECHA_ENTREGA),
      [sPasNumero] = s.NUMERO_DOC
   FROM CNT_SCHEMA.SOLICITUD s
   JOIN CNT_SCHEMA.DOCUMENTO d ON s.DOCUMENTO_ID = d.ID
   WHERE
      s.PILOTO = 0
      AND s.ESTADO = 'ENTREGADA'
      AND d.FECHA_ENTREGA >= '2023-01-01 00:00:00.000'

) f
PIVOT (
   COUNT(f.sPasNumero) FOR f.nAñoEntrega IN ([2023], [2024])
) pv
WHERE
   pv.dFechaEntrega IS NOT NULL













-- Enrolados

-- REGISTRADA

SELECT TOP 10 * FROM [CNT_SCHEMA].[SOLICITUD_HISTORIA]

-- 1
DROP TABLE IF EXISTS #tmp_sol_en_bio
SELECT
   f.*
   INTO #tmp_sol_en_bio
FROM (

   SELECT
      sh.*,
      [nTotal] = COUNT(1) OVER (PARTITION BY sh.SOLICITUD_ID),
      [sFirstValue(VALOR_PROP)] = LAST_VALUE(sh.VALOR_PROP) OVER (
                                                                     PARTITION BY sh.SOLICITUD_ID 
                                                                     ORDER BY sh.FECHA_CREADO ASC
                                                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                                  )
   FROM [CNT_SCHEMA].[SOLICITUD_HISTORIA] sh

) f
WHERE
   f.[nTotal] = 1
   AND f.[sFirstValue(VALOR_PROP)] = 'REGISTRADA'

-- 2
SELECT * FROM #tmp_sol_en_bio



SELECT *
FROM [CNT_SCHEMA].[SOLICITUD] s
JOIN [CNT_SCHEMA].[SOLICITUD_HISTORIA] h ON s.ID = h.SOLICITUD_ID
WHERE
   s.PILOTO = 0 -- Solicitides de producción
GROUP BY
   s.ESTADO
   -- s.TRAMIT_ID
   -- s.PILOTO
ORDER BY 2 DESC


/*

   1.	cuantos pasaportes por persona  (ROY)
   2.	sacaron pasaportes en periodos cortos
   3.	cuantos sacaron más 1 pasaporte antes del vencimiento.
   4.	pasaportes que nunca fueron usados (ROY)                          */

-- 1.	cuantos pasaportes por persona  (ROY)

-- 1.1 Cetral
SELECT
   f.[nTotalPAS],
   [nTotalPER] = COUNT(1)
FROM (
   SELECT 
      s.PERSONA_ID, 
      [nTotalPAS] = COUNT(1)
   FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
   JOIN CENTRAL_DB.CNT_SCHEMA.DOCUMENTO d ON s.NUMERO_DOC = d.DOCUMENTO_NUMERO
   -- JOIN CENTRAL_DB.CNT_SCHEMA.PERSONA p ON s.PERSONA_ID = p.ID
   -- JOIN CENTRAL_DB.CNT_SCHEMA.DATOS_RENIEC r ON p.DNI = r.DNI
   WHERE
      s.PILOTO = 0
      AND s.ESTADO = 'ENTREGADA'
      AND d.FECHA_EMISION BETWEEN '2019-01-01 00:00:00.000' AND '2024-09-26 23:59:59.999' 
   GROUP BY
      s.PERSONA_ID
) f
GROUP BY
   f.[nTotalPAS]
ORDER BY 1 ASC


-- 1.2 SIM

-- 1.2.1
SELECT
   [nTotalPasaportes] = pas2.nContar,
   [nPersonas] = COUNT(1)
FROM (

   SELECT
      t.uIdPersona,
      [nContar] = COUNT(1)
   FROM SIM.dbo.SimPasaporte tp
   JOIN SIM.dbo.SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.bCulminado = 1
      -- AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND t.nIdTipoTramite = 90 -- PAS-E
      AND tp.dFechaEmision >= '2019-01-01 00:00:00.000'
      -- AND ISNUMERIC(tp.sPasNumero) = 1
      -- AND LEN(LTRIM(RTRIM(tp.sPasNumero))) = 9
      -- AND tp.sPasNumero LIKE '1[1-2]%'
   GROUP BY
      t.uIdPersona

) pas2
GROUP BY
   pas2.nContar
ORDER BY
   1 ASC

-- 1.2.2
SELECT
   p2.sIdPersona,
   [nTotal] = COUNT(1)
   INTO #tmp_pas_2019_by_per
FROM (

   SELECT
      p.sPasNumero,
      [sIdPersona] = REPLACE(CONCAT(p.sNombre, p.sPaterno, p.sMaterno, CAST(p.dFechaNacimiento AS FLOAT)), ' ', '')
   FROM SIM.dbo.SimPasaporte p
   WHERE
      p.dFechaEmision >= '2019-01-01 00:00:00.000'
      AND ISNUMERIC(p.sPasNumero) = 1
      AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
      AND p.sPasNumero LIKE '1[1-2]%'

) p2
GROUP BY
   p2.sIdPersona


-- 1.2.2
SELECT
   [nPasaportes] = f.nTotal,
   [nTotalPersona] = COUNT(1)
FROM #tmp_pas_2019_by_per f
GROUP BY
   f.nTotal

-- 1.2.2.1 Duplicados
SELECT f2.*
FROM (

   SELECT
      f.*,
      [nTotalPersona] = COUNT(1) OVER (PARTITION BY f.sIdPersona)
   FROM (
      SELECT
         p.sPasNumero,
         t.uIdPersona,
         [sIdPersona] = REPLACE(CONCAT(p.sNombre, p.sPaterno, p.sMaterno, CAST(p.dFechaNacimiento AS FLOAT)), ' ', '')
      FROM SIM.dbo.SimPasaporte p
      JOIN SIM.dbo.SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
      WHERE
         p.dFechaEmision >= '2019-01-01 00:00:00.000'
         AND ISNUMERIC(p.sPasNumero) = 1
         AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
         AND p.sPasNumero LIKE '1[1-2]%'
   ) f

) f2
WHERE f2.nTotalPersona >= 2



SELECT f.* 
FROM (
   SELECT
      t.uIdPersona, tp.sPasNumero, tp.dFechaEmision, tp.dFechaExpiracion,
      [#] = COUNT(1) OVER (PARTITION BY t.uIdPersona)
   FROM SIM.dbo.SimPasaporte tp
   JOIN SIM.dbo.SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.bCulminado = 1
      AND t.nIdTipoTramite = 90 -- PAS-E
      AND tp.dFechaEmision >= '2019-01-01 00:00:00.000'
      -- AND ISNUMERIC(tp.sPasNumero) = 1
      -- AND LEN(LTRIM(RTRIM(tp.sPasNumero))) = 9
      -- AND tp.sPasNumero LIKE '1[1-2]%'
) f
WHERE
   f.[#] > 1


-- Año

SELECT * 
FROM (
   SELECT
      t.sNumeroTramite,
      [nAÑo] = DATEPART(YYYY, tp.dFechaEmision)
   FROM SIM.dbo.SimPasaporte tp
   JOIN SIM.dbo.SimTramite t ON tp.sNumeroTramite = t.sNumeroTramite
   WHERE
      t.bCancelado = 0
      -- AND t.bCulminado = 1
      AND t.nIdTipoTramite = 90 -- PAS-E
      AND tp.dFechaEmision >= '2019-01-01 00:00:00.000'
) f 
PIVOT (
   COUNT(f.sNumeroTramite) FOR nAño IN([2019], [2020], [2021], [2022], [2023], [2024])
) pv

-- 4.	pasaportes que nunca fueron usados (ROY)

-- 4.1 SIM
-- 4.1.1 `tmp`
DROP TABLE IF EXISTS #tmp_pase
SELECT 
   f.* 
   INTO #tmp_pase
FROM (

   SELECT
      p.sPasNumero,
      t.uIdPersona,
      [#] = ROW_NUMBER() OVER (PARTITION BY p.sPasNumero ORDER BY p.sPasNumero)
   FROM SIM.dbo.SimTramite t
   -- JOIN SIM.dbo.SimPersona pe ON t.uIdPersona = pe.uIdPersona
   JOIN SIM.dbo.SimPasaporte p ON t.sNumeroTramite = p.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.bCulminado = 1
      AND p.dFechaEmision >= '2019-01-01 00:00:00.000'
      -- AND t.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
      AND t.nIdTipoTramite IN (90) -- Expedición de Pasaporte Electrónico
      AND ISNUMERIC(p.sPasNumero) = 1
      AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
      AND p.sPasNumero LIKE '1[1-2]%'

) f
WHERE 
   f.[#] = 1

CREATE NONCLUSTERED INDEX ix_tmp_pase 
   ON #tmp_pase(uIdPersona)

-- ...
SELECT 
   f.[bUsoPas],
   [nTotal] = COUNT(1)
FROM (
   SELECT
      p.*,
      [bUsoPas] = IIF(
                        EXISTS(
                                 SELECT TOP 1 1 FROM SIM.dbo.SimMovMigra mm 
                                 WHERE 
                                    mm.uIdPersona = p.uIdPersona
                                    AND mm.sIdDocumento = 'PAS'
                                    AND mm.sNumeroDoc = p.sPasNumero
                        )
                     , 
                     'Si', 
                     'No'
                  )
   FROM #tmp_pase p

) f
GROUP BY
   f.[bUsoPas]

-- 4.1 Central

-- 4.1.1 `tmp`
SELECT
   f.[bUsoPas],
   [nTotal] = COUNT(1)
FROM (

   SELECT 
      s.NUMERO_DOC,
      t.uIdPersona,
      [bUsoPas] = IIF(
                        EXISTS(
                                 SELECT TOP 1 1 FROM SIM.dbo.SimMovMigra mm 
                                 WHERE 
                                    mm.uIdPersona = t.uIdPersona
                                    AND mm.sIdDocumento = 'PAS'
                                    AND mm.sNumeroDoc = s.NUMERO_DOC
                        )
                     , 
                     'Si', 
                     'No'
                  )
   FROM CENTRAL_DB.CNT_SCHEMA.SOLICITUD s
   LEFT JOIN SIM.dbo.SimTramite t ON s.TRAMIT_ID = t.sNumeroTramite
   WHERE
      s.PILOTO = 0
      AND s.ESTADO = 'ENTREGADA'

) f
GROUP BY
   f.[bUsoPas]



-- 3.	cuantos sacaron más 1 pasaporte antes del vencimiento.

-- 3.1 Personas con mas de >= 2 pasaportes

SELECT TOP 1 * FROM SIM.dbo.SimPasaporte

DROP TABLE IF EXISTS #tmp_mas2pas
SELECT f.* INTO #tmp_mas2pas
FROM (

   SELECT
      p.sPasNumero,
      t.uIdPersona,
      p.dFechaEmision,
      p.dFechaExpiracion,
      [#] = COUNT(1) OVER (PARTITION BY t.uIdPersona)
   FROM SIM.dbo.SimTramite t
   -- JOIN SIM.dbo.SimPersona pe ON t.uIdPersona = pe.uIdPersona
   JOIN SIM.dbo.SimPasaporte p ON t.sNumeroTramite = p.sNumeroTramite
   WHERE
      t.bCancelado = 0
      AND t.bCulminado = 1
      -- AND p.dFechaEmision >= '2019-01-01 00:00:00.000'
      -- AND t.nIdTipoTramite IN (2, 90) -- EXPEDICION DE PASAPORTE | Expedición de Pasaporte Electrónico
      AND t.nIdTipoTramite IN (90) -- Expedición de Pasaporte Electrónico
      /* AND ISNUMERIC(p.sPasNumero) = 1
      AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
      AND p.sPasNumero LIKE '1[1-2]%' */

) f
WHERE f.[#] > 1

-- 3.2 Personas con mas de >= 2 pasaportes
-- 5,064,610
-- 5,064,611
SELECT * 
FROM (

   SELECT
      p.*,
      [bEmitidoAntesVencAnt] = (
                                    CASE
                                       WHEN LAG(p.dFechaExpiracion) OVER (PARTITION BY p.uIdPersona ORDER  BY p.dFechaEmision ASC) IS NULL THEN 0
                                       WHEN (
                                                DATEDIFF(
                                                   DD,
                                                   p.dFechaEmision,
                                                   LAG(p.dFechaExpiracion) OVER (PARTITION BY p.uIdPersona ORDER  BY p.dFechaEmision ASC)
                                                )
                                          ) > 0 THEN 1
                                       ELSE 0
                                    END
      )
   FROM #tmp_mas2pas p

) f
ORDER BY
   f.uIdPersona, f.dFechaEmision

-- SELECT DATEDIFF(DD, '2023-01-01', '2023-02-01')


-- CENTRAL
SELECT TOP 10 * FROM [CNT_SCHEMA].[SOLICITUD]
SELECT TOP 10 * FROM [CNT_SCHEMA].[DOCUMENTO]

DROP TABLE IF EXISTS #XTMP01
SELECT
   PERSONA_ID,
   COUNT(*) CANTIDAD 
   INTO #XTMP01
FROM [CNT_SCHEMA].[SOLICITUD] s
JOIN CENTRAL_DB.CNT_SCHEMA.DOCUMENTO d ON s.NUMERO_DOC = d.DOCUMENTO_NUMERO
WHERE 
   -- FECHA_RECEPCION BETWEEN '2019-01-01 00:00:00.000' AND '2024-09-26 23:59:59.997' 
   d.FECHA_EMISION BETWEEN '2019-01-01 00:00:00.000' AND '2024-09-26 23:59:59.997' 
   AND NUMERO_DOC IS NOT NULL 
   /* AND s.PILOTO = 0
   AND s.ESTADO = 'ENTREGADA' */
GROUP BY 
   PERSONA_ID
ORDER BY 1 DESC

SELECT 
   CANTIDAD,
   count(CANTIDAD) CantidadDePersonas
   -- SUM(CANTIDAD) CantidadDePasaportes
FROM #XTMP01
GROUP BY CANTIDAD  
ORDER BY 1 

SELECT p.sPasNumero, p.sEstadoActual
FROM SIM.dbo.SimPasaporte p
WHERE p.sPasNumero IN (
                        SELECT 
                           s.NUMERO_DOC
                        FROM [CNT_SCHEMA].[SOLICITUD] s
                        WHERE s.PILOTO = 1
)


-- Validacion --
SELECT *
  FROM #XTMP01
WHERE CANTIDAD = 10

SELECT *
  FROM [CNT_SCHEMA].[SOLICITUD]
 WHERE PERSONA_ID IN (
 '168220')
 AND  FECHA_RECEPCION >= '2019-01-01 00:00:00.000'
ORDER BY PERSONA_ID 


SELECT * FROM BD_SIRIM.dbo.SidUsuario
