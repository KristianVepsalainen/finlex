test_that("flx_get_consolidated_text retrieves sections for a known statute", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_consolidated_text(year = 1992, number = 1535) # Tuloverolaki
  
  expect_s3_class(out, "tbl_df")
  expect_true(all(out$status == "ok"))
  expect_equal(out$section_index, seq_len(nrow(out)))
  expect_true(all(!is.na(out$text)))
  expect_true(nrow(out) > 1)
})

test_that("flx_get_consolidated_text reports not_found for statutes outside API coverage", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_consolidated_text(year = 1889, number = 39) # Rikoslaki
  
  expect_equal(out$status, "not_found")
  expect_true(is.na(out$text))
})

test_that("flx_get_consolidated_text is vectorized across statutes", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_consolidated_text(year = c(1992, 1889), number = c(1535, 39))
  
  expect_true("ok" %in% out$status)
  expect_true("not_found" %in% out$status)
})