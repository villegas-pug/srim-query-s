-- 248

/* Se define como regla que las personas con tramites pendientes de Regularizacion Migratoria y necesiten realizar la salida 
del territorio nacional debe ser mediante permiso de viaje*/

-- PTP, CCM, Solicitud de calidad Migra

Select * from simtramite where nIdTipoTramite=113 
and snumeroTramite in (
	Select sNumeroTramite from SimTramiteInm where sEstadoActual = 'P')
and uidpersona in (
	Select c1.uidpersona from
		(
			SELECT uidPersona as uidpersona, max(dFechaDigita) as FechaSalida -- dFechaControl
			from simmovmigra 
			where 
				stipo = 'S' and banulado=0
				and uidpersona not in (select uidpersona from simperuano)
			group by uidpersona
		)c1 left join 
		(
			SELECT uidPersona as persona, max(dFechaDigita) as FechaEntrada -- dFechaControl
			from simmovmigra where stipo = 'E' and banulado=0 -- bTemporal=0
			and uidpersona not in (select uidpersona from simperuano)
			group by uidpersona
		)c2
		on c1.uidpersona=c2.persona
		Where FechaSalida>FechaEntrada
		and FechaEntrada is not null)
and uidpersona not in (
	Select uidpersona from SimTramite where sNumeroTramite in (Select sNumeroTramite from simPermiso)
	
	)
	   	    	  

	--Se valida que la mayoria de data inconsistente corresponde a la no regularizacion del proceso de control 
	--migratorio por lo que cuentan con aprobacion
	--del tramite de regularizacion migratoria pero el registro de control migratorio no ha sido actualizado'


------249------------------------------------------------------------------------------------
/*

Se define como regla de calidad de datos que para Autorización de estadía fuera del país por mas de ciento ochenta y tres (183) días 
calendario consecutivos se debe Contar con permiso temporal de permanencia vigente 

*/
-- 
Select snumeroTramite, dfechaHoraReg, uidpersona from simtramite where nIdTipoTramite=39
and snumeroTramite in (
	-- Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P'
	Select sNumeroTramite from SimTramiteInm where sEstadoActual = 'A'
)
and sNumeroTramite in (select sNumeroTramite from simPermiso where datediff(day,dfechaInicio,dfechaFin) > 183)
and uidpersona in (Select uidpersona from SimCarnetPTP where dFechaVenc<getdate())
	

---250----
/*
	Para tramites de autorizacion de estadia fuera del pais se debe estar en el territorio nacional
	-- Calcular fechas de salida con fecha de tramite de permiso
*/

USE SIM
Select * from simTipoTramite where nIdTipoTramite=39

