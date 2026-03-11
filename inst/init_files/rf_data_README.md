# Data Dictionary

Document your data schema so scripts and templates can be written correctly.

## recipients.csv

| column | type | description | example |
|---|---|---|---|
| recipient_id | integer | Unique recipient key used across all files. | 1001 |
| name | character | Recipient display name. | Alex Smith |
| email | character | Recipient email address. | alex@example.org |

## data.csv

| column | type | description | example |
|---|---|---|---|
| recipient_id | integer | Foreign key to `recipients.csv`. | 1001 |
| date | date | Observation date in `YYYY-MM-DD` format. | 2026-07-14 |
| species | character | Recorded species label. | Vanessa atalanta |
| count | integer | Number of individuals seen. | 3 |

## Notes

- Add every column used in `scripts/computation.R` and `templates/content.Rmd`.
- Include units, allowed values, and missing value conventions where relevant.
