USE SIM
GO

-- 1. Más de 1 pasaporte, mismo año ...
SELECT 
   spas.sIdDocumento,
   spas.sNumeroDoc,
   [nTotal] = COUNT(1)
FROM SimPasaporte spas
WHERE
   -- spas.sEstadoActual = 'E'
   spas.dFechaEmision BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'
GROUP BY
   spas.sIdDocumento,
   spas.sNumeroDoc
ORDER BY 3 DESC


-- 2.  

