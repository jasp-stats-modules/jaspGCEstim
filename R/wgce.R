.wgceParseLimits <- function(input, label) {
  input <- trimws(as.character(input))
  if (length(input) != 1L || !nzchar(input))
    stop(label, " cannot be empty.", call. = FALSE)
  pieces <- trimws(strsplit(input, ",", fixed = TRUE)[[1L]])
  values <- suppressWarnings(as.numeric(pieces))
  if (any(!nzchar(pieces)) || any(!is.finite(values)))
    stop(label,
         " must contain finite numbers separated by commas.",
         call. = FALSE)
  values
}

.wgceParsePrior <- function(input, count, label) {
  tokens <- trimws(strsplit(trimws(as.character(input)), ",", fixed = TRUE)[[1L]])
  tokens <- gsub("[[:space:]]+", "", tokens)
  valid <- "^[0-9]+(\\.[0-9]+)?(/[0-9]+(\\.[0-9]+)?)?$"
  if (length(tokens) != count || any(!grepl(valid, tokens)))
    stop(
      "Enter exactly ",
      count,
      " positive ",
      label,
      " probabilities as decimals or fractions, separated by commas.",
      call. = FALSE
    )
  values <- vapply(tokens, function(token) {
    parts <- as.numeric(strsplit(token, "/", fixed = TRUE)[[1L]])
    if (length(parts) == 1L)
      parts[1L]
    else
      parts[1L] / parts[2L]
  }, numeric(1L))
  if (any(!is.finite(values)) || any(values <= 0) ||
      abs(sum(values) - 1) > 1e-6)
    stop(label, " probabilities must be positive and sum to 1.", call. = FALSE)
  unname(values / sum(values))
}

.wgceSaveColumn <- function(container, name, values, rows, totalRows) {
  if (length(values) != length(rows))
    stop("Saved values do not match the complete cases.", call. = FALSE)
  aligned <- rep(NA_real_, totalRows)
  aligned[rows] <- as.numeric(values)
  column <- jaspBase::createJaspColumn(name)
  container[[name]] <- column
  column$setScale(aligned)
}

.wgceTable <- function(jaspResults, key, title, columns) {
  table <- jaspBase::createJaspTable(title = title)
  table$addCitation(
    "Cabral, J. (2026). GCEstim: Regression Coefficients Estimation Using the Generalized Cross Entropy. R package version 1.1.0. https://CRAN.R-project.org/package=GCEstim"
  )
  for (column in columns)
    do.call(table$addColumnInfo, column)
  table$showSpecifiedColumnsOnly <- TRUE
  jaspResults[[key]] <- table
  table
}

