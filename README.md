
# recorderFeedback

**recorderFeedback** is an R package for generating personalised,
data-driven feedback, originally designed for citizen science wildlife
recording but adaptable to other domains. The package provides tools to
set up a feedback workflow, load data, generate content, and distribute
feedback to recipients.

## Features

- **Project Initialisation**: Quickly scaffold a new feedback project
  with all necessary files and folders.
- **Data Loading**: Import recipient and observation data from
  configurable sources.
- **Computation**: Run custom analyses or summaries on your data before
  generating feedback.
- **Content Rendering**: Create personalised feedback documents for each
  recipient using RMarkdown templates.
- **Batch Processing**: Automate feedback generation for multiple
  recipients.
- **Email Dispatch**: Send feedback via email using SMTP.

Package functions are prefixed with `rf_`.

## Installation

Install from GitHub using `devtools`:

``` r
devtools::install_github("yourusername/recorderFeedback")
```

## Quick Start

``` r
library(recorderFeedback)

#initialise a new project
rf_init(path = "example")
```

    ## Created folder: example/data

    ##   Added .gitignore to: example/data

    ## Created folder: example/templates

    ## Created folder: example/renders

    ## Created folder: example/scripts

    ## Created folder: example/scripts/extras

    ##   Added .gitignore to: example/scripts/extras

    ## Working directory set to: C:/Users/simrol/OneDrive - UKCEH/R_onedrive/R_2025/recorderFeedback/example

``` r
config <- config::get()

#get recipients
rf_get_recipients()
```

    ## [1] "Recipient file has been updated"

``` r
knitr::kable(head(read.csv(config$recipients_file)))
```

| email               | name  | recipient_id |
|:--------------------|:------|-------------:|
| <alice@example.com> | Alice |            1 |
| <bob@example.com>   | Bob   |            2 |
| <carol@example.com> | Carol |            3 |
| <dave@example.com>  | Dave  |            4 |
| <eve@example.com>   | Eve   |            5 |

``` r
#get data
rf_get_data()
```

    ## [1] "Data file has been updated"

``` r
knitr::kable(head(read.csv(config$data_file)))
```

| recipient_id | latitude |  longitude | species             | species_vernacular |
|-------------:|---------:|-----------:|:--------------------|:-------------------|
|            1 | 53.96196 |  0.1651712 | Vulpes vulpes       | Red Fox            |
|            2 | 53.77311 | -0.4897633 | Meles meles         | Badger             |
|            3 | 53.79761 |  0.6105198 | Meles meles         | Badger             |
|            4 | 53.89003 |  0.2078202 | Erinaceus europaeus | Hedgehog           |
|            5 | 53.73566 |  0.5859544 | Vulpes vulpes       | Red Fox            |
|            1 | 53.07644 |  0.5836285 | Vulpes vulpes       | Red Fox            |

``` r
#verify the data is all good
rf_verify_data(T)
```

    ## Number of data records: 20

    ## Number of recipients: 5

    ## Data and recipients verification complete: no blocking errors found.

``` r
#render a single feedback item
rf_render_single(recipient_id = 1)
```

    ## [1] "renders/singles/content_1_2025-08-15.html"

