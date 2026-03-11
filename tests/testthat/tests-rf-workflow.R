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
    expect_true(file.exists(file.path("config.yml")))
    expect_true(file.exists(file.path("README.md")))
    expect_true(file.exists(file.path(".gitignore")))
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
