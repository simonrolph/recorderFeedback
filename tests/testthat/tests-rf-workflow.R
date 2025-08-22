library(testthat)
library(recorderFeedback)

tmp <- tempdir()

# test project initialisation
test_that("Project initialisation works", {
  expect_message(rf_init(path = tmp))
  expect_true(dir.exists(file.path("data")))
  expect_true(dir.exists(file.path("renders")))
  expect_true(file.exists(file.path("config.yml")))
  expect_true(dir.exists(file.path("templates")))
})

#test that the configuration files exist
test_that("Configuration files exist", {
  config_path <- file.path("config.yml")
  expect_true(file.exists(config_path))
  config <<- config::get()
  expect_true(!is.null(config))

  expect_true(file.exists(file.path(getwd(),config$recipients_script)))
  expect_true(file.exists(file.path(getwd(),config$data_script)))

  expect_true(file.exists(file.path(getwd(),config$focal_filter_script)))
  expect_true(file.exists(file.path(getwd(),config$computation_script_bg)))
  expect_true(file.exists(file.path(getwd(),config$computation_script_focal)))
  expect_true(file.exists(file.path(getwd(),config$content_template_file)))
  expect_true(file.exists(file.path(getwd(),config$html_template_file)))
})

#data and recipient files
test_that("Recipients and data load correctly", {
  expect_message(rf_get_recipients())
  expect_true(file.exists(file.path(getwd(),config$recipients_file)))
  expect_message(rf_get_data())
  expect_true(file.exists(file.path(getwd(),config$data_file)))
})

test_that("Data verification runs", {
  expect_message(rf_verify_data(TRUE))
})


test_that("Batch pipeline runs", {
  batch_id <- "test_batch"
  rf_render_all(batch_id)

  expect_equal(nrow(targets::tar_meta(fields="error",complete_only = TRUE)),0)

  meta_path <- file.path("renders", batch_id, "meta_table.csv")
  expect_true(file.exists(meta_path))
})

test_that("Batch verification runs", {
  expect_message(rf_verify_batch(batch_id))
})

#for some reason this deletes the temporay directory so I run this test last
test_that("Single feedback item renders", {
  expect_silent(rf_render_single(recipient_id = 1))
})
