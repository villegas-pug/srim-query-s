USE SIM
GO

-- 1. Trámites CCM, CPP y PTP en etapa `ENTREGA DE CARNET` con estato `PENDIENTE` ...
-- ======================================================================================================================================================================== */

-- 1.1
SELECT
   
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'P'
   -- AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP; 57 ↔ PRORROGA DE RESIDENCIA
   AND t.nIdTipoTramite IN (58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   -- AND t.nIdTipoTramite IN (57)-- 57 ↔ PRORROGA DE RESIDENCIA
   AND EXISTS ( -- Ultimas etapas
      
                  SELECT 1 FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite 
                     AND et.bActivo = 1
                     AND et.sEstado = 'F'
                     AND et.nIdEtapa IN (17, 63, 80) -- 58, 113, 126
                     -- AND et.nIdEtapa IN (24) -- 57
              
   )
   AND NOT EXISTS ( -- Reconsideraciones o apelaciones

         SELECT 
            1
         FROM SimEtapaTramiteInm eti
         WHERE
            eti.sNumeroTramite = t.sNumeroTramite 
            AND eti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
            AND eti.sEstado = 'I'
            AND eti.bActivo = 1
            
   )

-- 1.2: Visualización de datos:

-- Test ...

-- ======================================================================================================================================================================== */


-- 2. Trámites PRR, CCM, CPP y PTP en estato `APROBADO`, sin embargo no registra etapa que actualiza el estado a `APROBADO` ...
-- ======================================================================================================================================================================== */

-- 2.1

SELECT
   
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   -- [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND YEAR(t.dFechaHora) >= (
                                 SELECT et.nAño
                                 FROM (
                                    VALUES
                                       (2021, 57), -- >=2021  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                       (2022, 58), -- >=2022 = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                       (2021, 113), -- >=2021 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                       (2023, 126) -- >=2023 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 ) et([nAño], [nIdTipoTramite])
                                 WHERE
                                    et.nIdTipoTramite = t.nIdTipoTramite
   )
   AND NOT EXISTS ( -- Etapas que aprueban el trámite ...
      
                  SELECT 1 FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite 
                     AND et.bActivo = 1
                     -- AND et.sEstado = 'F'
                     AND (
                        et.nIdEtapa = (
                                             SELECT et.nIdEtapa
                                             FROM (
                                                VALUES
                                                   (57, 22), -- 57  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                                   (58, 17), -- 58  = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                                   (113, 63), -- 113 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                                   (126, 80) -- 126 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                             ) et([nIdTipoTramite], [nIdEtapa])
                                             WHERE
                                                et.nIdTipoTramite = t.nIdTipoTramite
                        )
                        OR
                        et.nIdEtapa IN (67, 68) -- Reconsideracion y Apelación
                     )
              
   )


-- 2.2: Visualización de datos:

-- Test ...

-- ======================================================================================================================================================================== */


-- 3. Trámites PRR, CCM, CPP y PTP en estato `APROBADO`, sin embargo registra la ultima etapa en estado `INICIADO` ...
-- ======================================================================================================================================================================== */

SELECT
   
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND YEAR(t.dFechaHora) >= (
                                 SELECT tmp.nAño
                                 FROM (
                                    VALUES
                                       (2021, 57), -- >=2021  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                       (2022, 58), -- >=2022 = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                       (2021, 113), -- >=2021 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                       (2023, 126) -- >=2023 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                 ) tmp([nAño], [nIdTipoTramite])
                                 WHERE
                                    tmp.nIdTipoTramite = t.nIdTipoTramite
   )
   AND EXISTS ( -- Etapas que aprueban el trámite ...
                  SELECT 1
                  FROM (
                     SELECT 
                        et.*,
                        [#] = ROW_NUMBER() OVER (ORDER BY et.nIdEtapaTramite DESC)
                     FROM SimEtapaTramiteInm et
                     WHERE
                        et.sNumeroTramite = t.sNumeroTramite 
                  ) et2
                  WHERE 
                     et2.[#] = 1
                     AND et2.bActivo = 1
                     AND et2.sEstado = 'I'
                     AND et2.nIdEtapa = (
                                          SELECT tmp.nIdEtapa
                                          FROM (
                                             VALUES
                                                (57, 22), -- 57  = 22 ↔ CONFORMIDAD SUB-DIREC.INMGRA. 
                                                (58, 17), -- 58  = 17 ↔ ENTREGA DE CARNET EXTRANJERIA
                                                (113, 63), -- 113 = 63 ↔ ENTREGA DE CARNÉ P.T.P.
                                                (126, 80) -- 126 = 80 ↔ ENTREGA DE CARNÉ C.P.P.
                                          ) tmp([nIdTipoTramite], [nIdEtapa])
                                          WHERE
                                             tmp.nIdTipoTramite = t.nIdTipoTramite
                                          )
                     )


-- ======================================================================================================================================================================== */


-- 4. Entradas o salidas registradas igual fecha, hora, minuto y segundo.
-- ======================================================================================================================================================================== */

SELECT 

   TOP 100
   mm2.sIdMovMigratorio,
   mm2.uIdPersona,
   mm2.dFechaControl,
   mm2.sTipo,
   mm2.sIdPaisNacionalidad,
   mm2.sNombres

FROM (

   SELECT 
      mm.*,
      -- [nDupl] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sTipo, CONVERT(VARCHAR(16), mm.dFechaControl, 120)) -- HH:mm
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY 
                                       mm.uIdPersona, 
                                       mm.sTipo, 
                                       CONVERT(VARCHAR(19), mm.dFechaControl, 120)
                                 ) -- HH:mm:ss
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) mm2
WHERE
   mm2.nDupl >= 2
ORDER BY mm2.uIdPersona

-- Test

-- ======================================================================================================================================================================== */


-- 5. Ingreso de extranjeros mayores de 18 año de edad con documento de viaje PNA(Partida de nacimiento) en Control Migratorio.
-- ======================================================================================================================================================================== */

SELECT 
   
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Tipo Control] = mm.sTipo,
   [Id Persona] = mm.uIdPersona,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Fecha Control] = mm.dFechaControl,
   [Edad (Control Migratorio)] = DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl),
   [Pais Nacionalidad] = mm.sIdPaisNacionalidad