Select snumeroTramite, dfechaHoraReg, uidpersona from simtramite where nIdTipoTramite=39
and snumeroTramite in (
	Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')

and uidpersona in (
	Select c1.uidpersona from
		(
		SELECT uidPersona as uidpersona, max(dFechaDigita) as FechaSalida 
		from simmovmigra where stipo = 'S' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c1 left join 
		(
		SELECT uidPersona as persona, max(dFechaDigita) as FechaEntrada 
		from simmovmigra where stipo = 'E' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c2
		on c1.uidpersona=c2.persona
		Where FechaSalida>FechaEntrada
		and FechaEntrada is not null)

--251. Se define como regla que para los tramites de Prórroga de Permanencia pendientes debe Encontrarse dentro del país

Select * from simTramite where nidTipoTramite = 57
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')
and uidpersona in (
	Select c1.uidpersona from
		(
		SELECT uidPersona as uidpersona, max(dFechaDigita) as FechaSalida 
		from simmovmigra where stipo = 'S' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c1 left join 
		(
		SELECT uidPersona as persona, max(dFechaDigita) as FechaEntrada 
		from simmovmigra where stipo = 'E' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c2
		on c1.uidpersona=c2.persona
		Where FechaSalida>FechaEntrada
		and FechaEntrada is not null)
and uidpersona not in
(
Select uidpersona from simTramite where SnumeroTramite in

(select snumeroTramite from simpermiso where dFechaFin>getdate()))


--------------------------252---
--Se define como regla que para los tramites de Permiso especial para suscribir documentos debe Encontrarse dentro del país

Select * from simTipoTramite where nidTipoTramite = 61
Select * from simTramite where nidTipoTramite = 61
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')
and uidpersona in (
	Select c1.uidpersona from
		(
		SELECT uidPersona as uidpersona, max(dFechaDigita) as FechaSalida 
		from simmovmigra where stipo = 'S' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c1 left join 
		(
		SELECT uidPersona as persona, max(dFechaDigita) as FechaEntrada 
		from simmovmigra where stipo = 'E' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c2
		on c1.uidpersona=c2.persona
		Where FechaSalida>FechaEntrada
		and FechaEntrada is not null)
and uidpersona not in
(
Select uidpersona from simTramite where SnumeroTramite in

(select snumeroTramite from simpermiso where dFechaFin>getdate()))

--253--Para Permiso de trabajo extraordinario debe Encontrarse dentro del país.-----------------

Select * from simTramite where nidTipoTramite = 60
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')
and uidpersona in (
	Select c1.uidpersona from
		(
		SELECT uidPersona as uidpersona, max(dFechaDigita) as FechaSalida 
		from simmovmigra where stipo = 'S' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c1 left join 
		(
		SELECT uidPersona as persona, max(dFechaDigita) as FechaEntrada 
		from simmovmigra where stipo = 'E' and banulado=0
		and uidpersona not in (select uidpersona from simperuano)
		group by uidpersona
		)c2
		on c1.uidpersona=c2.persona
		Where FechaSalida>FechaEntrada
		and FechaEntrada is not null)
and uidpersona not in
(
Select uidpersona from simTramite where SnumeroTramite in

(select snumeroTramite from simpermiso where dFechaFin>getdate()))

--254. Se define que para los tramites de Permiso de trabajo extraordinario se debe Contar con residencia vigente---------------------------------
-- Cambiar definicion de regla

use SIM
SELECT * FROM simtipoTramite where nidTipoTramite = 56

Select * from simTramite 
where 
	nidTipoTramite = 60
	and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')
	and uidpersona not in (
		select uidpersona from simCarnetExtranjeria 
		where 
			dFechaVencRes > getdate()
			and banulado=0
	)

--255. Se define como regla que para el tramite de "Prórroga de Permanencia de Designado Temporal" se otorga por maximo 183 dias----------------------------------
Select * from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (293)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 183
and banulado =0))


--256. Se define como regla que para el tramite de Prórroga de Permanencia Investigación Temporal se otorga por maximo 90 dias--------------------


Select * from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (291)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 90
and banulado =0))

--257. Se define como regla que para los tramites de Prórroga de la Calidad Migratoria de Religioso Residente, Prórroga de la Calidad Migratoria Formación Residente, --Prórroga de la Calidad Migratoria Designado Residente se otorga como maximo 365 dias
Select * from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (299,324,296)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 365
and banulado =0))

--258. 
/* Se define como regla que para los tramites de Solicitud de Calidad Migratoria Religioso Residente debe otorgarse una
permanencia de 365 dias maximo 
*/


Select * from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (299,298)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and uidpersona in (select uidpersona from simpersona where nidcalidad in (299,298))
and datediff(day,dFechainicioVigencia,dfechaInicioVigencia)>365)



/*--259. Se define como regla que los tramites de Cambio de Calidad Migratoria Designado Temporal debe otorgarse una permanencia de 183 dias como maximo*/-----------------------

Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (293)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 183



--260.
/* Se define como regla que para los tramites de Cambio de Calidad Migratoria Investigación Temporal" se otorga una permanencia de 90 dias*/


Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (291)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 90


-- 261. 
--Se define como regla que los tramites de Solicitud de 
--Calidad Migratoria de Formacion Temporal tienen una permanencia maxima de 90 dias
use sim
Select * from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (290)
and datediff(day,dfechaInicioVigencia, dFechaFinVigencia)>90
)


--262. 
/* Se define como regla que los tramites de Solicitud de Calidad Migratoria Designado Temporal tengan un plazo de permanencia de ciento ochenta y tres (183) días*/

Select * from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (293)
and datediff(day,dfechaInicioVigencia, dFechaFinVigencia)>183)


Select * from simCambioCalMig where snumerotramite ='LM230716116'


--263.
/*
" Se define como regla que los tramitetes de Solicitud de Calidad Migratoria Artística Temporal tengan 90 dias de permanencia */
Select * from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (297)
and dFechaFinVigencia-dfechaInicioVigencia>90)

--264. 
/* Se define como regla que los tramites de Cambio Calidad Migratoria Designado Residente y Cambio de Calidad Migratoria formación residente
tengan 365 dias de permanencia*/

Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (298)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia != 1

--265----------15--------------------------------
/*
Se define como regla que para la Expedición del Carné de Extranjería para la Solicitud de Calidad Migratoria se debe contar con una visa que autoriza la calidad migratoria
*/
Select * from simtramite where nidtipotramite =55 and uidpersona in (Select uidpersona from simcarnetExtranjeria)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and uidpersona not in (Select uidpersona from simtramite where snumerotramite in (Select snumerotramite from simVisa))
and bcancelado =0

--266-------------------------16---------------------
/*Los CE deben tener una vigencia de 3 años en el caso de menores de edad*/
Select * from simCarnetExtranjeria e where dateDiff(day,dfechaEmision,dFechaCaducidad) > 1098
and banulado=0
and uidpersona in (
	Select uidpersona from simpersona where datediff(day,dfechaNacimiento, e.dFechaEmision)<=6580)
and stipo != 'R'

--267----------------------17-----------------------
/*"Autorización de estadía fuera del país 

CE vigente*/
Select * from simTramite where nidtipotramite =113 and uidpersona in (
Select uidpersona from simpersona where nidcalidad=313)
and snumeroTramite in (
	Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')

and uidpersona in (Select uidpersona from simcarnetextranjeria where dFechaCaducidad<getdate())

--268. ----------------18----------------------
--A
/*"Cambio de Calidad Migratoria Rentista Residente" 312
no debe contar con renovacion*/

Select * from simCambioCalMig where nidCalAnterior =312 and nidCalsolicitada=312

