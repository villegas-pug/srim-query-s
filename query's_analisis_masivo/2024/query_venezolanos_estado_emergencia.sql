USE SIM
GO

/*

Ate, 
Villa El Salvador, 
Ancón, 
Puente Piedra, 
Comas, 
Carabayllo, 
Independencia, 
San Martín de Porres, 
Los Olivos, 
San Juan de Lurigancho, 
Lurigancho Chosica, 
Ventanilla

*/

SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Calidad Migratoria] = cm.sDescripcion,

   -- Adicional
   [Departamento / Distrito] = u.sNombre,
   [Dirección Domicilio] = e.sDomicilio,
   [Telefono] = e.sTelefono,
   [Estatura] = e.nEstatura,
   [Email] = e.sEmail,
   [Nacionalidad] = p.sNacionalidad,

   -- Ultimo movimiento
   [Ultimo Movimineto] = (
                              SELECT TOP 1 mm.sTipo
                              FROM SimMovMigra mm
                              WHERE
                                 mm.bAnulado = 0
                                 AND mm.bTemporal = 0
                                 AND mm.uIdPersona = pe.uIdPersona
                              ORDER BY 
                                 mm.dFechaControl DESC
   ),
   [Fecha Ultimo Movimineto] = (
                                 SELECT TOP 1 mm.dFechaControl
                                 FROM SimMovMigra mm
                                 WHERE
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = pe.uIdPersona
                                 ORDER BY 
                                    mm.dFechaControl DESC
   )
   
FROM SimPersona pe
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
JOIN SimPais p ON pe.sIdPaisNacionalidad = p.sIdPais
WHERE
   pe.sIdPaisNacionalidad != 'PER'
   AND u.sNombre IN (
                     'Ate', 
                     'Villa El Salvador', 
                     'Ancon', 
                     'Puente Piedra', 
                     'Comas', 
                     'Carabayllo', 
                     'Independencia', 
                     'San Martin de Porres', 
                     'Los Olivos', 
                     'San Juan de Lurigancho', 
                     'Lurigancho', 
                     'Ventanilla'
   )


-- 2
/*
   La:-3.20 Lo: -75.84
   La:-11.99 Lo: -77.09
*/
SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,
   [Calidad Migratoria] = cm.sDescripcion,

   -- Adicional
   [Departamento / Distrito] = u.sNombre,
   [Dirección Domicilio] = e.sDomicilio,
   [Telefono] = e.sTelefono,
   [Estatura] = e.nEstatura,
   [Email] = e.sEmail,

   -- Ultimo movimiento
   [Ultimo Movimineto] = (
                              SELECT TOP 1 mm.sTipo
                              FROM SimMovMigra mm
                              WHERE
                                 mm.bAnulado = 0
                                 AND mm.bTemporal = 0
                                 AND mm.uIdPersona = pe.uIdPersona
                              ORDER BY 
                                 mm.dFechaControl DESC
   ),
   [Fecha Ultimo Movimineto] = (
                                 SELECT TOP 1 mm.dFechaControl
                                 FROM SimMovMigra mm
                                 WHERE
                                    mm.bAnulado = 0
                                    AND mm.bTemporal = 0
                                    AND mm.uIdPersona = pe.uIdPersona
                                 ORDER BY 
                                    mm.dFechaControl DESC
   )
   
FROM SimPersona pe
JOIN SimCalidadMigratoria cm ON pe.nIdCalidad = cm.nIdCalidad
JOIN SimExtranjero e ON pe.uIdPersona = e.uIdPersona
JOIN SimUbigeo u ON e.sIdUbigeoDomicilio = u.sIdUbigeo
JOIN BD_SIRIM.dbo.ResultadoConsultaGeocoder g ON pe.uIdPersona = g.uIdPersona
WHERE
   g.sEstado IN (
      'c',
      'P'
   )
   -- AND CAST(g.dLatitud AS FLOAT) BETWEEN -11.99 AND -3.20
   -- AND CAST(g.dLongitud AS FLOAT) BETWEEN -77.09 AND -75.84
   AND CONVERT(VARCHAR(6), g.dLatitud) = '-11.99'
   AND CONVERT(VARCHAR(6), g.dLongitud) = '-77.09'



   /* AND g.dLatitud BETWEEN -11.99 AND -3.20
   AND g.dLongitud BETWEEN -77.09 AND -75.84 */


SELECT FORMAT(55.123, '##.##')

SELECT TOP 10 * FROM BD_SIRIM.dbo.ResultadoConsultaGeocoder 