``` r
# run the pipeline
batch_id <- "test_batch"
rf_generate(batch_id)
```

    ## + template_file dispatched
    ## ✔ template_file completed [330ms, 796 B]
    ## + html_template_file dispatched
    ## ✔ html_template_file completed [0ms, 2.28 kB]
    ## + recipients_target dispatched
    ## ✔ recipients_target completed [0ms, 213 B]
    ## + raw_data_file dispatched
    ## ✔ raw_data_file completed [0ms, 1.39 kB]
    ## + computation_file dispatched
    ## ✔ computation_file completed [0ms, 262 B]
    ## + computation_file_focal dispatched
    ## ✔ computation_file_focal completed [0ms, 262 B]
    ## + raw_data dispatched
    ## ✔ raw_data completed [0ms, 605 B]
    ## + bg_computed_objects dispatched
    ## ✔ bg_computed_objects completed [20ms, 44 B]
    ## + recipient_objects_1 dispatched
    ## ✔ recipient_objects_1 completed [0ms, 378 B]
    ## + recipient_objects_2 dispatched
    ## ✔ recipient_objects_2 completed [0ms, 412 B]
    ## + recipient_objects_3 dispatched
    ## ✔ recipient_objects_3 completed [0ms, 407 B]
    ## + recipient_objects_4 dispatched
    ## ✔ recipient_objects_4 completed [0ms, 402 B]
    ## + recipient_objects_5 dispatched
    ## ✔ recipient_objects_5 completed [0ms, 403 B]
    ## + data_story_content_1 dispatched
    ## ✔ data_story_content_1 completed [1.1s, 3.39 kB]
    ## + data_story_content_2 dispatched
    ## ✔ data_story_content_2 completed [790ms, 3.53 kB]
    ## + data_story_content_3 dispatched
    ## ✔ data_story_content_3 completed [940ms, 3.54 kB]
    ## + data_story_content_4 dispatched
    ## ✔ data_story_content_4 completed [1.2s, 3.53 kB]
    ## + data_story_content_5 dispatched
    ## ✔ data_story_content_5 completed [1.2s, 3.52 kB]
    ## + meta_data_1 dispatched
    ## ✔ meta_data_1 completed [0ms, 172 B]
    ## + meta_data_2 dispatched
    ## ✔ meta_data_2 completed [0ms, 175 B]
    ## + meta_data_3 dispatched
    ## ✔ meta_data_3 completed [0ms, 172 B]
    ## + meta_data_4 dispatched
    ## ✔ meta_data_4 completed [0ms, 174 B]
    ## + meta_data_5 dispatched
    ## ✔ meta_data_5 completed [0ms, 174 B]
    ## + meta_table dispatched
    ## ✔ meta_table completed [20ms, 653 B]
    ## ✔ ended pipeline [7.2s, 24 completed, 0 skipped]
    ## Warning messages:
    ## 1: package 'targets' was built under R version 4.5.1 
    ## 2: package 'tarchetypes' was built under R version 4.5.1 
    ## 3: package 'assertr' was built under R version 4.5.1 
    ## 4: package 'lubridate' was built under R version 4.5.1 
    ## 5: 1 targets produced warnings. Run targets::tar_meta(fields = warnings, complete_only = TRUE) for the messages. 

``` r
#view the meta table
meta_table <- read.csv(file.path("renders",batch_id,"/meta_table.csv"))
knitr::kable(head(meta_table))
```

| recipient_id | file | content_key | email | name | batch_id |
|---:|:---|:---|:---|:---|:---|
| 1 | renders/test_batch/content_1_2025-08-15.html | test_batchax197s7f4rqb2o1k | <alice@example.com> | Alice | test_batch |
| 2 | renders/test_batch/content_2_2025-08-15.html | test_batchj3rqrqww63pyq21h | <bob@example.com> | Bob | test_batch |
| 3 | renders/test_batch/content_3_2025-08-15.html | test_batchq9zryyeo3ynmubf2 | <carol@example.com> | Carol | test_batch |
| 4 | renders/test_batch/content_4_2025-08-15.html | test_batchw9u37ang7eij7jd9 | <dave@example.com> | Dave | test_batch |
| 5 | renders/test_batch/content_5_2025-08-15.html | test_batch8x65335n14ojgtxe | <eve@example.com> | Eve | test_batch |

``` r
#verify the batch
rf_verify_batch(batch_id)
```

    ## Batch verification complete: no blocking errors found.

