#' Get entity names and IDs from newest revisions of BLE data sets slated for collations
#'
#' @param ids (numeric) Vector of BLE dataset IDs to grab
#'
#' @return (list) A nested list. 1st-level list item corresponds to dataset, 2nd-level items correspond to entities within a dataset and contain a string of the entity Id. List items are named accordingly (dataset after the packageId and entities after the entity name).
#'
get_uncollated_entities <- function(ids = NULL) {
  # list of BLE Core Program ids. do we need to update them when new ids come out? seems not optimal and NOT good practice
  cp <-
    c(2, 3, 4, 11, 12, 13, 14, 18) # only discrete samples, no moorings/CDOM

  if (is.null(ids))
    ids <- cp

  stopifnot(is.numeric(ids), is.vector(ids))

  # hardcoded list of what entities to grab from each cp data just based on order. NOT good practice
  elist <- list(1, 3, 1, 1, 1, 1, c(1, 2), 1)

  # throws a warning if any ID supplied is not in our list
  # works when the ID DOES exist but is not CP and when the ID straight up doesn't exist
  if (!all(ids %in% cp)) {
    out <- which(!ids %in% cp)
    warning(
      paste(
        "Dataset ID",
        ids[out],
        "is not a supported water/sediment BLE Core Program dataset and has been removed. \n"
      )
    )
    # then removes the offending ID(s). pretty easy to do, which is why I chose to throw a warning instead of an error
    ids <- ids[-out]
  }

  # loop over IDs (1, 2, 4) and get a list of all revisions
  revs <-
    sapply(ids, EDIutils::list_data_package_revisions, scope = "knb-lter-ble")

  # getting the max or most recent revision number from each data package
  rev <- sapply(revs, max)

  # construct pkgs ids
  pkg_ids <- paste0("knb-lter-ble.", ids, ".", rev)

  message("Querying Environmental Data Initiative (EDI) for the latest BLE data versions...")

  # loop over pkg ids and ask for ALL entity IDs and names from each pkg
  allids <- lapply(pkg_ids, EDIutils::read_data_entity_names)

  # filter elist by Ids supplied
  elist <- elist[match(ids, cp)]

  # get just the entity IDs we want
  eids <- sapply(seq_along(allids), function(x) {
    if (length(elist[[x]]) > 1) {
      e <- list()
      for (i in elist[[x]]) {
      e[[i]] <- allids[[x]][elist[[x]], 1][[i]]
      names(e)[[i]] <- allids[[x]][elist[[x]], 2][[i]]
      }
    } else {
      e <- list(allids[[x]][elist[[x]], 1])
    names(e) <- allids[[x]][elist[[x]], 2]
    }

    return(e)
  })


  enames <- sapply(seq_along(allids), function(x) {
    allids[[x]][elist[[x]], 2]
  })

  # eids and pkg_ids should be the same length and in the correct orders
  names(eids) <- pkg_ids

  # realized I need the pkg id too not just the entity id
  return(eids)
}



#' Download BLE data files slated for collation
#'
#' @param ids (numeric) Vector of BLE dataset IDs to grab, default is to get all data
#' @param path (character) Path to write CSVs to, defaults to working directory
#' @param write (logical) Whether to write data entities to file, defaults to FALSE
#' @param skip_metadata (logical) whether to skip metadata, defaults to FALSE
#'
#' @return (list) A nested list of data frames. 1st-level list items are named "data" and "metadata" (if metadata = TRUE). For "data": 2nd-level list items correspond to datasets, 3rd-level items correspond to entities within a dataset and contain a data.frame of the data entity. List items are named accordingly (dataset after the packageId and entities after the entity name). Optionally, if write=T, functions also write to CSVs files in specified path. File names are the full package Id, followed by two underscores, followed by the full entity name. For "metadata": 2nd-level list items correspond to datasets, and contain the metadata for that dataset in "emld" aka list format.
#'
#' @examples
get_uncollated_dfs <- function(ids = NULL,
                          path = NULL,
                          write = FALSE,
                          skip_metadata = FALSE) {

  if (is.null(path))
    path <- getwd()

  # checking if path exists
  stopifnot(dir.exists(path))
  e <- get_uncollated_entities(ids)
  message("Downloading latest data files...")

  # if you read this bit of code
  # beware that all the "raw"s are different
  # lexical scoping!

  # and I dislike the IFs sequences I'm resorting to here
  # would like more elegance
  raw <- lapply(seq_along(e), function(x) {
    if (length(e[[x]]) > 1) {
      # not particularly proud of this sequence
      raw <- lapply(seq_along(e[[x]]), function(y) {
        raw <- EDIutils::read_data_entity(packageId = names(e)[x],
                                          entityId = e[[x]][[y]])
        return(raw)
      })

    }
    else {
      raw <- list(EDIutils::read_data_entity(packageId = names(e)[x],
                                             entityId = e[[x]]))
    }
    names(raw) <- names(e[[x]]) # attach entity names
    return(raw)
  })

  # attach pkg ids
  names(raw) <- names(e)

  dfs <- invisible(rrapply::rrapply(
    object = raw,
    f = readr::read_csv,
    how = "list",
    show_col_types = F # argument to read_csv in readr >2.0.0
  ))

  # writing to path is optional???
  # doesn't work right now
  if (!is.null(path) && write) {
    message("Writing data to files...")

    lapply(seq_along(dfs), function(x) {
      ds <- dfs[[x]]
      if (length(ds) > 1) {
        lapply(seq_along(ds), function(y) {
          readr::write_csv(x = ds[[y]],
                           file = file.path(path, paste0(names(dfs)[[x]], "__", names(ds)[[y]], ".csv")))
        })
      } else {
        readr::write_csv(x = ds[[1]],
                         file = file.path(path, paste0(names(dfs)[[x]], "__", names(ds)[[1]], ".csv"))
        )
      }

    })
  }

  output = list(data = dfs)

  # return metadata
  if (!skip_metadata) {
    m <- lapply(names(e), FUN = EDIutils::read_metadata)
    names(m) <- names(e)
    m <- lapply(m, emld::as_emld)
    output$metadata <- m
  }

  message("Download complete!")
  return(output)
}


