# finlex

<!-- badges: start -->
<!-- badges: end -->

**finlex** on osa **lexverse**-ekosysteemiä (vrt. tidyverse), joka tarjoaa
työkaluja avoimen lakidatan hakemiseen ja analysointiin. Tämä paketti hakee
dataa Suomen [Finlex Avoin data -rajapinnasta](https://opendata.finlex.fi).

## Asennus

```r
# install.packages("pak")
pak::pak("kristianvepsalainen/finlex")
```

## Käyttö

```r
library(finlex)

# Kaikki vuonna 2023 annetut uudet säädökset
flx_download_statutes(start_year = 2023, end_year = 2023,
                       categories = "new-statute")
```

## Tila

Paketti on hyvin varhaisessa kehitysvaiheessa (0.0.0.9000). Ensimmäinen
tavoite on saada perustoiminnallisuus CRAN-kelpoiseksi.
