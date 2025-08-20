
# recorderFeedback

**recorderFeedback** is an R package for generating personalised,
data-driven feedback, originally designed for citizen science wildlife
recording but adaptable to other domains. The package provides tools to
set up a feedback workflow, load data, generate content, and distribute
feedback to recipients.

## Features

- **Project Initialisation**: Quickly scaffold a new feedback project
  with all necessary files and folders.
- **Data Loading**: Import recipient and observation data from
  configurable sources.
- **Computation**: Run custom analyses or summaries on your data before
  generating feedback.
- **Content Rendering**: Create personalised feedback documents for each
  recipient using RMarkdown templates.
- **Batch Processing**: Automate feedback generation for multiple
  recipients.
- **Email Dispatch**: Send feedback via email using SMTP.

Package functions are prefixed with `rf_`.

## Installation

Install from GitHub using `devtools`:

``` r
devtools::install_github("simonrolph/recorderFeedback")
```

## Quick Start

When you initialise a project with `rf_init()`, files are copied to set
up your workflow, ensuring you have all the necessary templates,
scripts, and configuration to get started quickly.

- `config.yml`: The central configuration file referenced in the README,
  where you set paths and options for your project.
- `scripts/computation.R`, `scripts/get_data.R`,
  `scripts/get_recipients.R`: Scripts for loading data, recipients, and
  running computations, matching the workflow steps outlined in the
  README.
- `templates/content.Rmd`, `templates/email_format.R`,
  `templates/template.html`: Templates for rendering the feedback and
  formatting emails
- `run_pipeline.R`, `_targets.R`: Pipeline orchestration scripts,
  supporting batch processing and automation

This diagram attempts to explain how it fits together:

``` mermaid
graph TD
    A[Data source] --> |"rf_get_recipients()<br>config$recipients_script" | B["Recipient data (.csv)"<br>config$recipient_file]
    C[Data source] --> |"rf_get_data()<br>config$data_script" | D["Records data(.csv)"<br>config$data_file]
    F["Templates<br>config$content_template_file<br>config$html_template_file"] --> E
    H["Computation scripts<br>config$computation_script_focal<br>config$computation_script_background"] --> E
    B --> E("{Targets} pipeline<br>_targets.R")
    D --> E
    E --> |"rf_generate()"| G[Batch content and meta data<br>.html files]
    G --> |"rf_dispatch_smtp()"| J[Feedback received by recipients]
```

Key terms:

- Recipient: someone to receive feedback
- Focal/background: whether the data relates to the recipient (focal),
  or not (background)
- Template: a RMarkdown document defining how the data is manipulated
  and visualised
- Computations: calculations or other processing done on the raw data
  prior to rendering them template

``` r
library(recorderFeedback)

#initialise a new project
rf_init(path = "example")
```

    ## Created folder: example/data

    ##   Added .gitignore to: example/data

    ## Created folder: example/templates

    ## Created folder: example/renders

    ## Created folder: example/scripts

    ## Created folder: example/scripts/extras

    ##   Added .gitignore to: example/scripts/extras

    ## Working directory set to: C:/Users/simrol/OneDrive - UKCEH/R_onedrive/R_2025/recorderFeedback/example

``` r
config <- config::get()

#get recipients
rf_get_recipients()
```

    ## [1] "Recipient file has been updated"

``` r
knitr::kable(head(read.csv(config$recipients_file)))
```

| email               | name  | recipient_id |
|:--------------------|:------|-------------:|
| <alice@example.com> | Alice |            1 |
| <bob@example.com>   | Bob   |            2 |
| <carol@example.com> | Carol |            3 |
| <dave@example.com>  | Dave  |            4 |
| <eve@example.com>   | Eve   |            5 |

``` r
#get data
rf_get_data()
```

    ## [1] "Data file has been updated"

``` r
knitr::kable(head(read.csv(config$data_file)))
```

| recipient_id | latitude |  longitude | species             | species_vernacular |
|-------------:|---------:|-----------:|:--------------------|:-------------------|
|            1 | 53.96196 |  0.1651712 | Vulpes vulpes       | Red Fox            |
|            2 | 53.77311 | -0.4897633 | Meles meles         | Badger             |
|            3 | 53.79761 |  0.6105198 | Meles meles         | Badger             |
|            4 | 53.89003 |  0.2078202 | Erinaceus europaeus | Hedgehog           |
|            5 | 53.73566 |  0.5859544 | Vulpes vulpes       | Red Fox            |
|            1 | 53.07644 |  0.5836285 | Vulpes vulpes       | Red Fox            |

``` r
#verify the data is all good
rf_verify_data(T)
```

    ## Number of data records: 20

    ## Number of recipients: 5

    ## Data and recipients verification complete: no blocking errors found.

``` r
#render a single feedback item
rf_render_single(recipient_id = 1)
```

    ## [1] "renders/singles/content_1_2025-08-20.html"

