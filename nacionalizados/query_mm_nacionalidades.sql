/*

	1. Cantidad de ciudadanos que ingresaron al país.
	2. Cantidad de ciudadanos que salieron del país.
	3. Cantidad de ciudadanos que se encuentran actualmente en el país como turista y otra calidad.
	4. Cantidad de ciudadanos que se encuentran irregular por exceso de permanencia.
	5. Cantidad de ciudadanos que se encuentran realizando un trámite ante MIGRACIONES.

	» Paises:
	- República del Salvador, Emiratos Árabes, Arabia Saudita, Qatar, República de Kosovo, Bosnia, Herzegovina, República de Albania

*/

-- Aux: `tmp` ...
SELECT 
	smm.*,
	[sPaisNacionalidad] = spa.sNacionalidad
	INTO #tmp_mm_nacionalidades
FROM SimMovMigra smm
JOIN SimPais spa ON smm.sIdPaisNacionalidad = spa.sIdPais
WHERE
	smm.bAnulado = 0
	AND smm.dFechaControl >= '2016-01-01 00:00:00.000'
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.sIdPaisNacionalidad IN ('SAL', 'EAU', 'ASA', 'QAT', 'KOS', 'BOS')

-- Index ...
CREATE INDEX IX_tmp_mm_nacionalidades_uIdPersona
    ON dbo.#tmp_mm_nacionalidades(uIdPersona)



