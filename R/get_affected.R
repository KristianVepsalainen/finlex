#' Get statutes affected by an amending or repealing statute
#'
#' For a given amending or repealing statute, retrieves the statute(s) it
#' affects (the `affectedDocument` references in the Akoma Ntoso
#' document). A single amending statute can affect more than one target
#' statute (for example, an omnibus act amending several other acts), in
#' which case one row is returned per affected target.
#'
#' @param year Integer vector. Year(s) of the amending/repealing statute(s).
#' @param number Integer vector. Number(s) of the statute(s) within that
#'   year. Recycled against `year` if shorter.
#'
#' @return A [tibble::tibble()] with the columns:
#'   \describe{
#'     \item{source_year}{Year of the amending/repealing statute, as
#'       supplied.}
#'     \item{source_number}{Number of the amending/repealing statute, as
#'       supplied.}
#'     \item{status}{One of `"ok"` (at least one affected statute found),
#'       `"no_affected"` (statute found, but no affected-document
#'       references present), `"not_found"`, or `"error"`.}
#'     \item{target_href}{URI of the affected statute, or `NA`.}
#'     \item{target_year}{Year of the affected statute, or `NA`.}
#'     \item{target_number}{Number of the affected statute, or `NA`.}
#'   }
#'
#' @details
#' This function does not check whether the supplied statute is actually
#' an amendment or repeal; it simply looks for `affectedDocument`
#' references in whatever statute is requested. New statutes will
#' typically return `status = "no_affected"`.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Look up affected statutes for a known amending statute
#' flx_download_statutes(
#'   start_year = 2023, end_year = 2023,
#'   categories = "amending-statute"
#' ) |>
#'   head(1) |>
#'   with(flx_get_affected(year, number))
#' }
flx_get_affected <- function(year, number) {
  
  stopifnot(is.numeric(year), is.numeric(number))
  
  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.integer(number), n)
  
  out <- vector("list", n)
  
  for (i in seq_len(n)) {
    out[[i]] <- flx_get_affected_one(year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }
  
  dplyr::bind_rows(out)
}

#' Get statutes affected by a single amending or repealing statute
#'
#' Internal helper used by [flx_get_affected()].
#'
#' @param year Integer. Year of the amending/repealing statute.
#' @param number Integer. Number of the statute within that year.
#'
#' @return A [tibble::tibble()] with one row per affected target (or one
#'   row with `NA` target fields if none are found), see
#'   [flx_get_affected()] for columns.
#' @keywords internal
#' @noRd
flx_get_affected_one <- function(year, number) {
  
  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/%d/%d/fin@",
    year, number
  )
  
  empty <- tibble::tibble(
    source_year   = year,
    source_number = number,
    status        = NA_character_,
    target_href   = NA_character_,
    target_year   = NA_integer_,
    target_number = NA_integer_
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
  
  # An empty AknXmlList means the statute is not present in the API,
  # even though the HTTP request itself succeeded (status 200).
  if (identical(root_name, "AknXmlList")) {
    empty$status <- "not_found"
    return(empty)
  }
  
  ns <- xml2::xml_ns(doc)
  affected <- xml2::xml_find_all(doc, "//d1:affectedDocument", ns)
  
  if (length(affected) == 0) {
    empty$status <- "no_affected"
    return(empty)
  }
  
  hrefs <- xml2::xml_attr(affected, "href")
  target_year   <- as.integer(sub(".*/statute/([0-9]{4})/([0-9]+).*", "\\1", hrefs))
  target_number <- as.integer(sub(".*/statute/([0-9]{4})/([0-9]+).*", "\\2", hrefs))
  
  tibble::tibble(
    source_year   = year,
    source_number = number,
    status        = "ok",
    target_href   = hrefs,
    target_year   = target_year,
    target_number = target_number
  )
}