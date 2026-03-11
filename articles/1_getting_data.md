# Getting Data

``` r
library(recorderFeedback)
```

## Getting Data

This vignette is for first-time users of **recorderFeedback**. It
explains how recipient data and observation data are loaded into your
project in a way that can be repeated every reporting cycle.

### Before You Start

You should have:

- A project created with
  [`rf_init()`](https://simonrolph.github.io/recorderFeedback/reference/rf_init.md).
- A `config.yml` file in your project root.
- The package loaded with
  [`library(recorderFeedback)`](https://simonrolph.github.io/recorderFeedback/).

If you have not initialised a project yet, run:

``` r
rf_init("my_feedback_project")
```

Then work inside that folder so relative paths in `config.yml` resolve
correctly.

### Configuration

Data input is controlled by your project’s `config.yml`. The most
important fields are:

- `recipients_file`: Path to your recipients data (e.g.,
  `"data/recipients.csv"`).
- `recipients_script`: Script for loading recipients (e.g.,
  `"scripts/get_recipients.R"`).
- `data_file`: Path to your records/observations data (e.g.,
  `"data/data.csv"`).
- `data_script`: Script for loading records (e.g.,
  `"scripts/get_data.R"`).

Each `*_script` should create or update the corresponding `*_file`.

``` r
config <- config::get()
config[c("recipients_script", "recipients_file", "data_script", "data_file")]
```

### Loading Recipients

[`rf_get_recipients()`](https://simonrolph.github.io/recorderFeedback/reference/rf_get_recipients.md)
runs the script defined in `recipients_script`. That script should write
a recipients table to `recipients_file`.

At minimum, recipients data should include:

- `recipient_id`
- `name`
- `email`

``` r
rf_get_recipients()
recipients <- read.csv(config$recipients_file)
knitr::kable(head(recipients))
```

### Loading Records

[`rf_get_data()`](https://simonrolph.github.io/recorderFeedback/reference/rf_get_data.md)
runs the script defined in `data_script`. That script should write your
raw records to `data_file`.

Your records must include `recipient_id` so each record can be linked to
a recipient.

``` r
rf_get_data()
records <- read.csv(config$data_file)
knitr::kable(head(records))
```

### Validate Inputs Early

Run validation immediately after loading data. This catches missing
files, missing columns, and recipient/data mismatches before rendering.

``` r
rf_verify_data(verbose = TRUE)
```

### Common First-Run Issues

- `Data file has not been updated`: your `scripts/get_data.R` script did
  not write to `config$data_file`.
- `Recipient file has not been updated`: your `scripts/get_recipients.R`
  script did not write to `config$recipients_file`.
- Missing column errors: ensure required columns are named exactly
  (`recipient_id`, `name`, `email`).

### Next Step

Once data loading works, continue to the “Generating Content” vignette
to render recipient-specific reports.
