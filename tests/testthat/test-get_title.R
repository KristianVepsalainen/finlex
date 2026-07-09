test_that("flx_get_title finds a known statute", {
  skip_on_cran()
  skip_if_offline()

  out <- flx_get_title(year = 1992, number = 1535) # Tuloverolaki

  expect_s3_class(out, "tbl_df")
  expect_equal(out$status, "ok")
  expect_true(!is.na(out$title))
})

test_that("flx_get_title reports not_found for statutes outside API coverage", {
  skip_on_cran()
  skip_if_offline()

  out <- flx_get_title(year = 1889, number = 39) # Rikoslaki - predates API coverage

  expect_equal(out$status, "not_found")
  expect_true(is.na(out$title))
})

test_that("flx_get_title is vectorized and recycles arguments", {
  skip_on_cran()
  skip_if_offline()

  out <- flx_get_title(year = c(1992, 1993), number = c(1535, 1501))

  expect_equal(nrow(out), 2)
  expect_equal(out$year, c(1992, 1993))
})
