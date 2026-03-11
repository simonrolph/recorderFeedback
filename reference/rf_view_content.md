# View rendered feedback for a recipient

Opens the rendered HTML file for a specific recipient and batch in the
system's default browser.

## Usage

``` r
rf_view_content(batch_id, recipient_id = NULL)
```

## Arguments

- batch_id:

  Character. The feedback batch identifier.

- recipient_id:

  Character or numeric. The recipient's ID.

## Value

Invisible TRUE if file is opened successfully, otherwise stops with an
error.
