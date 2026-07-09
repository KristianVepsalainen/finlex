test_that("flx_get_affected returns valid structure for a real amending statute", {
  skip_on_cran()
  skip_if_offline()
  
  amendments <- flx_download_statutes(
    start_year = 2023, end_year = 2023,
    categories = "amending-statute", quiet = TRUE
  )
  skip_if(nrow(amendments) == 0, "No amending statutes found for 2023")
  
  target <- amendments[1, ]
  out <- flx_get_affected(year = target$year, number = target$number)
  
  expect_s3_class(out, "tbl_df")
  expect_true(all(c(
    "source_year", "source_number", "status",
    "target_href", "target_year", "target_number"
  ) %in% names(out)))
  expect_true(all(out$status %in% c("ok", "no_affected", "not_found", "error")))
})

test_that("flx_get_affected handles a statute with no affected-document references", {
  skip_on_cran()
  skip_if_offline()
  
  # A new statute (as opposed to an amendment) typically has no
  # affectedDocument references.
  out <- flx_get_affected(year = 1992, number = 1535) # Tuloverolaki
  
  expect_true(all(out$status %in% c("no_affected", "ok")))
})

test_that("flx_get_affected reports not_found for statutes outside API coverage", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_affected(year = 1889, number = 39) # Rikoslaki - predates API coverage
  
  expect_equal(out$status, "not_found")
})