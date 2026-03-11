# Verify data and recipient files

Checks that the raw data file and recipient file exist, are readable,
contain the required columns, and optionally prints summary info.

## Usage

``` r
rf_verify_data(verbose = FALSE)
```

## Arguments

- verbose:

  Logical, if TRUE prints number of records and recipients.

## Value

Invisible TRUE if all checks pass, otherwise stops with an error.
