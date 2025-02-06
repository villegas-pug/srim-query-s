SELECT * FROM [dbo].[SsmPrmPreRegistroViaje]

SELECT 
	TOP 10 * 
FROM [dbo].[SsmPrmPasajero] pa
WHERE
	/*pa.sPrimerApellido LIKE '%CAU%'
	AND pa.sSegundoApellido LIKE '%QUIR%'*/
	pa.sNumeroDocumento IN (
		'120163612',
		'12063612',
		'1201636K',
		'109008866',
		'516946681',
		'528900744',
		'F77127320'
	)

	