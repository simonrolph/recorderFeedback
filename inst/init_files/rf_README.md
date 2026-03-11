# Recorder Feedback Project

This project was initialised with `recorderFeedback::rf_init()`.

## Getting Started (Delete This Section Once Set Up)

Use this checklist to get your first batch rendered quickly. After your project is working, you can delete this section.

1. Review and edit `config.yml`.
	Confirm all script paths, template paths, and output locations are correct for your project.
2. Prepare your scripts in `scripts/`.
	- `get_recipients.R` should create a table of recipients with a unique ID.
	- `get_data.R` should load the source data used in feedback generation.
	- `computation.R` should define objects used by your template.
	- `focal_filter.R` should subset data for each recipient/item.
	- `recipient_select.R` can optionally decide which recipients are rendered in a batch.
3. Prepare your templates in `templates/`.
	- `content.Rmd` should contain the main feedback content.
	- `template.html` should provide the HTML wrapper/styling.
	- `email_format.R` should define the email body/subject formatting.
4. Run a first dry workflow in R.

```r
# Run from project root
rf_get_recipients()
rf_get_data()
rf_verify_data(verbose = TRUE)

batch_id <- format(Sys.time(), "%Y%m%d_test")
rf_render_all(batch_id = batch_id)
rf_verify_batch(batch_id = batch_id)
```

5. Inspect output files.
	Check `renders/<batch_id>/` and open a few outputs to confirm layout and computed values look correct.
6. Iterate on scripts/templates and rerun.
	It is normal to tweak `content.Rmd`, `template.html`, and computation logic a few times before production use.
7. Render or preview one record when debugging.

```r
rf_render_single(recipient_id = 1)
```

8. Remove this section.
	Once your workflow is stable, delete this whole "Getting Started" block and replace it with project-specific notes.

## What Was Created

- `config.yml`: Main configuration for file paths, scripts, and output.
- `_targets.R`: Pipeline definition used by the `{targets}` workflow.
- `run_pipeline.R`: Convenience script to run the pipeline.
- `templates/`: HTML, R Markdown, and email template files.
- `scripts/`: Data loading, recipient generation, filtering, and computations.
- `scripts/recipient_select.R`: Optional batch selection hook for selective rendering.
- `data/`: Inputs and intermediate files (gitignored by default).
- `renders/`: Batch render outputs.

## Typical Workflow

1. Edit `config.yml` to match your project setup.
2. Update scripts in `scripts/` and templates in `templates/`.
3. Pull inputs using `rf_get_recipients()` and `rf_get_data()`.
4. Validate data using `rf_verify_data()`.
5. Render output with `rf_render_all(batch_id = "my_batch")`.
6. Check results with `rf_verify_batch(batch_id = "my_batch")`.

## Useful Functions

- `rf_init()`
- `rf_get_recipients()`
- `rf_get_data()`
- `rf_verify_data()`
- `rf_render_all()`
- `rf_verify_batch()`
- `rf_render_single(recipient_id = 1)`

See package vignettes for complete examples.
