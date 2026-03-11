#' Create meta table for feedback batch
#'
#' Generates a summary table of feedback files and recipients, and writes it to disk.
#'
#' @param x A list or data frame of feedback results to summarize.
#' @param batch_id Character. Identifier for the feedback batch.
#' @param recipient_data Data frame. Recipient information to join.
#' @return Character. Path to the written meta table CSV file.
#' @export
rf_make_meta_table <- function(x,batch_id,recipient_data){
  file_name <- paste0("renders/",batch_id,"/meta_table.csv")
  dir.create(dirname(file_name), recursive = TRUE, showWarnings = FALSE)

  if (is.list(x) && !is.data.frame(x)) {
    rows <- lapply(x, function(el) {
      if (is.null(el)) {
        return(data.frame())
      }
      if (is.list(el) && !is.data.frame(el)) {
        # `targets` can produce length-0 entries for failed upstream targets.
        # Convert those to NA so row binding stays stable.
        el <- lapply(el, function(v) {
          if (length(v) == 0) {
            return(NA)
          }
          v[[1]]
        })
      }
      as.data.frame(el, stringsAsFactors = FALSE)
    })

    all_names <- unique(unlist(lapply(rows, names)))
    rows <- lapply(rows, function(df) {
      missing <- setdiff(all_names, names(df))
      if (length(missing) > 0) {
        for (nm in missing) {
          df[[nm]] <- NA
        }
      }
      df[all_names]
    })

    x <- do.call(rbind, rows)
  }

  x <- merge(x, recipient_data, by = "recipient_id", all.x = TRUE, sort = FALSE)
  x$batch_id <- batch_id
  write.csv(x, file_name,row.names = F)

  file_name
}
