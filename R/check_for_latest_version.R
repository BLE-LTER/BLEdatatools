#'
#' #' Check for outdated packages on local computer
#' #'
#' #' @param path (character) Path to folder containing CSVs from download_data(). CSV must have original packageid text. defaults to NULL.
#' #' @param dfs (list) Name of list in local environment created from download_data(), defaults to NULL
#' #' @param replace (boolean) Whether to delete outdated files and replace with new files, defaults to TRUE.
#' #'
#' #' @return
#' #' #@export
#' #'
#' #' @examples
#' #'
#' check_for_latest_version <- function(path=NULL, dfs=NULL, replace=F){
#'   # function searches for revisions to all BLE package ids right now.
#'   ble_packages <- search_ble_packages(env = "production")
#'   #rev <- ble_packages$packageid
#'
#'   message("Finding newest data...")
#'
#'
#'   # if path and dfs are null, use wd()
#'   if(is.null(path) & is.null(dfs)){
#'     path <- getwd()
#'   }
#'
#'   if(is.null(dfs)){
#'     stopifnot(dir.exists(path))  # checking if path exists
#'   # need to add error message for when there are no files matching the pattern in the local folder.
#'
#'   # get list of package ids from local folder
#'   local<-cbind((data.frame(do.call(rbind,(strsplit(list.files(path = paste(path), recursive = TRUE,
#'                                                               pattern = paste0("\\", "knb-lter-ble"),
#'                                                               full.names = T), split="__"))))[,1]),
#'                (data.frame(do.call(rbind,(strsplit(list.files(path = paste(path), recursive = TRUE,
#'                                                               pattern = paste0("\\", "knb-lter-ble"),
#'                                                               full.names = F), split="__"))))))
#'  names(local) <- c("file", "pckid", "pckname")
#'  local$file <- paste0(local$file,"__", local$pckname)
#'
#'
#'   # same as above but no strsplit and not working for some reason....
#'   # local<-cbind((data.frame(do.call(rbind,(strsplit(list.files(path = paste(path), recursive = TRUE,
#'   #                                                             pattern = paste0("\\", "knb-lter-ble"),
#'   #                                                             full.names = T), split="__"))))[,1]),
#'   #              (data.frame(do.call(rbind, list.files(path = paste(path), recursive = TRUE,
#'   #                                                                   pattern = paste0("\\", "knb-lter-ble"),
#'   #                                                                   full.names = F)))))
#'   # names(local) <- c("file", "pckid")
#'   }
#'
#'   # if path is null find local package ids from environment list of dfs
#'   if(is.null(path)){
#'     local <- data.frame(names(dfs))
#'     names(local) <- "pckid"
#'   }
#'
#'   # vector of local package ids that do not match latest revisions list
#'   matches <- data.frame(setdiff(local$pckid, grep(paste(local$pckid, collapse= "|"),
#'                           ble_packages$packageid, value=TRUE)))
#'   names(matches) <- "pckid"   # do i want matches to also have package name??
#'
#'
#'   # messages alerting user if packages are updated. If all packages match latest revision list, function stops.
#'   if(length(matches) < 1){
#'     stop(message("All BLE data packages are up to date. \n"))
#'   }  # if not list all packages that are not up to date.
#'   else{
#'     message(
#'       paste("Package with ID ",
#'         matches, "is not up to date. \n"))
#'   }
#'   # here is the replace part, still working on getting new data
#'   if(is.null(dfs) & replace==T){
#'     message(
#'       paste("Finding latest version of ",
#'             matches, "... \n"))
#'
#'     # could make this work with just download_data() packages, either download ALL or filter out the return() of download_data for just the outdated packages
#'     # download_data(ids=(matches), write=T)
#'
#'     # could fix this in download_data, if there is replace files option it will download only ones that need to be updated??
#'
#'     #OR!!
#'
#'     # because I want this to work for all BLE packages.
#'     # maybe I need to loop the EDI functions over the list of package ids? but how do i deal with entity # ?
#'
#'     # transaction <- EDIutils::create_data_package_archive(packageID)
#'     # EDIutils::read_data_package_archive(packageID, transaction, path = path)
#'
#'
#'     # REMOVE OUTDATED FILES from path
#'     # need to figure out what function will do if dfs is supplied.
#'
#'     remove <- dplyr::left_join(matches, local, by="pckid")
#'
#'     # take file name from removeand pass file.remove() to each.
#'     for(i in remove$file){
#'       file.remove(paste(i))
#'     }
#'
#'   }else{
#'     return(paste("No files were changed."))
#'   }
#' }
#'
#' check_for_latest_version(path="~/data/BLE DATA EDI")
#'
