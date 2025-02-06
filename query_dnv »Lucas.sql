USE SIM
GO

/*
   -- bActivo
	-- 0 → Habilitada
	-- 1 → Inhabilitada
=========================================================================================================================================================== */

-- 1: ...
SELECT 

   -- [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Nombre] = pna.sNombre,
   [Paterno] = pna.sPaterno,
   [Materno] = pna.sMaterno,
   [Sexo] = pna.sSexo,
   [Documento] = pna.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', pna.sNumDocIdentidad),
   [Fecha Nacimiento] = pna.dFechaNacimiento,
   [Pais Nacionalidad] = pna.sIdPaisNacionalidad,
   [Fecha Inicio Medida] = pna.dFechaInicioMedida,
   [Fecha Emisión] = di.dFechaEmision,
   [Fecha Recepción] = di.dFechaRecepcion,
   [Fecha Cancelación DNV] = pna.dFechaCancelacion,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
   [Observaciones] = pna.sObservaciones,
   [Estado] = IIF(pna.bActivo = 1, 'Inhabilitado', 'Habilitado')

FROM SimPersonaNoAutorizada pna
RIGHT JOIN SimDocInvalidacion di ON pna.nIdDocInvalidacion = di.nIdDocInvalidacion
LEFT JOIN SimMotivoInvalidacion mi ON pna.sIdMotivoInv = mi.sIdMotivoInv
LEFT JOIN SimTablaTipo tt ON pna.sIdAlertaInv = tt.strequivalente
WHERE
   pna.bActivo = 1 -- Inhabilitada


/*
   2. Solicitud: 
      
      Usuario  : David Angel, Cantorin Ortega.
      Campos   : Nombre | Apellido | Tipo | Número de documento de identidad | Jefatura Zonal correspondiente | Periodo de la vigencia de la alerta.
--========================================================================================================================================== */

SELECT 

   [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Nombre] = pna.sNombre,
   [Paterno] = pna.sPaterno,
   [Materno] = pna.sMaterno,
   [Sexo] = pna.sSexo,
   [Documento] = pna.sIdDocumento,
   [Num Doc Identidad] = pna.sNumDocIdentidad,
   [Fecha Nacimiento] = pna.dFechaNacimiento,
   [Pais Nacionalidad] = pna.sIdPaisNacionalidad,
   [Fecha Emisión] = di.dFechaEmision,
   [Fecha Recepción] = di.dFechaRecepcion,
   [Fecha Fin Medida] = pna.dFechaFinMedida,
   -- [Fecha Cancelación DNV] = pna.dFechaCancelacion,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
   [Fecha Inicio Medida] = pna.dFechaInicioMedida,
   [Fecha Fin Medida] = pna.dFechaFinMedida,
   [Estado] = IIF(pna.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [Observaciones] = pna.sObservaciones

   -- dnv

FROM SimPersonaNoAutorizada pna
JOIN SimDocInvalidacion di ON pna.nIdDocInvalidacion = di.nIdDocInvalidacion
LEFT JOIN SimMotivoInvalidacion mi ON pna.sIdMotivoInv = mi.sIdMotivoInv
LEFT JOIN SimTablaTipo tt ON pna.sIdAlertaInv = tt.strequivalente
WHERE
   pna.bActivo = 1 -- Inhabilitada
   AND pna.sIdPaisNacionalidad = 'BOL'

-- Test
SELECT
   -- TOP 100 *
   a.nNumCant,
   a.sTipoCant,
   [nTotal] = COUNT(1)
FROM SimPersonaNoAutorizada a
WHERE 
   a.bActivo = 1 -- Inhabilitada
   -- AND a.dFechaFinMedida IS NOT NULL
   AND a.sIdPaisNacionalidad = 'BOL'
GROUP BY
   a.nNumCant,
   a.sTipoCant


SELECT TOP 10 * FROM SimPersonaNoAutorizada
SELECT TOP 10 * FROM SimDocInvalidacion

-- =========================================================================================================================================================== */

/*
   Usuario  : David Angel, Cantorin Ortega.
   Campos   : Nombre | Apellido | Tipo | Número de documento de identidad | Jefatura Zonal correspondiente | Periodo de la vigencia de la alerta.
--========================================================================================================================================== */

SELECT 

   [Num Doc Invalida] = CONCAT(di.sIdDocInvalida, ' N° ', di.sNumDocInvalida),
   [Nombre] = pna.sNombre,
   [Paterno] = pna.sPaterno,
   [Materno] = pna.sMaterno,
   [Sexo] = pna.sSexo,
   [Documento] = pna.sIdDocumento,
   [Num Doc Identidad] = CONCAT('''', pna.sNumDocIdentidad),
   -- [Fecha Nacimiento] = pna.dFechaNacimiento,
   [Pais Nacionalidad] = pna.sIdPaisNacionalidad,
   -- [Fecha Emisión] = di.dFechaEmision,
   -- [Fecha Recepción] = di.dFechaRecepcion,
   -- [Fecha Cancelación DNV] = pna.dFechaCancelacion,
   [Motivo] = mi.sDescripcion,
   [Tipo Alerta] = COALESCE(tt.sDescripcion, 'NO REGISTRA TIPO'),
   [Fecha Inicio Medida] = pna.dFechaInicioMedida,
   [Fecha Fin Medida] = pna.dFechaFinMedida,
   [Estado] = IIF(pna.bActivo = 1, 'Inhabilitado', 'Habilitado'),
   [Observaciones] = pna.sObservaciones

FROM SimPersonaNoAutorizada pna
RIGHT JOIN SimDocInvalidacion di ON pna.nIdDocInvalidacion = di.nIdDocInvalidacion
LEFT JOIN SimMotivoInvalidacion mi ON pna.sIdMotivoInv = mi.sIdMotivoInv
LEFT JOIN SimTablaTipo tt ON pna.sIdAlertaInv = tt.strequivalente
WHERE
   pna.bActivo = 1 -- Inhabilitada
   AND (pna.dFechaInicioMedida IS NOT NULL AND pna.dFechaInicioMedida != '1900-01-01 00:00:00.000')
   AND (pna.dFechaFinMedida IS NOT NULL AND pna.dFechaFinMedida != '1900-01-01 00:00:00.000')

-- =========================================================================================================================================================== */

/*

PASAPORTE Nº 09856493015 POR HABER TENIDO PROCESO JUDICIAL POR TID-LA SGCS DEL PJ,
INFORMA CON OFICIO N° 370-2019-SG-CS-PJ (11/01/2019) QUE EL CIUDADANO HA SIDO SENTENCIADO
POR EL DELITO DE TID ART. 296, POR EL 05-JUZGADO PENAL-CALLAO EL 09/10/2003 Y LA 1-SALA PENAL-CALLAO EL 07/04/2004,
IMPONIENDOLE 6 AÑOS Y 5 MESES PENA PRIVATIVA DE LIBERTAD EFECTIVA, 300 DÍAS MULTA. FIN DE LA CONDENA 07/09/2009.

*/

SELECT TOP 10 * FROM SimPersonaNoAutorizada a
WHERE a.sObservaciones LIKE '%días%'

SELECT TOP 10 * FROM SimDocInvalidacion