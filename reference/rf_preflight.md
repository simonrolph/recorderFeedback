# Preflight validation before render or dispatch

Runs early checks to fail fast before expensive render or email steps.

## Usage

``` r
rf_preflight(
  stage = c("render", "dispatch"),
  batch_id = NULL,
  verbose = TRUE,
  check_recorder_schema = TRUE,
  recorder_schema_cols = c("date", "species", "site"),
  recorder_schema_required = FALSE
)
```

## Arguments

- stage:

  Character. One of \`"render"\` or \`"dispatch"\`.

- batch_id:

  Character. Required when \`stage = "dispatch"\`.

- verbose:

  Logical. If TRUE, prints progress messages.

- check_recorder_schema:

  Logical. Passed to \[rf_verify_data()\].

- recorder_schema_cols:

  Character vector of recorder schema columns.

- recorder_schema_required:

  Logical. Passed to \[rf_verify_data()\].

## Value

Invisible TRUE if all checks pass, otherwise stops with an error.