``` r
#view content
#rf_view_content(batch_id = batch_id,recipient_id = 3)

#peer into the contents of one of the renders
print(readLines(meta_table$file[1]))
```

    ##   [1] "<!DOCTYPE html>"                                                                                                                                               
    ##   [2] "<html>"                                                                                                                                                        
    ##   [3] "<head>"                                                                                                                                                        
    ##   [4] "<meta charset=\"utf-8\"> <!-- utf-8 works for most cases -->"                                                                                                  
    ##   [5] "<meta name=\"viewport\" content=\"width=device-width\"> <!-- Forcing initial-scale shouldn't be necessary -->"                                                 
    ##   [6] "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"> <!-- Use the latest (edge) version of IE rendering engine -->"                                       
    ##   [7] "<meta name=\"x-apple-disable-message-reformatting\">  <!-- Disable auto-scale in iOS 10 Mail entirely -->"                                                     
    ##   [8] "<meta name=\"format-detection\" content=\"telephone=no,address=no,email=no,date=no,url=no\"> <!-- Tell iOS not to automatically link certain text strings. -->"
    ##   [9] "<meta name=\"color-scheme\" content=\"light\">"                                                                                                                
    ##  [10] "<meta name=\"supported-color-schemes\" content=\"light\">"                                                                                                     
    ##  [11] "<!-- What it does: Makes background images in 72ppi Outlook render at correct size. -->"                                                                       
    ##  [12] "<!--[if gte mso 9]>"                                                                                                                                           
    ##  [13] "<xml>"                                                                                                                                                         
    ##  [14] "<o:OfficeDocumentSettings>"                                                                                                                                    
    ##  [15] "<o:AllowPNG/>"                                                                                                                                                 
    ##  [16] "<o:PixelsPerInch>96</o:PixelsPerInch>"                                                                                                                         
    ##  [17] "</o:OfficeDocumentSettings>"                                                                                                                                   
    ##  [18] "</xml>"                                                                                                                                                        
    ##  [19] "<![endif]-->"                                                                                                                                                  
    ##  [20] "<title>Recorder Feedback Example Email</title>"                                                                                                                
    ##  [21] "<style>"                                                                                                                                                       
    ##  [22] "body {"                                                                                                                                                        
    ##  [23] "font-family: Helvetica, sans-serif;"                                                                                                                           
    ##  [24] "font-size: 16px;"                                                                                                                                              
    ##  [25] "}"                                                                                                                                                             
    ##  [26] ".content {"                                                                                                                                                    
    ##  [27] "background-color: white;"                                                                                                                                      
    ##  [28] "}"                                                                                                                                                             
    ##  [29] ".content .message-block {"                                                                                                                                     
    ##  [30] "margin-bottom: 24px;"                                                                                                                                          
    ##  [31] "}"                                                                                                                                                             
    ##  [32] ".header .message-block, .footer message-block {"                                                                                                               
    ##  [33] "margin-bottom: 12px;"                                                                                                                                          
    ##  [34] "}"                                                                                                                                                             
    ##  [35] "img {"                                                                                                                                                         
    ##  [36] "max-width: 100%;"                                                                                                                                              
    ##  [37] "}"                                                                                                                                                             
    ##  [38] "@media only screen and (max-width: 767px) {"                                                                                                                   
    ##  [39] ".container {"                                                                                                                                                  
    ##  [40] "width: 100%;"                                                                                                                                                  
    ##  [41] "}"                                                                                                                                                             
    ##  [42] ".articles, .articles tr, .articles td {"                                                                                                                       
    ##  [43] "display: block;"                                                                                                                                               
    ##  [44] "width: 100%;"                                                                                                                                                  
    ##  [45] "}"                                                                                                                                                             
    ##  [46] ".article {"                                                                                                                                                    
    ##  [47] "margin-bottom: 24px;"                                                                                                                                          
    ##  [48] "}"                                                                                                                                                             
    ##  [49] "}"                                                                                                                                                             
    ##  [50] "</style>"                                                                                                                                                      
    ##  [51] "</head>"                                                                                                                                                       
    ##  [52] "<body style=\"background-color:#f6f6f6;font-family:Helvetica, sans-serif;color:#222;margin:0;padding:0;\">"                                                    
    ##  [53] "<table width=\"96%\" align=\"center\" class=\"container\" style=\"max-width:660px\">"                                                                          
    ##  [54] "<tr>"                                                                                                                                                          
    ##  [55] "<td style=\"padding:24px;\">"                                                                                                                                  
    ##  [56] "<div class=\"header\" style=\"font-family:Helvetica, sans-serif;color:#999999;font-size:12px;font-weight:normal;margin:0 0 24px 0;text-align:center;\">"       
    ##  [57] "Personalised feedback prototype"                                                                                                                               
    ##  [58] ""                                                                                                                                                              
    ##  [59] "</div>"                                                                                                                                                        
    ##  [60] ""                                                                                                                                                              
    ##  [61] "<table width=\"100%\" class=\"content\" style=\"background-color:white;\">"                                                                                    
    ##  [62] "<tr>"                                                                                                                                                          
    ##  [63] "<td style=\"padding:12px;\"><div id=\"hello-alice\" class=\"section level1\">"                                                                                 
    ##  [64] "<h1>Hello Alice!</h1>"                                                                                                                                         
    ##  [65] "<p>Look at your data:</p>"                                                                                                                                     
    ##  [66] "<table>"                                                                                                                                                       
    ##  [67] "<thead>"                                                                                                                                                       
    ##  [68] "<tr class=\"header\">"                                                                                                                                         
    ##  [69] "<th align=\"right\">recipient_id</th>"                                                                                                                         
    ##  [70] "<th align=\"right\">latitude</th>"                                                                                                                             
    ##  [71] "<th align=\"right\">longitude</th>"                                                                                                                            
    ##  [72] "<th align=\"left\">species</th>"                                                                                                                               
    ##  [73] "<th align=\"left\">species_vernacular</th>"                                                                                                                    
    ##  [74] "</tr>"                                                                                                                                                         
    ##  [75] "</thead>"                                                                                                                                                      
    ##  [76] "<tbody>"                                                                                                                                                       
    ##  [77] "<tr class=\"odd\">"                                                                                                                                            
    ##  [78] "<td align=\"right\">1</td>"                                                                                                                                    
    ##  [79] "<td align=\"right\">53.96196</td>"                                                                                                                             
    ##  [80] "<td align=\"right\">0.1651712</td>"                                                                                                                            
    ##  [81] "<td align=\"left\">Vulpes vulpes</td>"                                                                                                                         
    ##  [82] "<td align=\"left\">Red Fox</td>"                                                                                                                               
    ##  [83] "</tr>"                                                                                                                                                         
    ##  [84] "<tr class=\"even\">"                                                                                                                                           
    ##  [85] "<td align=\"right\">1</td>"                                                                                                                                    
    ##  [86] "<td align=\"right\">53.07644</td>"                                                                                                                             
    ##  [87] "<td align=\"right\">0.5836285</td>"                                                                                                                            
    ##  [88] "<td align=\"left\">Vulpes vulpes</td>"                                                                                                                         
    ##  [89] "<td align=\"left\">Red Fox</td>"                                                                                                                               
    ##  [90] "</tr>"                                                                                                                                                         
    ##  [91] "<tr class=\"odd\">"                                                                                                                                            
    ##  [92] "<td align=\"right\">1</td>"                                                                                                                                    
    ##  [93] "<td align=\"right\">53.16806</td>"                                                                                                                             
    ##  [94] "<td align=\"right\">-0.0963481</td>"                                                                                                                           
    ##  [95] "<td align=\"left\">Meles meles</td>"                                                                                                                           
    ##  [96] "<td align=\"left\">Badger</td>"                                                                                                                                
    ##  [97] "</tr>"                                                                                                                                                         
    ##  [98] "<tr class=\"even\">"                                                                                                                                           
    ##  [99] "<td align=\"right\">1</td>"                                                                                                                                    
    ## [100] "<td align=\"right\">53.23645</td>"                                                                                                                             
    ## [101] "<td align=\"right\">0.9453273</td>"                                                                                                                            
    ## [102] "<td align=\"left\">Vulpes vulpes</td>"                                                                                                                         
    ## [103] "<td align=\"left\">Red Fox</td>"                                                                                                                               
    ## [104] "</tr>"                                                                                                                                                         
    ## [105] "</tbody>"                                                                                                                                                      
    ## [106] "</table>"                                                                                                                                                      
    ## [107] "<p>Best wishes, recorderFeedback</p>"                                                                                                                          
    ## [108] "</div></td>"                                                                                                                                                   
    ## [109] "</tr>"                                                                                                                                                         
    ## [110] "</table>"                                                                                                                                                      
    ## [111] "<div class=\"footer\" style=\"font-family:Helvetica, sans-serif;color:#999999;font-size:12px;font-weight:normal;margin:24px 0 0 0;\">"                         
    ## [112] "<p>This message was generated for  on 2025-08-15 17:07:59 BST.</p>"                                                                                            
    ## [113] ""                                                                                                                                                              
    ## [114] "</div>"                                                                                                                                                        
    ## [115] "</td>"                                                                                                                                                         
    ## [116] "</tr>"                                                                                                                                                         
    ## [117] "</table>"                                                                                                                                                      
    ## [118] "</body>"                                                                                                                                                       
    ## [119] "</html>"

``` r
#send the emails
#rf_dispatch_smtp(batch_id)
```

## Workflow Overview

1.  **Initialise Project**: Use `rf_init()` to create a new project
    structure.
2.  **Configure**: Edit the configuration file to set paths and options.
3.  **Load Data**: Import recipients and data using provided functions.
4.  **Compute**: Optionally process data for summaries or statistics.
5.  **Render Feedback**: Generate personalised feedback documents.
6.  **Distribute**: Send feedback via email or other channels.

## Key terms:

- Recipient: someone to receive feedback
- Focal/background: whether the data relates to the recipient (focal),
  or not (background)
- Template: a RMarkdown document defining how the data is manipulated
  and visualised
- Computations: calculations or other processing done on the raw data
  prior to rendering them template

## Configuration

### General

`config.yml`

### Data sources (recipients)

`scripts/get_recipients.R`

### Data sources (records)

`scripts/get_data.R`

### Content (R)

`templates/content.Rmd` `templates/email_format.R`

### Look and feel (HTML+CSS)

`templates/template.html`

### Pipeline

`_targets.R` `run_pipeline.R`
