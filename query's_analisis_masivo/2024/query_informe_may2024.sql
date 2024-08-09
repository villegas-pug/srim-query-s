USE SIM
GO

-- 1. Prefijo de número de trámite no corresponde a prefijo de trámite de dependencia.
-- ======================================================================================================================================================================== */

-- 1.1
SELECT 
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Tramite] = t.sNumeroTramite,
   [Fecha Trámite] = CAST(t.dFechaHora AS DATE),
   [Tipo Tramite] = tt.sDescripcion,
   [Dependencia] = d.sNombre,
   [Prefijo Trámite Dependencia] = d.sPrefijoTramite
   /* [Dependencia Número Trámite (Prefijo)] = (
                                                SELECT d2.sNombre 
                                                FROM SimDependencia d2 
                                                WHERE 
                                                   d2.bActivo = 1
                                                   AND d2.nIdTipoDependencia = 2 -- 2 | JEFATURA DE MIGRACIONES
                                                   AND d2.sPrefijoTramite = LEFT(LTRIM(t.sNumeroTramite), 2)
   ) */
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   -- AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ISNUMERIC(LEFT(LTRIM(t.sNumeroTramite), 2)) = 0 -- Prefijo únicamente letras
   AND (

      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND LEFT(LTRIM(t.sNumeroTramite), 2)  NOT IN (d.sPrefijoTramite, 'SW')

   )


-- 1.2: Visualización de datos:
SELECT -- Prefijo igual
   TOP 1000000
   t.sNumeroTramite,
   d.sNombre,
   d.sPrefijoTramite
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND (
      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND d.sPrefijoTramite != 'SW'
      AND d.sPrefijoTramite = LEFT(LTRIM(t.sNumeroTramite), 2)
   )
UNION ALL
SELECT -- Prefijo distinto
   TOP 10000
   t.sNumeroTramite,
   d.sNombre,
   d.sPrefijoTramite
FROM SimTramite t
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND (
      t.sNumeroTramite LIKE '[a-zA-Z][a-zA-Z]%' -- Prefijo únicamente letras
      AND d.sPrefijoTramite NOT IN (LEFT(LTRIM(t.sNumeroTramite), 2), 'SW')
   )

-- Test

-- ======================================================================================================================================================================== */

-- 2. Trámites de CCM, CPP y PTP con estato de trámite `PENDIENTE` en etapa que actualiza el estado a `APROBADO` con estado `FINALIZADO` ...
-- ======================================================================================================================================================================== */

-- 2.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
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
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
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

