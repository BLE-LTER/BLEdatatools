# BLEdatatools
R package to download and collate BLE LTER data from the Environmental Data Initiative repository

# Installation

```r
# install the package from GitHub
remotes::install_github("BLE-LTER/BLEdatatools")
```

Restart the R session by selecting Session/Restart R in the RStudio Menu bar or pressing Ctrl+Shift+F10. 

```r
# load the package into the active R session
library(BLEdatatools)
```

# Usage

## One stop shop

```r
collate()
```

This single function call queries EDI for the latest BLE LTER Core Program updates, downloads the relevant files, and finally collates the observations according to time and location to output a collated or "master" data sheet of Core Program water and sediment data. 

## Customizing collated data output

### Skipping metadata summary

`collate()` by default also outputs a summary of dataset- and column-level metadata to help you orient yourself in the dataset. Setting the optional function argument `skip_metadata = TRUE` will skip this step.

```r
collate(skip_metadata = TRUE)
```

### Choosing specific datasets to include

`collate()` by default fetches and collates all water and sediment datasets from the Core Program.

Here is a list:

If you want to skip certain datasets, specify them by customizing the `ids` optional argument. If `ids` is present, only dataset IDs listed in the argument will be collated.

```r
collate(ids = c(2, 3, 4))
```

### Changing the output format

`collate()` by defaults outputs a R list object. Change the "output" optional argument to "excel" or "csv" to also write to file a multi-tab Excel file or multiple CSV files respectively. The file(s) will be written to the current working directory by default, or a directory you specify in the optional argument `path`.

```r
collate(output = "excel", path = getwd())
```
