# RecorderFeedback Agent Helper

This file gives an AI coding agent the context needed to help a user run the
`recorderFeedback` package end to end.

## Purpose

Use this project to generate personalized feedback content for recipients,
then optionally dispatch via SMTP email.

## Key Functions

- `rf_get_recipients()`
- `rf_get_data()`
- `rf_preflight(stage = "render")`
- `rf_verify_data(verbose = TRUE)`
- `rf_render_single(recipient_id = 1)`
- `rf_render_all(batch_id)`
- `rf_verify_batch(batch_id, verbose = TRUE)`
- `rf_dispatch_smtp(batch_id)`

## Required Project Files

- `config.yml`
- `_targets.R`
- `run_pipeline.R`
- `scripts/get_recipients.R`
- `scripts/get_data.R`
- `scripts/focal_filter.R`
- `scripts/recipient_select.R`
- `scripts/computation.R`
- `templates/content.Rmd`
- `templates/template.html`
- `templates/email_format.R`

## Selective Rendering

Selective rendering is controlled by `config$recipient_select_script`.
That script must define:

`recipient_select(recipients, data, config)`

Accepted return values:

- `NULL` to render all recipients.
- A logical vector (`length == nrow(recipients)`).
- A vector of `recipient_id` values to include.
- A data frame containing `recipient_id`, `selected`, and optional `skip_reason`.

Recipients that are not selected are written to `renders/<batch_id>/meta_table.csv`
with `render_status = "skipped"`.

## Standard Runbook

1. Run `rf_get_recipients()` and `rf_get_data()`.
2. Run `rf_verify_data(TRUE)` and `rf_preflight(stage = "render")`.
3. Optionally test one recipient with `rf_render_single(recipient_id = 1)`.
4. Run batch render with a unique `batch_id` via `rf_render_all(batch_id)`.
5. Validate with `rf_verify_batch(batch_id, TRUE)`.
6. Run `rf_preflight(stage = "dispatch", batch_id = batch_id)`.
7. Inspect `renders/<batch_id>/meta_table.csv`.
8. Only if explicitly requested and mail config is ready, run `rf_dispatch_smtp(batch_id)`.

## Safety

- Keep `test_mode: TRUE` until dispatch is production-ready.
- Do not dispatch emails without explicit user confirmation.
- Do not delete previous batches unless the user asks.
