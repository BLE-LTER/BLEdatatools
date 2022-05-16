#' Search all BLE LTER packages
#'
#' Modify EDI utils search_data_packages funtion to return only BLE LTER data. Default is to provide a dataframe with
#' all BLE package id ("scope.identifier.revision" format), title, publication dates, and the package number from
#' package id.
#'
#' @param fields (string) Searchable metadata fields in EDI repository to include query that produces output.
#' The way this function is written now, this string must follow the Solr query syntex (e.g. "id, packageid, title").
#'
#'
#' @param env (string) Repository environment. Can be "production", "staging", or "development".
#'
#' @return
#' @export
#'
#' @examples
#'

search_ble_packages <- function(fields = 'id,packageid,title,pubdate', env = 'production') {

  scope <- 'knb-lter-ble'

  query = paste0('q=scope:', scope, '&fl=', fields)

  # df created using EDI utils function
  df <- EDIutils::search_data_packages(query = query, env = env)

  # column including BLE package id number
  id_number <- sub(".*knb-lter-ble.", "", df$id)

  # bind new id column to data frame
  df <- cbind(df, id_number)

  return(df)
}
