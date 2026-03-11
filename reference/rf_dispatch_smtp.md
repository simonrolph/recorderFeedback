# Dispatch feedback via SMTP email

Sends rendered feedback files to recipients via SMTP with preflight
checks, retries, rate limiting, and dispatch logging.

## Usage

``` r
rf_dispatch_smtp(
  batch_id,
  dry_run = FALSE,
  resume = TRUE,
  confirm_live_send = FALSE,
  max_retries = NULL,
  retry_backoff_sec = NULL,
  rate_per_minute = NULL,
  preview_n = 0,
  preview_recipient_ids = NULL,
  preview_only = FALSE,
  preview_dir = NULL
)
```

## Arguments

- batch_id:

  Character. Identifier for the batch.

- dry_run:

  Logical. If TRUE, do not send mail; only validate and write logs.

- resume:

  Logical. If TRUE, skip recipients already marked \`Success\` in
  \`renders/\<batch_id\>/dispatch_log.csv\`.

- confirm_live_send:

  Logical. Must be TRUE to send to real recipients when \`test_mode\` is
  FALSE.

- max_retries:

  Integer. Number of retries after the first failed attempt. Defaults to
  \`config\$mail_retry_max\`.

- retry_backoff_sec:

  Numeric. Base seconds for exponential backoff. Defaults to
  \`config\$mail_retry_backoff_sec\`.

- rate_per_minute:

  Numeric. Maximum send attempts per minute. Defaults to
  \`config\$mail_rate_per_minute\`.

- preview_n:

  Integer. If \> 0, only process the first \`preview_n\` recipients.

- preview_recipient_ids:

  Optional vector of recipient IDs to process.

- preview_only:

  Logical. If TRUE, write preview HTML files and do not send.

- preview_dir:

  Optional output directory for preview HTML files.

## Value

Invisible named list with \`log_file\`, \`summary_file\`, and
\`summary\`.
