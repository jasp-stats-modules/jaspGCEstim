#' Standalone Ridge Trace JASP Analysis
#'
#' Explore ridge coefficient paths, lambda selection and cross-validation diagnostics through the JASP interface.
#'
#' @param jaspResults JASP results container.
#' @param dataset JASP data frame.
#' @param options Analysis options supplied by the corresponding JASP form.
#' @return Updates the JASP results container and returns invisibly.
#' @export
ridgeTraceInternal <- function(jaspResults, dataset, options) {
  o <- options
  outputOrder <- c(
    "modelSummary",
    "selectedLambda",
    "coefficients",
    "coefficientRanges",
    "lambdaResults",
    "plotPaths",
    "plotCV",
    "plotSample",
    "plotRanges",
    "plotSensitivity",
    "plotFolds",
    "plotStability"
  )
  col <- function(name, title, type = "number")
    list(name = name,
         title = title,
         type = type)
  tab <- function(key, title, columns) {
    table <- .wgceTable(jaspResults, key, title, columns)
    table$position <- match(key, outputOrder)
    table$dependOn(names(o))
    table
  }
  summaryTable <- tab("modelSummary", "Ridge Trace Model Summary", list(
    col("measure", "Measure", "string"),
    col("value", "Value", "string")
  ))
  if (!isTRUE(o$run)) {
    summaryTable$setData(
      data.frame(measure = "Status", value = "Select variables and options, then select Fit and update model.")
    )
    return(invisible(NULL))
  }
  tryCatch({
    dep <- as.character(unlist(o$dependent, use.names = FALSE))
    covs <- as.character(unlist(o$covariates, use.names = FALSE))
    factors <- as.character(unlist(o$factors, use.names = FALSE))
    selected <- c(dep, covs, factors)
    if (length(dep) != 1L ||
        !length(c(covs, factors)))
      stop("Select one dependent variable and at least one predictor.")
    if (anyDuplicated(selected))
      stop("Select each variable only once.")
    encoded <- jaspBase::encodeColNames(selected)
    if (!all(encoded %in% names(dataset)))
      stop("Selected variables are missing from the dataset.")
    data <- dataset[, encoded, drop = FALSE]
    data <- data[stats::complete.cases(data), , drop = FALSE]
    if (nrow(data) < 3L)
      stop("At least three complete cases are required.")
    numericNames <- encoded[seq_len(1L + length(covs))]
    if (any(!vapply(data[numericNames], function(x)
      is.numeric(x) && all(is.finite(x)), logical(1))))
      stop("The dependent variable and covariates must contain finite numeric values.")
    if (length(unique(data[[encoded[1L]]])) < 2L)
      stop("The dependent variable has no variation.")
    for (name in encoded[match(covs, selected)])
      if (length(unique(data[[name]])) < 2L)
        stop("Covariates must have variation.")
    for (name in encoded[match(factors, selected)]) {
      data[[name]] <- droplevels(as.factor(data[[name]]))
      if (nlevels(data[[name]]) < 2L)
        stop("Each factor requires at least two observed levels.")
    }
    form <- stats::reformulate(encoded[-1L],
                               response = encoded[1L],
                               intercept = isTRUE(o$intercept))
    X <- stats::model.matrix(form, data)
    if (!ncol(X) ||
        any(!is.finite(X)))
      stop("Invalid model matrix.")
    effective <- .ridgeEffective(o)
    scalar <- function(x, label, min, max = Inf) {
      if (length(x) != 1L ||
          !is.numeric(x) ||
          !is.finite(x) || x != floor(x) || x < min || x > max)
        stop(label, " must be an integer between ", min, " and ", max, ".")
    }
    for (name in c("run",
                   "intercept",
                   "standardize",
                   "penalizeIntercept",
                   "customGrid",
                   "cv"))
      if (!is.logical(o[[name]]) ||
          length(o[[name]]) != 1L ||
          is.na(o[[name]]))
        stop("Invalid option: ", name)
    if (!o$errorMeasure %in% c("RMSE", "MSE", "MAE", "sMAPE"))
      stop("Choose RMSE, MSE, MAE or sMAPE.")
    if (!o$selection %in% c("min", "1se", "manual"))
      stop("Invalid lambda selection rule.")
    if (!o$axisScale %in% c("log", "linear"))
      stop("Invalid lambda axis scale.")
    if (!o$plotSample %in% c("auto", "show", "hide"))
      stop("Invalid in-sample plot option.")
    scalar(o$tableRows, "Maximum lambda rows", 1)
    if (isTRUE(o$cv)) {
      scalar(o$cvNfolds, "CV folds", 2, nrow(data))
      scalar(o$seed, "Seed", 1, .Machine$integer.max)
    }
    if (effective$standardize && isTRUE(o$cv) && ncol(X) == 2L)
      stop(
        "Cross-validation with standardization, an intercept and one predictor column is not currently supported by GCEstim. This is an implementation limitation; disable standardization or CV to inspect this model."
      )
    lambda <- .ridgeLambda(o$customGrid,
                           o$lambdaValues,
                           o$lambdaMin,
                           o$lambdaMax,
                           o$lambdaN)
    displayTerms <- .ridgeTerms(list(coefficients = t(X)), o$showIntercept, o$displayTerms)
    # Only this new analysis owns this numerical state.
    fitKeys <- c(
      "dependent",
      "covariates",
      "factors",
      "intercept",
      "standardize",
      "penalizeIntercept",
      "customGrid",
      "lambdaMin",
      "lambdaMax",
      "lambdaN",
      "lambdaValues",
      "cv",
      "cvNfolds",
      "seed",
      "errorMeasure"
    )
    state <- jaspResults[["ridgeTraceState"]]
    if (is.null(state)) {
      state <- jaspBase::createJaspState()
      state$dependOn(c("run", fitKeys))
      jaspResults[["ridgeTraceState"]] <- state
    }
    key <- list(
      data = data,
      form = paste(deparse(form), collapse = " "),
      standardize = effective$standardize,
      penalize = isTRUE(o$intercept) &&
        !effective$standardize && isTRUE(o$penalizeIntercept),
      lambda = if (isTRUE(o$customGrid))
        lambda
      else
        c(o$lambdaMin, o$lambdaMax, o$lambdaN),
      custom = o$customGrid,
      cv = o$cv,
      folds = if (o$cv)
        o$cvNfolds
      else
        NULL,
      seed = if (o$cv)
        o$seed
      else
        NULL,
      measure = o$errorMeasure
    )
    cache <- state$object
    reused <- is.list(cache) &&
      identical(cache$version, 1L) && identical(cache$key, key)
    if (!reused) {
      started <- proc.time()[["elapsed"]]
      warnings <- character()
      fit <- withCallingHandlers(
        GCEstim::ridgetrace(
          formula = form,
          data = data,
          lambda = lambda,
          lambda.min = o$lambdaMin,
          lambda.max = o$lambdaMax,
          lambda.n = o$lambdaN,
          standardize = effective$standardize,
          penalize.intercept = o$penalizeIntercept,
          cv = o$cv,
          cv.nfolds = o$cvNfolds,
          seed = o$seed,
          errormeasure = o$errorMeasure
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      )
      cache <- list(
        version = 1L,
        key = key,
        fit = .ridgeCompact(fit, ncol(X), o$cv, o$cvNfolds),
        measure = o$errorMeasure,
        warnings = unique(warnings),
        engineVersion = as.character(utils::packageVersion("GCEstim")),
        elapsed = proc.time()[["elapsed"]] - started
      )
      state$object <- cache
    }
    f <- cache$fit
    if (o$selection == "manual")
      scalar(o$manualIndex, "Manual grid position", 1, length(f$lambda))
    manual <- f$lambda[if (o$selection == "manual")
      o$manualIndex
      else
        1L]
    s <- .ridgeSelection(f, effective$selection, manual, o$cv)
    selected <- if (is.na(s$index))
      rep(NA_real_, nrow(f$coefficients))
    else
      as.numeric(f$coefficients[, s$index])
    selectedLambda <- if (is.na(s$index))
      NA_real_
    else
      f$lambda[s$index]
    rule <- if (effective$selection == "manual")
      "Manual (grid position)"
    else if (effective$selection == "1se")
      "1-SE rule"
    else
      if (o$cv)
        "Minimum mean CV error"
    else
      "Minimum in-sample error (descriptive)"
    notes <- c(
      if (isTRUE(o$cv) && effective$standardize)
        "GCEstim standardizes using the complete dataset before constructing CV folds. These results do not use independent fold-specific preprocessing.",
      if (!isTRUE(o$cv) && o$selection == "1se")
        "CV is disabled; descriptive minimum in-sample error is used. The stored 1-SE preference is retained."
    )
    warnings <- unique(
      c(
        cache$warnings,
        s$warning,
        if (length(f$foldCoefficients) &&
            any(vapply(f$foldCoefficients, function(x)
              any(!is.finite(x)), logical(1))))
          "Some nonfinite fold-training coefficients are omitted from stability plots."
      )
    )
    summary <- c(
      "Formula" = paste(deparse(form), collapse = " "),
      "Complete cases" = nrow(data),
      "Predictor columns (excluding intercept)" = ncol(X) - as.integer(o$intercept),
      "Intercept" = if (o$intercept)
        "Included"
      else
        "Omitted",
      "Standardization" = if (!o$intercept)
        "Not applicable"
      else if (effective$standardize)
        "Yes"
      else
        "No",
      "Intercept penalization" = if (!o$intercept)
        "Not applicable"
      else if (effective$standardize)
        "No (intercept reconstructed after standardization)"
      else if (o$penalizeIntercept)
        "Yes"
      else
        "No",
      "Lambda grid" = if (o$customGrid)
        "Custom, sorted ascending"
      else
        "Geometric",
      "Lambda values" = length(f$lambda),
      "Cross-validation" = if (o$cv)
        "Enabled"
      else
        "Disabled",
      "CV folds" = if (o$cv)
        o$cvNfolds
      else
        "Not applicable",
      "Seed" = if (o$cv)
        o$seed
      else
        "Not applicable",
      "Error measure" = cache$measure,
      "Selection rule" = rule,
      "GCEstim version" = cache$engineVersion,
      "Fit time (s)" = sprintf("%.2f", cache$elapsed)
    )
    if (length(notes))
      summary <- c(summary, Notes = paste(notes, collapse = " "))
    if (length(warnings))
      summary <- c(summary, Warnings = paste(warnings, collapse = "; "))
    summaryTable$setData(data.frame(measure = names(summary), value = unname(summary)))
    tab("selectedLambda",
        "Selected Lambda",
        list(
          col("minimum", "Minimum lambda"),
          col("maximum", "Maximum lambda"),
          col("selected", "Selected lambda"),
          col("rule", "Selection rule", "string")
        ))$setData(data.frame(
          minimum = min(f$lambda),
          maximum = max(f$lambda),
          selected = selectedLambda,
          rule = rule
        ))
    labels <- .gceCoefficientLabels(rownames(f$coefficients))
    tab(
      "coefficients",
      paste(
        "Coefficients at Lambda",
        if (is.finite(selectedLambda))
          format(signif(selectedLambda, 3), trim = TRUE)
        else
          "Unavailable"
      ),
      list(
        col("term", "Coefficient", "string"),
        col("estimate", "Estimate")
      )
    )$setData(data.frame(term = unname(labels), estimate = selected))
    ranges <- tab("coefficientRanges",
                  "Coefficient Ranges",
                  list(
                    col("term", "Coefficient", "string"),
                    col("minimum", "Minimum"),
                    col("maximum", "Maximum"),
                    col("maxAbs", "Maximum absolute"),
                    col("selected", "Selected")
                  ))
    ranges$setData(
      data.frame(
        term = unname(labels),
        minimum = f$minimum,
        maximum = f$maximum,
        maxAbs = f$maxAbs,
        selected = selected
      )
    )
    ranges$addFootnote("Ranges describe the evaluated lambda grid; they are not confidence intervals.")
    if (isTRUE(o$showLambdaTable)) {
      columns <- list(
        col("position", "Grid position"),
        col("lambda", "Lambda"),
        col("sample", paste("In-sample", cache$measure))
      )
      values <- data.frame(
        position = seq_along(f$lambda),
        lambda = f$lambda,
        sample = ifelse(is.finite(f$sample), f$sample, NA_real_)
      )
      if (isTRUE(o$cv)) {
        columns <- c(columns, list(col(
          "cvMean", paste("CV", cache$measure)
        ), col("cvSE", "CV SE")))
        values$cvMean <- s$mean
        values$cvSE <- s$se
      }
      columns <- c(columns, list(
        col("selected", "Selected", "string"),
        col("minimum", "Minimum error", "string")
      ))
      values$selected <- ifelse(!is.na(s$index) &
                                  values$position == s$index, "Yes", "")
      values$minimum <- ifelse(!is.na(s$minimum) &
                                 values$position == s$minimum,
                               "Yes",
                               "")
      if (isTRUE(o$cv)) {
        columns <- c(columns, list(col("oneSE", "1-SE rule", "string")))
        values$oneSE <- ifelse(!is.na(s$oneSE) &
                                 values$position == s$oneSE, "Yes", "")
      }
      table <- tab("lambdaResults", "Lambda Results", columns)
      table$setData(utils::head(values, o$tableRows))
      table$addFootnote(
        paste(
          "Showing up to",
          o$tableRows,
          "rows in ascending lambda order. CV summaries require all folds to be finite. SE describes fold variation, not a confidence interval."
        )
      )
    }
    plotNames <- c(
      "plotPaths",
      "plotCV",
      "plotSample",
      "plotRanges",
      "plotSensitivity",
      "plotFolds",
      "plotStability"
    )
    titles <- c(
      "Ridge Coefficient Paths",
      "Cross-Validation Error",
      "In-Sample Error",
      "Coefficient Ranges",
      "Local Coefficient Sensitivity",
      "Fold-Specific CV Errors",
      "Coefficient Stability Across CV Folds"
    )
    plotOptions <- o
    for (i in seq_along(plotNames)) {
      name <- plotNames[i]
      available <- !name %in% c("plotCV", "plotFolds", "plotStability") ||
        isTRUE(o$cv)
      visible <- available &&
        if (name == "plotSample")
          o$plotSample == "show" ||
        (o$plotSample == "auto" &&
           !isTRUE(o$cv))
      else
        isTRUE(o[[name]])
      if (!visible)
        next
      coefficientPlot <- name %in% c("plotPaths",
                                     "plotRanges",
                                     "plotSensitivity",
                                     "plotStability")
      height <- if (!coefficientPlot)
        420
      else if (name == "plotRanges")
        max(400, 120 + 24 * length(displayTerms))
      else
        if (name == "plotPaths" &&
            !isTRUE(o$facet))
          max(400, 320 + 24 * ceiling(length(displayTerms) / 3))
      else
        max(400, 200 * ceiling(length(displayTerms) / 3))
      obj <- jaspBase::createJaspPlot(title = titles[i],
                                      width = 650,
                                      height = height)
      obj$position <- match(name, outputOrder)
      obj$dependOn(names(o))
      jaspResults[[name]] <- obj
      tryCatch({
        state <- list(
          key = name,
          selection = c(s, list(rule = effective$selection)),
          options = plotOptions,
          terms = displayTerms
        )
        p <- .ridgePlot(
          cache,
          state,
          ggplot2::theme_minimal(base_family = "Arial"),
          list(color = "#346da4")
        )
        ggplot2::ggplot_build(p)
        obj$plotObject <- p
      }, error = function(e)
        obj$setError(paste0(titles[i], ": ", conditionMessage(e))))
    }
  }, error = function(e)
    summaryTable$setError(paste0("Ridge Trace: ", conditionMessage(e))))
  invisible(NULL)
}
