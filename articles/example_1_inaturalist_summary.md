# Example: iNaturalist Summary

``` r
library(recorderFeedback)
```

## Overview

This end-to-end example shows how to use **recorderFeedback** with
iNaturalist data. It is written for new users, so each stage is
explicit: initialise project, load recipients, fetch observations,
render content, then distribute.

### What You Will Build

By the end you will have:

1.  A recipients table linked to iNaturalist user IDs.
2.  A records table fetched from the iNaturalist API.
3.  A simple personalised report template.
4.  One test render and one batch render.
5.  Optional SMTP dispatch.

## Setup

Initialise a project directory and read config:

``` r
rf_init("inaturalist_example")
config <- config::get()
```

Run subsequent commands from that project directory so relative paths in
`config.yml` are valid.

## Getting data

### Defining recipients

Recipients are individuals for whom feedback reports will be generated.
For this example, we manually define them in a script.

**File: `scripts/get_recipients.R`**

``` r
config <- config::get()
df <- data.frame(
  email = c("simon@example.com"),
  name = c("Simon"),
  recipient_id = c("1152941") # iNaturalist user ID
)
write.csv(df, config$recipients_file, row.names = FALSE)
```

Run the recipient script:

``` r
rf_get_recipients()
```

Inspect recipients:

``` r
read.csv(config$recipients_file)
```

### Collecting iNaturalist records

We now pull iNaturalist observations for each recipient over the last 30
days.

Install required packages if needed:

``` r
install.packages(c("httr", "jsonlite"))
```

**File: `scripts/get_data.R`**

``` r
library(httr)
library(jsonlite)

get_inat_observations <- function(user_id) {
  today <- Sys.Date()
  start_date <- today - 30
  
  base_url <- "https://api.inaturalist.org/v1/observations"
  query <- list(
    user_id = user_id,
    d1 = start_date,
    d2 = today,
    per_page = 30,
    order = "desc",
    order_by = "created_at"
  )
  
  response <- GET(base_url, query = query)
  stop_for_status(response)
  
  data <- content(response, as = "text", encoding = "UTF-8")
  obs <- fromJSON(data, flatten = TRUE)
  
  output <- obs$results[, c(
    "id",
    "user.id",
    "observed_on",
    "taxon.preferred_common_name",
    "taxon.name",
    "taxon.iconic_taxon_name"
  )]
  names(output) <- c(
    "record_id",
    "recipient_id",
    "date",
    "common_name",
    "scientific_name",
    "species_group"
  )
  
  return(output)
}

recipients <- read.csv(config$recipients_file)
observations <- data.frame()
for (i in seq_len(nrow(recipients))) {
  observations <- rbind(observations,
                        get_inat_observations(recipients$recipient_id[i]))
}

write.csv(observations, config$data_file, row.names = FALSE)
```

Run and verify:

``` r
rf_get_data()
```

``` r
rf_verify_data(verbose = TRUE)
```

## Generating content

### Creating a template

We build a simple R Markdown template that generates a personalized
summary for each recipient.

The template includes:

- Greeting with recipient name
- Count of unique species recorded
- A table of recent observations

(To keep this vignette self-contained, the template text is printed
directly.)

    #> ---
    #>  title: "iNaturalist Summary"
    #>  params:
    #>    recipient_name: ""
    #>    recipient_email: "UNKNOWN"
    #>    focal_data: ""
    #>    bg_data: ""
    #>    focal_computed_objects: ""
    #>    bg_computed_objects: ""
    #>    content_key: ""
    #>    config: ""
    #>    extra_params: ""
    #>  footer-date-time: "`r format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z')`"
    #>  recipient-email: "`r params$recipient_email`"
    #>  ---
    #>  
    #>  ```{r setup, include=FALSE}
    #>  knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE,
    #>                        fig.align = 'center', error = FALSE, results = 'asis')
    #>  ```
    #>  
    #>  # Hello `r params$recipient_name`!
    #>  
    #>  You have recorded `r length(unique(params$focal_data$scientific_name))` species recently!
    #>  
    #>  ```{r table}
    #>  table_data <- params$focal_data[, c('date', 'species_group', 'scientific_name', 'common_name')]
    #>  names(table_data) <- c('Date', 'Group', 'Species', 'Common name')
    #>  knitr::kable(table_data)
    #>  ```
    #>  
    #>  Best wishes,  
    #>  recorderFeedback

### Rendering

Render a single report for testing:

``` r
rf_render_single(recipient_id = "1152941")
```

Render for all recipients:

``` r
batch_id <- "vignette_demo"
rf_render_all(batch_id = batch_id)
rf_verify_batch(batch_id, verbose = TRUE)
```

## Distribution

Finally, send reports by email using configured SMTP settings. For first
tests, keep `test_mode: TRUE` in `config.yml`.

``` r
rf_dispatch_smtp(batch_id = batch_id)
```

## Troubleshooting

- No records returned: verify the iNaturalist `recipient_id` values are
  valid user IDs.
- API errors: rerun later or reduce request size while testing.
- Render failure: test with
  [`rf_render_single()`](https://simonrolph.github.io/recorderFeedback/reference/rf_render_single.md)
  and inspect the template chunk that fails.

## Summary

This vignette showed how to:

1.  Define recipients.
2.  Fetch their iNaturalist records via the API.
3.  Build a personalised R Markdown report.
4.  Render reports individually or in batch.
5.  Distribute them via email.

The **recorderFeedback** package provides a structured workflow for
automating ecological feedback loops such as iNaturalist activity
summaries.
