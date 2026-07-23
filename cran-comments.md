## R CMD check results

0 errors | 0 warnings | 1 note

* Possibly misspelled word in DESCRIPTION: "tibbles" -- this is correct
  (plural of the tibble data structure from the tidyverse).

## This is a package update

New in this version (0.2.0):

* `flx_get_text()`: full statute text, split into sections.
* `flx_get_doc()`: retrieve treaties, government proposals, authority
  regulations, and certain collective agreements.
* `flx_get_consolidated_text()`: consolidated (up-to-date) statute text.
* Added a package vignette.

No breaking changes to the existing exported functions
(`flx_download_statutes()`, `flx_get_title()`, `flx_get_metadata()`,
`flx_get_affected()`).

## Test environments

* local: Fedora Linux 44, R 4.6.1
* win-builder (R-devel)
* R-hub v2: Linux (R-devel), Windows (R-devel), macOS arm64 (R-devel)
