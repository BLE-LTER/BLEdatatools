#' Collate data from different water/sediment BLE LTER data sets
#' @description
#'
#' @param ids (numeric) Vector of BLE dataset IDs to grab. Default is to get all data.
#' @param output (character) Choice of "excel", "csv", or "object". Returns one Excel file or many CSV files in addition to a R list of data frames, or skipping writing to file altogether, respectively. Defaults to "object".
#' @param path (character) Path to working directory. Data files will be written to this directory. Defaults to the R session's working directory if unspecfied.
#' @param avg_rep (logical) TRUE/FALSE on whether to average replicates. Defaults to FALSE.
#' @param skip_metadata (logical) whether to skip metadata, defaults to FALSE
#'
#' @return (list) Named list of data frames: "water_data", "sediment_data", "dataset_metadata", and "column_metadata"
#' @export
collate <-
  function(ids = NULL,
           output = "object",
           path = NULL,
           avg_rep = FALSE,
           skip_metadata = FALSE) {
    # -------------------------------------------------
    # ---------- CHECKING ARGUMENTs -------------------
    # -------------------------------------------------
    if (is.null(path))
      path <- getwd()
    stopifnot(is.numeric(ids) ||
                is.null(ids),
              output %in% c("excel", "csv", "object"))
    # -------------------------------------------------
    # --------- DOWNLOADS -----------------------------
    # -------------------------------------------------
    fromedi <-
      get_uncollated_dfs(ids = ids,
                         path = path,
                         skip_metadata = skip_metadata)
    data <- fromedi[["data"]]
    message("Collating Core Program datasets...")
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
    data <-
      rrapply::rrapply(
        object = data,
        f = preprocess,
        classes = "data.frame",
        how = "replace"
      )
    # why is rrapply not working???
    # return(data)

    # sediment pigments long to wide
    if (12 %in% ids) {
      data$`knb-lter-ble.12`[[1]] <-
        tidyr::pivot_wider(
          data$`knb-lter-ble.12`[[1]],
          names_from = pigment,
          values_from = c(areal_concentration_mg_m2, mass_concentration_ug_g, flag)
        )
    }


    # avg rep for nutrients
    if (14 %in% ids) {
      if (avg_rep) {
        # 2019 reps are NA but now are 1
        # data[[7]][[1]][is.na(data[[7]][[1]][["rep"]]), "rep"] <- 1
        # # duplicates haiz
        # data[[7]][[1]] <- data[[7]][[1]][which(!duplicated(data[[7]][[1]])), ]
        # aggregate(data[[7]][[1]][[8]], list(data[[7]][[1]]$rep), FUN=mean)
        # aggregate(data[[7]][[1]][[8]], list(data[[7]][[1]]$rep), FUN=mean)

      } else {
        nutrient <- data$`knb-lter-ble.14`
        nutrient[[1]][is.na(nutrient[[1]][["rep"]]), "rep"] <- 1
        nutrient[[1]] <-
          nutrient[[1]][which(!duplicated(nutrient[[1]])), ]
        # stop-gap solution while Quinn looks at stuff
        nutrient[[1]][84, 6] <- "bottom"
        nutrient[[1]] <-
          tidyr::pivot_wider(
            nutrient[[1]],
            names_from = rep,
            values_from = c(
              ammonium_umol_N_L,
              phosphate_umol_P_L,
              silicate_umol_SiO2_L,
              nitrate_nitrite_umol_N_L,
              flag_NH3,
              flag_PO4,
              flag_SiO2,
              flag_NO23
            ),
            names_prefix = "rep"
          )
        # data[[7]][[1]][is.null(data[[7]][[1]])] <- NA
      }
    }
    # --------------------------------------------------------
    # sort the data frames into water and sediment -----------
    # --------------------------------------------------------
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
    # ----------------------------------------------------
    # ------------------- water --------------------------
    # ----------------------------------------------------
    if (length(wlist) > 0) {
      wdf <-
        purrr::reduce(
          purrr::compact(wlist),
          #remove the NULL list items
          dplyr::full_join,
          by = c(
            "node",
            "lagoon",
            "station",
            "season",
            "date_time",
            "water_column_position",
            "latitude",
            "longitude",
            "station_name",
            "habitat_type",
            "station_sampling_priority"
          ),
          copy = TRUE
        )
      # remove redundant collection_method columns
      cols <- grep("collection_method", colnames(wdf))
      wdf <- subset(wdf, select = -cols[2:length(cols)])

      # rename to collection_method
      colnames(wdf)[grep("collection_method", colnames(wdf))] <-
        "collection_method"
      wdf <- bleutils::order_cp_cols(wdf, type = "water")
      wdf <-  bleutils::sort_cp_rows(wdf, type = "water")
    } else
      wdf <- NULL

    # ---------------------------------------------------------------
    # -------------- sediment ---------------------------------------
    # ---------------------------------------------------------------
    if (length(slist) > 0) {
      sdf <- purrr::reduce(
        purrr::compact(slist),
        # remove NULL list items
        dplyr::full_join,
        by = c(
          "node",
          "lagoon",
          "station",
          "season",
          "date_time",
          "latitude",
          "longitude",
          "station_name",
          "habitat_type",
          "station_sampling_priority"
        ),
        copy = TRUE
      )
      sdf <- bleutils::order_cp_cols(sdf, type = "sediment")
      sdf <-  bleutils::sort_cp_rows(sdf, type = "sediment")
    } else
      sdf <- NULL
    out <- list(water_data = wdf,
                sediment_data = sdf)

    # ------------------------------------------------
    # --- METADATA -----------------------------------
    # ------------------------------------------------
    if (!skip_metadata) {
      message("Summarizing dataset and column metadata...")
      metadata <- fromedi[['metadata']]
      metalist <- collate_metadata(ids = ids,
                                   metadata = metadata)
      out <- c(out, metalist)
    } else
      message("Skipping summary of metadata...")

    # ---------------------------------------------------------------
    # --------- WRITING TO FILE -------------------------------------
    # ---------------------------------------------------------------

    if (output == 'excel') {
      file <- file.path(path, "BLE_LTER_Core_Program_collated_data.xlsx")
      # using the 'xlsx' library
      # xlsx::write.xlsx(wdf, file = file, sheetName = "water_data", row.names = FALSE)
      # xlsx::write.xlsx(sdf, file = file, sheetName = "sediment_data", row.names = FALSE, append = TRUE)
      # if (skip_metadata) {
      #   xlsx::write.xlsx(metalist[["dataset_metadata"]], file = file, sheetName = "dataset_metadata", rows.names = FALSE, append = TRUE)
      #   xlsx::write.xlsx(metalist[["column_metadata"]], file = file, sheetName = "column_metadata", row.names = FALSE, append = TRUE)
      # }
      #
      # using the 'openxlsx' library

      openxlsx::write.xlsx(x = out,
                           file = file,
                           rowNames = FALSE)
      message(paste0("Excel file written to path: ", file))
    }
    if (output == 'csv') {
      file2 <-
        file.path(path,
                  "BLE_LTER_Core_Program_collated_sediment_data.csv")
      if (!is.null(wdf)) {
        file1 <-
          file.path(path, "BLE_LTER_Core_Program_collated_water_data.csv")
        write.csv(wdf, file = file1, row.names = FALSE)
      } else file1 <- "No water dataset IDs specified. Water data was skipped."
      if (!is.null(sdf)) {
        file2 <-
          file.path(path,
                    "BLE_LTER_Core_Program_collated_sediment_data.csv")
        write.csv(sdf, file = file2, row.names = FALSE)
      } else file2 <- "No sediment dataset IDs specified. Sediment data was skipped."
      if (!skip_metadata) {
        file3 <-
          file.path(path,
                    "BLE_LTER_Core_Program_collated_dataset_metadata.csv")
        file4 <-
          file.path(path,
                    "BLE_LTER_Core_Program_collated_column_metadata.csv")
        write.csv(metalist[["dataset_metadata"]], file = file3, row.names = FALSE)
        write.csv(metalist[["column_metadata"]], file = file4, row.names = FALSE)
        message(paste(
          "CSV files written to paths: ",
          file1,
          file2,
          file3,
          file4,
          sep = "\n   "
        ))
      } else
        message(paste("CSV files written to paths: ", file1, file2, sep = "\n   "))
    }

    message("Collation complete!")
    return(out)
  }

