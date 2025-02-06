USE SIM
GO

-- ========================================================================================================================
-- Venezolanos 2016 - 2022: Permanecen y cuantos se fueron. Porcentaje de mujeres. Si realizaron regularización.
-- ========================================================================================================================
SELECT
	[nacionalidad] = mm.sNacionalidad,
	[total] = COUNT(1) 
FROM (

	SELECT 
		smm.*,
		spa.sNacionalidad,
		sp.sSexo,
		[nRow_mm] = ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC)
	FROM SimMovMigra smm
	JOIN SimPersona sp ON smm.uIdPersona = sp.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl  BETWEEN '2016-01-01 00:00:00.000' AND '2022-11-01 23:59:59.999'
		-- AND smm.sIdPaisNacionalidad = 'VEN'
		AND smm.sIdPaisNacionalidad IN ('HAI', 'CUB') -- HAI | CUB

) mm
WHERE 
	mm.nRow_mm = 1
	AND mm.sTipo = 'E' -- Permanecen
	-- AND mm.sTipo = 'S' -- Se fueron
	-- AND mm.sSexo = 'M'
	AND mm.sSexo = 'F'
GROUP BY 
	mm.sNacionalidad
-- ========================================================================================================================

-- ========================================================================================================================
-- Venezolanos 2016 - 2022: Si realizaron regularización.
-- 113 | REGULARIZACION DE EXTRANJEROS
-- ========================================================================================================================
SELECT 
	[año regularizacion] = reg.sNacionalidad,
	[total] = COUNT(reg.sNumeroTramite)
FROM (

	SELECT 
		sti.*,
		spa.sNacionalidad,
		[nRow_reg] = ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sti.dFechaFin DESC)
	FROM SimTramite st 
	JOIN SimPersona sp ON sp.uIdPersona = st.uIdPersona
	JOIN SimPais spa ON sp.sIdPaisNacionalidad = spa.sIdPais
	JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
	WHERE
		-- sp.sIdPaisNacionalidad = 'VEN'
		sp.sIdPaisNacionalidad IN ('HAI', 'CUB') -- HAI | CUB
		AND st.nIdTipoTramite = 113
		AND sti.sEstadoActual = 'A'

) reg
WHERE reg.nRow_reg = 1
GROUP BY 
	-- DATEPART(YYYY, reg.dFechaFin)
	reg.sNacionalidad
-- ========================================================================================================================