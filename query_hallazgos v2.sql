USE SIM
GO

/*░
-- 7. Base de datos de Control Migratorio del Sistema Integrado de Migraciones de ciudadanos peruanos que no registran nacionalidad (NNN).
-- ========================================================================================================================================================= */

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	smm.sIdMovMigratorio,
	smm.uIdPersona,
	[sIdDocumento_CM] = smm.sIdDocumento,
	[sNumeroDoc_CM] = smm.sNumeroDoc,
	[sIdPaisNacionalidad_CM] = smm.sIdPaisNacionalidad,
	[sIdPaisNacionalidad_P] = sper.sIdPaisNacionalidad
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
	sper.bActivo = 1
	AND smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND (smm.sIdPaisNacionalidad = 'NNN' AND sper.sIdPaisNacionalidad != 'NNN')
	-- AND smm.sIdDocumento IN ('DNI', 'PAS')
	-- AND smm.nIdCalidad = 21 -- 21 | PERUANO

-- =========================================================================================================================================================



/*░
	11. Nombres registrados en el Control Migratorio no corresponden al nombres asociados a `uIdPersona` ...
===========================================================================================================================================================*/

-- 1: SimMovMigra ...
DROP TABLE IF EXISTS #tmp_movmig
SELECT
	smm.sIdMovMigratorio,
	[uIdPersona_CM] = smm.uIdPersona,
	[sNombres_CM] = smm.sNombres
	INTO #tmp_movmig
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.bTemporal = 0
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.sIdPaisNacionalidad = 'PER'
	AND (smm.sNombres != '' AND smm.sNombres IS NOT NULL)

-- Index
CREATE NONCLUSTERED INDEX IX_tmp_movmig_uIdPersona
    ON dbo.#tmp_movmig(uIdPersona_CM)

CREATE NONCLUSTERED INDEX IX_tmp_movmig_sNombres
    ON dbo.#tmp_movmig(sNombres_CM)

-- 2: SimPersona ...
DROP TABLE IF EXISTS #tmp_persona
SELECT
	[uIdPersona_PER] = sper.uIdPersona,
	[sPaterno_PER] = sper.sPaterno, 
	[sMaterno_PER] = sper.sMaterno, 
	[sNombre_PER] = sper.sNombre
	INTO #tmp_persona
FROM SimPersona sper
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND sper.sIdPaisNacionalidad = 'PER'
	AND sper.sPaterno != '' AND sper.sMaterno != ''
	AND sper.sPaterno IS NOT NULL AND sper.sMaterno IS NOT NULL

-- Index
CREATE NONCLUSTERED INDEX IX_tmp_persona_uIdPersona
    ON dbo.#tmp_persona(uIdPersona_PER)

-- 3: Final ...
-- 3.1: ...
DROP TABLE IF EXISTS #final
SELECT 
	m.*,
	p.*
	INTO #final
FROM #tmp_movmig m
JOIN #tmp_persona p ON m.uIdPersona_CM = p.uIdPersona_PER
WHERE
	(PATINDEX('%[éáíóúñ''''-]%', p.sPaterno_PER) = 0 AND PATINDEX('%[éáíóúñ''''-]%', p.sMaterno_PER) = 0 AND PATINDEX('%[éáíóúñ''''-]%', m.sNombres_CM) = 0)
	AND (m.sNombres_CM NOT LIKE '%' + LEFT(p.sPaterno_PER, 3) + '%' AND m.sNombres_CM NOT LIKE '%' + LEFT(p.sMaterno_PER, 3) + '%')

-- Test ...
-- 627,912
SELECT 
	u.sLogin,
	u.sNombre,
	[nTotal] = COUNT(1)
FROM #final f
JOIN SimPersona p ON p.uIdPersona = f.uIdPersona_PER
JOIN SimSesion s ON p.nIdSesion = s.nIdSesion
JOIN SimUsuario u ON s.nIdOperador = u.nIdOperador
GROUP BY
	u.sLogin,
	u.sNombre
ORDER BY 3 DESC

DROP TABLE IF EXISTS final_base_1
SELECT * INTO final_base_1 FROM #final
--============================================================================================================================================================ */


/*░
	14. Ciudadanos con nacionalidad `PERUANA` y calidad diferente a `PERUANO` ...
============================================================================================================================================================ */

SELECT 
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	sper.sSexo,
	sper.dFechaNacimiento,
	sper.sIdPaisNacimiento,
	sper.sIdPaisResidencia,
	sper.sIdPaisNacionalidad,
	sper.sIdEstadoCivil,
	sper.sIdDocIdentidad,
	sper.sNumDocIdentidad,
	sper.uIdPersona,
	[sCalidad] = sc.sDescripcion
FROM SimPersona sper
JOIN SimCalidadMigratoria sc ON sper.nIdCalidad = sc.nIdCalidad
WHERE
	sper.bActivo = 1
	AND sper.uIdPersona != '00000000-0000-0000-0000-000000000000'
	-- AND (sper.sIdPaisNacionalidad = 'PER' AND sper.sIdPaisNacimiento = 'PER')
	AND sper.sIdPaisNacionalidad = 'PER'
	AND sper.sIdDocIdentidad = 'DNI'
	AND (LEN(sper.sNumDocIdentidad) = 8 AND ISNUMERIC(sper.sNumDocIdentidad) = 1)
	AND sper.nIdCalidad != 21 -- 21 | PERUANO


--============================================================================================================================================================


/* ░
   16. En SIM.dbo.SimMovMigra.sNombres registrada vacíos o nulos en relación a los nombres asociados al  `uIdPersona` de SIM.dbo.SimPersona ...
--============================================================================================================================================================ */

SELECT
   -- 1
   [Nombres] = sper.sNombre,
   [Apellido 1] = sper.sPaterno,
   [Apellido 2] = sper.sMaterno,
   [Sexo] = sper.sSexo,
   [Fecha Nacimiento] = sPer.dFechaNacimiento,

   -- Aux ...
   smm.sIdMovMigratorio,
   smm.uIdPersona,
   [sNombres_MovMigra] = smm.sNombres,
   [sNombres_SimPersona] = LTRIM(RTRIM(CONCAT(sper.sPaterno, ' ', sper.sMaterno, ' ', sper.sNombre)))
FROM SimMovMigra smm
JOIN SimPersona sper ON smm.uIdPersona = sper.uIdPersona
WHERE
   smm.bAnulado = 0
   AND smm.bTemporal = 0
   AND sper.bActivo = 1
   -- AND smm.dFechaControl >= '2011-01-01 00:00:00.000'
   AND (smm.uIdPersona != '00000000-0000-0000-0000-000000000000' AND smm.uIdPersona IS NOT NULL)
   AND (smm.sNombres IS NULL OR smm.sNombres = '')

--============================================================================================================================================================


-- 42. Trámites de CCM, CPP y PTP con estato de trámite `PENDIENTE` en etapa que actualiza el estado a `APROBADO` con estado `FINALIZADO` ...
-- ======================================================================================================================================================================== */

-- 42.1
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

-- ======================================================================================================================================================================== */


-- 44. Trámites de PRR, CCM, CPP y PTP con estato de trámite `APROBADO` en etapa que actualiza el estado a `APROBADO` con estado `INICIADO` ...
-- ========================================================================================================================================================================

-- 44.1
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

-- ========================================================================================================================================================================

