/*================================================================================================*/
/*► Filtros: */
DECLARE @fec_chunk VARCHAR(55) = '2022-01-01 00:00:00'
/*================================================================================================*/

/*================================================================================================*/
/*► STEP-01: Obtener movmigra extranjeros ... */
/*================================================================================================*/
DROP TABLE IF EXISTS #tmp_extranj_movmigra
SELECT 
	DISTINCT
	smm.uIdPersona
	INTO #tmp_extranj_movmigra
FROM SimMovMigra smm
WHERE
	smm.bAnulado = 0
	AND smm.dFechaControl >= '2016-01-01 00:00:00'
	AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
	AND smm.sTipo IN ('E', 'S')
	AND smm.sIdPaisNacionalidad != 'PER'

/*→ INDEX: uIdPersona*/
CREATE NONCLUSTERED INDEX ix_#tmp_extranj_movmigra
	ON #tmp_extranj_movmigra(uIdPersona)
/*================================================================================================*/

/*================================================================================================*/
/*► STEP-01: Obtener el ultimo movimiento  migratorio de extranjeros ... */
/*================================================================================================*/
DROP TABLE IF EXISTS #tmp_extranj_ulti_movmigra
SELECT * INTO #tmp_extranj_ulti_movmigra FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY smm.uIdPersona ORDER BY smm.dFechaControl DESC) nRow_mm
	FROM SimMovMigra smm
	WHERE
		smm.bAnulado = 0
		AND smm.dFechaControl >= '2022-01-01 00:00:00'
		AND smm.uIdPersona != '00000000-0000-0000-0000-000000000000'
		AND smm.sTipo IN ('E', 'S')
		AND smm.sIdPaisNacionalidad != 'PER'
) tmp_smm
WHERE 
	tmp_smm.nRow_mm <= 2

/*→ INDEX: uIdPersona*/
CREATE NONCLUSTERED INDEX ix_#tmp_extranj_ulti_movmigra_uIdPersona
	ON #tmp_extranj_ulti_movmigra(uIdPersona)
/*================================================================================================*/

/*================================================================================================*/
/*► STEP-02: Obtener el ultimo trámite de CCM y ... */
/*================================================================================================*/
DROP TABLE IF EXISTS #tmp_extranj_ulti_ccm
--SELECT * FROM #tmp_extranj_ulti_ccm ORDER BY uIdPersona
SELECT * INTO #tmp_extranj_ulti_ccm FROM(
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY uIdPersona ORDER BY dFechaAud DESC) nRow_tram
	FROM (
		SELECT * FROM (
			SELECT 
				st.uIdPersona,
				st.nIdTipoTramite,
				sti.sEstadoActual,
				[nIdCalSolicitada] = '',
				st.dFechaHoraReg [dFechaAud],
				[dFechaVencimiento] = '',
				ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY st.dFechaHoraReg DESC) nRow
			FROM SimTramite st
			JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
			WHERE
				sti.sEstadoActual = 'P'
				AND (st.nIdTipoTramite = 58 OR st.nIdTipoTramite = 39) -- CCM & Permiso de Viaje
				AND st.dFechaHoraReg >= '2022-01-01 00:00:00'
				AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
		) tmp_tram
		WHERE
			tmp_tram.nRow <= 2

		UNION ALL
		
		SELECT * FROM (-- Ultimo CCM Aprobado ...
			SELECT 
				st.uIdPersona,
				st.nIdTipoTramite,
				sti.sEstadoActual,
				sccm.nIdCalSolicitada,
				sccm.dFechaAprobacion [dFechaAud],
				sccm.dFechaVencimiento,
				ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sccm.dFechaAprobacion DESC) nRow
			FROM SimTramite st
			JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
			JOIN SimCambioCalMig sccm ON st.sNumeroTramite = sccm.sNumeroTramite
			WHERE
				sti.sEstadoActual = 'A'
				AND st.nIdTipoTramite = 58 -- CCM
				AND st.dFechaHoraReg >= '2022-01-01 00:00:00'
				AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
		) tmp_tram
		WHERE
			tmp_tram.nRow = 1

		UNION ALL

		SELECT * FROM (-- Ultima PRP Aprobada ...
			SELECT 
				st.uIdPersona,
				st.nIdTipoTramite,
				sti.sEstadoActual,
				[nIdCalSolicitada] = '',
				sti.dFechaFin [dFechaAud],
				spro.dFechaVencimiento,
				ROW_NUMBER() OVER (PARTITION BY st.uIdPersona ORDER BY sti.dFechaFin DESC) nRow
			FROM SimTramite st
			JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
			JOIN SimProrroga spro ON st.sNumeroTramite = spro.sNumeroTramite
			WHERE
				sti.sEstadoActual = 'A'
				AND st.nIdTipoTramite = 56 -- PRP
				AND st.dFechaHoraReg >= '2022-01-01 00:00:00'
				AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
		) tmp_tram
		WHERE
			tmp_tram.nRow = 1
	) tmp_1
) tmp_2
WHERE tmp_2.nRow_tram <= 2

