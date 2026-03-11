# RecorderFeedback Agent Helper

This file gives an AI coding agent the context needed to help a user run the
`recorderFeedback` package end to end.

## Purpose

Use this repository to generate personalized feedback content for recipients,
then optionally dispatch via SMTP email.

## Project Type

- R package with workflow helpers and templates.
- Typical user flow is project initialization, data loading, rendering, and dispatch.

## Key Package Functions

- `rf_init(path = ".")`: scaffold a project folder.
- `rf_get_recipients()`: run the configured script to update recipients CSV.
- `rf_get_data()`: run the configured script to update records CSV.
- `rf_verify_data(verbose = TRUE)`: verify required columns and data readiness.
- `rf_render_single(recipient_id = 1)`: render one recipient for debugging.
- `rf_render_all(batch_id)`: run the targets pipeline for a full batch.
- `rf_verify_batch(batch_id, verbose = TRUE)`: validate rendered outputs and metadata.
- `rf_dispatch_smtp(batch_id)`: send rendered content by email.

## Required Files and Layout

The package expects initialized projects to contain:

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
- `data/` for CSV inputs
- `renders/` for generated outputs

## Config Keys Agent Must Check

From `config.yml` (default profile):

- Inputs and loaders:
  - `recipients_file`, `recipients_script`
  - `data_file`, `data_script`
- Rendering logic:
  - `focal_filter_script`
  - `recipient_select_script` (optional selective rendering hook)
  - `computation_script_bg`, `computation_script_focal`
  - `content_template_file`, `html_template_file`, `email_format`
- Email:
  - `test_mode`, `mail_*` keys

If any configured file is missing, agent should stop and report the missing path
with a clear fix.

## Selective Rendering Contract

`rf_render_all(batch_id)` supports selection via `recipient_select_script`.
That script must define:

`recipient_select(recipients, data, config)`

Accepted return values:

- `NULL`: render all recipients.
- Logical vector (length `nrow(recipients)`).
- Vector of `recipient_id` values to include.
- Data frame with `recipient_id`, `selected`, and optional `skip_reason`.

Expected behavior:

- Selected recipients are rendered.
- Non-selected recipients appear in `renders/<batch_id>/meta_table.csv` with
  `render_status = "skipped"` and no HTML `file`.
- Failed renders appear with `render_status = "failed"`.

## Standard Agent Runbook

When a user asks to generate feedback, follow this order:

1. Confirm repository root and that `config.yml` exists.
2. Load package and config.
3. Refresh source files:
   - `rf_get_recipients()`
   - `rf_get_data()`
4. Validate data:
   - `rf_verify_data(TRUE)`
5. Optional debug step:
   - `rf_render_single(recipient_id = <known_id>)`
6. Batch render:
   - choose `batch_id` (timestamp-safe, unique)
   - run `rf_render_all(batch_id)`
7. Verify outputs:
   - `rf_verify_batch(batch_id, TRUE)`
   - inspect `renders/<batch_id>/meta_table.csv`
8. Optional dispatch:
   - if SMTP configured and user confirms, run `rf_dispatch_smtp(batch_id)`

## Batch Output Expectations

After successful rendering:

- Folder exists: `renders/<batch_id>/`
- File exists: `renders/<batch_id>/meta_table.csv`
- Per-recipient HTML files exist for `render_status == "rendered"`
- `meta_table.csv` contains `recipient_id`, `file`, and status fields

## Troubleshooting Rules For Agents

- If `meta_table.csv` is missing: rendering did not complete. Check
  `targets::tar_meta(fields = "error", complete_only = TRUE)`.
- If a single recipient fails in batch: reproduce with `rf_render_single()`.
- If emails are skipped unexpectedly: inspect `recipient_select_script` and
  `render_status` values in meta table.
- If recipient counts mismatch: compare `config$recipients_file` to
  `meta_table.csv` and check for skipped recipients.

## Safety and Execution Notes

- Prefer `test_mode: TRUE` while developing email steps.
- Do not run SMTP dispatch without explicit user confirmation.
- Use unique `batch_id` values to avoid confusion with prior renders.
- Do not delete existing render directories unless the user asks.

## Minimal Example Session

```r
library(recorderFeedback)

rf_get_recipients()
rf_get_data()
rf_verify_data(TRUE)

batch_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
rf_render_all(batch_id)
rf_verify_batch(batch_id, TRUE)

meta <- read.csv(file.path("renders", batch_id, "meta_table.csv"))
head(meta)
# rf_dispatch_smtp(batch_id)  # optional
```
