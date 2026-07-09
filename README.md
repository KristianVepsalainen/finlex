# finlex

<!-- badges: start -->
<!-- badges: end -->

**finlex** on osa **lexverse**-ekosysteemiä (vrt. tidyverse), joka tarjoaa
työkaluja avoimen lakidatan hakemiseen ja analysointiin. Tämä paketti hakee
dataa Suomen [Finlex Avoin data -rajapinnasta](https://opendata.finlex.fi).

## Asennus

```r
# install.packages("pak")
pak::pak("KristianVepsalainen/finlex")
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

## Using finlex commercially?

finlex is released under the MIT license, so you're free to use it in
commercial products and services with no obligation to ask permission.
That said, if you do use it commercially or in research, I'd genuinely
love to hear about it — drop a line at kristian.vepsalainen@proton.me.
It's not required, just appreciated.
