# TASW-GCE uses the existing W-GCE table and row-alignment helpers unchanged.
.taswgceVector <- function(x, label) {
  if (length(x) != 1L || is.na(x) || !nzchar(trimws(x)))
    stop(label, " cannot be empty.")
  # A trailing delimiter must not silently disappear in strsplit().
  if (grepl(",[[:space:]]*$", x)) stop(label, " has an empty value.")
  unique(.wgceParseLimits(x, label))
}

.taswgceScalar <- function(x, label, min, max = Inf, integer = FALSE) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) ||
      x < min || x > max || (integer && x != floor(x)))
    stop(label, " is outside its permitted range.")
  x
}

#' TASW-GCE standardized-support cross-validated linear model
#' @export
taswgceInternal <- function(jaspResults, dataset, options) {
  outputOrder <- c("modelSummary", "plotCV", "cvResults",
                   "signalSupports", "signalProbabilities", "coefficients",
                   paste0("plot", 1:7))
  tab <- function(key, title, specs) {
    table <- .wgceTable(jaspResults, key, title, specs)
    table$position <- match(key, outputOrder)
    table$dependOn(names(options))
    table
  }
  col <- function(name, title, type = "number", ...) list(name = name, title = title, type = type, ...)
  summaryTable <- tab("modelSummary", "Model Summary", list(
    col("measure", "Measure", "string"), col("value", "Value", "string")))
  if (!isTRUE(options$run)) {
    summaryTable$setData(data.frame(measure = "Status",
      value = "Select variables and options, then select Fit and update model."))
    return(invisible(NULL))
  }
  tryCatch({
    dep <- as.character(unlist(options$dependent, use.names = FALSE))
    covs <- as.character(unlist(options$covariates, use.names = FALSE))
    factors <- as.character(unlist(options$factors, use.names = FALSE))
    if (length(dep) != 1L || !length(c(covs, factors)))
      stop("Select one dependent variable and at least one predictor.")
    selected <- c(dep, covs, factors)
    if (anyDuplicated(selected)) stop("Select each variable only once.")
    encoded <- jaspBase::encodeColNames(selected)
    if (!all(encoded %in% names(dataset))) stop("Selected variables are missing.")
    data <- dataset[, encoded, drop = FALSE]
    rows <- which(stats::complete.cases(data))
    data <- data[rows, , drop = FALSE]
    if (nrow(data) < 3L) stop("At least three complete cases are required.")
    numericNames <- encoded[seq_len(1L + length(covs))]
    if (any(!vapply(data[numericNames], is.numeric, logical(1L))) ||
        any(!vapply(data[numericNames], function(x) all(is.finite(x)), logical(1L))))
      stop("The dependent variable and covariates must be finite numeric values.")
    for (f in encoded[match(factors, selected)]) {
      data[[f]] <- droplevels(as.factor(data[[f]]))
      if (nlevels(data[[f]]) < 2L) stop("Each factor needs at least two observed levels.")
    }
    for (f in encoded[match(covs, selected)])
      if (length(unique(data[[f]])) < 2L) stop("Covariates must have variation.")
    form <- stats::reformulate(encoded[-1L], response = encoded[1L],
                               intercept = isTRUE(options$intercept))
    X <- stats::model.matrix(form, data)
    terms <- colnames(X)
    if (!ncol(X) || any(!is.finite(X))) stop("Invalid model matrix.")
    M <- .taswgceVector(options$M, "Signal points")
    J <- .taswgceVector(options$J, "Noise points")
    for (v in list(M, J))
      if (any(v < 3 | v != floor(v) | v %% 2 != 1))
        stop("Support point counts must be odd integers of at least three.")
    weights <- .taswgceVector(options$weight, "Noise weights")
    if (any(weights < 0 | weights > 1)) stop("Noise weights must be between zero and one.")
    .taswgceScalar(options$cvNfolds, "CV folds", 2, nrow(data), TRUE)
    .taswgceScalar(options$cvTableRows, "CV rows", 1, integer = TRUE)
    .taswgceScalar(options$supportSignalVectorN, "Support spaces", 1, integer = TRUE)
    .taswgceScalar(options$supportSignalVectorMin, "Minimum support range", 0.01)
    .taswgceScalar(options$supportSignalVectorMax, "Maximum support range", 0.01)
    .taswgceScalar(options$supportSignal, "Signal support", 0.000001)
    .taswgceScalar(options$twostepsN, "Re-estimations", 0, integer = TRUE)
    .taswgceScalar(options$seed, "Seed", 1, .Machine$integer.max, TRUE)
    .taswgceScalar(options$bootConfLevel, "Confidence level", 0.5, 0.99)
    if (isTRUE(options$bootstrap)) .taswgceScalar(options$bootB, "Bootstrap samples", 10, integer = TRUE)
    if (options$supportSignalVectorMin >= options$supportSignalVectorMax) stop("Minimum support range must be smaller than maximum.")
    choices <- list(errorMeasure = c("RMSE", "MSE", "MAE", "MAPE", "sMAPE", "MASE"),
      errorMeasureWhich = c("1se", "min"), bootMethod = c("residuals", "cases", "wild"),
      bootCIMethod = c("percentile", "basic"),
      method = paste0(c(rep("dual.", 10), rep("primal.", 2)),
        c("BFGS", "lbfgsb3c", "L-BFGS-B", "lbfgs", "CG", "Rcgmin", "bobyqa", "newuoa", "nlminb", "nlm", "solnl", "solnp")))
    for (name in names(choices))
      if (length(options[[name]]) != 1L || !options[[name]] %in% choices[[name]])
        stop("Invalid option: ", name)
    trueCoef <- NULL
    if (isTRUE(options$plot5) || isTRUE(options$plot7)) {
      # Coefficients may repeat; do not use the candidate-grid parser here.
      if (grepl(",[[:space:]]*$", options$trueCoef)) stop("True coefficients have an empty value.")
      trueCoef <- .wgceParseLimits(options$trueCoef, "True coefficients")
      if (length(trueCoef) != ncol(X)) stop("Provide one true coefficient per model-matrix column.")
    }
    # Dependencies deliberately exclude display options.
    fitOptions <- setdiff(names(options), c("run", "cvTableRows", "trueCoef", "NormEnt",
      "plotCV", paste0("plot", 1:7), "saveFitted", "saveResiduals", "saveW"))
    state <- jaspResults[["taswgceState"]]
    if (is.null(state)) {
      state <- jaspBase::createJaspState()
      state$dependOn(c("run", fitOptions))
      jaspResults[["taswgceState"]] <- state
    }
    # Include data and fit settings in the cache key as well as declaring dependencies.
    key <- list(data = data, options = options[fitOptions])
    cache <- state$object
    reused <- !is.null(cache) && identical(cache$key, key)
    if (!reused) {
      warnings <- character()
      started <- proc.time()[["elapsed"]]
      fit <- withCallingHandlers(GCEstim::cv.lmgce(
        formula = form, data = data, support.method = "standardized",
        support.signal = if (options$supportSignalVectorN == 1L) options$supportSignal else NULL,
        support.signal.vector.n = options$supportSignalVectorN,
        support.signal.vector.min = options$supportSignalVectorMin,
        support.signal.vector.max = options$supportSignalVectorMax,
        support.signal.points = M, support.noise.points = J,
        cv.nfolds = options$cvNfolds, errormeasure = options$errorMeasure,
        errormeasure.which = options$errorMeasureWhich, weight = weights,
        twosteps.n = options$twostepsN, method = options$method, caseGLM = "D",
        boot.B = if (isTRUE(options$bootstrap)) options$bootB else 0L,
        boot.method = if (isTRUE(options$bootstrap)) options$bootMethod else "residuals",
        OLS = isTRUE(options$OLS), seed = as.integer(options$seed)),
        warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") })
      if (is.null(fit$best)) stop("Cross-validation did not return a selected model.")
      ci <- stats::confint(fit$best, level = options$bootConfLevel,
        method = if (isTRUE(options$bootstrap)) options$bootCIMethod else "z")
      cache <- list(key = key, fit = fit, ci = ci, warnings = unique(warnings),
                    elapsed = proc.time()[["elapsed"]] - started)
      state$object <- cache
    }
    fit <- cache$fit
    best <- fit$best
    coefs <- summary(best)$coefficients
    ci <- cache$ci
    intervalText <- function(x) paste0("[", paste(format(signif(x, 6), trim = TRUE), collapse = ", "), "]")
    noiseLimit <- 3 * stats::sd(data[[encoded[1L]]])
    methodLabel <- sub("^dual\\.", "Dual: ", options$method)
    methodLabel <- sub("^primal\\.", "Primal: ", methodLabel)
    summaryValues <- c(
      "Formula" = paste(deparse(form), collapse = " "),
      "Complete cases" = nrow(data),
      "Cross-validation folds" = options$cvNfolds,
      "Prediction-error measure" = options$errorMeasure,
      "Selection rule" = c("1se" = "Within one standard error", "min" = "Minimum error")[[options$errorMeasureWhich]],
      "Seed" = options$seed,
      "Method" = methodLabel,
      "Support method" = "Standardized coefficients",
      "Signal support specification" = "Symmetric",
      "Noise support specification" = paste0(
        "3 sigma: ",
        intervalText(c(-noiseLimit, noiseLimit))),
      "Number of support spaces" = options$supportSignalVectorN,
      "Candidate signal support points" = paste(M, collapse = ", "),
      "Candidate noise support points" = paste(J, collapse = ", "),
      "Candidate noise weight values" = paste(weights, collapse = ", "),
      "Post-GCE re-estimations" = options$twostepsN,
      "Confidence interval type" = if (isTRUE(options$bootstrap))
        c(percentile = "Bootstrap percentile", basic = "Bootstrap basic")[[options$bootCIMethod]] else "Asymptotic (z)",
      "Confidence level" = paste0(100 * options$bootConfLevel, "%"),
      "Fit time (s)" = sprintf("%.2f", cache$elapsed))
    if (isTRUE(options$bootstrap)) summaryValues <- c(summaryValues,
      "Bootstrap samples" = options$bootB,
      "Bootstrap resampling method" = c(residuals = "Residual", cases = "Case", wild = "Wild")[[options$bootMethod]])
    if (length(cache$warnings)) summaryValues <- c(summaryValues, Warnings = paste(cache$warnings, collapse = "; "))
    summaryTable$setData(data.frame(measure = names(summaryValues), value = unname(summaryValues)))
    limits <- as.matrix(best$support.matrix)
    supportTable <- tab("signalSupports", paste0("Signal Supports (", fit$support.signal.points.best, " points)"),
      list(col("term", "Coefficient", "string"), col("lower", "Lower"), col("upper", "Upper")))
    supportTable$setData(data.frame(term = if (is.null(rownames(limits))) terms else rownames(limits),
                                     lower = limits[, 1L], upper = limits[, 2L]))
    ciTitle <- paste0(100 * options$bootConfLevel, "% Confidence Interval (",
      if (isTRUE(options$bootstrap)) paste("bootstrap", options$bootCIMethod) else "asymptotic", ")")
    specs <- list(col("term", "Term", "string"), col("estimate", "Estimate"),
      col("lower", "Lower", overtitle = ciTitle), col("upper", "Upper", overtitle = ciTitle))
    values <- data.frame(term = rownames(coefs), estimate = coefs[, "Estimate"],
      lower = ci[rownames(coefs), 1L], upper = ci[rownames(coefs), 2L])
    if (!isTRUE(options$bootstrap)) {
      specs <- c(specs, list(col("sd", "Std. Deviation"), col("z", "z"), col("p", "p", "pvalue")))
      values$sd <- coefs[, "Std. Deviation"]
      values$z <- coefs[, "z value"]
      values$p <- coefs[, "Pr(>|t|)"]
    }
    tab("coefficients", "Coefficients", specs)$setData(values)
    cv <- as.data.frame(fit$results)
    cv <- head(cv[order(cv$error.measure.cv.mean, na.last = TRUE), , drop = FALSE], options$cvTableRows)
    tab("cvResults", "Cross-validation Results", list(col("M", "Signal points"), col("J", "Noise points"),
      col("weight", "Weight"), col("error", "Error"), col("mean", "CV error"),
      col("converged", "Converged", "string"), col("time", "Time (s)")))$setData(data.frame(
        M = cv$support.signal.points, J = cv$support.noise.points, weight = cv$weight,
        error = cv$error.measure, mean = cv$error.measure.cv.mean,
        converged = ifelse(cv$convergence == 0, "Yes", "No"), time = cv$time))
    p <- as.matrix(best$p)
    if (nrow(p) != nrow(coefs) || !ncol(p)) stop("Unexpected signal probability dimensions.")
    pnames <- paste0("p", seq_len(ncol(p)))
    specs <- c(list(col("term", "Coefficient", "string")), lapply(pnames, function(n) col(n, n)))
    values <- data.frame(term = if (is.null(rownames(p))) rownames(coefs) else rownames(p), p)
    names(values) <- c("term", pnames)
    tab("signalProbabilities", "Estimated Signal Support Probabilities (p)", specs)$setData(values)
    if (isTRUE(options$saveFitted) || isTRUE(options$saveResiduals) || isTRUE(options$saveW)) {
      saved <- jaspBase::createJaspContainer()
      saved$dependOn(c(fitOptions, "run", "saveFitted", "saveResiduals", "saveW"))
      jaspResults[["savedColumns"]] <- saved
      if (isTRUE(options$saveFitted)) .wgceSaveColumn(saved, "TASWGCE_fitted", best$fitted.values, rows, nrow(dataset))
      if (isTRUE(options$saveResiduals)) .wgceSaveColumn(saved, "TASWGCE_residual", best$residuals, rows, nrow(dataset))
      if (isTRUE(options$saveW)) {
        w <- as.matrix(best$w)
        if (nrow(w) != length(rows) || !ncol(w)) stop("Unexpected noise probability dimensions.")
        for (j in seq_len(ncol(w))) .wgceSaveColumn(saved, paste0("TASWGCE_w", j), w[, j], rows, nrow(dataset))
      }
    }
    titles <- c("Estimates and Confidence Intervals", "Supports vs Prediction Error", "Supports vs Estimates",
      "Supports vs Normalized Entropy", "Supports vs Precision Error", "GCE Re-estimation vs Prediction Error",
      "GCE Re-estimation vs Precision Error", "Cross-validation Error by Support Combination")
    for (i in seq_len(8L)) {
      name <- c(paste0("plot", 1:7), "plotCV")[i]
      available <- if (i %in% 2:5) options$supportSignalVectorN > 1L else
        if (i %in% 6:7) options$twostepsN > 0L else if (i == 8L) length(M) > 1L else TRUE
      if (!isTRUE(options[[name]]) || !available) next
      obj <- jaspBase::createJaspPlot(title = titles[i], width = 650,
        height = if (i == 8L) 160 + 140 * length(weights) else max(400, 140 + 55 * ncol(X)))
      obj$position <- match(name, outputOrder)
      obj$dependOn(c(fitOptions, "run", name, "NormEnt", "trueCoef"))
      jaspResults[[name]] <- obj
      tryCatch({
        if (i <= 7L) {
          args <- list(x = best, which = i, type = "ggplot2", OLS = isTRUE(options$OLS))
          if (i == 1L) { args$ci.level <- options$bootConfLevel; args$ci.method <- if (isTRUE(options$bootstrap)) options$bootCIMethod else "z" }
          if (i %in% c(2L, 5L)) args$NormEnt <- isTRUE(options$NormEnt)
          if (i %in% c(5L, 7L)) args$coef <- trueCoef
          result <- do.call(graphics::plot, args)
        } else result <- graphics::plot(fit, which = 1, ncol = 1, scales = "free")
        p <- if (inherits(result, "ggplot")) result else if (i == 1L) result[["p1"]] else result[[1L]]
        if (!inherits(p, "ggplot")) stop("GCEstim did not return a ggplot object.")
        obj$plotObject <- p
      }, error = function(e) obj$setError(conditionMessage(e)))
    }
  }, error = function(e) summaryTable$setError(conditionMessage(e)))
  invisible(NULL)
}