-- 2.2: Visualización de datos:
SELECT
   t.sNumeroTramite,
   tt.sSigla
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND ti.sEstadoActual = 'P'
   AND t.nIdTipoTramite IN (58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
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


-- Test ...

-- ======================================================================================================================================================================== */


-- 3. Trámites de PRR, CCM, CPP y PTP con estado de trámite `APROBADO`, sin registro de etapa que actualiza el estado a `APROBADO` ...
-- ======================================================================================================================================================================== */

-- 3.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
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
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
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


-- 3.2: Visualización de datos:
SELECT
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sSigla
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
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


-- Test ...

-- ======================================================================================================================================================================== */


-- 4. Trámites de PRR, CCM, CPP y PTP con estato de trámite `APROBADO` en etapa que actualiza el estado a `APROBADO` con estado `INICIADO` ...
-- ======================================================================================================================================================================== */


-- 4.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
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
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
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

-- 4.2: Visualización de datos:
SELECT
   t.sNumeroTramite,
   tt.sSigla,
   e.sDescripcion
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
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


-- 5. Trámites de inmigración con estado de trámite `APROBADOS` en etapa `ASOCIACIÓN BENEFICIARIO` ...
-- ======================================================================================================================================================================== */

-- 5.1

SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   [Número Trámite] = t.sNumeroTramite,
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
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   -- AND ti.nIdEtapaActual = 12 -- 12 | ASOCIACION BENEFICIARIO
   AND (
            SELECT COUNT(1)
               FROM (
                  SELECT 
                     et.nIdEtapa,
                     [#] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite)
                  FROM SimEtapaTramiteInm et
                  WHERE
                     et.sNumeroTramite = t.sNumeroTramite
                     AND et.bActivo = 1

               ) et2
               WHERE
                  et2.[#] = 2
                  AND et2.nIdEtapa IN (11, 12) -- 12 | ASOCIACION BENEFICIARIO; 11 | RECEPCIÓN DINM
            ) = 2
   ORDER BY t.dFechaHora DESC


-- 5.2: Visualización de datos:
SELECT
   t.sNumeroTramite,
   tt.sSigla
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57 ↔ PRR; 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND (
            SELECT COUNT(1)
            FROM (
               SELECT 
                  et.nIdEtapa,
                  [#] = COUNT(1) OVER (PARTITION BY et.sNumeroTramite)
               FROM SimEtapaTramiteInm et
               WHERE
                  et.sNumeroTramite = t.sNumeroTramite
                  AND et.bActivo = 1

            ) et2
            WHERE
               et2.[#] = 2
               AND et2.nIdEtapa IN (11, 12) -- 12 | ASOCIACION BENEFICIARIO; 11 | RECEPCIÓN DINM
            ) = 2

-- Test

-- ======================================================================================================================================================================== */

-- 6 Trámites de inmigración con estado de trámite `APROBADO` y registro de etapas con estado `INICIADO` ...
-- ======================================================================================================================================================================== */

-- 6.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
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
   [Dependencia] = d.sNombre,

   --Aux 2
   [Cantidad Etapas (I)] = et.[nCantEtapas(I)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC),
         [nCantEtapas(I)] = COUNT(1) OVER (PARTITION BY eti.sNumeroTramite)
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.sEstado = 'I'
         AND eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1
      AND f.[nCantEtapas(I)] >= 1

) et ON et.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.sEstadoActual = 'A'
      
-- 6.2: Visualización de datos:
SELECT
   t.sNumeroTramite,
   tt.sSigla,
   et.[nCantEtapas(I)]
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC),
         [nCantEtapas(I)] = COUNT(1) OVER (PARTITION BY eti.sNumeroTramite)
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.sEstado = 'I'
         AND eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1
      AND f.[nCantEtapas(I)] >= 1

) et ON et.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.sEstadoActual = 'A'

-- ======================================================================================================================================================================== */


-- 7. Etapa actual de trámites de inmigración en SIM.dbo.SimTramiteInm, diferente a ultima etapa registrada en SIM.dbo.SimEtapaTramiteInm ...
-- ======================================================================================================================================================================== */

-- 7.1
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Número Trámite] = t.sNumeroTramite,
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
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre,

   --Aux
   [Id Etapa (SimTramiteInm)] = ti.nIdEtapaActual,
   [Id Etapa (SimEtapaTramiteInm)] = let.[nIdEtapa(Ult)],
   [Estado Etapa (SimEtapaTramiteInm)] = let.[sEstado(Ult)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]

-- 7.2: Visualización de datos:

SELECT -- Etapas distitas
   t.sNumeroTramite,
   tt.sSigla, 
   ti.nIdEtapaActual,
   let.[nIdEtapa(Ult)]
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]
UNION ALL
SELECT -- Etapas iguales
   TOP 500000
   t.sNumeroTramite,
   tt.sSigla, 
   ti.nIdEtapaActual,
   let.[nIdEtapa(Ult)]
FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.nIdEtapaActual = let.[nIdEtapa(Ult)]


-- Test ...

-- ======================================================================================================================================================================== */

-- 8. Datos personales registrados en SIM.dbo.SimPasaporte distintos a datos personales asociados al trámite ...
-- ======================================================================================================================================================================== */

