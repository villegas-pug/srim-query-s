use sim


--197. Los tramites con estado aprobado no deben estar en etapa de Iniciado
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (
Select * from simEtapatramiteInm where snumerotramite in(
Select [Número Tramite]  from (
SELECT
   
   [Id Persona] = p.uIdPersona,
   [Nombres] = p.sNombre,
   [Apellido 1] = p.sPaterno,
   [Apellido 2] = p.sMaterno,
   [Sexo] = p.sSexo,
   [Fecha de Nacimiento] = p.dFechaNacimiento,
   [Nacionalidad ] = p.sIdPaisNacionalidad,
   [Número Tramite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Etapa Actual] = e.sDescripcion,
   [Fecha Trámite] = t.dFechaHora,
   [Dependencia] = d.sNombre,
   [Cantidad Etapas (I)] = et.[nCantEtapas(I)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimEtapa e ON ti.nIdEtapaActual = e.nIdEtapa
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT f.*
      FROM (
      SELECT 
         eti.sNumeroTramite,
         [#] = ROW_NUMBER() OVER (PARTITION BY eti.sNumeroTramite ORDER BY eti.nIdEtapaTramite DESC),
         [nCantEtapas(I)] = COUNT(1) OVER (PARTITION BY eti.sNumeroTramite)
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.sEstado = 'I'
         AND eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1
      AND f.[nCantEtapas(I)] >= 1

) et ON et.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.bCulminado = 1
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)-- 57: PRR; 58: CCM; 113: CPP; 126: PTP
   AND ti.sEstadoActual = 'A'

   )C2)
   and sEstado='I')c1
   Update #RegInconsistentes Set sEstado='F'
   Select * from #RegInconsistentes





--198. La etapa registrada en SimTramiteINM debe coincidir con la ultima 
--etapa registrada en SimEtapaTramiteINM
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (
Select * from (
SELECT
   
   [Número Trámite] = t.sNumeroTramite,
   [Tipo Trámite] = tt.sDescripcion,
   [Estado Trámite] = (

                        CASE ti.sEstadoActual
                           WHEN 'P' THEN 'PENDIENTE'
                           WHEN 'R' THEN 'ANULADO'
                           WHEN 'D' THEN 'DENEGADO'
                           WHEN 'A' THEN 'APROBADO'
                           WHEN 'E' THEN 'DESISTIDO'
                           WHEN 'B' THEN 'ABANDONO'
                           WHEN 'N' THEN 'NO PRESENTADA'
                        END
                     ),
   [Fecha Trámite] = t.dFechaHora,
   --Aux
   [Id Etapa (SimTramiteInm)] = ti.nIdEtapaActual,
   [Id Etapa (SimEtapaTramiteInm)] = let.[nIdEtapa(Ult)],
   [nIdultimo]=let.[nIdUltimo],
   [Estado Etapa (SimEtapaTramiteInm)] = let.[sEstado(Ult)]

FROM SimTramite t
JOIN SimTramiteInm ti ON t.sNumeroTramite = ti.sNumeroTramite
JOIN SimPersona p ON t.uIdPersona = p.uIdPersona
JOIN SimTipoTramite tt ON t.nIdTipoTramite = tt.nIdTipoTramite
JOIN SimDependencia d ON t.sIdDependencia = d.sIdDependencia
JOIN (

   SELECT 
      f.*
   FROM (
      SELECT 
         eti.sNumeroTramite,

         -- Aux
         [#] = ROW_NUMBER() OVER (
                              PARTITION BY eti.sNumeroTramite 
                              ORDER BY eti.nIdEtapaTramite ASC
                           ),
         [nIdEtapa(Ult)] = LAST_VALUE(eti.nIdEtapa) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   ),
         [sEstado(Ult)] = LAST_VALUE(eti.sEstado) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                ),
		[nIdUltimo] = LAST_VALUE(eti.nIdEtapaTramite) OVER (
                                                      PARTITION BY eti.sNumeroTramite 
                                                      ORDER BY eti.nIdEtapaTramite ASC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                                   )
      FROM SimEtapaTramiteInm eti
      WHERE
         eti.bActivo = 1
   ) f
   WHERE
      f.[#] = 1

) let ON let.sNumeroTramite = t.sNumeroTramite
WHERE
   t.bCancelado = 0
   AND t.dFechaHora >= '2016-01-01 00:00:00.000'
   AND t.nIdTipoTramite IN (57, 58, 113, 126)
   AND ti.nIdEtapaActual != let.[nIdEtapa(Ult)]

   )C1
   )z1

