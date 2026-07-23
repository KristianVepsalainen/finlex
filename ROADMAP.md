# Roadmap to finlex 1.0.0

Status as of 2026-07-20: v0.1.0 on CRAN. Seven functions built (four more
than what's on CRAN): `flx_download_statutes()`, `flx_get_title()`,
`flx_get_metadata()`, `flx_get_affected()`, `flx_get_text()`,
`flx_get_doc()`, `flx_get_consolidated_text()`. Vignette in place.

This document tracks what's left before calling finlex 1.0 -- the point at
which the public API is considered stable and users can rely on it not
changing in breaking ways.

## A. Function coverage

- [x] `flx_get_consolidated_text()` -- the *ajantasainen* (consolidated,
  always-current) version of a statute, using `actDocumentType =
  "statute-consolidated"` with `langAndVersion = "fin@latest"` (the
  temporal version must be given explicitly for consolidated text, unlike
  the original as-enacted text, which resolves fine with plain `fin@`).
  Done 2026-07-20.
- [ ] Swedish-language support. Finland is officially bilingual; all
  current functions hardcode `fin@` in the URL. Add a `lang` parameter
  (`"fin"`/`"swe"`) across the statute functions. Note: the `act`
  endpoint's `actDocumentType` enum also includes
  `statute-foreign-language-translation` and `statute-sami-translation`
  -- worth checking whether Swedish falls under
  `langAndVersion = "swe@..."` on the regular `statute` type, or needs
  its own `actDocumentType`. Verify via Swagger before coding, as with
  every other endpoint so far.
- [ ] `flx_get_judgment()` (or a more honestly named variant) for the two
  document types actually available under `/akn/fi/judgment/...`:
  `chancellor-of-justice-decision` and `data-protection-ombudsman-decision`.
  Deliberately deferred earlier -- revisit now that scope is clear.
- [ ] `treaty-metadata` and `legal-literature-references` handling
  (deferred from `flx_get_doc()` -- different structure, need their own
  investigation before coding).
- [ ] `flx_classify_statute()` -- optional derived classification
  (Act/Decree/Decision-type grouping from title patterns). Deliberately
  kept separate from raw data retrieval; still on the table as a
  standalone helper.
- [ ] Revisit whether full KKO/KHO case law ever appears on the
  `judgment` endpoint -- if Finlex expands it, this is the highest-value
  addition to the package but is out of our control.

## B. Robustness

- [ ] Input validation: sanity-check year ranges (e.g. reject
  `end_year < start_year` consistently across all functions, not just
  `flx_download_statutes()`).
- [x] `langAndVersion = "fin@latest"` is now used (for consolidated
  text) and confirmed working. Document this pattern explicitly for
  users who might want `"latest"` behaviour elsewhere.
- [ ] Review error messages for clarity when `match.arg()` rejects an
  invalid `doc_type`/`categories` value -- default R error text is terse.

## C. Testing

- [ ] Consider adding `httptest2` mocks for at least the core functions,
  so CI doesn't depend entirely on live network calls (used already in
  the africalaws project for the same reason: faster, more reliable CI,
  no risk from Finlex API downtime).
- [ ] Expand edge-case coverage: empty result sets, multi-page pagination
  edge cases in `flx_download_statutes()`, statutes with zero sections.
- [ ] Add a GitHub Actions `R-CMD-check` workflow
  (`usethis::use_github_action("check-standard")`) for continuous
  checking on every push -- currently only the one-off R-hub workflow
  exists.

## D. Documentation & polish

- [ ] pkgdown site (`usethis::use_pkgdown()` + GitHub Actions deploy).
  Move the hex logo to `man/figures/logo.png` so pkgdown picks it up
  automatically.
- [ ] README badges: CRAN status, R-CMD-check, CRAN downloads.
- [ ] `CITATION` file for academic users citing the package.
- [ ] Verify and document the Finlex Open Data licence/terms of use
  explicitly in the README (important for downstream users who need to
  know their redistribution rights).
- [ ] Keep `NEWS.md` current with every release, not just 0.1.0.
- [ ] Add the new functions (`flx_get_doc()`, `flx_get_consolidated_text()`,
  etc.) to the vignette, or add a second vignette covering the
  non-statute document types.

## E. Process

- [x] Get v0.1.0 through CRAN review -- done, package is live on CRAN.
- [ ] Submit accumulated new functions (A + B above) as v0.2.0.
- [ ] Gather real-world feedback for at least one release cycle before
  committing to 1.0 -- breaking changes are much cheaper before 1.0 than
  after.
- [ ] Once API feels settled and documented: bump to 1.0.0, tag release,
  announce (e.g. R-bloggers, relevant Finnish open-data/legal-tech
  communities -- good fit with the lexverse credibility-building goal).

## Suggested next concrete step

Swedish-language support (A) is a good next candidate -- but check the
Swagger enum for the exact mechanism (separate `actDocumentType` vs.
`langAndVersion = "swe@..."`) before writing any code, the same lesson
learned from `statute-consolidated`.
