library(testthat)
library(recorderFeedback)

make_test_project <- function(load_data = FALSE, label = "workflow") {
  keep_outputs <- tolower(Sys.getenv("RF_KEEP_TEST_OUTPUTS", "false")) %in% c("true", "1", "yes")

  if (keep_outputs) {
    root <- file.path(normalizePath(".", winslash = "/", mustWork = TRUE), "test-output")
    dir.create(root, recursive = TRUE, showWarnings = FALSE)

    stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
    unique_id <- sprintf("%06d", sample.int(999999, 1))
    path <- file.path(root, paste0(label, "-", stamp, "-", unique_id))
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    message("Test project kept at: ", path)
  } else {
    path <- tempfile("rf_workflow_")
    dir.create(path, recursive = TRUE)
  }

  withr::with_dir(path, {
    rf_init(path = path)

    if (load_data) {
      rf_get_recipients()
      rf_get_data()
    }
  })

  path
}

# test project initialisation
test_that("Project initialisation works", {
  tmp <- make_test_project(load_data = FALSE, label = "project-init")

  withr::with_dir(tmp, {
    expect_true(dir.exists(file.path("data")))
    expect_true(dir.exists(file.path("renders")))
    expect_true(dir.exists(file.path(".github")))
    expect_true(file.exists(file.path("config.yml")))
    expect_true(file.exists(file.path("README.md")))
    expect_true(file.exists(file.path(".gitignore")))
    expect_true(file.exists(file.path(".github", "AGENTS.md")))
    expect_true(dir.exists(file.path("templates")))
  })
})

#test that the configuration files exist
test_that("Configuration files exist", {
  tmp <- make_test_project(load_data = FALSE, label = "config-files")

  withr::with_dir(tmp, {
    config_path <- file.path("config.yml")
    expect_true(file.exists(config_path))
    config <- config::get()
    expect_true(!is.null(config))

    expect_true(file.exists(file.path(getwd(),config$recipients_script)))
    expect_true(file.exists(file.path(getwd(),config$data_script)))

    expect_true(file.exists(file.path(getwd(),config$focal_filter_script)))
    expect_true(file.exists(file.path(getwd(),config$recipient_select_script)))
    expect_true(file.exists(file.path(getwd(),config$computation_script_bg)))
    expect_true(file.exists(file.path(getwd(),config$computation_script_focal)))
    expect_true(file.exists(file.path(getwd(),config$content_template_file)))
    expect_true(file.exists(file.path(getwd(),config$html_template_file)))
  })
})

#data and recipient files
test_that("Recipients and data load correctly", {
  tmp <- make_test_project(load_data = FALSE, label = "data-load")

  withr::with_dir(tmp, {
    expect_message(rf_get_recipients())
    config <- config::get()
    expect_true(file.exists(file.path(getwd(),config$recipients_file)))
    expect_message(rf_get_data())
    expect_true(file.exists(file.path(getwd(),config$data_file)))
  })
})

test_that("Data verification runs", {
  tmp <- make_test_project(load_data = TRUE, label = "data-verify")

  withr::with_dir(tmp, {
    expect_message(rf_verify_data(TRUE))
  })
})

test_that("Data verification fails for duplicate recipient_id", {
  tmp <- make_test_project(load_data = TRUE, label = "data-dup-recipient")

  withr::with_dir(tmp, {
    config <- config::get()
    recipients <- read.csv(config$recipients_file, stringsAsFactors = FALSE)
    recipients <- rbind(recipients, recipients[1, , drop = FALSE])
    write.csv(recipients, config$recipients_file, row.names = FALSE)

    expect_error(rf_verify_data(), "Duplicate recipient_id")
  })
})

test_that("Data verification fails for invalid email", {
  tmp <- make_test_project(load_data = TRUE, label = "data-invalid-email")

  withr::with_dir(tmp, {
    config <- config::get()
    recipients <- read.csv(config$recipients_file, stringsAsFactors = FALSE)
    recipients$email[1] <- "not-an-email"
    write.csv(recipients, config$recipients_file, row.names = FALSE)

    expect_error(rf_verify_data(), "Invalid email format")
  })
})

