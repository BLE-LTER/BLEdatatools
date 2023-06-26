# BLEdatatools

R package developed by BLE LTER information managers and graduate students to download and collate the Beaufort Lagoon Ecosystems LTER's Core Program data from the Environmental Data Initiative (EDI) repository. 

# Introduction

[BLE LTER](https://ble.lternet.edu) publishes its Core Program data across many data packages' "IDs" in the EDI repository. For example, different measurements, such as dissolved organic carbon (DOC) and concentrations of nutrients, done on the same container of water sampled from a Beaufort Sea lagoon, will be accessible from different places. While this serves our data publishing process well, it can be challenging for some of our data users who wants to see all the available data in one place. This package aims to provide a reproducible and trackable way to join the latest data according to time and location. 

We encourage users to use the functionality in this package as a jump start to their analysis, while still keeping track of the original datasets and keep an eye out for updates.

We recommend users: 

- Re-run the collation whenever there are updates to the underlying data packages, or whenever you start an analysis, to make sure you've got the latest versions.
- Do not use stale versions of files. Check the dates on your files.
- Check the collated data against the underlying data packages. By default, the outputs provide metadata that will help track down any particular number back to a published source on EDI. We try our best to preserve the numbers as-is from the originals, however in the case we have overlooked something, please refer to the published EDI source as authoritative instead of the collated data.
- Cite the underlying data packages in your publications and results. The outputs of this package are convenience products and should not be cited. The EDI datasets have DOIs and you can find suggested citations on the EDI website. Feel free to cite this R package if it has helped you, though. 

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

## Start here: the one-stop shop function

```r
collate()
```

This single function call queries EDI for the latest BLE LTER Core Program updates, downloads the relevant files, and finally collates the observations according to time and location to output two collated or "master" data sheets, one each of Core Program water and sediment data, plus dataset- and column-level metadata.

## Customizations

### Choosing specific datasets to include

`collate()` by default fetches and collates all water and sediment datasets from the Core Program.

Quick reference list of Core Program dataset IDs:
2: water column dissolved organic carbon (DOC), total dissolved nitrogen
3: CTD/TCM mooring data, YSI data (only YSI data is collated by this R package)
4: water column d18O
11: water column particulate organic matter (POM) carbon and nitrogen content, d13C and d15N
12: sediment pigment concentrations
13: water column chlorophyll
14: water column and sediment nutrient concentrations
18: sediment carbon and nitrogen content, d13C and d15N

You can also call `BLEdatatools::which_ids()` in the R console to quickly reference this list.

If you want to skip certain datasets, specify them by customizing the `ids` optional argument. If `ids` is present, only dataset IDs listed in the argument will be collated.

```r
collate(ids = c(2, 3, 4))
```

### Changing the output format

`collate()` by defaults outputs a R list object. Change the "output" optional argument to "excel" or "csv" to also write to file a multi-tab Excel file or multiple CSV files respectively. The file(s) will be written to the current working directory by default, or a directory you specify in the optional argument `path`. Output file names will contain the current date, for tracking purposes.

```r
collate(output = "excel", path = getwd())

# OR

collate(output = "csv", path = getwd())
```

### Changing certain behaviors

The nutrients (knb-lter-ble.14.1) started reporting two replicate measurements per sample in 2021. By default, `collate()` pivots these columns from long to a wider format to make the nutrients data more compatible with other Core Program datasets. Users have the option to change this behavior by changing the `avg_rep` argument to `collate()`. I've copied the documentation on `avg_rep` below

avg_rep (logical): TRUE/FALSE on whether to average replicates. This really only affects the nutrients dataset (knb-lter-ble.14) because this is the only dataset in consideration still retaining replicates in the published version. If FALSE, any data with replicates will be pivoted to a wider format, with the rep number appended to the new column names. E.g., two rows (reps 1 and 2) of one column "ammonium_umol_N_L" become one row of two columns "ammonium_umol_N_L_rep1" and "ammonium_umol_N_L_rep2". If TRUE, numeric columns will be averaged (NAs are ignored) and character columns will be collapsed into one string (e.g. if two replicates from the same sample have the flags VALID and BD, this becomes "VALID BD"). Note that in the original nutrients data, 2018-2019 reps are always NA, because we did not report replicates for these years. "NA" reps become rep 1 for the purposes of this package. Defaults to FALSE.

```r
collate(avg_rep = TRUE)
```

### Skipping metadata summary

`collate()` by default also outputs a summary of dataset- and column-level metadata to help you orient yourself in the dataset. Setting the optional function argument `skip_metadata = TRUE` will skip this step.

```r
collate(skip_metadata = TRUE)
```

Note that variable names in the metadata summaries will not correspond exactly to the order and names of the collated data columns. For example, "ammonium_umol_N_L" in metadata may become "ammonium_umol_N_L_rep1" and "ammonium_umol_N_L_rep2". You should be able to easily deduct which is which, though. This is because the metadata summaries is lifted wholesale, as-is from the metadata versions on EDI, while the data columns may undergo additional processing (such as described above).