-- 90 ↔ Expedición de Pasaporte Electrónico

-- 8.1
-- 8.1.1
DROP TABLE IF EXISTS #tmp_pas_j_per
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha de Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad ] = pe.sIdPaisNacionalidad,

   -- Pas
   [uIdPersona(SimPasaporte)] = t.uIdPersona,
   [sPasNumero(SimPasaporte)] = p.sPasNumero,
   [sNombre(SimPasaporte)] = LTRIM(RTRIM(p.sNombre)),
   [sPaterno(SimPasaporte)] = LTRIM(RTRIM(p.sPaterno)),
   [sMaterno(SimPasaporte)] = LTRIM(RTRIM(p.sMaterno)),

   -- Per
   [uIdPersona(SimPersona)] = pe.uIdPersona,
   [sNombre(SimPersona)] = LTRIM(RTRIM(pe.sNombre)),
   [sPaterno(SimPersona)] = LTRIM(RTRIM(pe.sPaterno)),
   [sMaterno(SimPersona)] = LTRIM(RTRIM(pe.sMaterno))

   INTO #tmp_pas_j_per
FROM SimTramitePas p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND pe.bActivo = 1
   AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico

-- 8.1.2
SELECT pp.* FROM #tmp_pas_j_per pp
WHERE
   (
      DIFFERENCE(pp.[sNombre(SimPersona)], pp.[sNombre(SimPasaporte)]) <= 3
      AND DIFFERENCE(pp.[sPaterno(SimPersona)], pp.[sPaterno(SimPasaporte)]) <= 3
      AND DIFFERENCE(pp.[sMaterno(SimPersona)], pp.[sMaterno(SimPasaporte)]) <= 3
   )


-- 8.2: Visualización de datos:
SELECT
   f.nGradoSimilitud,
   COUNT(1)
FROM (

   SELECT 

      p.sNumeroTramite,
      [nGradoSimilitud] = (
               CAST(
                  ROUND(
                     (
                        (DIFFERENCE(pe.sNombre, p.sNombre) + DIFFERENCE(pe.sPaterno, p.sPaterno) + DIFFERENCE(pe.sMaterno, p.sMaterno)) / 3
                     ),
                     0
                  ) AS TINYINT
               )

      )

   FROM SimTramitePas p
   JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
   JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
   WHERE
      t.bCancelado = 0
      AND pe.bActivo = 1
      AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico

) f
GROUP BY
   f.nGradoSimilitud
ORDER BY 2 DESC

-- Test
SELECT DIFFERENCE('roxana carla', 'carla roxana')

-- ======================================================================================================================================================================== */


-- 9. Registros de Control Migratorio duplicados en tipo de movimiento, fecha de control, hora, minuto y segundo.
-- ======================================================================================================================================================================== */

-- 9.1
SELECT 

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   -- Aux
   [Id Mov Migratorio] = mm2.sIdMovMigratorio,
   [Fecha Control] = mm2.dFechaControl,
   [Tipo] = mm2.sTipo,
   [Pais Nacionalidad] = mm2.sIdPaisNacionalidad

FROM (

   SELECT 
      mm.*,
      -- [nDupl] = COUNT(1) OVER (PARTITION BY mm.uIdPersona, mm.sTipo, CONVERT(VARCHAR(16), mm.dFechaControl, 120)) -- HH:mm
      [nDupl] = COUNT(1) OVER (
                                 PARTITION BY 
                                       mm.uIdPersona, 
                                       mm.sTipo, 
                                       CONVERT(VARCHAR(19), mm.dFechaControl, 120)
                                 ) -- yyyy-MM-dd HH:mm:ss
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) mm2
JOIN SimPersona p ON mm2.uIdPersona = p.uIdPersona
WHERE
   mm2.nDupl >= 2


-- 9.2: Visualización de datos:
SELECT 
   TOP 100000
   f.*