FROM SimMovMigra mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.sTipo = 'E'
   AND (mm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND mm.sIdPaisNacionalidad IS NOT NULL)
   AND mm.sIdDocumento = 'PNA' -- PNA | PARTIDA DE NACIMIENTO
   -- AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
   AND DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl) >= 18 -- Mayores de edad

-- Test
SELECT DATEDIFF(YYYY, '2024-01-01', GETDATE())
SELECT DATEDIFF(YYYY, '2023-01-01', '2024-05-01')

-- ======================================================================================================================================================================== */


-- 6. Prefijo de Número de trámite no corresponde a prefijo de trámite de dependencia.
-- ======================================================================================================================================================================== */

SELECT 

   [Número Tramite] = t.sNumeroTramite,
   [Fecha Trámite] = CAST(t.dFechaHora AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Dependencia] = d.sNombre,
   [Prefijo Dependencia] = d.sPrefijoTramite,
   [Dependencia Número Trámite (Prefijo)] = (
                                                SELECT d2.sNombre 
                                                FROM SimDependencia d2 
                                                WHERE 
                                                   d2.bActivo = 1
                                                   AND d2.nIdTipoDependencia = 2 -- 2 | JEFATURA DE MIGRACIONES
                                                   AND d2.sPrefijoTramite = LEFT(LTRIM(t.sNumeroTramite), 2)
   )
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   -- AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ISNUMERIC(LEFT(LTRIM(t.sNumeroTramite), 2)) = 0 -- Prefijo únicamente letras
   AND (

      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND d.sPrefijoTramite NOT IN (LEFT(LTRIM(t.sNumeroTramite), 2), 'SW')

   )

-- Test

-- ======================================================================================================================================================================== */

-- 4. Ingreso de `Menores de 9 años` con Partida de Nacimiento sin Calidad `HUMANITARIA` .
-- 4. Ingreso de `Mayores de edad` con Partida de Nacimiento sin Calidad `HUMANITARIA` .