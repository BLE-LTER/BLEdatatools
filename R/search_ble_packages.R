#' Search all BLE LTER packages
#'
#' Modify EDI utils search_data_packages function to return only BLE LTER data. Default is to provide a dataframe with
#' all BLE package id ("scope.identifier.revision" format), title, and the package identifier from
#' package id.
#'
#'
#' @param fields (character) Searchable metadata fields in EDI repository to include query that produces output.
#' The way this function is written now (badly), this string must follow the Solr query syntex (e.g. "id,packageid,title").
#'
#'
#' @param env (character) Repository environment. Can be "production", "staging", or "development".
#'
#' @return
#' @export
#'
#' @examples
#'

search_ble_packages <- function(fields = 'id,packageid,title', env = 'production') {

  scope <- 'knb-lter-ble'

  query = paste0('q=scope:', scope, '&fl=', fields)

  # df created using EDI utils function
  df <- EDIutils::search_data_packages(query = query, env = env)

  # column including BLE package identifier
  identifier <- as.numeric(sub(".*knb-lter-ble.", "", df$id))

  # bind new id column to data frame
  df <- cbind(df, identifier)

  return(df)
}
