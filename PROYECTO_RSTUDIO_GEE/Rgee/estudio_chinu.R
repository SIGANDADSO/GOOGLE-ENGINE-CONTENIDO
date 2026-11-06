# 1. Desactivar el bloqueo de instalación para evitar el error "Permission denied"
# options(install.lock = FALSE)

# 2. Instalar los paquetes uno por uno
# install.packages('sp') # Datos espaciales clásicos (coordenadas, líneas)
# install.packages('cptcity') # Paletas de colores para mapas satelitales
# install.packages('sf')  #Estándar moderno para datos vectoriales (Shapefiles, GeoJSON)
# install.packages('geojsonio') # Conversión de sf a formato compatible con GEE
# install.packages('rgee') #para usar GEE


# 3.  Cargar reticulate para gestionar Python
library(reticulate) #depende del pquete rgee

# 4. Verificar qué Python está detectando R actualmente
# py_config()

# 5. Instalar las librerías necesarias en el entorno de RStudio
py_install(
  packages = c("earthengine-api", "numpy"),
  pip = TRUE
)

# 6. Cargar librerías espaciales y de diseño
library(sp)         # Datos espaciales clásicos (coordenadas, líneas)
# Es una librería (sp) de respaldo. rgee y sf la requieren cargada en la sesión para mantener la compatibilidad con sistemas de coordenadas antiguos y asegurar que ciertos cálculos geométricos estables heredados no fallen al interactuar con el entorno de Python.

library(cptcity)    # Paletas de colores para mapas satelitales
library(sf)         # Estándar moderno para datos vectoriales (Shapefiles, GeoJSON)
library(geojsonio)  # Conversión de sf a formato compatible con GEE

# 7.  Cargar e inicializar rgee
library(rgee)

# ¡OJO! Solo usa esta línea si ya tenías un error previo de autenticación. 
# Si es tu primera vez, puedes dejarla comentada con 
# ee_clean_user_credentials() 

# CASO DE BORRAR CARPETA rgee::ee_clean_user_credentials("xxxxxxxx") 

# 7.1. Configurar la ruta de tu NUEVO proyecto o Asset principal
options(rgee.asset_path = "projects/earthengine-legacy/assets/users/ee-andresdecarlo58")

# 7.2. Autenticar con tu NUEVA cuenta de Google Earth Engine
# Recuerda marcar TODAS las casillas de Google Drive en el navegador web
ee_Authenticate(user = "ee-andresdecarlo58")

# 7.3. Inicializar la sesión con la nueva configuración limpia
ee_Initialize(user = "ee-andresdecarlo58", drive = FALSE)

################PASOS AHORA PARA TRABAJAR EN EL PROYECTO###########

#1. setwd(): Set Working Directory es decir establecer la carpeta de trabajo.
getwd() # obtener primero la ruta
setwd("D:/Carlos/Documents/QGIS/ENTRENAMIENTO QGIS/PROGRAMACION SIG/ENTRENAMIENTO GEE/CARGUES-GEE-GIT/GOOGLE-ENGINE-CONTENIDO/PROYECTO_RSTUDIO_GEE")

#2. area de estudio
ar_ee <- st_read("Insumos/colombia/cordoba/chinu/chinuu.shp") %>%
  sf_as_ee() #uso de library(sf) y library(geojsonio)

#3. Mostrar el área de estudio
Map$centerObject(ar_ee, 10)
Map$addLayer(ar_ee, list(color = "gray"), "Área de estudio")

# Cargar una colección Landsat 8
chinu <- ee$ImageCollection("LANDSAT/LC08/C02/T1_TOA")$filterBounds(ar_ee)$filterDate("2020-01-01", "2025-12-31")$sort("CLOUD_COVER")$first()$clip(ar_ee)

# Mostrar composición falso color (SWIR1 - NIR - Red)
Map$addLayer(
  eeObject = chinu$select(c("B6", "B5", "B4")),
  visParams = list(
    min = 0,
    max = 0.4,
    gamma = 1.2
  ),
  name = "Falso color"
)
# Mostrar Color natural (RGB)

Map$addLayer(
  eeObject = chinu$select(c("B4", "B3", "B2")),
  visParams = list(
    min = 0,
    max = 0.3,
    gamma = 1.2
  ),
  name = "Color natural (4-3-2)"
)
# Calcular NDVI
NDVI <- chinu$normalizedDifference(c("B5", "B4"))$rename("NDVI")

# Mostrar NDVI
Map$addLayer(
  eeObject = NDVI,
  visParams = list(
    min = -1,
    max = 1,
    palette = cpt("grass_ndvi", 10) #uso de library(cptcity)
  ),
  name = "NDVI"
)


# Calcular el NBR usando la Banda 5 (NIR) y Banda 7 (SWIR 2)
NBR <- chinu$normalizedDifference(c("B5", "B7"))$rename("NBR")

# Mostrar NBR
Map$addLayer(
  eeObject = NBR,
  visParams = list(
    min = -0.4,
    max = 0.7,
    palette = c("red", "yellow", "green") # Red indica zonas quemadas o suelo desnudo
  ),
  name = "NBR"
)

####################################DEM##############################################
# Hallar el DEM 

dem <- ee$Image("NASA/NASADEM_HGT/001")$select("elevation")$clip(ar_ee)


# Mostrar dem
Map$addLayer(
   dem,
  visParams = list(
    min = 0,
    max = 5000,
    palette = c("#006400",
                "#7FBF3F",
                "#FEE08B",
                "#D95F0E",
                "#6D4C41")
    ),
  name = "dem"
)

#Calcula el sombreado del relieve-DEM
terrain <- ee$Algorithms$Terrain(dem)

hillshade <- terrain$select("hillshade")

#Mostrar sombreado
Map$addLayer(
  hillshade,
  visParams = list(
    min = 0,
    max = 255
  ),
  name = "Hillshade"
)

# visualizar la pendiente
slope <- terrain$select("slope")

Map$addLayer(
   slope,
  visParams = list(
    min = 0,
    max = 60,
    palette = c( "#2E8B57",
                 "#8BC34A",
                 "#FDD835",
                 "#A1887F",
                 "#6D4C41")
  ),
  name = "Pendiente"
)






