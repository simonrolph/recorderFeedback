#' Create meta table for feedback batch
#'
#' Generates a summary table of feedback files and recipients, and writes it to disk.
#'
#' @param x A list or data frame of feedback results to summarize.
#' @param batch_id Character. Identifier for the feedback batch.
#' @param recipient_data Data frame. Recipient information to join.
#' @param selection_data Data frame. Recipient selection information.
#' @return Character. Path to the written meta table CSV file.
#' @export
rf_make_meta_table <- function(x,batch_id,recipient_data,selection_data = NULL){
  file_name <- paste0("renders/",batch_id,"/meta_table.csv")
  dir.create(dirname(file_name), recursive = TRUE, showWarnings = FALSE)

  if (is.list(x) && !is.data.frame(x)) {
    if (length(x) == 0) {
      x <- data.frame(
        recipient_id = character(),
        file = character(),
        content_key = character(),
        render_status = character(),
        skip_reason = character(),
        stringsAsFactors = FALSE
      )
    } else {
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
  }

  if (!"render_status" %in% names(x)) {
    x$render_status <- ifelse(is.na(x$file), "failed", "rendered")
  }

  if (!"skip_reason" %in% names(x)) {
    x$skip_reason <- NA_character_
  }

  if (!is.null(selection_data)) {
    skipped <- selection_data[!selection_data$selected, c("recipient_id", "skip_reason"), drop = FALSE]

    if (nrow(skipped) > 0) {
      skipped$file <- NA_character_
      skipped$content_key <- NA_character_
      skipped$render_status <- "skipped"
      skipped <- skipped[, c("recipient_id", "file", "content_key", "render_status", "skip_reason")]

      x <- x[, c("recipient_id", "file", "content_key", "render_status", "skip_reason")]
      x <- rbind(x, skipped)
    }
  }

  x <- merge(x, recipient_data, by = "recipient_id", all.x = TRUE, sort = FALSE)
  x <- x[order(match(x$recipient_id, recipient_data$recipient_id)), , drop = FALSE]
  x$batch_id <- batch_id
  write.csv(x, file_name,row.names = F)

  file_name
}