/*→ INDEX: uIdPersona ... */
CREATE NONCLUSTERED INDEX ix_#tmp_extranj_ulti_ccm_uIdPersona
	ON #tmp_extranj_ulti_ccm(uIdPersona)
/*================================================================================================*/

/*================================================================================================*/
/*► STEP-03: Si ultimo movmigra es `E` y realizó CCM(Estado: P | Posterior al movmigra) ... */
/*================================================================================================*/
--DROP FUNCTION ufn_obtener_tipo_cal
CREATE OR ALTER FUNCTION ufn_obtener_tipo_cal(@cal VARCHAR(55))
RETURNS VARCHAR(100)
AS
BEGIN
	RETURN CASE 
				WHEN @cal LIKE '%TRAB%' THEN 'RESIDENTE'
				WHEN @cal LIKE '%PERMA%' THEN 'RESIDENTE'
				WHEN @cal IN ('FAMILIAR RESIDENTE', 'FAMILIAR DE RESIDENTE') THEN 'RESIDENTE'
				WHEN @cal LIKE '%INMIGRANTE%' THEN 'INMIGRANTE'
				ELSE 'TEMPORAL'
			END
END

DROP TABLE IF EXISTS tmp_estadia_migratoria
CREATE TABLE tmp_estadia_migratoria
(
	[uIdPersona] UNIQUEIDENTIFIER,
	[Tipo Calidad Migratoria] VARCHAR(55) NULL,
	[Calidad Migratoria] VARCHAR(55) NULL,
	[Fecha Inicio Calidad Migratoria] DATE NULL,
	[Fecha Vencimiento Calidad Migratoria] DATE NULL
)