#' W-GCE linear model
#' @param jaspResults JASP results container.
#' @param dataset JASP data frame.
#' @param options Options supplied by Wgce.qml.
#' @export
wgceInternal <- function(jaspResults, dataset, options) {
  summaryTable <- .wgceTable(jaspResults,
                             "modelSummary",
                             "Model Summary",
                             list(
                               list(
                                 name = "measure",
                                 title = "Measure",
                                 type = "string"
                               ),
                               list(
                                 name = "value",
                                 title = "Value",
                                 type = "string"
                               )
                             ))
  supportsTable <- .wgceTable(jaspResults,
                              "signalSupports",
                              "Signal Supports",
                              list(
                                list(
                                  name = "term",
                                  title = "Coefficient",
                                  type = "string"
                                ),
                                list(
                                  name = "lower",
                                  title = "Lower limit",
                                  type = "number"
                                ),
                                list(
                                  name = "upper",
                                  title = "Upper limit",
                                  type = "number"
                                )
                              ))
  coefficientColumns <- list(
    list(
      name = "term",
      title = "Term",
      type = "string"
    ),
    list(
      name = "estimate",
      title = "Estimate",
      type = "number"
    ),
    list(
      name = "lower",
      title = "Lower",
      type = "number",
      overtitle = paste0(
        100 * as.numeric(options$confLevel),
        "% Confidence Interval",
        if (isTRUE(options$bootstrap))
          paste0(" (bootstrap ", options$bootCIMethod, ")")
        else
          " (asymptotic)"
      )
    ),
    list(
      name = "upper",
      title = "Upper",
      type = "number",
      overtitle = paste0(
        100 * as.numeric(options$confLevel),
        "% Confidence Interval",
        if (isTRUE(options$bootstrap))
          paste0(" (bootstrap ", options$bootCIMethod, ")")
        else
          " (asymptotic)"
      )
    )
  )
  if (!isTRUE(options$bootstrap)) {
    coefficientColumns <- c(coefficientColumns, list(
      list(
        name = "sd",
        title = "Std. Deviation",
        type = "number"
      ),
      list(
        name = "z",
        title = "z",
        type = "number"
      ),
      list(
        name = "p",
        title = "p",
        type = "pvalue"
      )
    ))
  }
  coefficientsTable <- .wgceTable(jaspResults,
                                  "coefficients",
                                  "Coefficients",
                                  coefficientColumns)
  
  dependent <- as.character(unlist(options$dependent, use.names = FALSE))
  covariates <- as.character(unlist(options$covariates, use.names = FALSE))
  factors <- as.character(unlist(options$factors, use.names = FALSE))
  if (length(dependent) != 1L ||
      (!length(covariates) && !length(factors)))
    return(invisible(NULL))
  
  tryCatch({
    if (length(unique(c(dependent, covariates, factors))) !=
        length(c(dependent, covariates, factors)))
      stop("Select each variable only once.")
    
    selected <- unique(c(dependent, covariates, factors))
    encoded <- jaspBase::encodeColNames(selected)
    if (!all(encoded %in% names(dataset)))
      stop("The selected variables are missing from the dataset.")
    data <- dataset[, encoded, drop = FALSE]
    completeRows <- which(stats::complete.cases(data))
    data <- data[completeRows, , drop = FALSE]
    if (nrow(data) < 3L)
      stop("At least three complete cases are required.")
    
    dep <- encoded[1L]
    xNames <- encoded[match(covariates, selected)]
    factorNames <- encoded[match(factors, selected)]
    if (!is.numeric(data[[dep]]))
      stop("The dependent variable must be numeric.")
    if (any(!vapply(data[xNames], is.numeric, logical(1L))))
      stop("Covariates must be numeric.")
    for (f in factorNames) {
      data[[f]] <- droplevels(as.factor(data[[f]]))
      if (nlevels(data[[f]]) < 2L)
        stop("Each factor must have at least two observed levels.")
    }
    
    formula <- stats::reformulate(
      c(xNames, factorNames),
      response = dep,
      intercept = isTRUE(options$intercept)
    )
    X <- stats::model.matrix(formula, data = data)
    terms <- colnames(X)
    k <- length(terms)
    if (!k || any(!is.finite(X)))
      stop("The model matrix must contain finite coefficients.")
    
    M <- as.integer(options$M)
    J <- as.integer(options$J)
    if (length(M) != 1L || length(J) != 1L ||
        anyNA(c(M, J)) ||
        any(c(M, J) < 3L) || any(c(M, J) %% 2L != 1L))
      stop("Signal and noise point counts must be odd integers of at least 3.")
    signalPrior <- if (isTRUE(options$uniformSignalPrior))
      M
    else
      .wgceParsePrior(options$signalPriorWeights, M, "Signal prior")
    noisePrior <- if (isTRUE(options$uniformNoisePrior))
      J
    else
      .wgceParsePrior(options$noisePriorWeights, J, "Noise prior")
    confidenceLevel <- as.numeric(options$confLevel)
    if (length(confidenceLevel) != 1L ||
        !is.finite(confidenceLevel) ||
        confidenceLevel <= 0 || confidenceLevel >= 1)
      stop("Confidence level must be between 0 and 1.")
    bootB <- if (isTRUE(options$bootstrap))
      as.integer(options$bootB)
    else
      0L
    if (isTRUE(options$bootstrap) &&
        (length(bootB) != 1L || is.na(bootB) || bootB < 10L))
      stop("At least 10 bootstrap samples are required.")
    lowerInput <- .wgceParseLimits(options$lowerLimits, "Lower limits")
    upperInput <- .wgceParseLimits(options$upperLimits, "Upper limits")
    if (!(length(lowerInput) %in% c(1L, k)) ||
        !(length(upperInput) %in% c(1L, k)))
      stop(
        "Enter one limit or ",
        k,
        " limits per field. Coefficient order: ",
        paste(terms, collapse = ", "),
        "."
      )
    lower <- rep(lowerInput, length.out = k)
    upper <- rep(upperInput, length.out = k)
    if (any(lower >= upper))
      stop("Every signal lower limit must be below its upper limit.")
    
    supportSignal <- if (length(lowerInput) == 1L &&
                         length(upperInput) == 1L) {
      c(lower[1L], upper[1L])
    } else {
      matrix(c(lower, upper),
             nrow = k,
             dimnames = list(terms, c("LL", "UL")))
    }
    supportNoise <- NULL
    if (!isTRUE(options$threeSigma)) {
      supportNoise <- c(as.numeric(options$noiseLower),
                        as.numeric(options$noiseUpper))
      if (any(!is.finite(supportNoise)) ||
          supportNoise[1L] >= supportNoise[2L])
        stop("The noise lower limit must be below its upper limit.")
    }
    weight <- as.numeric(options$weight)
    if (length(weight) != 1L ||
        !is.finite(weight) || weight <= 0 || weight >= 1)
      stop("Noise weight must be strictly between zero and one.")
    
    fit <- GCEstim::lmgce(
      formula = formula,
      data = data,
      cv = FALSE,
      errormeasure.which = "min",
      support.method = "standardized",
      support.signal = supportSignal,
      support.signal.points = signalPrior,
      support.noise = supportNoise,
      support.noise.points = noisePrior,
      weight = weight,
      twosteps.n = 0L,
      method = as.character(options$method),
      caseGLM = "D",
      boot.B = bootB,
      boot.method = as.character(options$bootMethod),
      seed = as.integer(options$seed),
      OLS = isTRUE(options$OLS)
    )
    ci <- stats::confint(
      fit,
      level = confidenceLevel,
      method = if (isTRUE(options$bootstrap))
        as.character(options$bootCIMethod)
      else
        "z"
    )
    coefs <- summary(fit)$coefficients
    
    intervalText <- function(bounds) {
      paste0("[",
             format(signif(bounds[1L], 6), trim = TRUE),
             ", ",
             format(signif(bounds[2L], 6), trim = TRUE),
             "]")
    }
    signalSupportText <- if (all(lower == lower[1L]) &&
                             all(upper == upper[1L])) {
      intervalText(c(lower[1L], upper[1L]))
    } else {
      "Different for each coefficient (see Signal Supports)"
    }
    noiseSupportText <- if (isTRUE(options$threeSigma)) {
      limit <- 3 * stats::sd(as.numeric(data[[dep]]))
      paste0("Automatic (3 sigma): ", intervalText(c(-limit, limit)))
    } else {
      intervalText(supportNoise)
    }
    methodLabel <- sub("^dual\\.", "Dual: ", as.character(options$method))
    methodLabel <- sub("^primal\\.", "Primal: ", methodLabel)
    summaryValues <- c(
      "Formula" = paste(deparse(formula), collapse = " "),
      "Complete cases" = as.character(nrow(data)),
      "Signal support" = signalSupportText,
      "Signal support points" = as.character(M),
      "Signal prior" = if (isTRUE(options$uniformSignalPrior))
        "Uniform"
      else
        paste(signif(signalPrior, 6), collapse = ", "),
      "Noise support points" = as.character(J),
      "Noise prior" = if (isTRUE(options$uniformNoisePrior))
        "Uniform"
      else
        paste(signif(noisePrior, 6), collapse = ", "),
      "Noise support" = noiseSupportText,
      "Noise weight" = as.character(weight),
      "Optimization method" = methodLabel,
      "Confidence interval type" = if (isTRUE(options$bootstrap))
        paste("Bootstrap", options$bootCIMethod)
      else
        "Asymptotic normal",
      "Confidence level" = paste0(100 * confidenceLevel, "%")
    )
    if (isTRUE(options$bootstrap)) {
      summaryValues <- c(
        summaryValues,
        "Bootstrap samples" = as.character(bootB),
        "Bootstrap resampling method" = c(
          residuals = "Residual",
          cases = "Case",
          wild = "Wild"
        )[[as.character(options$bootMethod)]]
      )
    }
    summaryTable$setData(data.frame(
      measure = names(summaryValues),
      value = unname(summaryValues),
      stringsAsFactors = FALSE
    ))
    
    supportsTable$setData(data.frame(
      term = terms,
      lower = lower,
      upper = upper
    ))
    
    coefTerms <- rownames(coefs)
    coefficientData <- data.frame(
      term = coefTerms,
      estimate = as.numeric(coefs[, "Estimate"]),
      lower = as.numeric(ci[coefTerms, 1L]),
      upper = as.numeric(ci[coefTerms, 2L]),
      check.names = FALSE
    )
    if (!isTRUE(options$bootstrap)) {
      coefficientData$sd <- as.numeric(coefs[, "Std. Deviation"])
      coefficientData$z <- as.numeric(coefs[, "z value"])
      coefficientData$p <- as.numeric(coefs[, "Pr(>|t|)"])
    }
    coefficientsTable$setData(coefficientData)
    
    if (isTRUE(options$plot1)) {
      estimatePlot <- jaspBase::createJaspPlot(
        title = "Estimates and Confidence Intervals",
        width = 650,
        height = max(320L, 140L + 55L * k)
      )
      estimatePlot$addCitation(
        "Cabral, J. (2026). GCEstim: Regression Coefficients Estimation Using the Generalized Cross Entropy. R package version 1.1.0. https://CRAN.R-project.org/package=GCEstim"
      )
      estimatePlot$dependOn(
        c(
          "plot1",
          "dependent",
          "covariates",
          "factors",
          "intercept",
          "lowerLimits",
          "upperLimits",
          "M",
          "J",
          "weight",
          "threeSigma",
          "noiseLower",
          "noiseUpper",
          "method",
          "seed",
          "uniformSignalPrior",
          "signalPriorWeights",
          "uniformNoisePrior",
          "noisePriorWeights",
          "confLevel",
          "bootstrap",
          "bootB",
          "bootMethod",
          "bootCIMethod",
          "OLS"
        )
      )
      jaspResults[["estimatesPlot"]] <- estimatePlot
      
      tryCatch({
        p <- graphics::plot(
          fit,
          type = "ggplot2",
          which = 1L,
          ci.level = confidenceLevel,
          ci.method = if (isTRUE(options$bootstrap))
            as.character(options$bootCIMethod)
          else
            "z",
          OLS = isTRUE(options$OLS)
        )[["p1"]]
        if (is.null(p) || !inherits(p, "ggplot"))
          stop("GCEstim did not return an estimates plot.")
        estimatePlot$plotObject <- p
      }, error = function(e) {
        estimatePlot$setError(conditionMessage(e))
      })
    }
    
    pMatrix <- as.matrix(fit$p)
    if (nrow(pMatrix) != k || ncol(pMatrix) != M)
      stop("Signal probabilities have unexpected dimensions.")
    probabilityTable <- .wgceTable(
      jaspResults,
      "signalProbabilities",
      "Estimated Signal Support Probabilities (p)",
      c(list(
        list(
          name = "term",
          title = "Coefficient",
          type = "string"
        )
      ), lapply(seq_len(M), function(i)
        list(
          name = paste0("p", i),
          title = paste0("p_", i),
          type = "number"
        )))
    )
    probabilityData <- data.frame(term = terms, pMatrix, check.names = FALSE)
    names(probabilityData) <- c("term", paste0("p", seq_len(M)))
    probabilityTable$setData(probabilityData)
    
    if (isTRUE(options$saveFitted) ||
        isTRUE(options$saveResiduals) ||
        isTRUE(options$saveW)) {
      saved <- jaspBase::createJaspContainer()
      saved$dependOn(
        c(
          "dependent",
          "covariates",
          "factors",
          "intercept",
          "lowerLimits",
          "upperLimits",
          "M",
          "J",
          "weight",
          "uniformSignalPrior",
          "signalPriorWeights",
          "uniformNoisePrior",
          "noisePriorWeights",
          "threeSigma",
          "noiseLower",
          "noiseUpper",
          "method",
          "seed",
          "bootstrap",
          "bootB",
          "bootMethod",
          "OLS",
          "saveFitted",
          "saveResiduals",
          "saveW"
        )
      )
      jaspResults[["savedColumns"]] <- saved
      if (isTRUE(options$saveFitted))
        .wgceSaveColumn(saved,
                        "WGCE_fitted",
                        fit$fitted.values,
                        completeRows,
                        nrow(dataset))
      if (isTRUE(options$saveResiduals))
        .wgceSaveColumn(saved,
                        "WGCE_residual",
                        fit$residuals,
                        completeRows,
                        nrow(dataset))
      if (isTRUE(options$saveW)) {
        w <- as.matrix(fit$w)
        if (nrow(w) != length(completeRows) || ncol(w) != J)
          stop("Noise probabilities have unexpected dimensions.")
        for (j in seq_len(J))
          .wgceSaveColumn(saved,
                          paste0("WGCE_w", j),
                          w[, j],
                          completeRows,
                          nrow(dataset))
      }
    }
    
    return(invisible(NULL))
  }, error = function(e) {
    summaryTable$setError(conditionMessage(e))
    return(invisible(NULL))
  })
}
