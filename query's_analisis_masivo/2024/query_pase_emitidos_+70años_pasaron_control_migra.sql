USE SIM
GO

-- 1. Pasaportes electrónicos >= 70 años
DROP TABLE IF EXISTS #tmp_pase_70años_mayorigual
SELECT
   p.*,
   t.uIdPersona
	INTO #tmp_pase_70años_mayorigual
FROM SIM.dbo.SimPasaporte p
JOIN SIM.dbo.SimTramite t ON t.sNumeroTramite = p.sNumeroTramite
WHERE
   t.bCancelado = 0
	AND t.nIdTipoTramite = 90 -- EXPEDICIÓN DE PASAPORTE ELECTRÓNICO
	AND LEN(LTRIM(RTRIM(p.sPasNumero))) = 9
	AND ISNUMERIC(p.sPasNumero) = 1
	AND p.sPasNumero LIKE '1[1-2]%'
   AND DATEDIFF(YEAR, p.dFechaNacimiento, p.dFechaEmision) >= 70

-- 2. Primer movimiento de salida que uso el pase ...
DROP TABLE IF EXISTS #tmp_pase_70años_mayorigual_final
SELECT
   f.*,
   [nUsoPase(Dias)] = DATEDIFF(DD, f.dFechaEmision, f.dFechaControl)
   INTO #tmp_pase_70años_mayorigual_final
FROM (

   SELECT
      p.uIdPersona,
      p.sPasNumero,
      p.dFechaEmision,
      p.dFechaNacimiento,
      mm.dFechaControl,
      mm.sTipo,
      mm.sIdDocumento,
      mm.sNumeroDoc,

      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl ASC)

   FROM #tmp_pase_70años_mayorigual p
   JOIN SimMovMigra mm ON mm.uIdPersona = p.uIdPersona
                       AND mm.sIdDocumento = 'PAS'
                       AND mm.sNumeroDoc = p.sPasNumero
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND mm.dFechaControl >= p.dFechaEmision

) f
WHERE
   f.[#] = 1 -- Primer movimiento porsterios a la fecha emisión de pase
   AND f.sTipo = 'S'

-- 3 Final: Agrupar ...
SELECT 
   * 
FROM #tmp_pase_70años_mayorigual_final