CREATE OR ALTER PROCEDURE usp_crear_tmp_estadia_migratoria
AS
BEGIN

	--Variables
	DECLARE @uId UNIQUEIDENTIFIER

	--Cursor
	DECLARE mm_ext_c CURSOR FOR SELECT uIdPersona FROM #tmp_extranj_movmigra

	OPEN mm_ext_c

	FETCH NEXT FROM mm_ext_c INTO @uId

	WHILE @@FETCH_STATUS = 0
	BEGIN
		/*→ nRow: 1, 2 ...*/
		DECLARE @ult_mm CHAR(1) = (SELECT sTipo FROM #tmp_extranj_ulti_movmigra WHERE uIdPersona = @uId AND nRow_mm = 1),
				@penult_mm CHAR(1) = ISNULL((SELECT sTipo FROM #tmp_extranj_ulti_movmigra WHERE uIdPersona = @uId AND nRow_mm = 2), ''),

				@ult_tram INT = ISNULL((SELECT nIdTipoTramite FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 1), 0),
				@penult_tram INT = ISNULL((SELECT nIdTipoTramite FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 2), 0),

				@e_ult_tram CHAR(1) = ISNULL((SELECT sEstadoActual FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 1), ''),
				@e_penult_tram CHAR(1) = ISNULL((SELECT sEstadoActual FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 2), ''),

				@cal_ult_mm VARCHAR(55) = (SELECT scm.sDescripcion FROM #tmp_extranj_ulti_movmigra smm 
									       JOIN SimCalidadMigratoria scm ON  smm.nIdCalidad = scm.nIdCalidad
									       WHERE smm.uIdPersona = @uId AND smm.nRow_mm = 1),
				@cal_ult_e VARCHAR(55) = (SELECT scm.sDescripcion FROM #tmp_extranj_ulti_movmigra smm 
									      JOIN SimCalidadMigratoria scm ON  smm.nIdCalidad = scm.nIdCalidad
									      WHERE smm.uIdPersona = @uId AND smm.sTipo = 'E'),
				@cal_ccm_a VARCHAR(55) = (SELECT scm.sDescripcion FROM #tmp_extranj_ulti_ccm st
									      JOIN SimCalidadMigratoria scm ON  st.nIdCalSolicitada = scm.nIdCalidad
									      WHERE st.uIdPersona = @uId AND st.sEstadoActual = 'A'),
				@fec_aud_ccm_a DATETIME = ISNULL((SELECT dFechaAud FROM #tmp_extranj_ulti_ccm 
											      WHERE uIdPersona = @uId AND nIdTipoTramite = 58 AND sEstadoActual = 'A'), ''),
				@fec_aud_prp_a DATETIME = ISNULL((SELECT dFechaAud FROM #tmp_extranj_ulti_ccm 
											      WHERE uIdPersona = @uId AND nIdTipoTramite = 56 AND sEstadoActual = 'A'), ''),
				@fec_venc_ccm_a DATETIME = ISNULL((SELECT [dFechaVencimiento] FROM #tmp_extranj_ulti_ccm 
											       WHERE uIdPersona = @uId AND nIdTipoTramite = 58 AND sEstadoActual = 'A'), ''),
				@fec_venc_prp_a DATETIME = ISNULL((SELECT [dFechaVencimiento] FROM #tmp_extranj_ulti_ccm 
											       WHERE uIdPersona = @uId AND nIdTipoTramite = 56 AND sEstadoActual = 'A'), ''),
				@fec_aud_ult_tram DATETIME = ISNULL((SELECT dFechaAud FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 1), ''),
				@fec_aud_penult_tram DATETIME = ISNULL((SELECT dFechaAud FROM #tmp_extranj_ulti_ccm WHERE uIdPersona = @uId AND nRow_tram = 2), ''),
				@fec_ult_mm DATETIME = ISNULL((SELECT dFechaControl FROM #tmp_extranj_ulti_movmigra smm WHERE smm.uIdPersona = @uId AND smm.nRow_mm = 1), ''),
				@fec_ult_e DATETIME = ISNULL((SELECT dFechaControl FROM #tmp_extranj_ulti_movmigra WHERE uIdPersona = @uId AND sTipo = 'E'), ''),
				@fec_ult_s DATETIME = ISNULL((SELECT dFechaControl FROM #tmp_extranj_ulti_movmigra WHERE uIdPersona = @uId AND sTipo = 'S'), ''),

				@dias_perm_ult_e INT = (SELECT nPermanencia FROM #tmp_extranj_ulti_movmigra WHERE uIdPersona = @uId AND sTipo = 'E')
				
		/*► Si ultimo movmig es `E` o Si ultimo movmig es `S` y no registra trámites de CCM ... */
		IF (@ult_mm = 'E' OR (@ult_mm = 'S' AND @ult_tram = 0))
			INSERT INTO tmp_estadia_migratoria
				SELECT 
					@uId,
					[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ult_e)),
					@cal_ult_e,
					@fec_ult_e,
					DATEADD(DD, @dias_perm_ult_e, @fec_ult_e)

		ELSE IF(/*► Si tiene `E`y realizó el trámite de CCM(Estado: P) y solicitó Permiso de Viaje ...*/
					@ult_mm = 'S'
					AND @ult_tram = 39 
					AND @e_ult_tram = 'P'
					AND @penult_tram = 58
					AND @e_penult_tram = 'P'
				)
			INSERT INTO tmp_estadia_migratoria
					SELECT 
						@uId,
						[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ult_e)),
						@cal_ult_e,
						@fec_ult_e,
						DATEADD(DD, @dias_perm_ult_e, @fec_ult_e)
		
		ELSE IF(/*► CCM `A` ...*/
					(@ult_mm = 'E' OR @penult_mm = 'E')
					AND (@e_ult_tram = 'A' OR @e_penult_tram = 'A')
					AND (@ult_tram = 58 OR @penult_tram = 58)
					AND @fec_ult_e < @fec_aud_ccm_a --Si valor es: 1900-01-01 00:00:00.000, trámite no `A`
				)
			INSERT INTO tmp_estadia_migratoria
					SELECT 
						@uId,
						[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ccm_a)),
						@cal_ccm_a,
						@fec_aud_ccm_a,
						@fec_venc_ccm_a

		ELSE IF(/*► PRP `A` ...*/
					(@ult_mm = 'E' OR @penult_mm = 'E')
					AND (@e_ult_tram = 'A' OR @e_penult_tram = 'A')
					AND (@ult_tram = 56 OR @penult_tram = 56)-- PRP
					AND @fec_ult_e < @fec_aud_prp_a --Si valor es: 1900-01-01 00:00:00.000, trámite no `A`
				)
			INSERT INTO tmp_estadia_migratoria
					SELECT 
						@uId,
						[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ult_e)),
						@cal_ult_e,
						@fec_ult_e,
						@fec_venc_prp_a

		ELSE IF(/*► ...*/
					dbo.ufn_obtener_tipo_cal(@cal_ult_mm) = 'TEMPORAL'
					AND @ult_mm = 'E'
					AND (@ult_tram = 58 OR @penult_tram = 58)-- CCM
					AND (@e_ult_tram = 'A' OR @e_penult_tram = 'A')
					AND @fec_ult_mm < @fec_aud_ccm_a --Si valor es: 1900-01-01 00:00:00.000, trámite no `A`
				)
			INSERT INTO tmp_estadia_migratoria
					SELECT 
						@uId,
						[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ult_mm)),
						@cal_ult_mm,
						@fec_aud_ccm_a,
						@fec_venc_ccm_a

		ELSE IF(/*► ...*/
					dbo.ufn_obtener_tipo_cal(@cal_ult_e) = 'RESIDENTE'
					AND (@ult_mm = 'E' OR @penult_mm = 'E')
					AND (@ult_tram = 58 OR @penult_tram = 58)-- CCM
					AND (@e_ult_tram = 'A' OR @e_penult_tram = 'A')
					AND @fec_aud_ccm_a < @fec_ult_e --Si valor es: 1900-01-01 00:00:00.000, trámite no `A`
				)
			INSERT INTO tmp_estadia_migratoria
					SELECT 
						@uId,
						[Tipo Calidad Migratoria] = (SELECT dbo.ufn_obtener_tipo_cal(@cal_ccm_a)),
						@cal_ccm_a,
						@fec_aud_ccm_a,
						@fec_venc_ccm_a
		/*► ... */
		FETCH NEXT FROM mm_ext_c INTO @uId

	END

	--Cleanup
	CLOSE mm_ext_c
	DEALLOCATE mm_ext_c
	
END

--Index `tmp`
CREATE NONCLUSTERED INDEX ix_tmp_estadia_migratoria_uIdPersona
ON tmp_estadia_migratoria(uIdPersona)

/*→ Test-Main: */
EXEC usp_crear_tmp_estadia_migratoria
SELECT * FROM tmp_estadia_migratoria sem
WHERE sem.uIdPersona = 'C7A2A9F9-CB71-49F5-8E4D-5A0C9678634A'

/*→ Test ...*/
SELECT ISNULL((SELECT nIdTipoTramite FROM SimTipoTramite WHERE nIdTipoTramite = 10000), 0)
SELECT * FROM SimTipoTramite WHERE sDescripcion LIKE '%permane%'
SELECT * FROM SimCalidadMigratoria scm WHERE scm.sDescripcion LIKE '%tur%'

SELECT * FROM SimMovMigra smm WHERE smm.uIdPersona = 'C7A2A9F9-CB71-49F5-8E4D-5A0C9678634A' ORDER BY smm.dFechaControl DESC

SELECT * FROM SimPersona sp WHERE sp.sNombre LIKE '%luis%' AND sp.sPaterno = 'isnard' AND sp.sMaterno = 'jimenez'
/*================================================================================================*/
	