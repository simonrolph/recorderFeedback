# Create meta table for feedback batch

Generates a summary table of feedback files and recipients, and writes
it to disk.

## Usage

``` r
rf_make_meta_table(x, batch_id, recipient_data)
```

## Arguments

- x:

  A list or data frame of feedback results to summarize.

- batch_id:

  Character. Identifier for the feedback batch.

- recipient_data:

  Data frame. Recipient information to join.

## Value

Character. Path to the written meta table CSV file.
