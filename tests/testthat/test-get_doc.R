test_that("flx_get_doc retrieves a known authority regulation (PDF-only case)", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_doc(
    doc_type = "authority-regulation",
    year = 1996, number = 32082
  )
  
  expect_s3_class(out, "tbl_df")
  # This particular 1996 document has no machine-readable text, only a
  # scanned PDF -- this is expected, not a failure.
  expect_equal(out$status, "pdf_only")
  expect_true(!is.na(out$title))
  expect_true(is.na(out$text))
  expect_true(grepl("main\\.pdf$", out$pdf_url))
})

test_that("flx_get_doc reports not_found for a document that doesn't exist", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_doc(doc_type = "treaty", year = 1800, number = "1")
  
  expect_equal(out$status, "not_found")
  expect_true(is.na(out$text))
  expect_true(is.na(out$pdf_url))
})

test_that("flx_get_doc validates doc_type", {
  expect_error(flx_get_doc(doc_type = "not-a-real-type", year = 2020, number = "1"))
})

test_that("flx_get_doc is vectorized across year/number", {
  skip_on_cran()
  skip_if_offline()
  
  out <- flx_get_doc(
    doc_type = "authority-regulation",
    year = c(1996, 1800),
    number = c("32082", "1")
  )
  
  expect_equal(nrow(out), 2)
  expect_true("pdf_only" %in% out$status)
  expect_true("not_found" %in% out$status)
})