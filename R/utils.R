#' Get entity names and IDs from newest revisions of BLE data sets
#'
#' @param ids (numeric) Vector of dataset IDs to grab
#'
#' @return (list) A nested list. 1st-level list item corresponds to dataset, 2nd-level items correspond to entities within a dataset and contain a string of the entity Id. List items are named accordingly (dataset after the packageId and entities after the entity name).
#'
#' @examples
decide_entities <- function(ids = NULL) {
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

  message("Asking EDI for newest data...")

  # loop over pkg ids and ask for ALL entity IDs and names from each pkg
  allids <- lapply(pkg_ids, EDIutils::read_data_entity_names)

  # filter elist by Ids supplied
  elist <- elist[which(ids %in% cp)]

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
