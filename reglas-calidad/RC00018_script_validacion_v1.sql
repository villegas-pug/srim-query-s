-- RC00018
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