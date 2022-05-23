#' Collate data from different water/sediment BLE LTER data sets
#' @description
#'
#' @param data (list) Nested list of data frames, output from download_data
#' @param output (character) Choice of "excel", "csv", or "object". Returns one Excel file, many CSV files, or an in-memory list, respectively. Defaults to "object".
#'
#' @return
#' @export
#'
#' @examples
collate_data <- function(data, output = "object") {
  stopifnot(is.list(data), output %in% c("excel", "csv", "object"))

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
  data[[2]][[1]] <- preprocess(data[[2]][[1]], ysi = TRUE)
  data <- rrapply::rrapply(data, preprocess, how = "replace", classes = "data.frame")
  # why is rrapply not working???


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
      # by = c("station", "date_collected", "water_column_position"),
      copy = TRUE
    )

  # sediment

  sdf <- purrr::reduce(
    purrr::compact(slist), # remove NULL list items
    dplyr::full_join,
    copy = TRUE
  )

  return(list(water = wdf,
              sediment = sdf))

}
