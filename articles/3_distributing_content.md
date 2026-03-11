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

### Configuration

Distribution settings are managed in your project’s `config.yml` file.
Key entries include:

- `mail_server`: SMTP server address.
- `mail_port`: SMTP port (default: 587).
- `mail_use_tls` / `mail_use_ssl`: Security options for email.
- `mail_username`, `mail_password`: Credentials for authentication.
- `mail_sender`, `mail_name`: Sender details.
- `mail_subject`: Subject line for feedback emails.
- `mail_test_recipient`: Address for test emails.
- `mail_creds`: Authentication mode (`"anonymous"` or `"envvar"`).
- `test_mode`: If `TRUE`, all messages are redirected to
  `mail_test_recipient`.

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

For a safe first run, keep `test_mode: TRUE` in `config.yml`. This sends
all outputs to `mail_test_recipient` instead of real recipient
addresses.

### Customising Email Content

- Email body content comes from `content_template_file` and
  `html_template_file`.
- Sending format is controlled by `email_format` (usually
  `templates/email_format.R`).

### Verifying Distribution

After dispatch, you can verify which emails were sent and check for any
errors:

``` r
rf_verify_batch(batch_id)
```

You should also inspect the status report email sent to
`mail_test_recipient`.

### Common First-Run Issues

- Authentication failure: review `mail_creds`, username/password, host,
  and port.
- TLS/SSL mismatch: check `mail_use_tls` and `mail_use_ssl` for your
  SMTP provider.
- Footer email mismatch error: generated file email does not match the
  meta table row.

### Summary

- Email distribution is fully configurable via `config.yml`.
- Use
  [`rf_dispatch_smtp()`](https://simonrolph.github.io/recorderFeedback/reference/rf_dispatch_smtp.md)
  to send feedback to recipients.
- Keep `test_mode: TRUE` for dry runs, then switch to `FALSE` for live
  sending.

This approach helps you validate delivery safely before contacting real
recipients.
