# Package index

## Set up

- [`rf_init()`](https://simonrolph.github.io/recorderFeedback/reference/rf_init.md)
  : Initialise a recorder feedback project

## Getting Data

- [`rf_get_recipients()`](https://simonrolph.github.io/recorderFeedback/reference/rf_get_recipients.md)
  : Load recipient data
- [`rf_get_data()`](https://simonrolph.github.io/recorderFeedback/reference/rf_get_data.md)
  : Load raw data
- [`rf_verify_data()`](https://simonrolph.github.io/recorderFeedback/reference/rf_verify_data.md)
  : Verify data and recipient files

## Generating Content

- [`rf_render_single()`](https://simonrolph.github.io/recorderFeedback/reference/rf_render_single.md)
  : Render feedback for a single recipient
- [`rf_render_all()`](https://simonrolph.github.io/recorderFeedback/reference/rf_render_all.md)
  : Render feedback content for all recipients
- [`rf_view_content()`](https://simonrolph.github.io/recorderFeedback/reference/rf_view_content.md)
  : View rendered feedback for a recipient
- [`rf_verify_batch()`](https://simonrolph.github.io/recorderFeedback/reference/rf_verify_batch.md)
  : Verify a render batch

## Distributing Content

- [`rf_dispatch_smtp()`](https://simonrolph.github.io/recorderFeedback/reference/rf_dispatch_smtp.md)
  : Dispatch feedback via SMTP email

## Helper functions

Functions used internally within the package

- [`rf_make_meta_table()`](https://simonrolph.github.io/recorderFeedback/reference/rf_make_meta_table.md)
  : Create meta table for feedback batch
- [`rf_look_for_computed_objects()`](https://simonrolph.github.io/recorderFeedback/reference/rf_look_for_computed_objects.md)
  : Look in the R Markdown template and identify computed objects
  required in the code to render the template.
- [`rf_do_computations()`](https://simonrolph.github.io/recorderFeedback/reference/rf_do_computations.md)
  : Perform computations on data
- [`rf_render_content()`](https://simonrolph.github.io/recorderFeedback/reference/rf_render_content.md)
  : Render feedback content for all recipients
