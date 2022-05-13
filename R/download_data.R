
#' Download BLE data files
#'
#' @param ids (numeric) Vector of dataset IDs to grab
#' @param path (character) Path to write CSVs to
#' @param write (boolean) Whether to write to file
#'
#' @return (list) A list of data frames. Optionally, CSVs files in specified path
#' @export
#'
#' @examples
download_data <- function(ids = NULL, path = NULL, write = F) {
  if (is.null(path))
    path <- getwd()

  # checking if path exists
  stopifnot(dir.exists(path))

  e <- decide_entities(ids)

  message("Downloading data files...")


# TODO: need to retain names
  raw <- lapply(seq_along(e), function(x) {
    if (length(e[[x]]) > 1) {
      # not particularly proud of this sequence
      lapply(seq_along(e[[x]]), function(y) {
        EDIutils::read_data_entity(packageId = names(e)[x],
                                   entityId = e[[x]][[y]])
      })
    }
    else {
      EDIutils::read_data_entity(packageId = names(e)[x],
                                 entityId = e[[x]])
    }
  })

  # this is not a good way
  # there MUST be a better way to do this and also retain file names.
  # TODO: Ask colin at EDI
   dfs <- invisible(rrapply::rrapply(object = raw,
                           f = readr::read_csv,
                           how = "list",
                           show_col_types = F)) # argument to read_csv

   # writing to path is optional???
   # doesn't work right now
   if (!is.null(path) && write) {
     message("Writing data to files...")
     rrapply::rrapply(object = dfs,
                      f = function(x) {
                        readr::write_csv(x = x,
                                         file = names[e][.xposition])
                      },
                      how = "list")
   }

   message("Done.")
  return(dfs)
}
