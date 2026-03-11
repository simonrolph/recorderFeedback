rf_selection_file <- function(batch_id) {
  file.path("renders", batch_id, "recipient_selection.csv")
}

rf_resolve_config_path <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }

  if (file.exists(path)) {
    return(path)
  }

  candidate <- file.path(getwd(), path)
  if (file.exists(candidate)) {
    return(candidate)
  }

  path
}

rf_default_recipient_selection <- function(recipients) {
  data.frame(
    recipient_id = recipients$recipient_id,
    selected = TRUE,
    skip_reason = NA_character_,
    stringsAsFactors = FALSE
  )
}

rf_normalize_recipient_selection <- function(selection, recipients) {
  normalized <- rf_default_recipient_selection(recipients)

  if (is.null(selection)) {
    return(normalized)
  }

  default_skip_reason <- "Excluded by recipient_select()"

  if (is.logical(selection)) {
    if (length(selection) != nrow(recipients)) {
      stop("recipient_select() must return a logical vector the same length as recipients.")
    }

    normalized$selected <- selection
    normalized$skip_reason[!selection] <- default_skip_reason
    return(normalized)
  }

  if (is.atomic(selection) && !is.data.frame(selection)) {
    selected_ids <- as.character(selection)
    normalized$selected <- as.character(normalized$recipient_id) %in% selected_ids
    normalized$skip_reason[!normalized$selected] <- default_skip_reason
    return(normalized)
  }

  if (!is.data.frame(selection)) {
    stop(
      paste(
        "recipient_select() must return one of:",
        "NULL, a logical vector, a vector of recipient IDs,",
        "or a data frame containing recipient_id."
      )
    )
  }

  if (!"recipient_id" %in% names(selection)) {
    stop("recipient_select() data frame output must contain a recipient_id column.")
  }

  if (anyDuplicated(selection$recipient_id)) {
    stop("recipient_select() returned duplicate recipient_id values.")
  }

  selection_ids <- as.character(selection$recipient_id)
  matched <- match(as.character(normalized$recipient_id), selection_ids)

  if ("selected" %in% names(selection)) {
    normalized$selected <- FALSE
    normalized$skip_reason[] <- default_skip_reason

    has_match <- !is.na(matched)
    normalized$selected[has_match] <- as.logical(selection$selected[matched[has_match]])

    if ("skip_reason" %in% names(selection)) {
      normalized$skip_reason[has_match] <- as.character(selection$skip_reason[matched[has_match]])
    }

    normalized$skip_reason[normalized$selected] <- NA_character_
    missing_reason <- !normalized$selected & (is.na(normalized$skip_reason) | normalized$skip_reason == "")
    normalized$skip_reason[missing_reason] <- default_skip_reason

    return(normalized)
  }

  normalized$selected <- as.character(normalized$recipient_id) %in% selection_ids
  normalized$skip_reason[!normalized$selected] <- default_skip_reason
  normalized
}

rf_prepare_recipient_selection <- function(batch_id) {
  config <- config::get()
  recipients <- read.csv(config$recipients_file, stringsAsFactors = FALSE)
  records_data <- read.csv(config$data_file, stringsAsFactors = FALSE)

  selection <- rf_default_recipient_selection(recipients)
  selector_path <- rf_resolve_config_path(config$recipient_select_script)

  if (!is.null(selector_path)) {
    if (!file.exists(selector_path)) {
      stop("Recipient selection script not found: ", selector_path)
    }

    selector_env <- new.env(parent = globalenv())
    sys.source(selector_path, envir = selector_env)

    if (!exists("recipient_select", envir = selector_env, inherits = FALSE)) {
      stop("Recipient selection script must define recipient_select(recipients, data, config).")
    }

    selection_result <- selector_env$recipient_select(
      recipients = recipients,
      data = records_data,
      config = config
    )

    selection <- rf_normalize_recipient_selection(selection_result, recipients)
  }

  file_name <- rf_selection_file(batch_id)
  dir.create(dirname(file_name), recursive = TRUE, showWarnings = FALSE)
  write.csv(selection, file_name, row.names = FALSE)

  file_name
}