/*» -- 1. Cantidad de ciudadanos que ingresaron al país.
======================================================================================================*/
SELECT pv.* FROM (

	SELECT 
		mm2.uIdPersona,
		[nAñoControl] = DATEPART(YYYY, mm2.dFechaControl),
		mm2.sPaisNacionalidad
	FROM (

		SELECT 
			*,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm1.uIdPersona ORDER BY mm1.dFechaControl DESC)
		FROM #tmp_mm_nacionalidades mm1
		WHERE
			mm1.sTipo = 'E'

	) mm2
	WHERE 
		mm2.nFila_mm = 1

) mm3 
PIVOT(
	COUNT(mm3.uIdPersona) FOR mm3.[nAñoControl] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv
ORDER BY
	pv.sPaisNacionalidad


-- 1.2 

SELECT 
	sper.uIdPersona,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	[sDocumento_SimPersona] = sper.sIdDocIdentidad,
	[sNumeroDoc_SimPersona] = sper.sNumDocIdentidad,
	[sDocumento_Viaje] = mm2.sIdDocumento,
	[sNumeroDoc_Viaje] = mm2.sNumeroDoc,
	sper.sSexo,
	sper.dFechaNacimiento,
	mm2.sPaisNacionalidad,
	mm2.dFechaControl,
	[sUltimoMovMigra] = mm2.sTipo
FROM (

	SELECT 
		*,
		[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm1.uIdPersona ORDER BY mm1.dFechaControl DESC)
	FROM #tmp_mm_nacionalidades mm1

) mm2
JOIN SimPersona sper ON mm2.uIdPersona = sper.uIdPersona
WHERE 
	mm2.nFila_mm = 1

--======================================================================================================*/

/*» 2. Cantidad de ciudadanos que salieron del país.
======================================================================================================*/
SELECT pv.* FROM (

	SELECT 
		mm2.uIdPersona,
		[nAñoControl] = DATEPART(YYYY, mm2.dFechaControl),
		mm2.sPaisNacionalidad
	FROM (

		SELECT
			*,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm1.uIdPersona ORDER BY mm1.dFechaControl DESC)
		FROM #tmp_mm_nacionalidades mm1

	) mm2
	WHERE 
		mm2.nFila_mm = 1
		AND mm2.sTipo = 'S'

) mm3 
PIVOT(
	COUNT(mm3.uIdPersona) FOR mm3.[nAñoControl] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv
ORDER BY
	pv.sPaisNacionalidad
--======================================================================================================*/

/*» 3. Cantidad de ciudadanos que se encuentran actualmente en el país como turista y otra calidad.
======================================================================================================*/
SELECT pv.* FROM (

	SELECT 
		mm2.uIdPersona,
		mm2.sPaisNacionalidad,
		mm2.[sCalidadMigratoria],
		[nAñoControl] = DATEPART(YYYY, mm2.dFechaControl)
	FROM (

		SELECT
			mm1.*,
			[sCalidadMigratoria] = scm.sDescripcion,
			[nFila_mm] = ROW_NUMBER() OVER (PARTITION BY mm1.uIdPersona ORDER BY mm1.dFechaControl DESC)
		FROM #tmp_mm_nacionalidades mm1
		JOIN SimCalidadMigratoria scm ON mm1.nIdCalidad = scm.nIdCalidad

	) mm2
	WHERE 
		mm2.nFila_mm = 1
		AND mm2.sTipo = 'E'

) mm3 
PIVOT(
	COUNT(mm3.uIdPersona) FOR mm3.[nAñoControl] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv
ORDER BY
	pv.sPaisNacionalidad
--======================================================================================================*/

/*» 4. Cantidad de ciudadanos que se encuentran irregular por exceso de permanencia.
======================================================================================================*/
SELECT * FROM (

	SELECT
		r.uIdPersona,
		[nAñoIngreso] = DATEPART(YYYY, r.Ingreso),
		-- [sCalidadMigratoria] = r.CalidadMigratoria,
		[sNacionalidad] = r.Nacionalidad
	FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru r
	WHERE
		r.Ingreso >= '2016-01-01 00:00:00.000'
		AND r.EstadoR3 = 'Irregulares'
		AND r.Nacionalidad IN (
				'ARABE Y SAUDITA', 
				'BOSNIA Y HERSEGOVINA', 
				'EMIRATOS ARABES UNIDOS',
				'KOSOVO',
				'DE KATAR',
				'SALVADOREÑA'
			)

) r2 PIVOT(
	COUNT(r2.uIdPersona) FOR r2.[nAñoIngreso] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv
ORDER BY
	pv.sNacionalidad

-- 4.1: Det ...
SELECT
	sper.uIdPersona,
	sper.sNombre,
	sper.sPaterno,
	sper.sMaterno,
	[sDocumento_SimPersona] = sper.sIdDocIdentidad,
	[sNumeroDoc_SimPersona] = sper.sNumDocIdentidad,
	[sDocumento_Viaje] = '',
	[sNumeroDoc_Viaje] = '',
	sper.sSexo,
	sper.dFechaNacimiento,
	r.Nacionalidad,
	[nFechaIngreso] = r.Ingreso,
	[sUltimoMovMigra] = IIF(r.EnPeru = 1, 'E', 'S')
FROM BD_SIRIM.dbo.RimTotalExtranjerosPeru r
JOIN SimPersona sper ON r.uIdPersona = sper.uIdPersona
WHERE
	r.Ingreso >= '2016-01-01 00:00:00.000'
	AND r.EstadoR3 = 'Irregulares'
	AND r.Nacionalidad IN (
			'ARABE Y SAUDITA', 
			'BOSNIA Y HERSEGOVINA', 
			'EMIRATOS ARABES UNIDOS',
			'KOSOVO',
			'DE KATAR',
			'SALVADOREÑA'
		)


-- ======================================================================================================*/

/*» 5. Cantidad de ciudadanos que se encuentran realizando un trámite ante MIGRACIONES.
======================================================================================================*/
SELECT * FROM (

	SELECT 
		t.sNumeroTramite,
		t.sNacionalidad,
		t.[nAñoTramite]
	FROM (

		SELECT 
			st.sNumeroTramite,
			spa.sNacionalidad,
			[nAñoTramite] = DATEPART(YYYY, st.dFechaHoraReg),
			[nFila_t] = ROW_NUMBER() OVER(PARTITION BY st.uIdPersona ORDER BY st.dFechaHoraReg DESC)
		FROM SimTramite st
		JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
		-- JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
		JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
		JOIN SimPais spa ON sper.sIdPaisNacionalidad = spa.sIdPais
		WHERE
			st.bCancelado = 0
			AND st.dFechaHoraReg >= '2016-01-01 00:00:00.000'
			AND sti.sEstadoActual IN ('P', 'A')
			AND spa.sIdPais IN ('SAL', 'EAU', 'ASA', 'QAT', 'KOS', 'BOS')

	) t
	WHERE 
		t.nFila_t = 1

) t2 PIVOT(
	COUNT(t2.sNumeroTramite) FOR t2.[nAñoTramite] IN ([2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023])
) pv
ORDER BY
	pv.sNacionalidad
--======================================================================================================*/