``` r
# run the pipeline
batch_id <- "test_batch"
rf_render_all(batch_id)
```

    ## + template_file dispatched
    ## ✔ template_file completed [450ms, 1.20 kB]
    ## + html_template_file dispatched
    ## ✔ html_template_file completed [0ms, 2.28 kB]
    ## + recipients_target dispatched
    ## ✔ recipients_target completed [0ms, 213 B]
    ## + raw_data_file dispatched
    ## ✔ raw_data_file completed [0ms, 1.39 kB]
    ## + computation_file dispatched
    ## ✔ computation_file completed [0ms, 1.17 kB]
    ## + computation_file_focal dispatched
    ## ✔ computation_file_focal completed [0ms, 1.17 kB]
    ## + raw_data dispatched
    ## ✔ raw_data completed [0ms, 605 B]
    ## + bg_computed_objects dispatched
    ## ✔ bg_computed_objects completed [0ms, 78 B]
    ## + recipient_objects_1 dispatched
    ## ✔ recipient_objects_1 completed [0ms, 392 B]
    ## + recipient_objects_2 dispatched
    ## ✔ recipient_objects_2 completed [0ms, 424 B]
    ## + recipient_objects_3 dispatched
    ## ✔ recipient_objects_3 completed [20ms, 417 B]
    ## + recipient_objects_4 dispatched
    ## ✔ recipient_objects_4 completed [0ms, 413 B]
    ## + recipient_objects_5 dispatched
    ## ✔ recipient_objects_5 completed [0ms, 415 B]
    ## + data_story_content_1 dispatched
    ## ✔ data_story_content_1 completed [1.8s, 3.46 kB]
    ## + data_story_content_2 dispatched
    ## ✔ data_story_content_2 completed [1.2s, 3.60 kB]
    ## + data_story_content_3 dispatched
    ## ✔ data_story_content_3 completed [1.2s, 3.60 kB]
    ## + data_story_content_4 dispatched
    ## ✔ data_story_content_4 completed [1.2s, 3.60 kB]
    ## + data_story_content_5 dispatched
    ## ✔ data_story_content_5 completed [1.2s, 3.59 kB]
    ## + meta_data_1 dispatched
    ## ✔ meta_data_1 completed [0ms, 172 B]
    ## + meta_data_2 dispatched
    ## ✔ meta_data_2 completed [0ms, 175 B]
    ## + meta_data_3 dispatched
    ## ✔ meta_data_3 completed [0ms, 172 B]
    ## + meta_data_4 dispatched
    ## ✔ meta_data_4 completed [0ms, 174 B]
    ## + meta_data_5 dispatched
    ## ✔ meta_data_5 completed [0ms, 174 B]
    ## + meta_table dispatched
    ## ✔ meta_table completed [20ms, 653 B]
    ## ✔ ended pipeline [9.2s, 24 completed, 0 skipped]
    ## Warning messages:
    ## 1: package 'targets' was built under R version 4.5.1 
    ## 2: package 'tarchetypes' was built under R version 4.5.1 
    ## 3: package 'assertr' was built under R version 4.5.1 
    ## 4: package 'lubridate' was built under R version 4.5.1 
    ## 5: 1 targets produced warnings. Run targets::tar_meta(fields = warnings, complete_only = TRUE) for the messages. 

``` r
#view the meta table
meta_table <- read.csv(file.path("renders",batch_id,"/meta_table.csv"))
knitr::kable(head(meta_table))
```

| recipient_id | file | content_key | email | name | batch_id |
|---:|:---|:---|:---|:---|:---|
| 1 | renders/test_batch/content_1_2025-08-20.html | test_batchax197s7f4rqb2o1k | <alice@example.com> | Alice | test_batch |
| 2 | renders/test_batch/content_2_2025-08-20.html | test_batchj3rqrqww63pyq21h | <bob@example.com> | Bob | test_batch |
| 3 | renders/test_batch/content_3_2025-08-20.html | test_batchq9zryyeo3ynmubf2 | <carol@example.com> | Carol | test_batch |
| 4 | renders/test_batch/content_4_2025-08-20.html | test_batchw9u37ang7eij7jd9 | <dave@example.com> | Dave | test_batch |
| 5 | renders/test_batch/content_5_2025-08-20.html | test_batch8x65335n14ojgtxe | <eve@example.com> | Eve | test_batch |

``` r
#verify the batch
rf_verify_batch(batch_id)
```

    ## Batch verification complete: no blocking errors found.

``` r
#view content
#rf_view_content(batch_id = batch_id,recipient_id = 3)

#send the emails
#rf_dispatch_smtp(batch_id)
```

## Handling errors

If rendering a template fails the pipeline will continue, but you won’t
have a `.html` file in the designated `renders/[batch_id]` folder. Using
`rf_verify_batch()` will show you for which recipients the rendering
failed. Using `targets::tar_meta(fields = "error")` will also tell you
which targets failed and the corresponding error messages. Use
`render_single(recipient_id)` to render an individual feedback item and
view the detailed error message that is shown.
