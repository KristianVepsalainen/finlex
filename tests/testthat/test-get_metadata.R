test_that("flx_get_metadata retrieves metadata for a known statute", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_metadata(year = 1992, number = 1535) # Tuloverolaki
  
  expect_s3_class(out, "tbl_df")
  expect_equal(out$status, "ok")
  expect_s3_class(out$date_issued, "Date")
  expect_false(is.na(out$date_issued))
  expect_equal(out$title, "Tuloverolaki")
  expect_true(out$n_sections > 0)
})

test_that("flx_get_metadata reports not_found for statutes outside API coverage", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_metadata(year = 1889, number = 39) # Rikoslaki - predates API coverage
  
  expect_equal(out$status, "not_found")
  expect_true(is.na(out$date_issued))
  expect_true(is.na(out$title))
  expect_true(is.na(out$n_sections))
})

test_that("flx_get_metadata is vectorized", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_metadata(year = c(1992, 1993), number = c(1535, 1501))
  
  expect_equal(nrow(out), 2)
  expect_equal(out$year, c(1992, 1993))
})