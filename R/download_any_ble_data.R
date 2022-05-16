#' Download any BLE file on EDI
#'
#' @param package_id (numeric) Package identifier number that correspondes with the EDI package ID.
#' @param entity_number Idea that if this field is left blank, download all files within the package?
#'
#' @return CSV file(s) of entity/entities
#' @export
#'
#' @examples

download_any_data <- function(identifier, entity_number = NULL, path = NULL) {

  if (is.null(path))
    path <- getwd()

  # checking if path exists
  stopifnot(dir.exists(path))

  # add an error message here if user does not supply a proper package id number
  # alternatively, use EDIutils::list_data_package_identifiers
  stopifnot(is.numeric(identifier))

  ble_packages <- search_ble_packages(env = "production")
  possible_ids <- ble_packages$id_number

  # error message if any ID supplied is not in our list

  if (!identifier %in% possible_ids) {
    stop(
      paste(
        "Identifier",
        identifier,
        "is not a valid BLE LTER package identifier. \n"
      )
    )
  } else {
    title <- ble_packages[[which(ble_packages$id_number == identifier), "title"]]
    message(paste0("Found the package titled '", title, "'."))
  }

  rev <- max(EDIutils::list_data_package_revisions(scope = "knb-lter-ble",
                                         identifier = identifier,
                                         env = "production"))

  packageID <- paste0("knb-lter-ble.", identifier, ".", rev)

  message(paste0("The newest version of your package is: ", packageID, "."))

  #entity_names <-


}

