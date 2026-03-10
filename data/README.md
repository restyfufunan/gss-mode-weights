# Data

This directory is intentionally left empty. GSS data files cannot be redistributed.

## Download Instructions

1. Go to [https://gss.norc.org/get-the-data/stata](https://gss.norc.org/get-the-data/stata)
2. Download the **GSS Cumulative Data File (1972–2024), Release 2**
3. Place the `.dta` file in this directory and rename it `gss7224_r2.dta`

The expected path is defined in `00_setup.R`:

```r
GSS_DTA_PATH <- "gss7224_r2.dta"
```
