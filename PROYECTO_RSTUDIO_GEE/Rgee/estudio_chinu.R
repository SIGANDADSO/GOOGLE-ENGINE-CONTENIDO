#install packages
install.packages('sp')
install.packages('cptcity')
install.packages('rgee')
install.packages('sf')
install.packages("geojsonio")

#verficar el python que uso
reticulate::py_config()
#instalar desde rstudio
reticulate::py_install(
  packages = c("earthengine-api", "numpy"),
  pip = TRUE
)

#load packages
#Permite conectar R con Google Earth Engine.
library(rgee)
ee_clean_user_credentials() #borrar credenciales si hay error de autenticación
ee_Authenticate() # autenticar para concetar con cuenta de gee
ee_Initialize() ## inializar 

#Carga el paquete sp, uno de los paquetes clásicos para trabajar con datos espaciales
# se usa puntos, lineas, polígonos, coordenadas
library(sp)

#Carga paletas de colores para mapas: ayuda a colorear imagenes satélitales
library(cptcity)


#es el estándar para datos vectoriales en R.: lee shapefiles, GeoJSON, GPKG
# puede tambien unir capas, recortar, calcular áreas, transformar coordenadas
library(sf)

#gee necesita el paquete geojsonio para convertir el objeto sf a un objeto de Google Earth Engine.
library(geojsonio)


#setwd(): Set Working Directory es decir establecer la carpeta de trabajo.

setwd("D:/Carlos/Documents/QGIS/ENTRENAMIENTO QGIS/PROGRAMACION SIG/ENTRENAMIENTO GEE/CARGUES-GEE-GIT/GOOGLE-ENGINE-CONTENIDO/PROYECTO_RSTUDIO_GEE")

#area de estudio
ar_ee<-st_read("Insumos/colombia/cordoba/chinu/chinuu.shp")%>%
  sf_as_ee()

# Mostrar el área de estudio
Map$centerObject(ar_ee, 10)
Map$addLayer(ar_ee, list(color = "gray"), "Área de estudio")

# Cargar una colección Landsat 8
chinu <- ee$ImageCollection("LANDSAT/LC08/C02/T1_TOA")$
  filterBounds(ar_ee)$
  filterDate("2020-01-01", "2025-12-31")$
  sort("CLOUD_COVER")$
  first()$
  clip(ar_ee)

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
  name = "Color natural (4-3-2"
)
# Calcular NDVI
NDVI <- chinu$
  normalizedDifference(c("B5", "B4"))$
  rename("NDVI")

# Mostrar NDVI
Map$addLayer(
  eeObject = NDVI,
  visParams = list(
    min = -1,
    max = 1,
    palette = cpt("grass_ndvi", 10)
  ),
  name = "NDVI"
)


# Calcular el NBR usando la Banda 5 (NIR) y Banda 7 (SWIR 2)
NBR <- chinu$
  normalizedDifference(c("B5", "B7"))$
  rename("NBR")

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

dem <- ee$Image("NASA/NASADEM_HGT/001")$
         select("elevation")$
        clip(ar_ee)


# Mostrar dem
Map$addLayer(
  eeObject = dem,
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






