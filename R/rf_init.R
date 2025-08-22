#' Initialise a recorder feedback project
#'
#' Sets up the directory structure and template files for a new feedback project.
#'
#' @param path Character. Path to create the project.
#' @return Invisible
#' @export
rf_init <- function(path = ".") {

  # Helper to make dirs
  make_dir <- function(dir_path, gitignore = FALSE) {
    if (!dir.exists(dir_path)) {
      dir.create(dir_path, recursive = TRUE)
      message("Created folder: ", dir_path)
      if (gitignore) {
        writeLines(c("*","!.gitignore"), file.path(dir_path, ".gitignore"))
        message("  Added .gitignore to: ", dir_path)
      }
    } else {
      message("Folder already exists: ", dir_path)
    }
  }

  # Helper to make files
  make_file <- function(file_path) {
    if (!file.exists(file_path)) {
      file.create(file_path)
      message("Created file: ", file_path)
    } else {
      message("File already exists: ", file_path)
    }
  }

  # --- Create folders ---
  make_dir(file.path(path, "data"), gitignore = TRUE)
  make_dir(file.path(path, "templates"))
  make_dir(file.path(path, "renders"))
  make_dir(file.path(path, "scripts"))
  make_dir(file.path(path, "scripts", "extras"), gitignore = TRUE)


  # --- Copy template files ---
  template_dir <- system.file("init_files", package = "recorderFeedback")

  if (template_dir == "") {
    stop("Template directory not found in package installation.")
  }

  # --- Create files ---
  file.copy(file.path(template_dir, "rf_config.yml"),
            file.path(path, "config.yml"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_targets.R"),
            file.path(path, "_targets.R"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_run_pipeline.R"),
            file.path(path, "run_pipeline.R"), overwrite = FALSE)

  #template content
  file.copy(file.path(template_dir, "rf_template.html"),
            file.path(path, "templates" , "template.html"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_content.Rmd"),
            file.path(path, "templates" , "content.Rmd"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_email_format.R"),
            file.path(path, "templates" , "email_format.R"), overwrite = FALSE)

  #scripts
  file.copy(file.path(template_dir, "rf_get_recipients.R"),
            file.path(path, "scripts" , "get_recipients.R"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_get_data.R"),
            file.path(path, "scripts" , "get_data.R"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_computation.R"),
            file.path(path, "scripts" , "computation.R"), overwrite = FALSE)
  file.copy(file.path(template_dir, "rf_filter.R"),
            file.path(path, "scripts" , "focal_filter.R"), overwrite = FALSE)

  if(path != "."){
    setwd(path)
    message("Working directory set to: ", getwd())
  }

  invisible(TRUE)
}
