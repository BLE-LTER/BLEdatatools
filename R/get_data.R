#' Title
#'
#' @param ids Vector of data sets IDs, such as 1, 2, 4
#' @param path path to save CSVs to
#'
#' @return
#' @export
#'
#' @examples
get_data <- function(ids, path) {

  # rev_numbers <- EDIutils::list_data_package_revisions(scope =
  #                                                        "knb-lter-ble"
  #                                                      )

  # loop over IDs (1, 2, 4) and get a list of all revisions
  rev_numbers <- sapply(ids, EDIutils::list_data_package_revisions, scope = "knb-lter-ble")

  # getting the max or most recent revision no
  rev <- sapply(rev_numbers, max)

  # construct pkgs ids
  pkg_ids <- paste0("knb-lter-ble.", ids, ".", rev)

  # loop over pkg ids and ask for list of entity names
  entities <- sapply(pkg_ids, EDIutils::read_data_entity_names)

  #TODO: from list of entities, need to decide which entity to grab
  #TODO: grab them
  #TODO: read into CSVs
  return(entities)
}