#' Summarize BLE dataset and column metadata
#'
#' @param ids (integer) Inherited from the function call to collate
#' @param metadata (list) List of metadata
#'
#' @return (list) List of two data.frames: "dataset_metadata" and "column_metadata"
#'
#' @examples
collate_metadata <- function(ids = NULL, metadata) {
  # list of BLE Core Program ids. do we need to update them when new ids come out? seems not optimal and NOT good practice
  cp <-
    c(2, 3, 4, 11, 12, 13, 14, 18) # only discrete samples, no moorings/CDOM
  if (is.null(ids))
    ids <- cp
  # set up result dataframes
  dcols <- c(
    "dataset_title",
    "dataset_id_full",
    "dataset_id",
    "revision",
    "pubdate",
    "DOI",
    "URL"
  )
  dmeta <- data.frame(matrix(ncol = length(dcols), nrow = 0))
  colnames(dmeta) <- dcols
  attcols <- c("attribute_name",
               "attribute_definition",
               "attribute_units",
               "dataset_id")
  attmeta <- data.frame(matrix(ncol = length(attcols)))
  colnames(attmeta) <- attcols

  # hardcoded list of what entities to grab from each cp data just based on order. NOT good practice
  elist <- list(1, 3, 1, 1, 1, 1, c(1, 2), 1)
  # filter elist by Ids supplied
  elist <- elist[which(ids %in% cp)]
  attlist <- list()

  # loop along each dataset's metadata
  for (i in seq_along(metadata)) {
    meta <- metadata[[i]]
    # build URL
    url <-
      paste0(
        "https://doi.org/",
        clean_identifier(meta$dataset$alternateIdentifier$alternateIdentifier)
      )
    dmeta[nrow(dmeta) + 1,] <- c(
      meta$dataset$title,
      meta$packageId,
      stringr::str_extract(meta$packageId, "(?<=\\.)(.+)(?=\\.)"),
      # number between the two periods
      sub(".*\\.", "", meta$packageId),
      # number after second period
      meta$dataset$pubDate,
      meta$dataset$alternateIdentifier$alternateIdentifier,
      url
    )
    # grab attributeLists from the relevant entities
    dts <- meta$dataset$dataTable[elist[[i]]]
    for (j in seq_along(dts)) {
      attlist <- c(attlist, dts[[j]]$attributeList$attribute)
    }

  } # end loop

  # parse each attribute
  attmeta <- lapply(attlist, parse_attribute)
  attmeta <- data.table::rbindlist(attmeta, fill = TRUE)

  # insert dataset id
  attmeta$dataset_id <-
    sub("d", "", sub("\\-.*", "", attmeta$id)) # string before first dash, minus the d
  # remove columns that are largely irrelevant to researchers
  non_fields <- c(
    "enforced",
    "exclusive",
    "order",
    "references",
    "scope",
    "system",
    "typeSystem",
    "missingValueCode",
    "missingValueCodeExplanation",
    "propertyLabel",
    "propertyURI",
    "valueLabel",
    "valueURI",
    "label",
    "code",
    "codeExplanation",
    "definition",
    "domain",
    "storageType",
    "dateTimePrecision",
    "id"
  )
  attmeta <-
    subset(attmeta, select = !(names(attmeta) %in% non_fields))

  # filter redundant rows (e.g. the duplicated nodes and stations cols)
  cpcols <- c(
    "node",
    "lagoon",
    "station",
    "season",
    "date_time",
    "latitude",
    "longitude",
    "station_name",
    "habitat_type",
    "station_sampling_priority",
    "water_column_position"
  )
  attnames <- attmeta[["attributeName"]]
  # data cols are the non-cp cols
  datacols <- !attnames %in% cpcols
  # only get the first instance of each cp cols
  attmeta <-
    rbind(attmeta[match(cpcols, attnames), ], attmeta[datacols, ])
  attmeta$dataset_id <-
    ifelse(attmeta[["attributeName"]] %in% cpcols, NA, attmeta$dataset_id)
  # move dataset id first
  attmeta2 <-
    cbind(attmeta[, "dataset_id", drop = FALSE],
          attmeta[, "dataset_id" != colnames(attmeta), drop = FALSE])
  return(list(dataset_metadata = dmeta,
              column_metadata = attmeta2))
}
