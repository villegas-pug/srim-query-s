USE SIM
GO

-- 1. Frontera
/*
   10 ↔ PCF LA TINA
   11 ↔ PCF EL ALAMOR
   77 ↔ PCF ESPINDOLA
   115 ↔ CEBAF LA TINA - MACARA
*/

SELECT 
   (d.sNombre)[sDependencia],
   (CASE mm.sTipo
      WHEN 'S' THEN 'SALIDA'
      WHEN 'E' THEN 'ENTRADA'
   END)[sControl],
   (m.sIdModulo)[sTipoControl],
   (pn.sNacionalidad)[sNacionalidad],
   (per.sSexo)[sSexo],
   [sRangoEdad] = CASE 
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 0 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 9 THEN '0 - 9'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 10 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 19 THEN '10 - 19'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 20 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 29 THEN '20 - 29'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 30 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 39 THEN '30 - 39'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 40 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 49 THEN '40 - 49'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 50 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 59 THEN '50 - 59'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 60 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 69 THEN '60 - 69'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 70 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 79 THEN '70 - 79'
                     WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 80 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 89 THEN '80 - 89'
                     ELSE '90 a más'
               END,
   (pm.sNombre)[sOrigenDestino],
   CAST(mm.dFechaControl AS DATE) [dFechaControl],
   vt.sDescripcion sViaTransporte,
   COUNT(mm.sIdMovMigratorio)[nTotalCtrlMig]
FROM SimMovMigra mm
JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
JOIN SimModulo m ON mm.sIdModuloDigita = m.sIdModulo
JOIN SimPais pn ON mm.sIdPaisNacionalidad = pn.sIdPais
JOIN SimPersona per ON mm.uIdPersona = per.uIdPersona
JOIN SimPais pm ON mm.sIdPaisMov = pm.sIdPais
LEFT JOIN SimViaTransporte vt ON mm.sIdViaTransporte = vt.sIdViaTransporte
WHERE 
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND mm.dFechaControl BETWEEN '2022-01-01 00:00:00.000' AND '2024-07-04 23:59:59.999'
   -- AND mm.dFechaControl >= '2024-05-19 00:00:00.000'
   AND mm.sIdDependencia IN ('06', '10', '11', '77', '115')
GROUP BY
   d.sNombre,
   CASE mm.sTipo WHEN 'S' THEN 'SALIDA' WHEN 'E' THEN 'ENTRADA' END,
   m.sIdModulo,
   pn.sNacionalidad,
   per.sSexo,
   CASE 
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 0 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 9 THEN '0 - 9'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 10 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 19 THEN '10 - 19'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 20 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 29 THEN '20 - 29'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 30 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 39 THEN '30 - 39'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 40 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 49 THEN '40 - 49'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 50 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 59 THEN '50 - 59'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 60 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 69 THEN '60 - 69'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 70 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 79 THEN '70 - 79'
      WHEN DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) >= 80 AND DATEDIFF(YYYY, per.dFechaNacimiento, mm.dFechaControl) <= 89 THEN '80 - 89'
      ELSE '90 a más'
   END,
   pm.sNombre,
   CAST(mm.dFechaControl AS DATE),
   vt.sDescripcion


-- 2. Trámites `PIURA` ...
-- 06 ↔ PIURA
-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP; 57 ↔ PRORROGA DE RESIDENCIA
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
   [Fecha Ultima Etapa] = (
                              SELECT 
                                 TOP 1 
                                 [dFecha] = (
                                                CASE
                                                   WHEN et.sEstado = 'F' THEN et.dFechaHoraFin
                                                   ELSE et.dFechaHoraInicio
                                                END
                                             )
                              FROM SimEtapaTramiteInm et
                              WHERE
                                 et.sNumeroTramite = t.sNumeroTramite 
                                 AND et.bActivo = 1
                              ORDER BY et.nIdEtapaTramite DESC
                        ),
   [Estado Etapa Actual] = (
                                 SELECT 
                                    TOP 1 
                                    et.sEstado
                                 FROM SimEtapaTramiteInm et
                                 WHERE
                                    et.sNumeroTramite = t.sNumeroTramite 
                                    AND et.bActivo = 1
                                 ORDER BY et.nIdEtapaTramite DESC
                           ),
   [Dependencia] = d.sNombre

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
WHERE
   t.bCancelado = 0
   -- AND t.bCulminado = 1
   -- AND ti.sEstadoActual = 'P'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP; 57 ↔ PRORROGA DE RESIDENCIA
   AND t.sIdDependencia = '06' -- Piura


-- 2. Trámites `PIURA`: Etapas ...
-- 112 ↔ JEFATURA ZONAL CALLAO
-- 310,718 | 310,644

