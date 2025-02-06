# %% [markdown]
# # » `Dependencias`:

# %%
# !pip install plotly
# !pip install sqlalchemy
# !pip install numpy
# !pip install matplotlib
# !pip install xlsxwriter
# %pip install yagmail

# %% [markdown]
# 

# %%
import pandas as pd
from sqlalchemy import create_engine
import yagmail as m

# %% [markdown]
# ## 1. Conección → SIM(172.27.0.124)

# %%
SERVER = '172.27.0.124' # '172.27.0.242'
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
# ## 3. EXTRACCIÓN, CARGA Y NOTIFICACIÓN DE REPORTE:

# %% [markdown]
# ### 3.1 Exportar y carga ...

# %%
from datetime import date, timedelta

yesterday = date.today() - timedelta(days=1)

QUERY_SQL = f'''

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
                     AND mm.dFechaControl BETWEEN '{yesterday} 00:00:00.000' AND '{yesterday} 23:59:59.998'

               ) f
               WHERE
                  f.[#] = 1

'''

df_mm_extranj = get_query_sql(QUERY_SQL)
df_mm_extranj.drop('#', axis=1, inplace=True)



# %%
from datetime import date

root_path = r'D:\\srim_reportes\\lvilchez\\movmigra_extranj'
file_name = str(yesterday)
full_path = f'{root_path}\\{file_name}.xlsx'

df_mm_extranj.index += 1
df_mm_extranj.to_excel(full_path, sheet_name=file_name, engine='openpyxl')

# %% [markdown]
# ### 3.2 Enviar reporte:

# %%
mail_source = 'srim.migraciones.peru@gmail.com'
pwd_source = 'rghb eltq khee cqmn'
""" mail_target = ['fnunezc@migraciones.gob.pe', 'lvilchez@migraciones.gob.pe'] """
mail_cc = ['locador_srim_02@migraciones.gob.pe']
msj = f'Reporte de movimientos migratorios de ven, cub y nic del día: {file_name}.'

""" to=mail_target, """

try:
   mail = m.SMTP(user=mail_source, password=pwd_source)
   mail.send(
      cc=mail_cc,
      subject=msj,
      attachments=full_path
   )
except Exception as e:
  print(f'Error al enviar el correo: {e}')

# %% [markdown]
# 


