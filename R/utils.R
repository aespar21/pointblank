
#' Create a properly formatted validation step.
#' Get a validation step as a tbl row.
#' @importFrom tibble tibble
create_validation_step <- function(agent,
                                   assertion_type,
                                   column,
                                   value,
                                   report_count,
                                   warn_count,
                                   notify_count,
                                   tbl_name = as.character(NA),
                                   db_type = as.character(NA),
                                   credentials_file = as.character(NA)) {
  
  validation_step <-
    tibble::tibble(
      tbl_name = as.character(agent$focal_tbl_name),
      db_type = as.character(agent$focal_db_type),
      db_cred_file_path = as.character(agent$focal_db_cred_file_path),
      assertion_type = assertion_type,
      column = as.character(column),
      value = as.numeric(value),
      passed = as.logical(NA),
      report_count = as.numeric(report_count),
      warn_count = as.numeric(warn_count),
      notify_count = as.numeric(notify_count))
  
  # If just `tbl_name` provided, assume it is
  # a local data frame
  if (!is.na(tbl_name)) {
    validation_step$tbl_name <- tbl_name
  }
  
  if (!is.na(db_type)) {
    validation_step$db_type <- db_type
  }
  
  if (!is.na(credentials_file)) {
    validation_step$db_cred_file_path <- credentials_file
  }
  
  return(validation_step)
}


#' Acquire information on the coordinates of
#' a remote table. If a table is remote (i.e.,
#' in a database), this function will be
#' invoked to set an entry point for the
#' interrogation query.
#' @importFrom DBI dbListConnections dbListResults dbClearResult dbDisconnect
#' @importFrom RPostgreSQL PostgreSQL
#' @importFrom dplyr src_postgres tbl
set_entry_point <- function(table,
                            db_type = NULL,
                            credentials_file = NULL) {
  
  if (is.null(db_type) & inherits(table, "data.frame")) {
    
    # Create table entry object
    tbl_entry <- table
  }
  
  if (!is.null(db_type)) {
    
    if (db_type == "PostgreSQL") {
      
      # Establish a new PostgreSQL connection
      if (!is.null(credentials_file)) {
        
        # Disconnect any existing PostgreSQL connections
        cons <- DBI::dbListConnections(RPostgreSQL::PostgreSQL())
        
        for (con in cons) {
          if (length(DBI::dbListResults(con)) != 0) {
            DBI::dbClearResult(DBI::dbListResults(con)[[1]])}
          DBI::dbDisconnect(con)
        }
        
        # Serialize the credentials RDS file
        credentials <- readRDS(credentials_file)
        
        # Establish the connection with the serialized RDS object
        connection <-
          dplyr::src_postgres(
            dbname = credentials[1],
            host = credentials[2],
            port = credentials[3],
            user = credentials[4],
            password = credentials[5])
      } else if (is.null(credentials_file)) {
        stop("A credentials RDS file is required.")
      }
      
      # Create table entry object
      tbl_entry <- dplyr::tbl(src = connection, table)  
      
    }
  }
  
  invisible(tbl_entry)
}


#' Determine the course of action for a
#' given verification step. Based on a recent
#' judgment, what actions are taken now?
#' @importFrom tibble tibble
determine_action <- function(false_count,
                             report_count,
                             warn_count,
                             notify_count) {
  
  if (false_count >= report_count) {
    report <- TRUE
  } else {
    report <- FALSE
  }
  
  if (false_count >= warn_count) {
    warn <- TRUE
  } else {
    warn <- FALSE
  }
  
  if (false_count >= notify_count) {
    notify <- TRUE
  } else {
    notify <- FALSE
  }
  
  action_df <-
    tibble::tibble(
      report = report,
      warn = warn,
      notify = notify)
  
  return(action_df)
}
