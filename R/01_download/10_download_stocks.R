# --- DEFINIR RANGO DE FECHAS PARA PEDIDO ---
fecha_inicio <- ultima_fecha + 1
fecha_fin <- Sys.Date()

if (fecha_inicio > fecha_fin) {
  message("Ya estás actualizado. No hay datos nuevos.")
  quit(save = "no")
}

# --- CONSTRUIR URL DE CONSULTA ---
url <- paste0(
  "http://api.marketstack.com/v2/eod?",
  "access_key=", api_key,
  "&symbols=", símbolo,
  "&date_from=", fecha_inicio,
  "&date_to=", fecha_fin,
  "&limit=1000"
)

# --- HACER REQUEST ---
res <- GET(url)

if (res$status_code != 200) {
  stop("Error en la descarga: ", res$status_code)
}

data_raw <- content(res, as = "parsed", type = "application/json")

# --- VALIDAR DATOS ---
if (is.null(data_raw$data) || length(data_raw$data) == 0) {
  message("No hay datos nuevos disponibles.")
  quit(save = "no")
}

# --- PROCESAR Y LIMPIAR ---
nueva_data <- map_dfr(data_raw$data, as_tibble) %>%
  select(date, symbol, open, high, low, close, volume) %>%
  mutate(date = as.Date(date)) %>%
  arrange(date)

# --- FILTRAR DUPLICADOS POR SI ACASO ---
if (nrow(stock_data) > 0) {
  nueva_data <- nueva_data %>% filter(date > ultima_fecha)
}

# --- COMBINAR Y GUARDAR ---
data_actualizada <- bind_rows(stock_data, nueva_data) %>%
  arrange(date)

# Guardar archivo actualizado
write_csv(data_actualizada, ruta_archivo)

# Guardar backup del día
backup_name <- file.path(carpeta_datos, paste0(símbolo, "_", Sys.Date(), ".csv"))
write_csv(data_actualizada, backup_name)

message("✅ Datos de ", símbolo, " actualizados y guardados con éxito.")