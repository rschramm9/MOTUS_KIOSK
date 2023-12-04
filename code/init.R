# init.R
#
# Example R code to install packages if not already installed
#
# Script contributed by Daniel Ruskin 17Nov2023
#

my_packages = c(
  "rvest",
  "tidyr",
  "lubridate",
  "sf",
  "tidyverse",
  "DT",
  "leaflet",
  "leaflet.extras2",
  "httr",
  "glue",
  "data.table",
  "anytime",
  "stringr",
  "xml2",
  "sf",
  "rjson",
  "shiny",
  "shinymeta",
  "shinyjs",
  "shiny.i18n",
  "shinyWidgets"
)

install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))

pak::pkg_install(my_packages)
