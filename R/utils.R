#' Perform an HTTP GET request against the Finlex Open Data API
#'
#' Internal helper, not exported. Wraps [httr2::request()] with a polite
#' `User-Agent`, a request timeout, and automatic retries on transient
#' failures (HTTP 429 and 5xx responses). CRAN policy requires every
#' package that calls an external web service to identify itself, so this
#' header is always attached.
#'
#' @param url Character. Full request URL (without query string).
#' @param query A named list of query parameters, or `NULL` if none.
#' @param accept Character. Value for the `Accept` header. Defaults to
#'   `"application/json"`.
#'
#' @return An [httr2::response()] object as returned by
#'   [httr2::req_perform()]. Raises a condition of class
#'   `httr2_http_<status>` (e.g. `httr2_http_404`) on HTTP error responses,
#'   which calling functions can catch with [tryCatch()].
#'
#' @keywords internal
#' @noRd
flx_request <- function(url, query = NULL, accept = "application/json") {

  req <- httr2::request(url)

  if (!is.null(query)) {
    req <- httr2::req_url_query(req, !!!query)
  }

  req <- httr2::req_headers(
    req,
    "User-Agent" = "finlex R package (https://github.com/kristianvepsalainen/finlex)",
    "Accept"     = accept
  )

  req <- httr2::req_timeout(req, 30)

  req <- httr2::req_retry(
    req,
    max_tries = 5,
    is_transient = function(resp) httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L)
  )

  httr2::req_perform(req)
}

#' Null-coalescing helper
#'
#' @param a A value.
#' @param b Fallback value used when `a` is `NULL` or has length 0.
#' @keywords internal
#' @noRd
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