FROM (

   SELECT 
      mm.uIdPersona,
      [sDupl(Hora)] = (
                     CASE
                        WHEN (-- yyyy-MM-dd HH:mm:ss
                                 COUNT(1) OVER (
                                          PARTITION BY 
                                                mm.uIdPersona, 
                                                mm.sTipo, 
                                                CONVERT(VARCHAR(19), mm.dFechaControl, 120)
                                 ) >= 2
                        ) THEN 'HH:mn:ss'
                        WHEN (-- yyyy-MM-dd HH:mm
                                 COUNT(1) OVER (
                                          PARTITION BY 
                                                mm.uIdPersona, 
                                                mm.sTipo, 
                                                CONVERT(VARCHAR(16), mm.dFechaControl, 120)
                                 ) >= 2
                        ) THEN 'HH:mm'
                        WHEN (-- yyyy-MM-dd HH
                                 COUNT(1) OVER (
                                          PARTITION BY 
                                                mm.uIdPersona, 
                                                mm.sTipo, 
                                                CONVERT(VARCHAR(13), mm.dFechaControl, 120)
                                 ) >= 2
                        ) THEN 'HH'
                        ELSE ''
                     END
      )
      
   FROM SimMovMigra mm
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= '2016-01-01 00:00:00.000'
      AND CAST(mm.dFechaControl AS TIME) > '00:00:00' -- Excluye registros manuales

) f
WHERE f.[sDupl(Hora)] != ''



-- Test

-- ======================================================================================================================================================================== */


-- 10. Control Migratorios de extranjeros mayores de 18 años de edad con documento de viaje PNA(Partida de nacimiento).
-- ======================================================================================================================================================================== */

-- 10.1
SELECT 

   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,

   --- Aux   
   [Id Mov Migratorio] = mm.sIdMovMigratorio,
   [Documento Viaje] = mm.sIdDocumento,
   [Número Documento] = mm.sNumeroDoc,
   [Tipo Control] = mm.sTipo,
   [Fecha Nacimiento] = p.dFechaNacimiento,
   [Fecha Control] = mm.dFechaControl,
   [Edad (Control Migratorio)] = DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl),
   [Pais Nacionalidad] = mm.sIdPaisNacionalidad

FROM SimMovMigra mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   -- AND mm.sTipo = 'E'
   AND (mm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND mm.sIdPaisNacionalidad IS NOT NULL)
   AND mm.sIdDocumento = 'PNA' -- PNA | PARTIDA DE NACIMIENTO
   -- AND mm.dFechaControl >= '2010-01-01 00:00:00.000'
   AND DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl) >= 18 -- Mayores de edad

-- 10.2: Visualización de datos:
SELECT 

   TOP 100000
   mm.sIdDocumento,
   [nTotal] = COUNT(1)

FROM SimMovMigra mm
JOIN SimPersona p ON mm.uIdPersona = p.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND (mm.sIdPaisNacionalidad NOT IN ('PER', 'NNN') AND mm.sIdPaisNacionalidad IS NOT NULL)
   -- AND mm.sIdDocumento = 'PNA' -- PNA | PARTIDA DE NACIMIENTO
   AND DATEDIFF(YYYY, p.dFechaNacimiento, mm.dFechaControl) >= 18 -- Mayores de edad
   AND mm.sIdDocumento IN ('PNA', 'PAS', 'CIP', 'LIB', 'CE')
GROUP BY
   mm.sIdDocumento
ORDER BY 2 DESC

-- Test
SELECT DATEDIFF(YYYY, '2024-01-01', GETDATE())
SELECT DATEDIFF(YYYY, '2023-01-01', '2024-05-01')

-- ======================================================================================================================================================================== */

-- 11. Ingreso de `Menores de 9 años` con Partida de Nacimiento sin Calidad `HUMANITARIA` .
-- 12. Ingreso de `Mayores de edad` con Partida de Nacimiento sin Calidad `HUMANITARIA` .