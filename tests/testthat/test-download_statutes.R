test_that("flx_download_statutes returns a tibble with expected columns", {
  skip_on_cran()
  skip_if_offline()

  out <- flx_download_statutes(
    start_year = 2023,
    end_year   = 2023,
    categories = "new-statute",
    quiet      = TRUE
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("akn_uri", "year", "number", "statute_type") %in% names(out)))
  expect_true(all(out$year == 2023))
  expect_true(all(out$statute_type == "NewStatute"))
})

test_that("flx_download_statutes validates arguments", {
  expect_error(flx_download_statutes(start_year = 2020, end_year = 2010))
  expect_error(flx_download_statutes(categories = "not-a-real-category"))
})
