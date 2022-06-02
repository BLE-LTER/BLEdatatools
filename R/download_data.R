

#' Download BLE data files
#'
#' @param ids (numeric) Vector of dataset IDs to grab, default is to get all data
#' @param path (character) Path to write CSVs to, defaults to working directory
#' @param write (boolean) Whether to write data entities to file, defaults to FALSE
#' @param metadata (boolean) whether to get metadata, defaults to TRUE
#'
#' @return (list) A nested list of data frames. 1st-level list items are named "data" and "metadata" (if metadata = TRUE). For "data": 2nd-level list items correspond to datasets, 3rd-level items correspond to entities within a dataset and contain a data.frame of the data entity. List items are named accordingly (dataset after the packageId and entities after the entity name). Optionally, if write=T, functions also write to CSVs files in specified path. File names are the full package Id, followed by two underscores, followed by the full entity name. For "metadata": 2nd-level list items correspond to datasets, and contain a the metadata for that dataset in "emld" aka list format.
#' @export
#'
#' @examples
download_data <- function(ids = NULL,
                          path = NULL,
                          write = FALSE,
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

  output = list(data = dfs)

  # return metadata
  if (metadata) {
    m <- lapply(names(e), FUN = EDIutils::read_metadata)
    names(m) <- names(e)
    m <- lapply(m, emld::as_emld)
    output$metadata <- m
  }

  message("Done.")
  return(output)
}