DROP TABLE IF EXISTS #DataTramiteINM
Select * into #DataTramiteINM from (
Select * from simTramiteInm where snumerotramite in (
	Select [Número Trámite] from #RegInconsistentes))di


DROP TABLE IF EXISTS #DataEtapaTramiteINM    
	
Select * into #DataEtapaTramiteINM from (
Select * from simEtapaTramiteInm where nidetapatramite in (
Select nidultimo from #RegInconsistentes))di

Update #DataTramiteINM set nIdEtapaActual = (Select [Id Etapa (SimEtapaTramiteInm)] from #RegInconsistentes ri
where #DataTramiteINM.sNumeroTramite=ri.[Número Trámite])

Update #DataTramiteINM set nIdUltimaEtapa = (Select nidultimo from #RegInconsistentes ri
where #DataTramiteINM.sNumeroTramite=ri.[Número Trámite])


Select * from #DataTramiteINM order by snumerotramite




-- 200. Los tramites con entrega de carné finalizado y sin reconsideracion no deben estar en estado pendiente
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (
Select * from simTramiteINMApro where snumerotramite in(
SELECT
   
   st.sNumeroTramite
  
FROM SimTramite st
JOIN SimTramiteInm sti ON st.sNumeroTramite = sti.sNumeroTramite
JOIN SimPersona sper ON st.uIdPersona = sper.uIdPersona
JOIN SimTipoTramite stt ON st.nIdTipoTramite = stt.nIdTipoTramite
WHERE
   st.bCancelado = 0
   AND st.dFechaHora >= '2021-08-01 00:00:00.000' 
   AND st.uIdPersona != '00000000-0000-0000-0000-000000000000'
   AND st.nIdTipoTramite IN (58, 113, 126)
   AND sti.sEstadoActual = 'P'
   AND EXISTS (

      SELECT
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (
                                SELECT t.nIdEtapaFinal FROM (
                                    VALUES
                                       (58, 17),
                                       (113, 63),
                                       (126, 63),
                                       (126, 80)
                                 ) AS t([nIdTipoTramite], [nIdEtapaFinal])
                                 WHERE
                                    t.nIdTipoTramite = st.nIdTipoTramite
                           )
         AND seti.sEstado = 'F'
         AND seti.bActivo = 1
   )
   AND NOT EXISTS (

      SELECT 
         TOP 1 1
      FROM SimEtapaTramiteInm seti
      WHERE
         seti.sNumeroTramite = st.sNumeroTramite 
         AND seti.nIdEtapa IN (67, 68) -- 67 ↔ RECONSIDERACION.; 68 ↔ APELACION.
         AND seti.sEstado = 'I'
         AND seti.bActivo = 1
         
   )))c1
   Update #RegInconsistentes Set sEstadoActual='A'
   Select * from #RegInconsistentes

--210. Se define como regla que la Caducidad de los Carnet de Extranjeria para la Calidad Migratoria de permanente deben de ser como maximo de 5 años.


DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select DATEDIFF(day,dFechaEmision,dFechaCaducidad) as dias, * from SimCarnetExtranjeria where uidpersona in (
Select uIdPersona from simpersona where uidpersona not in (select uidpersona from simperuano) and nIdCalidad !=21
and uidpersona in (select uidpersona from SimCarnetExtranjeria)
and nIdCalidad =313)
and dFechaVencRes is not null
and banulado =0
and DATEDIFF(day,dFechaEmision,dFechaCaducidad)>1830


 )c1
 
Update #RegInconsistentes Set dFechaCaducidad = dateadd(day,-1,dateadd(year,5,dFechaEmision))


Select * from #RegInconsistentes
Where DATEDIFF(day,dFechaEmision,dFechaCaducidad)>1830

--211. Los tipos de Motivos de tramites deben estar contenidos en la tabla simTipoMotivo manteniendo la integridad referencial

ALTER TABLE simMotivo
ADD CONSTRAINT FK_simMotivo_simTipoMotivo FOREIGN KEY (nidtipomotivo)
REFERENCES simTipoMotivo (nidtipomotivo)

-- 212. Los tipos de tramites registrados en simTramite deben guardad integridad referencial con la tabla simTipoTramite

ALTER TABLE simTramite
ADD CONSTRAINT FK_simTramite_simTipoTramite FOREIGN KEY (nidTipoTramite)
REFERENCES simTipoTramite (nidtipoTramite)


--213. 

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (



Select * from simCarnetExtranjeria where snumerotramite in (

Select snumerotramite from SimTramite where 
bCancelado = 0
AND SimTramite.bCulminado = 1
and	sNumeroTramite in(

 Select sNumeroTramite from simCarnetExtranjeria 
 where convert(date,dFechaEmision)>convert(date,dfechaCaducidad)
 and dfechaCaducidad != '1900-01-01 00:00:00.000'
 and banulado =0))
 
 and banulado =0

 )c1
 
Update #RegInconsistentes Set dFechaCaducidad = dateadd(day,-1,dateadd(year,3,dFechaEmision))


Select * from #RegInconsistentes
where convert(date,dFechaEmision)>convert(date,dfechaCaducidad)




-- 226. El tiempo maximo de permanencia por Calidad Migratoria designada es 183 dias 
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (293)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 183


) c1

