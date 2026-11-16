# Optional presentation input must not reject an otherwise valid fitted model.
.gceOptionalTrueCoefficients <- function(input, count, enabled) {
  if (!isTRUE(enabled)) return(list(values = NULL, warning = NULL))
  tryCatch({
    if (length(input) != 1L || is.na(input) || !nzchar(trimws(input)))
      stop("Enter true coefficients for the selected precision-error plots.")
    if (grepl(",[[:space:]]*$", input))
      stop("True coefficients have an empty value.")
    values <- .wgceParseLimits(input, "True coefficients")
    if (length(values) != count)
      stop("Provide ", count, " true coefficients for the current model, including the intercept when selected and expanded factor terms.")
    list(values = values, warning = NULL)
  }, error = function(e) list(values = NULL,
    warning = paste0("Precision-error plots skipped: ", conditionMessage(e))))
}

# Labels are for table display only; identifiers used for joins remain intact.
.gceCoefficientLabels <- function(ids) {
  ids <- unique(as.character(ids))
  labels <- sub("^`([^`]*)`", "\\1", ids)
  stats::setNames(make.unique(labels, sep = " [coefficient] "), ids)
}
