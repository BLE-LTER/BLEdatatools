#### Example workflow for calculating CDOM indicies

## Load packages ----

library(BLEdatatools)
library(tidyr)
library(purrr)
library(devtools)

# to install CDOMtools package run:
# devtools::install_github("bristol-emily/CDOMtools", build_vignettes = TRUE)

library(CDOMtools)

## Read in CDOM spectra from EDI ----

spectra <- download_data(identifier = 15, # from this BLEdatatools package
                         entity_number = 1)

# rename columns more conciscely
colnames(spectra)[7] <- "wl"
colnames(spectra)[8] <- "abs"

# nest spectra data so that there is one row per sample
cdom <- tidyr::nest(spectra,
                    spectra = c("wl", "abs"))

## Save the absorption coefficients in the nested list
cdom_indicies <- cdom %>%
  mutate(a250 = purrr::map_dbl(spectra, ~{.x$abs[which (.x$wl == 250)]}),
         A254 = purrr::map_dbl(spectra, ~{.x$abs[which (.x$wl == 254)]}) / 2.303, # convert to decadic units for SUVA calculation
         a350 = purrr::map_dbl(spectra, ~{.x$abs[which (.x$wl == 350)]}),
         a375 = purrr::map_dbl(spectra, ~{.x$abs[which (.x$wl == 365)]}),
         S_275_295 = purrr::map_dbl(spectra,
                             ~{CDOMtools::calc_spectral_slope(wavelength = .$wl,
                                                   absorption = .$abs,
                                                   start = 275,
                                                   end = 295,
                                                   limit_of_quantification = 0.005)}),
         S_R = purrr::map_dbl(spectra,
                       ~{CDOMtools::calc_slope_ratio(wavelength = .$wl,
                                                     absorption = .$abs,
                                                     limit_of_quantification = 0.005)}))

# remove nested spectra
cdom_indicies$spectra <- NULL


# Note: to calculate SUVA_254, devide A254 by DOC concentration in mg C/L


