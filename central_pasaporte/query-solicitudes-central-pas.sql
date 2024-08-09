
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
SELECT TOP 10 * FROM [CNT_SCHEMA].[PERSONA]
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
      s.PILOTO = 0
      AND s.ESTADO = 'ENTREGADA'

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