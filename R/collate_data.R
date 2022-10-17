#' Collate data from different water/sediment BLE LTER data sets
#' @description
#'
#' @param ids (numeric) Vector of dataset IDs to grab, default is to get all data
#' @param output (character) Choice of "excel", "csv", or "object". Returns one Excel file, many CSV files, or an in-memory R list of data frames, respectively. Defaults to "object".
#'
#' @return
#' @export
#'
#' @examples
collate_data <- function(ids = NULL, output = "object", path = NULL) {
  if (is.null(path)) path <- getwd()
  stopifnot(is.numeric(ids) || is.null(ids), output %in% c("excel", "csv", "object"))
  data <- get_uncollated_dfs(ids = ids, path = path, metadata = TRUE)
  data <- data[["data"]]

  w <- c(2, 3, 4, 11, 13, 14) # IDs for water data
  s <- c(12, 14, 18) # IDs for sediment data
  pkgids <- names(data)
  dsids <-
    stringr::str_extract(pkgids, "(?<=\\.)(.+)(?=\\.)") # number between the two periods

  ## TODO: check for ids that don't belong. helper function?

  # have to pre-process first
  # like YSI data has "date_time" column while the others have "date_collected"
  # and "date_collected" becomes "date_time" in 2022, see issue #17
  # just hardcoding
  # data[[2]][[1]]$date_collected <- as.Date(data[[2]][[1]]$date_time)
  # data[[2]][[1]] <- dplyr::rename(data[[2]][[1]], date_time_YSI = date_time)

  # data[[2]][[1]] <- preprocess(data[[2]][[1]], ysi = TRUE)
  data <- rrapply::rrapply(data, f = preprocess, classes = "data.frame", how = "replace")
  # why is rrapply not working???
  # return(data)

  # sediment pigments long to wide
  data[[5]][[1]] <- tidyr::pivot_wider(data[[5]][[1]], names_from = pigment, values_from = c(areal_concentration_mg_m2, mass_concentration_ug_g, flag))

  # need to NOT duplicate common columns like node/lagoon/season/lat/lon

  # sort the data frames into water and sediment

  wlist <- list()
  slist <- list()

  for (i in seq_along(dsids)) {
    dsid <- dsids[[i]]
    if (dsid == 14) {
      wlist[[i]] <- data[[i]][[1]]
      slist[[i]] <- data[[i]][[2]]
    }
    else if (dsid %in% w && dsid != 14) {
      wlist[[i]] <- data[[i]][[1]]
    } else if (dsid %in% s && dsid != 14) {
      slist[[i]] <- data[[i]][[1]]
    }
  }

  # we've lost the names!

  # but anyway let's start merging


  # water
  wdf <-
    purrr::reduce(
      purrr::compact(wlist), #remove the NULL list items
      dplyr::full_join,
      by = c("node", "lagoon", "station", "season", "date_time", "water_column_position", "latitude", "longitude", "station_name", "habitat_type", "station_sampling_priority"),
      copy = TRUE
    )
  wdf <- bleutils::order_cp_cols(wdf, type = "water")
  wdf <-  bleutils::sort_cp_rows(wdf, type = "water")

  # remove redundant collection_method columns
  cols <- grep("collection_method", colnames(wdf))
  wdf <- subset(wdf, select = -cols[2:length(cols)])

  # sediment

  sdf <- purrr::reduce(
    purrr::compact(slist), # remove NULL list items
    dplyr::full_join,
    by = c("node", "lagoon", "station", "season", "date_time", "latitude", "longitude", "station_name", "habitat_type", "station_sampling_priority"),
    copy = TRUE
  )
  sdf <- bleutils::order_cp_cols(sdf, type = "sediment")
  sdf <-  bleutils::sort_cp_rows(sdf, type = "sediment")

  return(list(water = wdf,
              sediment = sdf))

}
