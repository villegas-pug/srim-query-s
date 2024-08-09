# %% [markdown]
# # » `Dependencias`:

# %%
# !pip install plotly
# !pip install sqlalchemy
# !pip install numpy
# !pip install matplotlib

# %% [markdown]
# 

# %%
import pandas as pd
from sqlalchemy import create_engine
import numpy as np
import re
# import cufflinks as cf
# from IPython.display import display, HTML

# cf.set_config_file

# %% [markdown]
# ## 1. Conección → SIM(172.27.0.124)

# %%
# spring.datasource.url = jdbc:sqlserver://172.27.250.27;databaseName=SIRIM
SERVER = '172.27.0.124' # '172.27.0.242'
#DRIVER = 'SQL Server Native Client 11.0'
DRIVER = 'ODBC Driver 17 for SQL Server'
DATABASE = 'SIM'
USERNAME = 'userestadistica' # 'udesa'
PASSWORD = '$Us3R_3sT4d1sTic4$' # 'DESARROLLO2006'
DATABASE_CONNECTION = f'mssql://{USERNAME}:{PASSWORD}@{SERVER}/{DATABASE}?driver={DRIVER}'

engine = create_engine(DATABASE_CONNECTION)
connection = engine.connect()

# %% [markdown]
# ## 2. Métodos genéricos:

# %%
def get_query_sql(query):
  try:
    df = pd.read_sql(query, connection)
    return df
  except:
    print('¡Ocurrió un error!')

# %% [markdown]
# ## 3. EXTRACCIÓN Y EXPLORACIÓN DE DATOS:

# %% [markdown]
# ### 3.1 Aerolineas `Google, SIM y STSG` ...

# %%
from datetime import date, timedelta

sol_cue_end_date = str(date.today() + timedelta(days=-1))

QUERY_SQL = f''' 

                  SELECT
                     [Id Solicitud Cue] = s.nIdSolicitudCue,
                     [Num Solicitud Cue] = s.sNumSolicitudCue,
                     [Fecha Solicitud] = CAST(s.dFechaSolicitud AS DATE),
                     [Tipo Tramite] = tt.sDescripcion,
                     [Número Trámite] = s.sNumeroTramite,

                     [Nombre] = s.sNombre,
                     [Primer Apellido] = s.sPrimerApellido,
                     [Segundo Apellido] = s.sSegundoApellido,
                     [Documento] = ISNULL(s.sIdDocumento, ''),
                     [Num Documento] = ISNULL(s.sNumDocumento, ''),

                     [Etapa CUE] = (SELECT sDescripcion FROM SimEtapaCUE WHERE nIdEtapaCUE= S.nIdEtapaCUE),
                     [Estado Actual Soli CUE] = (
                                                CASE
                                                   WHEN s.sEstadoActualSoliCUE = 'I' THEN 'INICIADO'
                                                   WHEN s.sEstadoActualSoliCUE = 'O' THEN 'OBSERVADO'
                                                   WHEN s.sEstadoActualSoliCUE = 'S' THEN 'SUBSANADO'
                                                   WHEN s.sEstadoActualSoliCUE = 'F' THEN 'FINALIZADO'
                                                END
                                             ),
                     -- ANALISIS
                     [Login Usuario Analisis] = (-- nIdUsrInicia
                                          CASE WHEN S.nIdEtapaCUE = 3
                                             THEN (
                                                      SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                              WHERE nIdOperador = CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                      FROM SimEtapaSolicitudCUE E 
                                                      WHERE 
                                                         E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                         AND E.nIdEtapaCUE = 2 
                                                         AND (E.sEstado ='F' OR E.sEstado ='S') 
                                                         AND e.bactivo = 1 
                                                      ORDER BY nidetapaSolicue DESC
                                                   )
                                             ELSE
                                                   CASE WHEN S.nIdEtapaCUE = 2 THEN -- ANALISIS
                                                      CASE 
                                                         WHEN s.sEstadoActualSoliCUE = 'F' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='F' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                                         WHEN s.sEstadoActualSoliCUE = 'S' THEN (SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) FROM SimEtapaSolicitudCUE E WHERE E.nIdSolicitudCUE = S.nIdSolicitudCue AND E.nIdEtapaCUE = 2 and E.sEstado ='S' and e.bactivo = 1 ORDER BY nidetapaSolicue DESC) --queda
                                                         WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                                         WHEN s.sEstadoActualSoliCUE = 'O' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                                      END							
                                                   ELSE '' 
                                                   END 	
                                          END
                     ),
                     [Login Usuario Evaluación] = ( -- nIdUsrFinaliza
                                             CASE 
                                                WHEN S.nIdEtapaCUE = 3 THEN -- EVALUACION
                                                   CASE 
                                                      WHEN s.sEstadoActualSoliCUE = 'F' THEN (
                                                                                                SELECT TOP 1 CAST(ISNULL((SELECT sLogin FROM SimUsuario 
                                                                                                                        WHERE 
                                                                                                                              nIdOperador= CAST(E.nIdUsrFinaliza AS int)),'') AS VARCHAR(10)) 
                                                                                                FROM SimEtapaSolicitudCUE E 
                                                                                                WHERE 
                                                                                                      E.nIdSolicitudCUE = S.nIdSolicitudCue 
                                                                                                      AND E.nIdEtapaCUE = 3 
                                                                                                      AND E.sEstado ='F' 
                                                                                                      AND e.bactivo = 1 
                                                                                                   ORDER BY nidetapaSolicue DESC
                                                                                             )
                                                      WHEN s.sEstadoActualSoliCUE = 'I' THEN (SELECT sLogin FROM SimUsuario WHERE nIdOperador= CAST(S.nIdOperadorCue AS int)) 
                                                   END
                                                ELSE
                                                   CASE 
                                                      WHEN S.nIdEtapaCUE != 3 THEN ''
                                                      ELSE '' 
                                                   END 		
                                             END
                     )
                     
                  FROM SimSolicitudCUE s
                  JOIN SimTipoTramite tt ON tt.nIdTipoTramite = s.nIdTipoTramite
                  WHERE 
                     s.bActivo = 1
                     AND s.dFechaSolicitud <= '{ sol_cue_end_date } 23:59:59.999'
                     AND s.nIdEtapaCUE = 1 -- RECEPCIÓN CUE
                     AND s.sEstadoActualSoliCUE = 'F'
                     AND (s.nProcesoCoincidencias = 1 AND s.nProcesoHuellas = 1)

 '''

df_cue_recepcion = get_query_sql(QUERY_SQL)


# %%
from datetime import date, timedelta

path = r'D:\reportes_srim\cue\recepción'
file_name = str(date.today() + timedelta(days=-1))
full_path = f'{path}\\{file_name}.xlsx'

df_cue_recepcion.to_excel(full_path, sheet_name=file_name)

# df_cue_recepcion