test_that("Optional recorder schema checks warn or fail as configured", {
  tmp <- make_test_project(load_data = TRUE, label = "data-schema-check")

  withr::with_dir(tmp, {
    expect_warning(
      rf_verify_data(check_recorder_schema = TRUE, recorder_schema_required = FALSE),
      "optional recorder schema columns"
    )

    expect_error(
      rf_verify_data(check_recorder_schema = TRUE, recorder_schema_required = TRUE),
      "optional recorder schema columns"
    )
  })
})

test_that("Preflight render and dispatch checks run", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "preflight")
  batch_id <- "preflight_batch"

  withr::with_dir(tmp, {
    expect_message(rf_preflight(stage = "render", check_recorder_schema = FALSE), "Preflight complete")

    rf_render_all(batch_id)
    expect_message(
      rf_preflight(stage = "dispatch", batch_id = batch_id, check_recorder_schema = FALSE),
      "Preflight complete"
    )
  })
})


test_that("Batch pipeline runs", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "batch-pipeline")
  batch_id <- "test_batch"

  withr::with_dir(tmp, {
    rf_render_all(batch_id)

    expect_equal(nrow(targets::tar_meta(fields="error",complete_only = TRUE)),0)

    meta_path <- file.path("renders", batch_id, "meta_table.csv")
    expect_true(file.exists(meta_path))
  })
})

test_that("Batch verification runs", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "batch-verify")
  batch_id <- "test_batch"

  withr::with_dir(tmp, {
    rf_render_all(batch_id)
    expect_message(rf_verify_batch(batch_id))
  })
})

test_that("Batch rendering can skip recipients via recipient_select", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "batch-select")
  batch_id <- "selected_batch"

  withr::with_dir(tmp, {
    config <- config::get()
    recipients <- read.csv(config$recipients_file, stringsAsFactors = FALSE)
    selected_id <- recipients$recipient_id[1]

    writeLines(
      c(
        "recipient_select <- function(recipients, data, config) {",
        "  data.frame(",
        "    recipient_id = recipients$recipient_id,",
        "    selected = recipients$recipient_id == recipients$recipient_id[1],",
        "    skip_reason = ifelse(recipients$recipient_id == recipients$recipient_id[1], NA_character_, 'Filtered in test'),",
        "    stringsAsFactors = FALSE",
        "  )",
        "}"
      ),
      config$recipient_select_script
    )

    rf_render_all(batch_id)

    meta_table <- read.csv(file.path("renders", batch_id, "meta_table.csv"), stringsAsFactors = FALSE)

    expect_equal(sum(meta_table$render_status == "rendered"), 1)
    expect_equal(sum(meta_table$render_status == "skipped"), nrow(recipients) - 1)
    expect_true(all(meta_table$recipient_id %in% recipients$recipient_id))
    expect_true(all(meta_table$file[meta_table$render_status == "skipped"] %in% c(NA, "")))
    expect_true(all(meta_table$skip_reason[meta_table$render_status == "skipped"] == "Filtered in test"))
    expect_true(any(meta_table$recipient_id == selected_id & meta_table$render_status == "rendered"))
  })
})

test_that("Single feedback item renders", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "single-render")

  withr::with_dir(tmp, {
    expect_silent(rf_render_single(recipient_id = 1))
  })
})

test_that("Dispatch dry run writes logs and summary", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "dispatch-dry-run")
  batch_id <- "dispatch_dry_run"

  withr::with_dir(tmp, {
    rf_render_all(batch_id)
    result <- rf_dispatch_smtp(batch_id, dry_run = TRUE)

    expect_true(file.exists(result$log_file))
    expect_true(file.exists(result$summary_file))

    log_tbl <- read.csv(result$log_file, stringsAsFactors = FALSE)
    summary_tbl <- read.csv(result$summary_file, stringsAsFactors = FALSE)

    expect_true(nrow(log_tbl) > 0)
    expect_true(all(log_tbl$dry_run))
    expect_true(all(log_tbl$status %in% c("DryRun", "Failed")))
    expect_true(nrow(summary_tbl) == 1)
    expect_true(summary_tbl$dry_run[1])
  })
})

