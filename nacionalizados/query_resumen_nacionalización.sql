USE SIM
GO

/*»

   1. CANTIDADES DE TRAMITES DE NACIONALIZACIÓN QUE TIENE MIGRACIONES Y SUS ETAPAS  (APROBADO, DENEGADO, FINALIZADO, ETC)
   2. CANTIDAD DE TRAMITES DE NACIONALIZACIÓN QUE TIENEN SU TITULO CON ESTADO DE ENTREGADO 
   3. CANTIDAD PROMEDIO DE TRAMITES DE NACIONALIZACION QUE INGRESAN POR MES
   4. CANTIDAD PROMEDIO DE TRAMITES QUE SE APRUEBAN POR MES
   5. CANTIDAD PROMEDIO DE TRAMITES POR MES QUE SE ENTREGAN SU TITULO DE NACIONALIZACIÓN

   Tipos de tramites de Nacionalización:
      → 69 | INS HIJOS DE PERUANOS NAC. EN EXT. MENORES DE EDAD
      → 71 | INS HIJOS DE PERUANOS NAC. EN EXT. MAYORES DE EDAD
      → 72 | INS HIJOS DE EXT. NAC.EN EXT.RES PERÚ DESDE 5 AÑOS
      → 73 | INS PERUANO POR MATRIMONIO
      → 76 | OBTENCIÓN NACIONALIDAD PERUANA POR NATURALIZACIÓN
      → 78 | OBTENCIÓN DE LA DOBLE NACIONALIDAD
      → 79 | RECUPERACIÓN DE LA NACIONALIDAD PERUANA
      
-- ============================================================================================================================================= */


-- 1. CANTIDADES DE TRAMITES DE NACIONALIZACIÓN QUE TIENE MIGRACIONES Y SUS ETAPAS  (APROBADO, DENEGADO, FINALIZADO, ETC) ...

SELECT pv.* FROM (

   SELECT 
      st.sNumeroTramite,
      [sTipotramite] = stt.sDescripcion,
      [sEstadoActual] = (
                           CASE stn.sEstadoActual
                              WHEN 'P' THEN 'PENDIENTE'
                              WHEN 'R' THEN 'ANULADO'
                              WHEN 'D' THEN 'DENEGADO'
                              WHEN 'A' THEN 'APROBADO'
                              WHEN 'E' THEN 'DESISTIDO'
                              WHEN 'B' THEN 'ABANDONO'
                              WHEN 'N' THEN 'NO PRESENTADA'
                           END
                        )

   FROM SimTramite st
   JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   WHERE
      st.bCancelado = 0
      AND st.dFechaHora >= '2016-01-01 00:00:00.000'
      -- AND st.dFechaHora BETWEEN '2016-01-01 00:00:00.000' AND '2023-06-30 23:59:59.999'
      AND st.nIdTipoTramite IN (
         69, 71, 72, 73, 76, 78, 79
      )

) n
PIVOT (
   COUNT(n.sNumeroTramite) FOR n.sEstadoActual IN ([PENDIENTE], [ANULADO], [DENEGADO], [APROBADO], [DESISTIDO], [ABANDONO], [NO PRESENTADA])
) pv


-- 2. CANTIDAD DE TRAMITES DE NACIONALIZACIÓN QUE TIENEN SU TITULO CON ESTADO DE ENTREGADO ...
SELECT pv.* FROM (

   SELECT 
      st.sNumeroTramite,
      [sTipotramite] = stt.sDescripcion,
      [nAñoEmision] = DATEPART(YYYY, stin.dFechaEmision)
   FROM SimTramite st
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   JOIN SimTituloNacionalidad stin ON st.sNumeroTramite = stin.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND stin.bAnulado = 0
      AND stin.bEntregado = 1
      AND stin.dFechaEmision >= '2016-01-01 00:00:00.000'

) n
PIVOT (
   COUNT(n.sNumeroTramite) FOR n.nAñoEmision IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023], [2024])
) pv

