#' Search all BLE LTER packages on EDI
#'
#' Modify EDI utils search_data_packages function to return only BLE LTER data. Default is to provide a dataframe with
#' all BLE package id ("scope.identifier.revision" format), title, and the package identifier from
#' package id.
#'
#'
#' @param fields (character) Metadata fields in EDI repository to include query that produces output. This string must follow the Solr query syntex.
#' Default is to provide the id, packageid, and title.
#'
#' @param env (character) Repository environment. Can be "production", "staging", or "development".
#'
#' @return (data.frame) Default parameters return the fields: id, packageid, title, identifier.
#' @export
#'
#' @examples packages <- search_ble_packages()
#'

search_ble_packages <- function(fields = 'id,packageid,title', env = 'production') {

  scope <- 'knb-lter-ble'

  query = paste0('q=scope:', scope, '&fl=', fields)

  # df created using EDI utils function
  df <- EDIutils::search_data_packages(query = query, env = env)

  # vector including BLE package identifier
  identifier <- as.numeric(sub(".*knb-lter-ble.", "", df$id))

  # bind new id column to data frame
  df <- cbind(df, identifier)

  return(df)
}