test_that("Dispatch resume skips successful recipients", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "dispatch-resume")
  batch_id <- "dispatch_resume"

  withr::with_dir(tmp, {
    rf_render_all(batch_id)
    first <- rf_dispatch_smtp(batch_id, dry_run = TRUE, resume = FALSE)
    first_log <- read.csv(first$log_file, stringsAsFactors = FALSE)
    expect_true(nrow(first_log) > 0)

    target_id <- first_log$recipient_id[1]
    target_count_before <- nrow(first_log[first_log$recipient_id == target_id, , drop = FALSE])

    appended_success <- data.frame(
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
      batch_id = batch_id,
      recipient_id = target_id,
      email = first_log$email[1],
      status = "Success",
      attempt = 1L,
      error_type = NA_character_,
      message = "Synthetic success for resume test",
      dry_run = TRUE,
      stringsAsFactors = FALSE
    )
    write.table(
      appended_success,
      file = first$log_file,
      sep = ",",
      row.names = FALSE,
      col.names = FALSE,
      append = TRUE,
      qmethod = "double"
    )

    rf_dispatch_smtp(batch_id, dry_run = TRUE, resume = TRUE)

    final_log <- read.csv(first$log_file, stringsAsFactors = FALSE)
    latest_target_rows <- final_log[final_log$recipient_id == target_id, , drop = FALSE]

    expect_true(nrow(latest_target_rows) == (target_count_before + 1))
  })
})

test_that("Dispatch preview supports templated subject/body and media columns", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is required for rendering tests")
  tmp <- make_test_project(load_data = TRUE, label = "dispatch-preview")
  batch_id <- "dispatch_preview"

  withr::with_dir(tmp, {
    rf_render_all(batch_id)

    cfg <- yaml::read_yaml("config.yml")
    cfg$default$mail_subject_template <- "Campaign {{campaign_name}} for {{name}}"
    cfg$default$mail_body_prefix_template <- "<p>Campaign {{campaign_name}} preview for {{name}}</p>"
    cfg$default$campaign_name <- "Butterfly Pulse"
    yaml::write_yaml(cfg, "config.yml")

    attachment_path <- file.path("renders", batch_id, "attachment_note.txt")
    inline_path <- file.path("renders", batch_id, "inline_note.png")
    writeLines("attachment", attachment_path)
    writeLines("inline image placeholder", inline_path)

    meta_path <- file.path("renders", batch_id, "meta_table.csv")
    meta <- read.csv(meta_path, stringsAsFactors = FALSE)
    target_id <- meta$recipient_id[1]
    meta$attachment_paths <- ""
    meta$inline_image_paths <- ""
    meta$attachment_paths[meta$recipient_id == target_id] <- attachment_path
    meta$inline_image_paths[meta$recipient_id == target_id] <- inline_path

    first_file <- meta$file[meta$recipient_id == target_id][1]
    first_email <- meta$email[meta$recipient_id == target_id][1]
    # Ensure the footer consistency check passes for the sampled preview row.
    write(paste0("<!-- ", first_email, " -->"), file = first_file, append = TRUE)

    write.csv(meta, meta_path, row.names = FALSE)

    result <- rf_dispatch_smtp(
      batch_id,
      preview_only = TRUE,
      preview_recipient_ids = target_id,
      resume = FALSE
    )

    preview_index_path <- file.path("renders", batch_id, "dispatch_preview", "preview_index.csv")
    expect_true(file.exists(preview_index_path))

    preview_index <- read.csv(preview_index_path, stringsAsFactors = FALSE)
    expect_true(any(preview_index$recipient_id == target_id))

    log_tbl <- read.csv(result$log_file, stringsAsFactors = FALSE)
    target_rows <- log_tbl[log_tbl$recipient_id == target_id & log_tbl$status == "Preview", , drop = FALSE]
    expect_true(nrow(target_rows) >= 1)
    expect_true(any(grepl("Campaign Butterfly Pulse for", target_rows$message, fixed = TRUE)))
  })
})