Update #RegInconsistentes Set nPermanencia = 183
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,183,dfechaAprobacion)

Select * from #RegInconsistentes


--227. Las CM de Formacion e Inversionista puede ser renovada hasta por 90 dias Adicionales (rev cod)

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select *from SimProrroga where snumerotramite in (
Select snumerotramite from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (290,302)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 90
and banulado =0))
)
)c1
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,90,dfechahoraAud)
update #RegInconsistentes set nDias =90
Select * from #RegInconsistentes

---------------------------ACD--------------------------------------
-- 228. Los carnet entregados deben tener la condicion de APROBADO

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select * FROM SimTramiteInmApro where snumerotramite in (
Select snumerotramite from simTramite where nidTipoTramite = 111
and bcancelado=0
and snumeroTramite in (Select snumeroTramite from simCarnetExtranjeria)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'P')
and snumeroTramite in (select sNumeroTramite from simEtapatramiteInm where nidEtapa in (17,63,79,80)
and sEstado ='F' and bactivo=1)
)
)c1
Update #RegInconsistentes Set sEstadoActual = 'A'

Select * from #RegInconsistentes



--234. 

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select * from simEtapaTramiteInm where snumerotramite in (
Select snumerotramite from simTramite where snumerotramite
in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and snumerotramite in (
select snumerotramite from simEtapaTramiteINM 
		where nidEtapa in (17,63,79,80)
		and sEstado != 'F'
		and bactivo=1)
and snumerotramite not in (
select snumerotramite from simEtapaTramiteINM 
		where nidEtapa in (83)
		and sEstado = 'F'
		and bactivo=1)
		)
		and sEstado != 'F'
		and nidEtapa in (17,63,79,80)
)c1
Update #RegInconsistentes Set sEstado = 'F'

Select * from #RegInconsistentes


--239. 
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select *from SimProrroga where snumerotramite in (
Select snumerotramite from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (292)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 183
and banulado =0))
)
)c1
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,183,dfechahoraAud)
update #RegInconsistentes set nDias =183
Select * from #RegInconsistentes




-- 240. 
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select *from SimProrroga where snumerotramite in (


Select snumerotramite from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (290)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 90
and banulado =0))
)
)c1
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,90,dfechahoraAud)
update #RegInconsistentes set nDias =90
Select * from #RegInconsistentes






--243.

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (292)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 183


) c1

Update #RegInconsistentes Set nPermanencia = 183
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,183,dfechaAprobacion)

Select * from #RegInconsistentes




--244.

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (290)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 90


) c1

Update #RegInconsistentes Set nPermanencia = 90
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,90,dfechaAprobacion)

Select * from #RegInconsistentes



--245. 


DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * , datediff(day, dfechaAprobacion,dFechaVencimiento) 
as tiempo from simCambioCalMig where nidcalSolicitada in (300, 296)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia !=1


) c1

Update #RegInconsistentes Set nPermanencia = 1
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,-1,dateadd(year,1,dfechaAprobacion))

Select * from #RegInconsistentes





--246. Se define como regla que los ciudadanos extranjeros deben contar con un solo numero de CE


DROP TABLE IF EXISTS #RegInconsistentes
DROP TABLE IF EXISTS #RegInconsistentes2
Select * into #RegInconsistentes FROM (

Select * from simcarnetextranjeria where uidpersona in (
Select persona from(
SElect count(*) as conteo, persona from (

Select sNumeroCarnet as carnet, uIdPersona as persona from SimCarnetExtranjeria where banulado=0
Group by sNumeroCarnet, uIdPersona)as c1
Group by persona
having count(*)>1)c2)
and banulado=0)c3

