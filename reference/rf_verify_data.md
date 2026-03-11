# Verify data and recipient files

Checks that the raw data file and recipient file exist, are readable,
contain required columns, validates recipient IDs and emails, and can
optionally check recorder-analytics schema columns.

## Usage

``` r
rf_verify_data(
  verbose = FALSE,
  check_recorder_schema = FALSE,
  recorder_schema_cols = c("date", "species", "site"),
  recorder_schema_required = FALSE
)
```

## Arguments

- verbose:

  Logical, if TRUE prints number of records and recipients.

- check_recorder_schema:

  Logical. If TRUE, validate recorder schema columns.

- recorder_schema_cols:

  Character vector of optional recorder schema columns. Defaults to
  c("date", "species", "site").

- recorder_schema_required:

  Logical. If TRUE, missing recorder schema columns are treated as
  errors. If FALSE, missing columns trigger warnings.

## Value

Invisible TRUE if all checks pass, otherwise stops with an error.
