

#' Download BLE data files
#'
#' @param ids (numeric) Vector of dataset IDs to grab, defaults to get all data
#' @param path (character) Path to write CSVs to, defaults to working directory
#' @param write (boolean) Whether to write to file, defaults to false
#' @param metadata (boolean) whether to get metadata, defaults to true
#'
#' @return (list) A nested list of data frames. 1st-level list item corresponds to dataset, 2nd-level items correspond to entities within a dataset and contain a data.frame of the data entity. List items are named accordingly (dataset after the packageId and entities after the entity name). Optionally, if write=T, functions also write to CSVs files in specified path. File names are the full package Id, followed by two underscores, followed by the full entity name.
#' @export
#'
#' @examples
download_data <- function(ids = NULL,
                          path = NULL,
                          write = F,
                          metadata = TRUE) {
  if (is.null(path))
    path <- getwd()

  # checking if path exists
  stopifnot(dir.exists(path))

  e <- decide_entities(ids)

  message("Downloading data files...")


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
    show_col_types = F # argument to read_csv
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
  output = list(data=dfs)
  
  #return metadata
  if (metadata== TRUE){m = lapply(names(e), FUN = EDIutils::read_metadata) 
  names(m)= names(e)
  output$metadata=m}
  
  
  
  

  message("Done.")
  return(output)
}