-- 3. CANTIDAD PROMEDIO DE TRAMITES DE NACIONALIZACION QUE INGRESAN POR MES ...
SELECT pv.* FROM (

   SELECT 
      st.sNumeroTramite,
      [sTipotramite] = stt.sDescripcion,
      [nAñoTramite] = DATEPART(MM, st.dFechaHora)
   FROM SimTramite st
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   WHERE
      st.bCancelado = 0
      AND st.nIdTipoTramite IN (
         69, 71, 72, 73, 76, 78, 79
      )
      AND st.dFechaHora BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

) n
PIVOT (
   COUNT(n.sNumeroTramite) FOR n.nAñoTramite IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 4. CANTIDAD PROMEDIO DE TRAMITES QUE SE APRUEBAN POR MES ...
SELECT pv.* FROM (

   SELECT 
      n.sNumeroTramite,
      n.sTipotramite,
      [nMesImpresion] = DATEPART(MM, n.dFechaImpresion)
   FROM (
      SELECT
         st.sNumeroTramite,
         [sTipotramite] = stt.sDescripcion,
         [dFechaImpresion] = (
                                 SELECT TOP 1 setn.dFechaHoraFin FROM SimEtapaTramiteNac setn 
                                 WHERE 
                                    setn.sNumeroTramite = st.sNumeroTramite
                                    AND setn.nIdEtapa = 6 -- 6 ↔ IMPRESION
                                    AND setn.sEstado = 'F'
                                 ORDER BY setn.dFechaHoraFin DESC
                              )
      FROM SimTramite st
      JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
      JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
      WHERE
         st.bCancelado = 0
         AND stn.sEstadoActual IN ('A', 'P')
         AND st.nIdTipoTramite IN (
            69, 71, 72, 73, 76, 78, 79
         )
   ) n
   WHERE
      n.dFechaImpresion BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

) n
PIVOT (
   COUNT(n.sNumeroTramite) FOR n.nMesImpresion IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 5. CANTIDAD PROMEDIO DE TRAMITES POR MES QUE SE ENTREGAN SU TITULO DE NACIONALIZACIÓN
SELECT pv.* FROM (

   SELECT 
      st.sNumeroTramite,
      [sTipotramite] = stt.sDescripcion,
      [nMesEmision] = DATEPART(MM, stin.dFechaEmision)
   FROM SimTramite st
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   JOIN SimTituloNacionalidad stin ON st.sNumeroTramite = stin.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND stin.bAnulado = 0
      AND stin.bEntregado = 1
      AND stin.dFechaEmision BETWEEN '2023-01-01 00:00:00.000' AND '2023-12-31 23:59:59.999'

) n
PIVOT (
   COUNT(n.sNumeroTramite) FOR n.nMesEmision IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) pv

-- 6. CANTIDAD DE TRAMITES EN ETAPA ENTREGA DE TÍTULO INICIADO(I) Y FINALIZADO(F); PERIODO: 2016 - 2023

SELECT 
   n_et_f.sTipotramite, 
   n_et_i.[Total Entrega (I)], 
   n_et_f.[Total Entrega (F)] 
FROM (

   SELECT -- ETAPA: ENTREGA TÍTULO (I)
      [sTipotramite] = stt.sDescripcion,
      [Total Entrega (I)] = COUNT(1)
   FROM SimTramite st
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND stn.sEstadoActual IN ('A', 'P')
      AND st.nIdTipoTramite IN (
         69, 71, 72, 73, 76, 78, 79
      )
      AND EXISTS (

         SELECT 1 FROM SimEtapaTramiteNac setn 
         WHERE 
            setn.sNumeroTramite = st.sNumeroTramite
            AND setn.nIdEtapa = 42 -- 42 ↔ ENTREGA DE TITULO
            AND setn.bActivo = 1
            AND setn.sEstado = 'I'
            AND setn.dFechaHoraInicio >= '2016-01-01 00:00:00.000'

      )
   GROUP BY
      stt.sDescripcion

) n_et_i
FULL JOIN (
   
   SELECT-- ETAPA: ENTREGA TÍTULO (F)
      [sTipotramite] = stt.sDescripcion,
      [Total Entrega (F)] = COUNT(1)
   FROM SimTramite st
   JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
   JOIN SimTramiteNac stn ON st.sNumeroTramite = stn.sNumeroTramite
   WHERE
      st.bCancelado = 0
      AND stn.sEstadoActual IN ('A', 'P')
      AND st.nIdTipoTramite IN (
         69, 71, 72, 73, 76, 78, 79
      )
      AND EXISTS (

         SELECT 1 FROM SimEtapaTramiteNac setn 
         WHERE 
            setn.sNumeroTramite = st.sNumeroTramite
            AND setn.nIdEtapa = 42 -- 42 ↔ ENTREGA DE TITULO
            AND setn.bActivo = 1
            /* AND setn.sEstado = 'I'
            AND setn.dFechaHoraInicio >= '2016-01-01 00:00:00.000' */
            AND setn.sEstado = 'F'
            AND setn.dFechaHoraFin >= '2016-01-01 00:00:00.000'

      )
   GROUP BY
      stt.sDescripcion

)  n_et_f ON n_et_i.sTipotramite = n_et_f.sTipotramite


SELECT * FROM SimProcedimiento spro
WHERE
   spro.sNombre LIKE '%vul%'