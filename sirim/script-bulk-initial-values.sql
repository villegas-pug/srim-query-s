USE BD_SIRIM
GO

/*
3  | Reglas de Consistencia
4	| Control Migratorio
5	| Trámites de Inmigración
6	| Alertas
*/

-- Bulk 1: Reglas
-- EXEC sp_help SgcdProcesos
-- INSERT INTO SgcdProcesos(sNombre, sDescripcion, nTotalRegCorrectos, nTotalRegIncorrectos, nTotalRegistros, nTotalReglas, bActivo, dFechaCreacion) VALUES()
-- SELECT * FROM SgcdProcesos
INSERT INTO SgcdProcesos(sNombre, bActivo, dFechaCreacion) VALUES('Control Migratorio', 1, GETDATE())
INSERT INTO SgcdProcesos(sNombre, bActivo, dFechaCreacion) VALUES('Inmigración', 1, GETDATE())
INSERT INTO SgcdProcesos(sNombre, bActivo, dFechaCreacion) VALUES('Alertas', 1, GETDATE())
INSERT INTO SgcdProcesos(sNombre, bActivo, dFechaCreacion) VALUES('Nacionalización', 1, GETDATE())

-- Bulk 2: SgcdLugarConsulta
-- SELECT * FROM SgcdLugarConsultas
EXEC sp_help SgcdLugarConsultas
INSERT INTO SgcdLugarConsultas(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Solo Migraciones')
INSERT INTO SgcdLugarConsultas(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Migraciones y Ciudadano')
INSERT INTO SgcdLugarConsultas(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Migraciones y entidades externas')
INSERT INTO SgcdLugarConsultas(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Migraciones, Ciudadano y entidades externas')


-- Bulk 3: SgcdCasosReportados
-- SELECT * FROM SgcdCasosReportados
INSERT INTO SgcdCasosReportados(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Ninguno')
INSERT INTO SgcdCasosReportados(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'En migraciones')
INSERT INTO SgcdCasosReportados(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'En entidades externas')
INSERT INTO SgcdCasosReportados(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Por Ciudadano')
INSERT INTO SgcdCasosReportados(bActivo, dFechaCreacion, sNombre) VALUES(1, GETDATE(), 'Por la prensa')

-- Bulk 4: SgcdDependencias
-- SELECT * FROM SgcdDependencias
INSERT INTO SgcdDependencias(sIdDependencia, bActivo, dFechaCreacion, sIdJefatura, sNombreDependencia, sNombreJJZZ)
   SELECT j.sIdDependencia, j.bActivo, GETDATE(), j.sIdJefatura, j.sNombreDependencia, j.sNombreJefaturaZonal 
   FROM BD_SIRIM.dbo.RimRNJefaturaZonal j

-- Bulk 5: SgcdOrigenReportaEscenarios
-- SELECT * FROM SgcdOrigenReportaEscenarios
-- EXEC sp_help SgcdOrigenReportaEscenarios
INSERT INTO SgcdOrigenReportaEscenarios(bActivo, sNombre) VALUES(1, GETDATE(), 'SRIM')

-- Bulk 6: SgcdDimension
-- SELECT * FROM RimRNDimension
EXEC sp_help SgcdDimension
INSERT INTO SgcdDimension(sNombre, bActivo) VALUES('SRIM', 1)

-- Bulk 7: Estados de regla
-- SELECT * FROM RimRNStatus
INSERT INTO RimRNStatus(sNombre, bActivo) VALUES('APROBADO', 1)
INSERT INTO RimRNStatus(sNombre, bActivo) VALUES('OBSERVADO', 1)

-- Bulk 8: Tipos script
-- SELECT * FROM RimRNTipoScript
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('DETECCION', 1)
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('VALIDACION', 1)
INSERT INTO RimRNTipoScript(sDescripcion, bActivo) VALUES('CORECCION', 1)

-- Bulk 9
-- SELECT * FROM RimRNJefaturaZonal
-- EXEC sp_help RimRNJefaturaZonal
SELECT COUNT(1) FROM RimRNJefaturaZonal
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('30',1,'JZAREQ','PCM AREQUIPA AIARB','Jefatura Zonal Arequipa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('31',1,'JZAREQ','PCM MATARANI','Jefatura Zonal Arequipa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('51',1,'JZAREQ','AREQUIPA','Jefatura Zonal Arequipa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MAP',1,'JZAREQ','MAC AREQUIPA PORONGOCHE','Jefatura Zonal Arequipa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('26',1,'JZCALL','PUERTO CALLAO','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('27',1,'JZCALL','A.I.J.CH.','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('33',1,'JZCALL','PCM AICFREO PISCO','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('49',1,'JZCALL','PCM PISCO AICFREO','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('84',1,'JZCALL','VENTANILLA','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('112',1,'JZCALL','JEFATURA ZONAL CALLAO','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('BLV',1,'JZCALL','BELLAVISTA','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('CBL',1,'JZCALL','BELLAVISTA CALLAO','Jefatura Zonal Callao')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('15',1,'JZCHIC','CHICLAYO','Jefatura Zonal Chiclayo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('17',1,'JZCHIC','PCF LA BALSA','Jefatura Zonal Cajamarca')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('54',1,'JZCHIC','PCM CHICLAYO AIJAQ','Jefatura Zonal Chiclayo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCC',1,'JZCHIC','MAC CAJAMARCA','Jefatura Zonal Cajamarca')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('12',1,'JZCHIM','HUARMEY','Jefatura Zonal Chimbote')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('47',1,'JZCHIM','CHIMBOTE','Jefatura Zonal Chimbote')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('78',1,'JZCHIM','PCM CHIMBOTE','Jefatura Zonal Chimbote')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCA',1,'JZCHIM','MAC ANCASH','Jefatura Zonal Chimbote')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('14',1,'JZCUSC','PCM CUSCO AIAVA','Jefatura Zonal Cusco')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('48',1,'JZCUSC','CUSCO','Jefatura Zonal Cusco')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MC ',1,'JZCUSC','MAC CUSCO','Jefatura Zonal Cusco')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('92',1,'JZHCYO','HUANCAYO','Jefatura Zonal Huancayo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCJ',1,'JZHCYO','MAC JUNIN','Jefatura Zonal Huancayo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('PVS',1,'JZHCYO','PUESTO DE VERIFICACION MIGRATORIA SATIPO','Jefatura Zonal Huancayo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('62',1,'JZILO','ILO','Jefatura Zonal Ilo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('35',1,'JZIQUI','IQUITOS','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('37',1,'JZIQUI','PCF SANTA ROSA IQUITOS','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('38',1,'JZIQUI','PCF CABO PANTOJA','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('39',1,'JZIQUI','PCM IQUITOS AIFSV','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('50',1,'JZIQUI','PCM IQUITOS CABALLOCOCHA','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('58',1,'JZIQUI','PCM RIO AMAZONAS BALSA MIGRACION COLOMBIA','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('60',1,'JZIQUI','PCF ISLANDIA','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('63',1,'JZIQUI','PCF SOPLIN VARGAS - LORETO','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('96',1,'JZIQUI','PCF EL ESTRECHO IQUITOS','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('116',1,'JZIQUI','PCM PUERTO MAYOR','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCL',1,'JZIQUI','MAC LORETO','Jefatura Zonal Iquitos')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('25',1,'JZLIMA','LIMA','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('59',1,'JZLIMA','MAC LIMA ESTE','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('82',1,'JZLIMA','LA MOLINA','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('101',1,'JZLIMA','LIMA NORTE','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('102',1,'JZLIMA','LIMA SUR','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('107',1,'JZLIMA','BREÑA','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('108',1,'JZLIMA','LIMAV','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('110',1,'JZLIMA','SURCO','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('111',1,'JZLIMA','SJMIRAFLORES','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('118',1,'JZLIMA','PCM PTO CHANCAY','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('200',1,'JZLIMA','MINISTERIO DE RELACIONES EXTERIORES','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('ADP',1,'JZLIMA','PURUCHUCO','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('ADV',1,'JZLIMA','LIMA - MIGRACENTRO VILLA MARÍA','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('CHO',1,'JZLIMA','SEDE ITINERANTE CHORRILLOS','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('IND',1,'JZLIMA','INDEPENDENCIA','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MLN',1,'JZLIMA','MAC LIMA NORTE','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('R1 ',1,'JZLIMA','LIMA ITINERANTE OIM – UNIÓN VENEZOLANA SAN ISIDRO','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('R5 ',1,'JZLIMA','LIMA ITINERANTE OIM – PASOS FIRMAS COMAS','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('R6 ',1,'JZLIMA','LIMA ITINERANTE OIM – ENCUENTRO CAREMI SJL','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('R7 ',1,'JZLIMA','LIMA ITINERANTE OIM – OCASIVEN SJM','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('SJL',1,'JZLIMA','Sede Itinerante San Juan de Lurigancho','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('SMP',1,'JZLIMA','SEDE ITINERANTE SAN MARTIN DE PORRES','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('VMT',1,'JZLIMA','SEDE ITINERANTE VILLA MARIA DEL TRIUNFO','Jefatura Zonal Lima')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('10',1,'JZPIUR','PCF LA TINA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('11',1,'JZPIUR','PCF EL ALAMOR','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('77',1,'JZPIUR','PCF ESPINDOLA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('93',1,'JZPIUR','PUERTO BAYOVAR','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('115',1,'JZPIUR','CEBAF LA TINA - MACARA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('06',1,'JZPIUR','PIURA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('07',1,'JZPIUR','SULLANA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('08',1,'JZPIUR','TALARA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('09',1,'JZPIUR','PAITA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MPI',1,'JZPIUR','MAC PIURA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('SIM',1,'JZPIUR','SEDE ITINERANTE MANCORA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('SIS',1,'JZPIUR','SEDE ITINERANTE SULLANA','Jefatura Zonal Piura')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('43',1,'JZPTOM','PTO MALDON.','Jefatura Zonal Puerto Maldonado')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('44',1,'JZPTOM','IÑAPARI','Jefatura Zonal Puerto Maldonado')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('97',1,'JZPTOM','PCF SAN LORENZO','Jefatura Zonal Puerto Maldonado')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('98',1,'JZPTOM','PCF SHIRINGAYOC','Jefatura Zonal Puerto Maldonado')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('40',1,'JZPUCA','PUCALLPA','Jefatura Zonal Pucallpa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('42',1,'JZPUCA','PCF PURUS','Jefatura Zonal Pucallpa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('99',1,'JZPUCA','PCF BREU','Jefatura Zonal Pucallpa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCH',1,'JZPUCA','MAC HUANUCO','Jefatura Zonal Pucallpa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCU',1,'JZPUCA','MAC UCAYALI','Jefatura Zonal Pucallpa')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('41',1,'JZPUNO','PCF CARANCAS','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('69',1,'JZPUNO','PUNO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('70',1,'JZPUNO','PCF DESAGUADERO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('71',1,'JZPUNO','JULI','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('74',1,'JZPUNO','KASANI','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('76',1,'JZPUNO','TILALI','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('85',1,'JZPUNO','CEBAF DESAGUADERO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('117',1,'JZPUNO','PCF TRIPARTITO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('03',1,'JZPUNO','PTO. JULI','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('04',1,'JZPUNO','PTO. PUNO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('05',1,'JZPUNO','AEROPUERTO INTERNACIONAL INCA MANCO CAPAC JULIACA','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCP',1,'JZPUNO','MAC PUNO','Jefatura Zonal Puno')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('64',1,'JZTACN','TACNA-RALLY_DAKAR','Jefatura Zonal Tacna')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('65',1,'JZTACN','TACNA','Jefatura Zonal Tacna')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('66',1,'JZTACN','STA. ROSA','Jefatura Zonal Tacna')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('68',1,'JZTACN','FERROCARRIL TACNA','Jefatura Zonal Tacna')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('AAC',1,'JZTACN','AGENCIA DE ATENCIÓN AL CIUDADANO ILO','Jefatura Zonal Ilo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('ILO',1,'JZTACN','MAC MOQUEGUA','Jefatura Zonal Ilo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('79',1,'JZTPTO','TARAPOTO ANTERIOR','Jefatura Zonal Tarapoto')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('83',1,'JZTPTO','TARAPOTO','Jefatura Zonal Tarapoto')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('103',1,'JZTPTO','PVM YURIMAGUAS','Jefatura Zonal Tarapoto')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('20',1,'JZTRUJ','TRUJILLO','Jefatura Zonal Trujillo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('21',1,'JZTRUJ','CHICAMA','Jefatura Zonal Trujillo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('22',1,'JZTRUJ','SALAVERRY','Jefatura Zonal Trujillo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('105',1,'JZTRUJ','PCM TRUJILLO AICMP','Jefatura Zonal Trujillo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('MCT',1,'JZTRUJ','MAC LA LIBERTAD','Jefatura Zonal Trujillo')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('13',1,'JZTUMB','CEBAF-TUMBES','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('19',1,'JZTUMB','PCM TUMBES APCR','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('32',1,'JZTUMB','PVM CARPITAS','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('80',1,'JZTUMB','PCF TUMBES-CEBAFEV1PER','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('81',1,'JZTUMB','PCF TUMBES-CEBAFEV1ECU','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('109',1,'JZTUMB','PCM TUMBES ACPCR','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('01',1,'JZTUMB','TUMBES','Jefatura Zonal Tumbes')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('16',1,'','PIMENTEL','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('23',1,'','A.I.J.CH PASAPORTES','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('24',1,'','A.I.J.CH. DIA','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('28',1,'','LAS PALMAS','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('29',1,'','PUERTO SUPE','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('34',1,'','PCF SANTA ROSA IQUITOS - INACTIVO','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('36',1,'','PTO ALEGR.','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('52',1,'','MOLLENDO','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('67',1,'','COLLPA','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('72',1,'','YUNGUYO','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('90',1,'','MIRAFLORES','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('95',1,'','WEB CONVENIO COLEGIO DE NOTARIOS','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('100',1,'','SERVICIOS WEB','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('104',1,'','PCF ANGAMOS','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('106',1,'','AIJCH-ITINERANTE','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('APR',1,'','MIGRACENTRO REAL PLAZA PRIMAVERA','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('CCM',1,'','CONVENIO CEDRO-MIGRACIONES','')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('CLI',1,'','SEDE ITINERANTE CERCADO DE LIMA','                                                                                                                              ')
INSERT INTO RimRNJefaturaZonal(sIdDependencia, bActivo, sIdJefatura, sNombreDependencia, sNombreJefaturaZonal) VALUES('CRB',1,'','SEDE CARABAYA','')

-- Bulk 7: Reglas
EXEC sp_help RimRNControlCambios
SELECT * FROM RimReglaNegocio
SELECT * FROM RimRNControlCambios
SELECT * FROM RimRNRegistroEjecucionScript
SELECT * FROM RimRNAuditoriaControlMigratorio

DELETE FROM RimReglaNegocio
TRUNCATE TABLE RimReglaNegocio
TRUNCATE TABLE RimRNControlCambios
TRUNCATE TABLE RimRNRegistroEjecucionScript
TRUNCATE TABLE RimRNAuditoriaControlMigratorio

-- DELETE FROM RimReglaNegocio
-- TRUNCATE TABLE RimRNControlCambios
-- DELETE FROM RimRNRegistroEjecucionScript




USE SIM
GO


SELECT 
   mm.sIdDocumento,
   [sMes] = DATEPART(MM, mm.dFechaControl),
   mm.sTipo,
   COUNT(1)
FROM SimMovMigra mm
WHERE
   mm.bAnulado = 0
	AND mm.bTemporal = 0
   AND mm.dFechaControl BETWEEN '2024-01-01 00:00:00.000' AND '2024-10-01 23:59:59.999'
   AND mm.sIdPaisNacionalidad = 'PER'
   -- AND mm.sIdDependencia = '27' -- AIJCH
GROUP BY
   mm.sIdDocumento,
   DATEPART(MM, mm.dFechaControl),
   mm.sTipo