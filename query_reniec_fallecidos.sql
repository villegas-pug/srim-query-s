USE SIM
GO


-- DNI | 1 APE | 2 APE | NOMBRES | SEXO | FEC NAC | TIPO DOCUMENTO

/* 
   PAS Colectivos:

      sDescripcion               +	nTotal
      -------------------------------------
      ANULACION DE PASAPORTE	   +  527
      REVALIDACION DE PASAPORTE  +  101
      TRAMITE ASOCIACION         +  12                */

-- 1. Bulk ciudadanos fallecidos ...
-- SELECT COUNT(1) FROM BD_SIRIM.dbo.RimReniecFallecidos -- 409,920
DROP TABLE IF EXISTS BD_SIRIM.dbo.RimReniecFallecidos
SELECT 
   TOP 0
   pe.sPaterno,
   pe.sMaterno,
   pe.sNombre,
   pe.sSexo,
   pe.dFechaNacimiento,
	pe.sNumDocIdentidad,
   [sIdDocIdentidad] = REPLICATE('', 55)
   INTO BD_SIRIM.dbo.RimReniecFallecidos
FROM SIM.dbo.SimPersona pe

-- 2. 
-- EXEC sp_help SimPasaporte

-- 2.1
DROP TABLE IF EXISTS #tmp_pasaporte
SELECT
   p2.* 
   INTO #tmp_pasaporte
FROM (
   SELECT
      p.*,
      t.bCancelado
   FROM SimPasaporte p
   JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
   /* WHERE
      t.nIdTipoTramite IN (2, 90) */
) p2
WHERE
   p2.bCancelado = 0 
   OR p2.bCancelado IS NULL

CREATE NONCLUSTERED INDEX ix_tmp_pasaporte_dni 
   ON #tmp_pasaporte(sNumeroDoc)

CREATE NONCLUSTERED INDEX ix_tmp_pasaporte_datos
   ON #tmp_pasaporte(sPaterno, sMaterno, sNombre, sSexo, dFechaNacimiento)

-- 2.1. Por DNI ...
DROP TABLE IF EXISTS #tmp_fallec_join_pas_by_dni
SELECT 
   f.*,

   -- Aux
   [sTipoTramite] = (
                        CASE 
                           WHEN p.sPasNumero IS NOT NULL THEN (
                              CASE
                                 WHEN LEN(p.sPasNumero) = 9 AND p.sPasNumero LIKE '1[1-2]%' THEN 'PASAPORTE ELECTRÓNICO'
                                 ELSE 'PASAPORTE MECANIZADO'
                              END
                           )
                           ELSE NULL
                        END
   ),
   p.sPasNumero,
   p.dFechaEmision,
   p.dFechaExpiracion,
   [sEstadoActual] = CASE p.sEstadoActual
                        WHEN 'A' THEN 'ANULADO'
								WHEN 'C' THEN 'NO EXPEDIDO'
								WHEN 'E' THEN 'EXPEDIDO'
								WHEN 'N' THEN 'NUEVO'
								WHEN 'R' THEN 'REVALIDADO'
								WHEN 'X' THEN 'CANCELADO'
								WHEN 'S' THEN 'SUSPENDIDO'
						  END,
   [¿Vencido?] = (
                     CASE
                        WHEN p.sPasNumero IS NULL THEN 'No registra pasaporte'
                        WHEN p.dFechaExpiracion != '1900-01-01 00:00:00.000' THEN (
                           CASE
                              WHEN DATEDIFF(DD, GETDATE(), p.dFechaExpiracion) <= 0 THEN 'Vencido'
                              ELSE 'Vigente'
                           END
                        )
                        ELSE 'Registra pasaporte, sin vencimiento'
                     END
   )

   INTO #tmp_fallec_join_pas_by_dni
FROM BD_SIRIM.dbo.RimReniecFallecidos f
LEFT JOIN #tmp_pasaporte p ON f.sNumDocIdentidad = p.sNumeroDoc
                           AND p.sIdDocumento = 'DNI'

-- 2.2 Por datos completos
DROP TABLE IF EXISTS #tmp_fallec_join_pas_by_datos
SELECT 
   f.*,

   -- Aux
   [sTipoTramite] = (
                        CASE 
                           WHEN p.sPasNumero IS NOT NULL THEN (
                              CASE
                                 WHEN LEN(p.sPasNumero) = 9 AND p.sPasNumero LIKE '1[1-2]%' THEN 'PASAPORTE ELECTRÓNICO'
                                 ELSE 'PASAPORTE MECANIZADO'
                              END
                           )
                           ELSE NULL
                        END
   ),
   p.sPasNumero,
   p.dFechaEmision,
   p.dFechaExpiracion,
   [sEstadoActual] = CASE p.sEstadoActual
                        WHEN 'A' THEN 'ANULADO'
								WHEN 'C' THEN 'NO EXPEDIDO'
								WHEN 'E' THEN 'EXPEDIDO'
								WHEN 'N' THEN 'NUEVO'
								WHEN 'R' THEN 'REVALIDADO'
								WHEN 'X' THEN 'CANCELADO'
								WHEN 'S' THEN 'SUSPENDIDO'
						  END,
   [¿Vencido?] = (
                     CASE
                        WHEN p.sPasNumero IS NULL THEN 'No registra pasaporte'
                        WHEN p.dFechaExpiracion != '1900-01-01 00:00:00.000' THEN (
                           CASE
                              WHEN DATEDIFF(DD, GETDATE(), p.dFechaExpiracion) <= 0 THEN 'Vencido'
                              ELSE 'Vigente'
                           END
                        )
                        ELSE 'Registra pasaporte, sin vencimiento'
                     END
   )

   INTO #tmp_fallec_join_pas_by_datos
