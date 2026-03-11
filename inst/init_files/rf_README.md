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
rf_preflight(stage = "render")

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

8. Preflight and test dispatch.

```r
# Validate dispatch rows/files without sending
rf_dispatch_smtp(batch_id = batch_id, dry_run = TRUE)

# Send in test mode (config.yml test_mode: TRUE)
rf_dispatch_smtp(batch_id = batch_id)

# Preview a sample without sending
rf_dispatch_smtp(batch_id = batch_id, preview_only = TRUE, preview_n = 5)
```

9. Move to live dispatch only when ready.

```r
# Required safeguard when config.yml test_mode: FALSE
rf_dispatch_smtp(batch_id = batch_id, confirm_live_send = TRUE)
```

10. Remove this section.
	Once your workflow is stable, delete this whole "Getting Started" block and replace it with project-specific notes.

## AI Agent Quickstart

You can use an AI coding agent (e.g. GitHub Copilot in VS Code) to adapt this
project to your use-case with minimal manual scripting. The `.github/AGENTS.md`
file gives the agent the context it needs.

### What to prepare

1. **Drop your real data into `data/`.**
   The agent will read from those files when writing `get_recipients.R` and
   `get_data.R`, so the more representative the files, the better the output.
   - `data/recipients.csv` — at minimum: `recipient_id`, `name`, `email`.
   - `data/data.csv` — source records keyed by `recipient_id`.

2. **Write a short plain-English specification.** Example:

   ---
   **Use-case:** Personalised end-of-season feedback emails for butterfly transect recorders.

   **Recipients:** Volunteer recorders enrolled in a national butterfly monitoring scheme.
   Each recipient has a unique `recorder_id`, a first name, and an email address.

   **Data:** One row per sighting visit. Columns available:
   `recorder_id`, `date` (YYYY-MM-DD), `species` (scientific), `common_name`,
   `count` (integer, individuals seen), `site` (named transect location),
   `latitude`, `longitude`.

   **Content to include in each email:**
   - A personalised greeting using the recorder's first name.
   - A headline summary: total records and species seen this season, with a
     percentage change versus the previous season.
   - A bar chart of monthly activity (individuals counted per month) for the
     current year.
   - A year-on-year trend chart showing records submitted and species richness
     across all years on record.
   - A table of the recorder's top 5 species this season (by total individuals).
   - A table of their top recording sites this season (by number of visits).
   - A bullet list of every species they have ever recorded.
   - A warm closing note thanking them for their contribution.

   **Tone:** Friendly and encouraging. Aimed at engaged volunteers, not scientists.

   **Styling:** Use the existing `template.html` wrapper. Charts should use
   muted, nature-inspired colours (greens, oranges). No raw data tables beyond
   the top-5 summaries.

   **Batch ID convention:** `butterfly-YYYY` where YYYY is the current year.
   ---

### What to ask the agent

Open GitHub Copilot Chat (or equivalent) in the project root and paste a
prompt like the one below. The agent will use `AGENTS.md` automatically because
it lives in `.github/`.

```
Using the recorderFeedback package and the data in data/, implement scripts and
a content template for the following use-case:

<paste your specification here>

Then run the full workflow: rf_get_recipients(), rf_get_data(),
rf_verify_data(), rf_preflight(), rf_render_single(1) as a smoke test, then
rf_render_all() for the full batch, and rf_verify_batch(). Fix any errors that
arise.
```

### What the agent will do

- Write `scripts/get_recipients.R` and `scripts/get_data.R` to load your files.
- Write `scripts/computation.R` with domain-appropriate analytics (counts,
  trends, charts, rankings).
- Write `templates/content.Rmd` with a personalised narrative and visuals.
- Update `config.yml` (campaign name, subject line, etc.).
- Create `.Renviron` with `RSTUDIO_PANDOC` if pandoc is not on your PATH.
- Execute the pipeline and fix any errors before handing back.

### Tips

- If you only have one of `recipients.csv` or `data.csv` ready, ask the agent
  to simulate the other — it can generate realistic synthetic data.
- After a successful batch, ask the agent to update `AGENTS.md` with any new
  lessons learned (e.g. schema quirks, pandoc paths, package dependencies).
- The `renders/<batch_id>/meta_table.csv` is a useful artefact to share with
  the agent when debugging partial failures.


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
7. Run dispatch preflight with `rf_dispatch_smtp(batch_id = "my_batch", dry_run = TRUE)`.
8. Dispatch with `rf_dispatch_smtp(batch_id = "my_batch")`.
9. Optional sample preview with `rf_dispatch_smtp(batch_id = "my_batch", preview_only = TRUE, preview_n = 5)`.

## Useful Functions

- `rf_init()`
- `rf_get_recipients()`
- `rf_get_data()`
- `rf_verify_data()`
- `rf_preflight(stage = "render")`
- `rf_render_all()`
- `rf_verify_batch()`
- `rf_render_single(recipient_id = 1)`
- `rf_dispatch_smtp(batch_id = "my_batch", dry_run = TRUE)`

You can customise campaign delivery in `config.yml` with:

- `mail_subject_template`
- `mail_body_prefix_template` / `mail_body_suffix_template`
- `mail_attachments_col` / `mail_inline_images_col`
- `campaign_name` / `campaign_metadata`

See package vignettes for complete examples.