#' Preprocess tables before putting them info the join
#' @description This (1) renames any date_time column to date_collected, and remove the time portion; (2) renames any occurrences of "STL" into "SSL"
#'
#'
#' @param df (data.frame) ONE data.frame containing BLE LTER water/sediment core data, as downloaded from EDI without any processing.
#' @param ysi (logical) Set this to TRUE when the data is YSI. Returns date_collected as usual, plus a date_time_YSI column that retains the time.
#'
#' @return (data.frame) A data.frame
#'
#' @examples
preprocess <- function(df, ysi = F) {
  if ("date_time" %in% colnames(df) && ysi) {
  # df <- dplyr::rename(df, date_time_ysi = date_time)
  # df$date_collected <- as.Date(df$date_time_ysi)
  }
  if ("date_time" %in% colnames(df) && !ysi) {
  # df <- dplyr::rename(df, date_collected = date_time)
  df$date_time <- as.Date(df$date_time)
  }
  if ("date_collected" %in% colnames(df)) {
    df <- dplyr::rename(df, date_time = date_collected)
  }
  # in case any datasets still have "STL" instead of "SSL" for Stefasson Sound
  df$station <- gsub("STL", "SSL", df$station)
  return(df)
}

#' Reformat DOI to a standard format
#'
#' @param identifier (character) DOI string
#'
#' @return (character) DOI string in standard format, e.g. 10.1029/2020gb006552. Without URL heads like "https://doi.org" or the "doi:" prefix.
#' @export
clean_identifier <- function(identifier) {
  identifier <- trimws(sub(" ", "", identifier))

  if (any(grepl("https://doi.org", identifier))) {
    identifier <- sub("https://doi.org/", "", identifier)
  }
  if (any(grepl("doi:", identifier))) {
    identifier <- sub("doi:", "", identifier)
  }
  identifier <- trimws(sub(" ", "", identifier))
  return(identifier)
}



#' @param x (list) attribute EML node
#'
#' @return
#'
#' @examples
parse_attribute <- function(x) {
  ## get full attribute list
  att <- unlist(x, recursive = TRUE, use.names = TRUE)
  measurementScale <- names(x$measurementScale)
  domain <- names(x$measurementScale[[measurementScale]])

  if (length(domain) == 1) {
    ## domain == "nonNumericDomain"
    domain <-
      names(x$measurementScale[[measurementScale]][[domain]])
  }
  domain <- domain[grepl("Domain", domain)]

  if (measurementScale == "dateTime" & is.null(domain)) {
    domain <- "dateTimeDomain"
  }

  att <-
    c(att, measurementScale = measurementScale, domain = domain)

  ## separate factors
  att <- att[!grepl("enumeratedDomain", names(att))]

  ## separate methods
  att <- att[!grepl("methods", names(att))]

  ## Alter names to be consistent with other tools
  names(att) <- gsub("standardUnit|customUnit",
                     "unit",
                     names(att))
  names(att) <- gsub(".+\\.+",
                     "",
                     names(att))
  att <- as.data.frame(t(att), stringsAsFactors = FALSE)
  return(att)
}