FROM BD_SIRIM.dbo.RimReniecFallecidos f
LEFT JOIN #tmp_pasaporte p ON DIFFERENCE(f.sNombre, p.sNombre) >= 3
                         AND f.sPaterno = p.sPaterno
                         AND f.sMaterno = p.sMaterno
                         AND f.dFechaNacimiento = p.dFechaNacimiento
                         AND f.sSexo = p.sSexo

-- 3.3 Final: 

-- Registran `PAS` ...
DROP TABLE IF EXISTS #tmp_fallec_join_pas_final_1
SELECT 
   f2.*
   INTO #tmp_fallec_join_pas_final_1
FROM (

   SELECT 
      *,
      [#] = ROW_NUMBER() OVER (PARTITION BY f.sNumDocIdentidad, f.sPasNumero ORDER BY f.sPasNumero)
   FROM (

         SELECT * FROM #tmp_fallec_join_pas_by_dni f WHERE f.[¿Vencido?] != 'No registra pasaporte'
         UNION ALL
         SELECT * FROM #tmp_fallec_join_pas_by_datos f WHERE f.[¿Vencido?] != 'No registra pasaporte'

   ) f

) f2
WHERE
   f2.[#] = 1

-- No Registran `PAS` ...
DROP TABLE IF EXISTS #tmp_fallec_join_pas_final_2
SELECT 
   f2.*
   INTO #tmp_fallec_join_pas_final_2
FROM (

   SELECT 
      *,
      [#] = ROW_NUMBER() OVER (PARTITION BY f.sNumDocIdentidad ORDER BY f.sNumDocIdentidad)
   FROM (

         SELECT * FROM #tmp_fallec_join_pas_by_dni f WHERE f.[¿Vencido?] = 'No registra pasaporte'
         UNION ALL
         SELECT * FROM #tmp_fallec_join_pas_by_datos f WHERE f.[¿Vencido?] = 'No registra pasaporte'

   ) f

) f2
WHERE
   f2.[#] = 1
   AND NOT EXISTS (
                     SELECT 1
                     FROM #tmp_fallec_join_pas_final_1 f1 
                     WHERE f1.sNumDocIdentidad = f2.sNumDocIdentidad
   )


-- Final:
-- 1
SELECT
   -- COUNT(DISTINCT f.sNumDocIdentidad)
   f.*
FROM (

   SELECT * FROM #tmp_fallec_join_pas_final_1
   UNION ALL
   SELECT * FROM #tmp_fallec_join_pas_final_2

) f
ORDER BY f.sNumDocIdentidad

-- 2
SELECT
   -- f.[¿Vencido?],
   f.sEstadoActual,
   [nTotal] = COUNT(1)
FROM (

   SELECT * FROM #tmp_fallec_join_pas_final_1
   UNION ALL
   SELECT * FROM #tmp_fallec_join_pas_final_2

) f
WHERE f.[¿Vencido?] != 'No registra pasaporte'
GROUP BY 
   -- f.[¿Vencido?],
   f.sEstadoActual
ORDER BY 2 DESC


-- Test
SELECT t.sNumeroTramite, t.nIdTipoTramite, p.* 
FROM SimPasaporte p
LEFT JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
WHERE p.sNumeroDoc = '80664301'


SELECT COUNT(1) FROM BD_SIRIM.dbo.RimReniecFallecidos -- 410,178
SELECT COUNT(DISTINCT f.sNumDocIdentidad) FROM BD_SIRIM.dbo.RimReniecFallecidos f -- 394,548

SELECT COUNT(1) 
FROM (
   SELECT DISTINCT f.sNombre, f.sPaterno, f.sMaterno, f.sSexo, f.dFechaNacimiento FROM BD_SIRIM.dbo.RimReniecFallecidos f -- 409,513
) f

SELECT * 
FROM (
   SELECT
      f.*,
      [#] = COUNT(1) OVER (PARTITION BY f.sNombre, f.sPaterno, f.sMaterno, f.sSexo, f.dFechaNacimiento),
      [#2] = COUNT(1) OVER (PARTITION BY f.sNumDocIdentidad)
   FROM BD_SIRIM.dbo.RimReniecFallecidos f -- 409,513
) f2
WHERE
   f2.[#] = 1
   AND f2.[#2] >= 2


SELECT COUNT(1) 
FROM BD_SIRIM.dbo.RimReniecFallecidos




-- =================================================================================================================================================================================