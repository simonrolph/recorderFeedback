# Verify a render batch

Checks that the rendered items match the recipient data and meta table.

## Usage

``` r
rf_verify_batch(batch_id, verbose = FALSE)
```

## Arguments

- batch_id:

  Character. Identifier for the batch to verify.

- verbose:

  Logical, if TRUE prints summary info.

## Value

Invisible TRUE if all checks pass, otherwise stops or warns.
