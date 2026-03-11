# Look in the R Markdown template and identify computed objects required in the code to render the template.

This function reads an R Markdown template file and identifies computed
objects used in the code. It specifically looks for background computed
objects (\`params\$bg_computed_objects\$\`) and user computed objects
(\`params\$user_computed_objects\$\`).

## Usage

``` r
rf_look_for_computed_objects(file_path_to_template)
```

## Arguments

- file_path_to_template:

  The file path to the R Markdown template.

## Value

A list containing two elements:

- `bg_computed_objects`: A character vector representing unique computed
  objects following "params\$bg_computed_objects\$".

- `user_computed_objects`: A character vector representing unique
  computed objects following "params\$user_computed_objects\$".
