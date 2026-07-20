#' Get a Finlex document by type, year, and number
#'
#' Retrieves a document from the generic document endpoint of the Finlex
#' Open Data API (`/akn/fi/doc/...`), which covers document types that are
#' not part of the Statute Book of Finland: treaties, government
#' proposals, authority regulations, and certain collective agreements.
#'
#' @param doc_type Character, length 1. One of `"authority-regulation"`,
#'   `"treaty"`, `"tax-treaty-consolidated"`, `"government-proposal"`,
#'   `"collective-agreement-general-applicability-decision"`, or
#'   `"trade-union-center-agreement"`. Call this function separately for
#'   different document types.
#' @param year Integer vector. Year(s) of the document(s).
#' @param number Character or integer vector. Number(s) of the
#'   document(s) within that year. Recycled against `year` if shorter.
#'   Accepts character because document numbers in these collections are
#'   not always simple integers.
#'
#' @return A [tibble::tibble()] with one row per document and the
#'   columns:
#'   \describe{
#'     \item{doc_type}{As supplied.}
#'     \item{year}{As supplied.}
#'     \item{number}{As supplied.}
#'     \item{status}{One of `"ok"`, `"pdf_only"` (the document exists but
#'       has no machine-readable text, only a scanned/original PDF),
#'       `"not_found"`, or `"error"`.}
#'     \item{title}{The document's official title.}
#'     \item{date_issued}{Date the document was issued, as a [Date].}
#'     \item{text}{The full body text of the document, or `NA` if only a
#'       PDF is available.}
#'     \item{pdf_url}{URL of the document's PDF version. Populated for
#'       both `"ok"` and `"pdf_only"` statuses.}
#'   }
#'
#' @details
#' Unlike [flx_get_text()], this function does not split the document
#' into sections. The document types covered here (treaties, government
#' proposals, agreements) do not share a consistent internal structure
#' the way statutes do, so the full body text is returned as a single
#' block.
#'
#' Some documents, particularly older ones, have never been digitised as
#' machine-readable text and exist only as a scanned or original PDF. For
#' these, `status` is `"pdf_only"`, `text` is `NA`, and `pdf_url` points
#' to the PDF so the content is still reachable.
#'
#' Two document types available in the underlying API are intentionally
#' *not* covered by this function: `"treaty-metadata"` (a lighter
#' reference record rather than a full document) and
#' `"legal-literature-references"` (an index of literature discussing
#' case law, not the case law itself). Both likely need bespoke handling
#' and may be added in a future version.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_get_doc(
#'   doc_type = "authority-regulation",
#'   year = 1996, number = 32082
#' )
#' }
flx_get_doc <- function(doc_type, year, number) {
  
  doc_type <- match.arg(
    doc_type,
    choices = c(
      "authority-regulation",
      "treaty",
      "tax-treaty-consolidated",
      "government-proposal",
      "collective-agreement-general-applicability-decision",
      "trade-union-center-agreement"
    )
  )
  
  stopifnot(is.numeric(year))
  
  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.character(number), n)
  
  out <- vector("list", n)
  
  for (i in seq_len(n)) {
    out[[i]] <- flx_get_doc_one(doc_type, year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }
  
  dplyr::bind_rows(out)
}

#' Get a single Finlex document by type, year, and number
#'
#' Internal helper used by [flx_get_doc()].
#'
#' @param doc_type Character. A single valid `docDocumentType` value.
#' @param year Integer. Year of the document.
#' @param number Character. Number of the document within that year.
#'
#' @return A one-row [tibble::tibble()], see [flx_get_doc()] for columns.
#' @keywords internal
#' @noRd
flx_get_doc_one <- function(doc_type, year, number) {
  
  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/doc/%s/%d/%s/fin@",
    doc_type, year, number
  )
  
  empty <- tibble::tibble(
    doc_type    = doc_type,
    year        = year,
    number      = number,
    status      = NA_character_,
    title       = NA_character_,
    date_issued = as.Date(NA_character_),
    text        = NA_character_,
    pdf_url     = NA_character_
  )
  
  resp <- tryCatch(
    flx_request(uri, accept = "application/xml"),
    httr2_http_404 = function(e) NULL,
    error = function(e) e
  )
  
  if (inherits(resp, "error")) {
    empty$status <- "error"
    return(empty)
  }
  if (is.null(resp)) {
    empty$status <- "not_found"
    return(empty)
  }
  
  doc <- xml2::read_xml(httr2::resp_body_string(resp))
  root_name <- xml2::xml_name(doc)
  
  # An empty AknXmlList means the document is not present in the API,
  # even though the HTTP request itself succeeded (status 200).
  if (identical(root_name, "AknXmlList")) {
    empty$status <- "not_found"
    return(empty)
  }
  
  ns <- xml2::xml_ns(doc)
  
  titles <- xml2::xml_text(xml2::xml_find_all(doc, "//d1:docTitle", ns))
  titles <- trimws(titles[nzchar(trimws(titles))])
  
  date_node <- xml2::xml_find_first(
    doc, "//d1:FRBRWork/d1:FRBRdate[@name='dateIssued']", ns
  )
  date_issued <- if (inherits(date_node, "xml_missing")) {
    NA_character_
  } else {
    xml2::xml_attr(date_node, "date")
  }
  
  pdf_url <- paste0(uri, "/main.pdf")
  
  # The content lives under mainBody for this document family (unlike
  # statutes, which use body). Older documents may have no machine-
  # readable text at all -- only a componentRef pointing at a PDF.
  body_node <- xml2::xml_find_first(doc, "//d1:mainBody", ns)
  body_text <- if (inherits(body_node, "xml_missing")) {
    NA_character_
  } else {
    trimws(xml2::xml_text(body_node))
  }
  
  if (is.na(body_text) || !nzchar(body_text)) {
    tibble::tibble(
      doc_type    = doc_type,
      year        = year,
      number      = number,
      status      = "pdf_only",
      title       = if (length(titles) == 0) NA_character_ else titles[1],
      date_issued = as.Date(date_issued),
      text        = NA_character_,
      pdf_url     = pdf_url
    )
  } else {
    tibble::tibble(
      doc_type    = doc_type,
      year        = year,
      number      = number,
      status      = "ok",
      title       = if (length(titles) == 0) NA_character_ else titles[1],
      date_issued = as.Date(date_issued),
      text        = body_text,
      pdf_url     = pdf_url
    )
  }
}