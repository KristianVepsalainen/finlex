# finlex 0.2.0

* `flx_get_text()`: get the full text of a statute, split into one row
  per section.
* `flx_get_doc()`: retrieve documents from the generic `doc` endpoint
  (treaties, government proposals, authority regulations, and certain
  collective agreements). Documents with no machine-readable text (only
  a scanned PDF) are reported with `status = "pdf_only"` and a `pdf_url`.
* `flx_get_consolidated_text()`: get the consolidated (up-to-date) text
  of a statute, with all amendments merged in.
* Added a package vignette covering all seven functions.

# finlex 0.1.0

* Initial CRAN release.
* `flx_download_statutes()`: download the catalogue of Finnish statutes for
  a given range of years and statute categories.
* `flx_get_title()`: get the official title of one or more statutes.
* `flx_get_metadata()`: get structured metadata (date issued, title, number
  of sections) for one or more statutes.
* `flx_get_affected()`: get the statute(s) affected by an amending or
  repealing statute.
