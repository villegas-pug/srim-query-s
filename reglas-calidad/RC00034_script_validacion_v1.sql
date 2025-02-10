-- RC00034

--> ░ 4. Se define como regla, que los Carnet de Extranjería, deben tener una vigencia de 3 años en el caso de menores de edad. ...
-- ========================================================================================================================================================================

SELECT 

   [Id Persona] = pe.uIdPersona,
   [Nombres] = pe.sNombre,
   [Apellido 1] = pe.sPaterno,
   [Apellido 2] = pe.sMaterno,
   [Sexo] = pe.sSexo,
   [Fecha Nacimiento] = pe.dFechaNacimiento,
   [Nacionalidad] = pe.sIdPaisNacionalidad,

   -- Aux
	[Número Carnet] = ce.sNumeroCarnet,
	[Fecha Emisión] = ce.dFechaEmision,
	[Fecha Caducidad] = ce.dFechaCaducidad,
	[Edad Emisión Carnet] = DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision)

FROM SimCarnetExtranjeria ce
JOIN SimTramite t ON ce.sNumeroTramite = t.sNumeroTramite
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona pe ON ce.uIdPersona = pe.uIdPersona
WHERE 
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND ti.sEstadoActual = 'A'
   AND ce.bAnulado = 0
   AND ce.sTipo = 'R'
   AND (ce.dFechaEmision IS NOT NULL OR ce.dFechaEmision != '1900-01-01 00:00:00.000')
   AND (ce.dFechaCaducidad IS NOT NULL OR ce.dFechaCaducidad != '1900-01-01 00:00:00.000')
   AND DATEDIFF(YYYY, pe.dFechaNacimiento, ce.dFechaEmision) < 18 -- Menores de edad
   AND DATEDIFF(YYYY, ce.dFechaEmision, ce.dFechaCaducidad) > 3 -- Vigencia > a 3 años
   
-- ========================================================================================================================================================================