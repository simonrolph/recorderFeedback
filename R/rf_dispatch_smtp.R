#' Dispatch feedback via SMTP email
#'
#' Sends generated feedback files to recipients using SMTP.
#'
#' @param batch_id Character. Identifier for the batch.
#' @return Message indicating status.
#' @export
rf_dispatch_smtp <- function(batch_id){
  meta_table <-read.csv(paste0("renders/",batch_id,"/meta_table.csv"))

  #configure smtp authentication
  if(config$mail_creds == "envvar"){
    Sys.setenv(SMTP_PASSWORD = config$mail_password)
    creds <- blastula::creds_envvar(
      user = config$mail_username,
      pass_envvar = "SMTP_PASSWORD",
      host = config$mail_server,
      port = config$mail_port,
      use_ssl = config$mail_use_ssl)
  }

  if(config$mail_creds == "anonymous"){
    creds <- blastula::creds_anonymous(host = config$mail_server,port=config$mail_port,use_ssl = config$mail_use_ssl)
  }



  #maintain a dataframe with the email and any errors that arise when sending
  status_log <- data.frame(
    recipient_id = character(),
    email = character(),
    status = character(),
    message = character(),
    stringsAsFactors = FALSE
  )

  #here we are going through all the recipients and sending email
  for (i in 1:nrow(meta_table)) {

    result <- tryCatch({
      # Debug: Print current row being processed
      print(paste("Processing row:", i))

      # Check for required columns in meta_table
      if (!all(c("content_key", "recipient_id", "file", "email") %in% colnames(meta_table))) {
        stop("meta_table is missing required columns.")
      }

      # Extract values
      content_key <- meta_table[i, "content_key"]
      recipient_id <- meta_table[i, "recipient_id"]
      file <- meta_table[i, "file"]
      email <- meta_table[i, "email"]


      #check email is in content
      lines_read <- paste0(readLines(file),collapse = "")
      if(grepl(email, lines_read, fixed = TRUE)==FALSE){
        stop("Target email address is different to email listed in footer")
      }

      #send email
      sender <- config$mail_sender
      names(sender) <- config$mail_name
      email_obj <- blastula:::cid_images(file)

      # send to test email if test mode activated
      if(config$test_mode){
        email<-config$mail_test_recipient
      }

      #send the email
      blastula::smtp_send(
        email_obj,
        from = sender,
        to = email,
        subject = config$mail_subject,
        credentials = creds,
        verbose = FALSE
      )
      data.frame(
        recipient_id = recipient_id,
        email = email,
        status = "Success",
        message = "Email sent",
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      print("Email not sent")
      data.frame(
        recipient_id = recipient_id,
        email = email,
        status = "Failed",
        message = e$message,
        stringsAsFactors = FALSE
      )
    })
    status_log <- rbind(status_log,result)
  }

  #send an email to test email with a status log
  status_lines <- apply(status_log, 1, function(row) {
    paste(
      "recipient ID:", row["recipient_id"],
      "| Email:", row["email"],
      "| Status:", row["status"],
      "| Message:", row["message"]
    )
  })

  report_email <- compose_email(
    body = md(
      paste0(
        "### Email Send Summary",
        "
      Total attempted: ", nrow(status_log),
        "
      ✅ Success: ", sum(status_log$status == "Success"),
        "
      ❌ Failed: ", sum(status_log$status == "Failed"),
        "
      Please check logs for more information"
      )
    ),
    footer = Sys.time()
  )

  smtp_send(
    email = report_email,
    from = sender,
    to = config$mail_test_recipient,  # your email
    subject = paste("Email Batch Status Report -", Sys.Date()),
    credentials = creds,
    verbose = FALSE
  )

  invisible(TRUE)
}