SELECT 
   t2.*
FROM (

   SELECT
      
      -- TOP 100

      [Número Tramite] = t.sNumeroTramite,
      [Fecha Trámite] = t.dFechaHora,
      [Tipo Trámite] = tt.sDescripcion,
      [Estado Trámite] = ti.sEstadoActual,
      [Id Etapa] = e.nIdEtapa,
      [Etapa Trámite] = e.sDescripcion,
      [Estado Etapa] = eti.sEstado,
      [Usuario (Inicia)] = ui.sNombre,
      [Usuario (Finaliza)] = uf.sNombre,
      [Fecha Etapa (Inicio)] = eti.dFechaHoraInicio,
      [Fecha Etapa (Fin)] = ISNULL(eti.dFechaHoraFin, eti.dFechaHoraInicio),
      [Dependencia] = d.sNombre,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC)

   FROM SimTramite t
   JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
   JOIN SimEtapaTramiteInm eti ON t.sNumeroTramite = eti.sNumeroTramite
   JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
   JOIN SimEtapa e ON eti.nIdEtapa = e.nIdEtapa
   JOIN SimUsuario ui ON ui.nIdOperador = eti.nIdUsrInicia
   JOIN SimUsuario uf ON uf.nIdOperador = eti.nIdUsrFinaliza
   JOIN SImDependencia d ON t.sIdDependencia = d.sIdDependencia
   WHERE
      t.bCancelado = 0
      -- AND t.bCulminado = 1
      AND t.uIdPersona != '00000000-0000-0000-0000-000000000000'
      AND eti.bActivo = 1 -- Etapa activa
      -- AND eti.sEstado = 'F' -- Etapa finalizadas
      AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 58 ↔ CCM; 113 ↔ CPP; 126 ↔ PTP; 57 ↔ PRORROGA DE RESIDENCIA
      AND t.sIdDependencia = '06' -- JJZZ Piura
      AND t.dFechaHora >= '2022-01-01 00:00:00.000'

) t2
WHERE
   t2.[#] = 1


-- Test
-- CCM | PRR | PTP | CPP

-- 3. PAS-E & CE ...
-- 112 ↔ JEFATURA ZONAL CALLAO
-- 90 ↔ Expedición de Pasaporte Electrónico

-- 3.1
SELECT -- PAS-E

   [Numero Tramite] = t.sNumeroTramite,
   [Tipo Tramite] = 'Pasaporte',
   [Pasaporte/CE] = p.sPasNumero,
   [Fecha Emision] = p.dFechaEmision,
   [Sexo] = pe.sSexo,
   [Rango Edad] = CASE 
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 0 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 9 THEN '0 - 9'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 10 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 19 THEN '10 - 19'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 20 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 29 THEN '20 - 29'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 30 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 39 THEN '30 - 39'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 40 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 49 THEN '40 - 49'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 50 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 59 THEN '50 - 59'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 60 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 69 THEN '60 - 69'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 70 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 79 THEN '70 - 79'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) >= 80 AND DATEDIFF(YYYY, pe.dFechaNacimiento, p.dFechaEmision) <= 89 THEN '80 - 89'
                        ELSE '90 a más'
               END,
   [Estado] = p.sEstadoActual

FROM SimPasaporte p
JOIN SimTramite t ON p.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1 
   AND t.nIdTipoTramite = 90 -- 90 ↔ Expedición de Pasaporte Electrónico
   AND t.sIdDependencia = '06' -- JJZZ Piura
   AND p.dFechaEmision >= '2022-01-01 00:00:00.000'
UNION ALL
SELECT -- C.E.

   [Numero Tramite] = t.sNumeroTramite,
   [Tipo Tramite] = 'CE',
   [Pasaporte/CE] = ce.sNumeroCarnet,
   [Fecha Emision] = ce.dFechaEmision,
   [Sexo] = pe.sSexo,
   [Rango Edad] = CASE 
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 0 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 9 THEN '0 - 9'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 10 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 19 THEN '10 - 19'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 20 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 29 THEN '20 - 29'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 30 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 39 THEN '30 - 39'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 40 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 49 THEN '40 - 49'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 50 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 59 THEN '50 - 59'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 60 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 69 THEN '60 - 69'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 70 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 79 THEN '70 - 79'
                        WHEN DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) >= 80 AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) <= 89 THEN '80 - 89'
                        ELSE '90 a más'
               END,
   [Estado] = 'E'
   
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimPersona pe ON t.uIdPersona = pe.uIdPersona
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1 
   AND ce.bEntregado = 1
   AND t.sIdDependencia = '06' -- JJZZ Piura
   AND ce.dFechaEmision >= '2022-01-01 00:00:00.000'

-- Test
