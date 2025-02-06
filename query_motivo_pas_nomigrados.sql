USE SIM
GO

SELECT 
	TOP 1 * 
FROM SimAudModPasaporte

-- 1: xDataSalida en VARCHAR ...
ALTER TABLE SimAudModPasaporte
	ADD sDataSalida AS (CONVERT(VARCHAR(MAX), xDataSalida))

-- 2.1: 
SELECT TOP 1 * FROM SimAudModPasaporte
SELECT REVERSE('<sNumeroPasaporte>123328092</sNumeroPasaporte>')
-- >etropasaPoremuNs/<290823321>etropasaPoremuNs<
ALTER TABLE SimAudModPasaporte
	ADD sDataEntrada AS (
		REPLACE(
			SUBSTRING(
				REVERSE(
					SUBSTRING(
						REVERSE(
							SUBSTRING(
								CONVERT(VARCHAR(MAX), xDataEntrada), 
								CHARINDEX('<sNumeroPasaporte>', CONVERT(VARCHAR(MAX), xDataEntrada)), 
								1000
							)
						),
						CHARINDEX(
							'>etropasaPoremuNs/<',
							REVERSE(
								SUBSTRING(
									CONVERT(VARCHAR(MAX), xDataEntrada), 
									CHARINDEX('<sNumeroPasaporte>', CONVERT(VARCHAR(MAX), xDataEntrada)), 
									1000
								)
							)
						)
						,
						1000
					)
				),
				19,
				9
			),
			' ',
			''
		)
	)


-- 2: 
ALTER TABLE SimAudModPasaporte
	ADD sDataSalida AS (
		REVERSE(
			SUBSTRING(
				REVERSE(
					SUBSTRING(
						CONVERT(VARCHAR(MAX), xDataSalida), 
						CHARINDEX('<sMensaje>', CONVERT(VARCHAR(MAX), xDataSalida)), 
						100
					)
				),
				CHARINDEX(
					'>ejasneMs/<',
					REVERSE(
						SUBSTRING(
							CONVERT(VARCHAR(MAX), xDataSalida), 
							CHARINDEX('<sMensaje>', CONVERT(VARCHAR(MAX), xDataSalida)), 
							100
						)
					)
				)
				,
				1000
			)
		)
	)

-- 3: ...
ALTER TABLE SimAudModPasaporte
	ADD sNumeroPasaporte VARCHAR(15)

ALTER TABLE SimAudModPasaporte
	ADD sMotivo VARCHAR(255)

UPDATE SimAudModPasaporte
	SET sNumeroPasaporte = sDataEntrada

UPDATE SimAudModPasaporte
	SET sMotivo = sDataSalida

DROP TABLE IF EXISTS #tmp_SimAudModPasaporte
SELECT 
	sap.nIdSimAudModPasaporte,
	[sNumeroPasaporte] = sap.sDataEntrada,
	[sMotivo] = sap.sDataSalida,
	sap.dFecha
	INTO #tmp_SimAudModPasaporte
FROM SimAudModPasaporte sap

SET QUOTED_IDENTIFIER ON
CREATE INDEX IX_SimAudModPasaporte_sDataEntrada
    ON dbo.SimAudModPasaporte(sDataEntrada)

SELECT TOP 100 * FROM SimAudModPasaporte

SELECT TOP 1 * FROM SimAudModPasaporte sap WHERE sap.sDataEntrada = '123328092'

-- 1: ...
SELECT TOP 0 spas.sPasNumero INTO #tmp_SimPasaporte FROM SimPasaporte spas

-- 1.1: Insert ...
-- INSERT INTO #tmp_SimPasaporte VALUES(

-- Index ...
CREATE INDEX IX_tmp_SimPasaporte_sPasNumero
    ON dbo.#tmp_SimPasaporte(sPasNumero)


-- 
-- SELECT * FROM #tmp_SimPasaporte_final
SELECT TOP 1 * FROM SimAudModPasaporte

DROP TABLE IF EXISTS #tmp_SimPasaporte_final
SELECT 
	spas.*,
	[sMotivo] = (
		SELECT 
			TOP 1 
			sap.xDataSalida.value('(/PARAMRAIZ/PARAMFILA/sMensaje)[1]', 'VARCHAR(MAX)')
		FROM SimAudModPasaporte sap (NOLOCK)
		WHERE 
			sap.xDataEntrada.value('(/PARAMRAIZ/PARAMFILA/sNumeroPasaporte)[1]', 'VARCHAR(MAX)') = spas.sPasNumero
	)
	-- INTO #tmp_SimPasaporte_final
FROM #tmp_SimPasaporte spas

SELECT 
	TOP 1 
	sap.*
FROM SimAudModPasaporte sap
















SELECT REVERSE('<sMensaje>OK</sMensaje></PARAMFILA></PARAMRAIZ>')
>ZIARMARAP/<>ALIFMARAP/<>ejasneMs/<KO>ejasneMs<
/*
select 
	top 10 * from [dbo].[SimAudModPasaporte]
where sProcedimiento='usp_RegistroPasaporteSIM_PE' 
and cast(xDataEntrada as varchar(8000)) like'%<sDni>09177011</sDni>%'
*/