Update #RegInconsistentes Set banulado = 1 where nidcarnet not in (Select nidcarnet from simcarnetextranjeria ce where dfechacaducidad = (
Select max(dfechacaducidad) from simcarnetextranjeria ce2 where 
ce2.uidpersona=ce.uidpersona
and banulado =0)
)

Select * into #RegInconsistentes2 FROM (Select * from simcarnetextranjeria where uidpersona in (
Select persona from(
SElect count(*) as conteo, persona from (

Select sNumeroCarnet as carnet, uIdPersona as persona from #RegInconsistentes where banulado=0
Group by sNumeroCarnet, uIdPersona)as c1
Group by persona
having count(*)>1)c2)) c5

DROP TABLE #RegInconsistentes

Declare @conta int
set @conta = (select count(*) from #RegInconsistentes2)
if @conta > 0
Begin
Update #RegInconsistentes2 Set banulado = 1 where nidcarnet not in (Select nidcarnet from simcarnetextranjeria ce where dfechaEmision = (
Select min(dfechaEmision) from simcarnetextranjeria ce2 where 
ce2.uidpersona=ce.uidpersona
and banulado =0)
)
End

Select * from #RegInconsistentes2

 

--247. 

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * from simVisa where snumeroTramite in (


Select snumeroTramite from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (293,292)
and datediff(day,dfechaInicioVigencia, dFechaFinVigencia)>183)



)
) c1

Update #RegInconsistentes Set dFechaFinVigencia = dateadd(day,183,dfechaInicioVigencia)
Update #RegInconsistentes Set ntiempo = 183
Select * from #RegInconsistentes





-- Revisar
--255

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select *from SimProrroga where snumerotramite in (
Select snumerotramite from simTramite where nidTipoTramite in (56)
and uidpersona in (select uidpersona from simpersona where uidpersona not in (
	Select uidpersona from simPeruano)
	and nidCalidad in (293)
and snumerotramite in(

Select snumerotramite from SimProrroga where ndias > 183
and banulado =0))
)
)c1
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,183,dfechahoraAud)
update #RegInconsistentes set nDias =183
Select * from #RegInconsistentes



--259.


DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select * from simCambioCalMig where nidcalSolicitada in (293)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 183


) c1

Update #RegInconsistentes Set nPermanencia = 183
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,183,dfechaAprobacion)

Select * from #RegInconsistentes






--260.

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (

Select * from simCambioCalMig where nidcalSolicitada in (291)
and snumeroTramite in (Select sNumeroTramite from SimTramiteInmApro where sEstadoActual = 'A')
and nPermanencia > 90

) c1

Update #RegInconsistentes Set nPermanencia = 90
Update #RegInconsistentes Set dFechaVencimiento = dateadd(day,90,dfechaAprobacion)

Select * from #RegInconsistentes




--262.
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * from simVisa where snumeroTramite in (


Select snumeroTramite from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (293)
and datediff(day,dfechaInicioVigencia, dFechaFinVigencia)>183)


)
) c1

Update #RegInconsistentes Set dFechaFinVigencia = dateadd(day,183,dfechaInicioVigencia)
Update #RegInconsistentes Set ntiempo = 183
Select * from #RegInconsistentes




--263.
DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (


Select * from simVisa where snumeroTramite in (


Select snumeroTramite from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (297)
and dFechaFinVigencia-dfechaInicioVigencia>90
and bcancelado=0)


)
) c1

Update #RegInconsistentes Set dFechaFinVigencia = dateadd(day,90,dfechaInicioVigencia)
Update #RegInconsistentes Set ntiempo = 90
Select * from #RegInconsistentes


--266.

DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (
Select * from simCarnetExtranjeria where dateDiff(day,dfechaEmision,dFechaCaducidad) > 1098
and banulado=0
and uidpersona in (
Select uidpersona from simpersona where datediff(day,dfechaNacimiento,getdate())<=6580)
and stipo != 'R') c1

Update #RegInconsistentes Set dFechaCaducidad = dateadd(day,-1,dateadd(year,3,dFechaEmision))

Select * from #RegInconsistentes


--269


DROP TABLE IF EXISTS #RegInconsistentes
Select * into #RegInconsistentes FROM (
Select * from simVisa where snumeroTramite in (
Select snumeroTramite from simTramite where nidTipoTramite in (55)
and snumeroTramite in (Select sNumeroTramite from simvisa where nidCalSolicitada in (290)
and datediff(day,dfechaInicioVigencia, dFechaFinVigencia)>90))) c1

Update #RegInconsistentes Set dFechaFinVigencia = dateadd(day,90,dfechaInicioVigencia)

Select * from #RegInconsistentes

