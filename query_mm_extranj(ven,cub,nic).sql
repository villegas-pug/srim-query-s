USE SIM
GO

SELECT f.* 
FROM (

   SELECT 
      
      [Nombres] = pe.sNombre,
      [Apellido 1] = pe.sPaterno,
      [Apellido 2] = pe.sMaterno,
      [Sexo] = pe.sSexo,
      [Fecha Nacimiento] = pe.dFechaNacimiento,
      [Nacionalidad] = pa.sNacionalidad,
      [Calidad Migratoria] = cm.sDescripcion,

      -- Adicional
      [Ultimo Movimiento] = IIF(mm.sTipo = 'E', 'ENTRADA', 'SALIDA'),
      [Ultima Fecha Movimiento] = mm.dFechaControl,
      [Documento Viaje] = mm.sIdDocumento,
      [Número Documento Viaje] = mm.sNumeroDoc,
      [Número Vuelo] = i.sNumeroNave,
      [Empresa Transporte] = tr.sNombreRazon,
      [Dependencia] = d.sNombre,
      [Via Transporte] = mm.sIdViaTransporte,

      -- Aux
      [#] = ROW_NUMBER() OVER (PARTITION BY mm.uIdPersona ORDER BY mm.dFechaControl DESC)

   FROM SIM.dbo.SimMovMigra mm
   JOIN SIM.dbo.SimPersona pe ON mm.uIdPersona = pe.uIdPersona
   JOIN SIM.dbo.SimPais pa ON pe.sIdPaisNacionalidad = pa.sIdPais
   JOIN SIM.dbo.SimCalidadMigratoria cm ON mm.nIdCalidad = cm.nIdCalidad
   JOIN SimDependencia d ON mm.sIdDependencia = d.sIdDependencia
   LEFT JOIN SIM.dbo.SimItinerario i ON mm.sIdItinerario = i.sIdItinerario
   LEFT JOIN SIM.dbo.SimEmpTransporte tr ON mm.nIdTransportista = tr.nIdTransportista
   WHERE
      mm.bAnulado = 0
      AND mm.bTemporal = 0
      AND pe.sIdPaisNacionalidad IN ('VEN', 'CUB', 'NIC')
      AND mm.dFechaControl BETWEEN '2025-01-06 00:00:00.000' AND '2025-01-06 23:59:59.998'

) f
WHERE
   f.[#] = 1





-- Test
-- venezolanos, cubanos y nicaragüenses
-- VEN	VENEZUELA; CUB	CUBA; NIC	NICARAGUA

SELECT * FROM SimPais p
WHERE p.sNombre LIKE '%nicara%'