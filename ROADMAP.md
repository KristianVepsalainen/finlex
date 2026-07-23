# Roadmap to finlex 1.0.0

Status as of 2026-07-23: v0.1.0 on CRAN, v0.1.0.9000 in development with
four additional functions and a pkgdown site. Seven functions built:
`flx_download_statutes()`, `flx_get_title()`, `flx_get_metadata()`,
`flx_get_affected()`, `flx_get_text()`, `flx_get_doc()`,
`flx_get_consolidated_text()`. Vignette in place. pkgdown site live via
GitHub Actions + GitHub Pages.

This document tracks what's left before calling finlex 1.0 -- the point at
which the public API is considered stable and users can rely on it not
changing in breaking ways.

## A. Function coverage

- [x] `flx_get_consolidated_text()` -- done 2026-07-20.
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
- [ ] `treaty-metadata` and `legal-literature-references` handling
  (deferred from `flx_get_doc()` -- different structure, need their own
  investigation before coding).
- [ ] `flx_classify_statute()` -- optional derived classification
  (Act/Decree/Decision-type grouping from title patterns).
- [ ] Revisit whether full KKO/KHO case law ever appears on the
  `judgment` endpoint.

## B. Robustness

- [ ] Input validation: sanity-check year ranges consistently across all
  functions.
- [x] `langAndVersion = "fin@latest"` confirmed working, used in
  `flx_get_consolidated_text()`.
- [ ] Review error messages for clarity when `match.arg()` rejects an
  invalid `doc_type`/`categories` value.

## C. Testing

- [ ] Consider adding `httptest2` mocks for at least the core functions.
- [ ] Expand edge-case coverage: empty result sets, multi-page pagination
  edge cases, statutes with zero sections.
- [ ] Add a GitHub Actions `R-CMD-check` workflow
  (`usethis::use_github_action("check-standard")`) for continuous
  checking on every push -- still only the one-off R-hub workflow and
  the pkgdown workflow exist; no check runs automatically on push yet.
  **Quick win, worth doing soon.**

## D. Documentation & polish

- [x] pkgdown site (`usethis::use_pkgdown()` +
  `usethis::use_pkgdown_github_pages()`). Done 2026-07-23, live via
  GitHub Actions + GitHub Pages.
- [ ] Confirm whether the hex logo was moved to `man/figures/logo.png`
  for pkgdown to pick up automatically -- follow-up needed, unclear if
  this step was completed alongside the pkgdown setup.
- [ ] README badges: CRAN status, pkgdown, R-CMD-check (once C above is
  done). **Quick win.**
- [ ] `CITATION` file for academic users citing the package
  (`usethis::use_citation()`). **Quick win.**
- [ ] Verify and document the Finlex Open Data licence/terms of use
  explicitly in the README.
- [ ] Keep `NEWS.md` current with every *user-facing* release -- routine
  infra changes (CI, pkgdown setup) don't need their own NEWS entries,
  only new functions, bug fixes, and breaking changes do.
- [ ] Add the new functions (`flx_get_doc()`, `flx_get_consolidated_text()`,
  etc.) to the vignette, or add a second vignette covering the
  non-statute document types.

## E. Process

- [x] Get v0.1.0 through CRAN review -- done, package is live on CRAN.
- [ ] Submit accumulated new functions (A + B above) as v0.2.0.
- [ ] Gather real-world feedback for at least one release cycle before
  committing to 1.0.
- [ ] Once API feels settled and documented: bump to 1.0.0, tag release,
  announce.

## Suggested next concrete steps (small and quick)

Three low-effort items ready to knock out in any order:
1. `R-CMD-check` GitHub Actions workflow (C) -- safety net for all
  future changes.
2. `CITATION` file (D) -- one command, `usethis::use_citation()`.
3. README badges (D) -- cosmetic but makes the repo look CRAN-ready at
  a glance; do after (1) so the R-CMD-check badge has something to link to.

Bigger items (Swedish support, judgment endpoint) still need a Swagger
check before coding, per the lesson learned with
`flx_get_consolidated_text()`.
