USE SIM
GO

--> 2. Se define como regla, que la fecha de nacimiento del pasajero no debe ser mayor a la fecha de control migratorio.
--> 3. ...


--> ░ 1. Se define como regla, que el uso del DNI como documento de viaje para ciudadanos peruanos en el control migratorio debe ser estrictamente personal.
-- ========================================================================================================================================================================

-- 1.1
DROP TABLE IF EXISTS #tmp_mm_dni
SELECT
   mm.sIdMovMigratorio,
   mm.uIdPersona,
   mm.dFechaControl,
   mm.sTipo,
   mm.sIdDocumento,
   mm.sNumeroDoc,
   [sNombre(SimPersona)] = pe.sNombre,
   [sPaterno(SimPersona)] = pe.sPaterno,
   [sMaterno(SimPersona)] = pe.sMaterno,
   [dFechaNacimiento(SimPersona)] = pe.dFechaNacimiento

   INTO #tmp_mm_dni
FROM SIM.dbo.SimMovMigra mm
JOIN SimPersona pe ON mm.uIdPersona = pe.uIdPersona
WHERE
   mm.bAnulado = 0
   AND mm.bTemporal = 0
   AND pe.sIdPaisNacionalidad = 'PER'
   AND mm.sIdDocumento = 'DNI'
   AND ( -- DNI
         ISNUMERIC(mm.sNumeroDoc) = 1
         AND LEN(mm.sNumeroDoc) = 8
   )
   AND mm.dFechaControl >= '2024-01-01 00:00:00.000'

CREATE NONCLUSTERED INDEX ix_tmp_mm_pase ON #tmp_mm_dni(uIdPersona, sNumeroDoc, dFechaControl)

-- 1.2 Final:
-- 1.2.1
DROP TABLE IF EXISTS #tmp_mm_dni_f
SELECT f2.* INTO #tmp_mm_dni_f
FROM (
   SELECT
      f.*,
      [nTotalDNI] = COUNT(1) OVER (PARTITION BY f.sNumeroDoc)
   FROM (

      SELECT
         mm.*,
         [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona, mm.sNumeroDoc ORDER BY mm.dFechaControl)
      FROM #tmp_mm_dni mm
   ) f
   WHERE
      f.[#] = 1 -- Personas
) f2
WHERE
   f2.nTotalDNI > 1 -- Total DNI usados

CREATE NONCLUSTERED INDEX ix_#tmp_mm_dni_f
   ON #tmp_mm_dni_f(uIdPersona, sNumeroDoc, [sNombre(SimPersona)], [sPaterno(SimPersona)], [sMaterno(SimPersona)])

-- 1.2.1
SELECT
   f1.*
FROM #tmp_mm_dni_f f1
WHERE
   EXISTS (
            SELECT TOP 1 1
            FROM #tmp_mm_dni_f f2
            WHERE
               f1.uIdPersona != f2.uIdPersona -- Personas distintas ...
               AND f1.sNumeroDoc = f2.sNumeroDoc -- `DNI` iguales ...
               AND (
                     DIFFERENCE(f1.[sNombre(SimPersona)], f2.[sNombre(SimPersona)]) <= 3
                     AND DIFFERENCE(f1.[sPaterno(SimPersona)], f2.[sPaterno(SimPersona)]) <= 2
                     AND DIFFERENCE(f1.[sMaterno(SimPersona)], f2.[sMaterno(SimPersona)]) <= 2
               )
   )

-- =================================================================================================================================================================================


-- 2. Se establece como regla de calidad que los países asociados al continente europeo no deberán registrar movimientos migratorios de salida a través del transporte fluvial.
-- =================================================================================================================================================================================

 SELECT 
 
   [Id Persona] = pe.uIdPersona,
   [Nombres]    = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   
   [Tipo Movimiento] = mm.sTipo,
   [Fecha Control] = mm.dFechaControl,
   [Via Transporte] = mm.sIdViaTransporte,
   [Pais Movimiento] = mm.sIdPaisMov,
   [Depemdencia] = mm.sIdDependencia


 FROM 

 SimMovMigra mm

 join SimPais ps on mm.sIdPaisMov = ps.sIdPais
 join SimPersona pe on  mm.uIdPersona = pe.uIdPersona
 join SimContinente con on ps.nIdContinente = con.nIdContinente

 where con.nIdContinente = 8 and mm.sIdViaTransporte ='F' 
 and  mm.bAnulado = 0 and mm.bTemporal = 0
 and mm.sTipo = 'S'
 and year(mm.dFechaControl)> 2016


/* ================================================================== FIN ========================================================================================= */






-- ░ Código de programación para limpiar datos de `SIM`.
-- =========================================================================================================================================================

/*
   ░ Limpieza de datos: 

      1.  Se define como regla, que cada persona debe tener una sola nacionalidad registrada en el registro de control migratorio.
      1.2 Se ha detectado que ...
-- ======================================================================================================================================================================== */


-- 1. Detección:

-- 1.1. CE
DROP TABLE IF EXISTS #tmp_ce
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ce
FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 1.2. CPP
DROP TABLE IF EXISTS #tmp_ptp
SELECT

   t.uIdPersona,
   t.sNumeroTramite,
   ce.sNumeroCarnet,
   ce.dFechaEmision,
   ce.bAnulado,
   ce.bImpreso,
   ce.bEntregado

   INTO #tmp_ptp
FROM SimCarnetPTP ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'


-- 2.3: Final ...

-- 2.3.1 Resumen:
DROP TABLE IF EXISTS #tmp_ce_final
SELECT 

   f.*
   INTO #tmp_ce_final

FROM (

   SELECT 
      e.*,
      [nOrdenCE(Desc)] = ROW_NUMBER() OVER (PARTITION BY e.uIdPersona ORDER BY e.dFechaEmision DESC), -- >=2, para `ANULAR`
      [nTotalCE] = COUNT(1) OVER (PARTITION BY e.uIdPersona),
      [nTotalCE(A)] = SUM(CAST(e.bAnulado AS INT)) OVER (PARTITION BY e.uIdPersona)
   FROM (
      SELECT * FROM #tmp_ce
      UNION ALL
      SELECT * FROM #tmp_ptp
   ) e

) f
WHERE
   f.[nTotalCE] > f.[nTotalCE(A)] -- Total CE debe ser mayor a anulados
   AND f.[nTotalCE] != f.[nTotalCE(A)] + 1 -- Total CE igaul a total anulados o distintos


-- 3.4: Final
SELECT TOP 100 *
FROM #tmp_ce_final f
ORDER BY 
   -- f.dFechaEmision DESC
   f.uIdPersona
   -- f.[nOrdenCE(Desc)]




-- ======================================================================================================================================================================== */

