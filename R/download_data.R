#' Download a BLE LTER data package or data entity from EDI
#'
#' The function finds the most recent package or entity from EDI. Can download an entire package as a zip file, or save an entity as a .csv or R object.
#'
#' @param identifier (numeric) Package identifier number that corresponds with the EDI package ID. Can only specify one identifier at a time.
#' @param entity_number (numeric). Entity identifier number. Optional. Can only specify one entity at a time. Entity must be a .csv file or function will produce an error.
#' @param path (character) Path to write files to. If left blank, will default to the working directory.
#' @param write (boolean) If true, writes the entity as a .csv file. Otherwise, saves the entity as an R object.
#'
#' @return Zip folder containing all package data entities, one .csv file containing specified data entity, or a data.frame containing the specified data entity.
#'
#' @examples
#' # download the third entity in package 1 as a .csv
#' download_data(identifier = 1, entity_number = 3)
#'
#' # download all entities in package 1 in a zip file
#' download_data(identifier = 1)
#'
#' # save DOC/TDN data (package 12, entity 1) as an R object
#' DOC <- download_data(identifier = 12, 1)
#' @export

download_data <- function(identifier,
                          entity_number = NULL,
                          path = NULL,
                          write = FALSE) {

  # if path not supplied, set the default path as the working directory
  if (is.null(path))
    path <- getwd()

  # checking if path exists
  stopifnot(dir.exists(path))

  # check if there is a proper identifier or entity_number supplied
  stopifnot(is.numeric(identifier))
  stopifnot(is.numeric(entity_number) | is.null(entity_number))

  if (length(identifier) != 1 | length(entity_number) > 1) {
    stop("Must provide 1 package identifier and 0 or 1 entity identifiers.
         This function does not support downloading multiple products at once.")
  }

  # get list of possible BLE LTER package identifiers
  possible_ids <-
    EDIutils::list_data_package_identifiers(scope = "knb-lter-ble")

  # error message if any identifier supplied is not a ble package identifier
  if (!identifier %in% possible_ids) {
    stop(
      paste0(identifier,
      " is not a valid BLE LTER package identifier.
      Use the search_ble_packages() function to find the correct identifier."
      )
    )
  } else {

    # use search_ble_packages function to find the name of the data package
    ble_packages <- search_ble_packages()
    title <-
      ble_packages[[which(ble_packages$identifier == identifier), "title"]]

    # tell the user the name of the package they specified with the identifier
    message(paste0("Found your package titled '", title, "'."))
  }

  # find most recent version of package
  rev <- max(EDIutils::list_data_package_revisions(scope = "knb-lter-ble",
                                         identifier = identifier,
                                         env = "production"))

  # define the packageId in scope, identifier, revision format
  packageId <- paste0("knb-lter-ble.", identifier, ".", rev)

  # if entity_number is not specified, download the entire package in a zip file
  if (is.null(entity_number)) {
   transaction <- EDIutils::create_data_package_archive(packageId)
   message(paste0("Downloading a zip file containing the newest version of the
                  package: ", packageId, "."))
   EDIutils::read_data_package_archive(packageId, transaction, path = path)
  } else {

    # read and save the entity ids and names in the package
    entityNames <- EDIutils::read_data_entity_names(packageId = packageId)

    # error function if the entity number does not exist
    possible_entities <- seq(1, nrow(entityNames), by = 1)
    if (!entity_number %in% possible_entities) {
      stop(paste0(
        entity_number, " is not a valid entity number for the package you specified.
      Use EDIutils::read_data_entity_names('", packageId,
      "') to see the entities that exist."))
    }

    # pull out the specified entity id and name
    entityId <- entityNames[[entity_number, "entityId"]]
    entityName <- entityNames[[entity_number, "entityName"]]

    # read the raw data file
    # TODO: figure out a stop error if the data entity is not a .csv
    raw <- EDIutils::read_data_entity(packageId = packageId,
                                      entityId = entityId,
                                      env = "production")

    # convert the raw data to a dataframe
    data <- readr::read_csv(file = raw, show_col_types = F)

    if (write) {

      # write a csv to the specified path or working directory
      # TODO: include entity name in the file
      message(paste0("Writing the entity titled '",
                     entityName,
                     "' from ",
                     packageId, "."))
      readr::write_csv(data,
                       file = file.path(path,
                                        paste0(packageId, "-entity",
                                               entity_number, ".csv")))

    } else {
      # otherwise return the dataframe
      message(paste0("Here is the entity called '",
                     entityName,
                     "'from ",
                     packageId, "."))
      return(data)

    }
  }
}

