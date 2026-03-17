# Render feedback content for all recipients

Generates personalized feedback documents for each recipient.

## Usage

``` r
rf_render_content(
  template_file,
  recipient_params,
  recipient_id,
  batch_id,
  email_format,
  template_html
)
```

## Arguments

- template_file:

  Character. RMarkdown file for template

- recipient_params:

  List. Parameters for the recipient

- recipient_id:

  Character. Identifier for the batch.

- batch_id:

  Character. Identifier for the batch.

- email_format:

  Function used as output format factory for
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

- template_html:

  Character. Template file for template

## Value

Path to rendered file.
