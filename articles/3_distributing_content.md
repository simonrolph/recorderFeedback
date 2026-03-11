# Distributing Content

``` r
library(recorderFeedback)
```

## Distributing Content

This vignette explains how to safely send generated feedback by email.
It is designed for new users who have already rendered a batch
successfully.

### Before Sending Any Email

Confirm these prerequisites first:

1.  You have run `rf_render_all(batch_id)`.
2.  `renders/<batch_id>/meta_table.csv` exists.
3.  `rf_verify_batch(batch_id)` completes without blocking errors.

You can run one preflight command before rendering and dispatching:

``` r
# Fail fast before render
rf_preflight(stage = "render")

# Fail fast before dispatch
rf_preflight(stage = "dispatch", batch_id = batch_id)
```

### Configuration

Distribution settings are managed in your project’s `config.yml` file.
Key entries include:

- `mail_server`: SMTP server address.
- `mail_port`: SMTP port (default: 587).
- `mail_use_tls` / `mail_use_ssl`: Security options for email.
- `mail_username`, `mail_password`: Credentials for authentication.
- `mail_sender`, `mail_name`: Sender details.
- `mail_subject`: Subject line for feedback emails.
- `mail_subject_template`: Subject template supporting variables like
  `{{name}}`, `{{recipient_id}}`, `{{campaign_name}}`, and
  `{{batch_id}}`.
- `mail_body_prefix_template`, `mail_body_suffix_template`: Optional
  HTML blocks inserted before/after rendered content with the same
  variable support.
- `mail_test_recipient`: Address for test emails.
- `mail_creds`: Authentication mode (`"anonymous"` or `"envvar"`).
- `test_mode`: If `TRUE`, all messages are redirected to
  `mail_test_recipient`.
- `mail_retry_max`: Number of retries after first failed send attempt.
- `mail_retry_backoff_sec`: Base backoff in seconds (uses exponential
  backoff).
- `mail_rate_per_minute`: Maximum send attempts per minute.
- `mail_attachments_col`: Column name in `meta_table.csv` containing
  attachment paths (delimited by `,`, `;`, or `|`).
- `mail_inline_images_col`: Column name in `meta_table.csv` containing
  inline image paths (delimited by `,`, `;`, or `|`).
- `campaign_name`, `campaign_metadata`: Campaign context used in
  templates.

``` r
config <- config::get()
config[c(
  "test_mode",
  "mail_creds",
  "mail_server",
  "mail_port",
  "mail_sender",
  "mail_name",
  "mail_subject",
  "mail_test_recipient"
)]
```

### Dispatching Feedback

After generating feedback content, use
[`rf_dispatch_smtp()`](https://simonrolph.github.io/recorderFeedback/reference/rf_dispatch_smtp.md)
to send emails to recipients. This function uses the configuration above
to connect to your mail server and distribute feedback.

``` r
batch_id <- "example_batch"
rf_dispatch_smtp(batch_id)
```

For a preflight check without sending any emails:

``` r
rf_dispatch_smtp(batch_id, dry_run = TRUE)
```

To continue a previously interrupted run and skip already successful
sends:

``` r
rf_dispatch_smtp(batch_id, resume = TRUE)
```

Preview a sample without sending any emails:

``` r
rf_dispatch_smtp(batch_id, preview_only = TRUE, preview_n = 5)
```

Preview specific recipients:

``` r
rf_dispatch_smtp(batch_id, preview_only = TRUE, preview_recipient_ids = c(101, 205, 309))
```

For a safe first run, keep `test_mode: TRUE` in `config.yml`. This sends
all outputs to `mail_test_recipient` instead of real recipient
addresses.

If `test_mode: FALSE`, you must explicitly confirm a live send:

``` r
rf_dispatch_smtp(batch_id, confirm_live_send = TRUE)
```

### Customising Email Content

- Email body content comes from `content_template_file` and
  `html_template_file`.
- Sending format is controlled by `email_format` (usually
  `templates/email_format.R`).
- Subject/body templating tokens include recipient fields from
  `meta_table.csv` plus campaign tokens such as `{{campaign_name}}`,
  `{{campaign_date}}`, `{{dispatch_timestamp}}`, and `{{batch_id}}`.
- To include attachments/inline images, add columns to `meta_table.csv`
  matching `mail_attachments_col` and `mail_inline_images_col` with file
  paths.

### Verifying Distribution

After dispatch, you can verify which emails were sent and check for any
errors:

``` r
rf_verify_batch(batch_id)
```

Inspect the generated dispatch files:

- `renders/<batch_id>/dispatch_log.csv`: One row per recipient send
  attempt.
- `renders/<batch_id>/dispatch_summary.csv`: Summary metrics for the
  run.
- `renders/<batch_id>/dispatch_preview/preview_index.csv`: Preview index
  when preview mode is used.

### Common First-Run Issues

- Authentication failure: review `mail_creds`, username/password, host,
  and port.
- TLS/SSL mismatch: check `mail_use_tls` and `mail_use_ssl` for your
  SMTP provider.
- Footer email mismatch error: generated file email does not match the
  meta table row.
- QA failures from
  [`rf_verify_data()`](https://simonrolph.github.io/recorderFeedback/reference/rf_verify_data.md):
  duplicate `recipient_id`, missing/invalid emails, or optional recorder
  schema checks (`date/species/site`).

### Summary

- Email distribution is fully configurable via `config.yml`.
- Use
  [`rf_dispatch_smtp()`](https://simonrolph.github.io/recorderFeedback/reference/rf_dispatch_smtp.md)
  to send feedback to recipients.
- Keep `test_mode: TRUE` for dry runs, then switch to `FALSE` for live
  sending.

This approach helps you validate delivery safely before contacting real
recipients.
