# RecorderFeedback Agent Helper

This file gives an AI coding agent the context needed to help a user run the
`recorderFeedback` package end to end.

## Purpose

Use this project to generate personalized feedback content for recipients,
then optionally dispatch via SMTP email.

This helper explains both:

1. How `recorderFeedback` bootstraps a new workspace with `rf_init()`.
2. How that scaffold is adapted to a specific domain use-case (for example,
	 butterfly recorder activity feedback).

## Workflow Overview

The package follows a staged workflow:

1. Initialize a project workspace (`rf_init()`).
2. Adapt scripts/templates/config to your use-case.
3. Pull recipients and source records (`rf_get_recipients()`, `rf_get_data()`).
4. Run QA and preflight checks (`rf_verify_data()`, `rf_preflight()`).
5. Render one sample (`rf_render_single()`) then batch render (`rf_render_all()`).
6. Verify batch outputs (`rf_verify_batch()`).
7. Preflight dispatch (`rf_preflight(stage = "dispatch")`).
8. Dispatch with SMTP (`rf_dispatch_smtp()`) when explicitly approved.

## Workspace Bootstrap (`rf_init`)

`rf_init(path = "...")` creates a reusable feedback workspace structure and
starter files. This is intentionally generic, so every project can tailor the
logic for a specific recording scheme.

Scaffolded areas include:

- `config.yml`: central project settings and paths.
- `scripts/`: data ingest, focal filtering, selection, and computation logic.
- `templates/`: content template, HTML wrapper, and email format function.
- `renders/`: output batches (`meta_table.csv`, rendered HTML, logs).
- `run_pipeline.R` + `_targets.R`: orchestration for batch rendering.

Treat `rf_init()` as project bootstrapping, not a finished workflow.

## Adapting To A Use-Case

After initialization, adapt these components for your domain:

- `scripts/get_recipients.R`
	Build recipient table with at least `recipient_id`, `name`, and `email`.
- `scripts/get_data.R`
	Pull observation/recording data keyed by `recipient_id`.
- `scripts/focal_filter.R`
	Define what subset of records is "focal" for each recipient.
- `scripts/computation.R`
	Build summary objects used by the report (counts, trends, rankings, maps).
- `scripts/recipient_select.R`
	Optional targeting rules for who is rendered in a batch.
- `templates/content.Rmd`
	Human-facing narrative and visuals for personalized feedback.
- `config.yml`
	Bind file paths, SMTP settings, and campaign/dispatch options.

For butterfly recorder feedback this could include
date-window summaries, species richness, top species, site coverage, and
year-on-year comparisons.

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

## Data Contracts

Minimum expected columns:

- Recipients: `recipient_id`, `name`, `email`
- Data: `recipient_id`

Optional recorder analytics schema checks can be enabled for columns such as:

- `date`
- `species`
- `site`

Use `rf_verify_data(check_recorder_schema = TRUE)` or `rf_preflight()` to
enforce these checks before rendering.

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

## Dispatch Controls (Operational)

Recommended sequence:

1. `rf_dispatch_smtp(batch_id, dry_run = TRUE)` for preflight send checks.
2. Keep `test_mode: TRUE` while validating formatting and recipients.
3. Use preview/sample mode when needed:
	`rf_dispatch_smtp(batch_id, preview_only = TRUE, preview_n = 5)`
4. Only for live send (`test_mode: FALSE`), require explicit confirmation:
	`rf_dispatch_smtp(batch_id, confirm_live_send = TRUE)`

Useful artifacts:

- `renders/<batch_id>/meta_table.csv`
- `renders/<batch_id>/dispatch_log.csv`
- `renders/<batch_id>/dispatch_summary.csv`
- `renders/<batch_id>/dispatch_preview/preview_index.csv` (if preview mode used)

## Safety

- Keep `test_mode: TRUE` until dispatch is production-ready.
- Do not dispatch emails without explicit user confirmation.
- Do not delete previous batches unless the user asks.
