# Run from the package source directory: Rscript --vanilla tests/step1.R
# Uses the real GCEstim estimator; JASP output objects are lightweight test doubles.
stopifnot(requireNamespace("GCEstim", quietly = TRUE))
stopifnot(as.character(utils::packageVersion("GCEstim")) == "1.1.0")
root <- if (dir.exists("R")) "." else ".."
loadAnalysis <- function(path) {
  env <- new.env(parent = globalenv())
  files <- list.files(file.path(path, "R"), pattern = "[.]R$", full.names = TRUE)
  if (length(files)) {
    for (file in files) sys.source(file, env)
  } else {
    ns <- asNamespace("jaspGCEstim")
    stopifnot(utils::packageVersion("jaspGCEstim") >= package_version("0.0.5"))
    for (key in ls(ns, all.names = TRUE)) {
      fn <- get(key, envir = ns)
      if (is.function(fn) && identical(environment(fn), ns)) {
        environment(fn) <- env
        env[[key]] <- fn
      }
    }
  }
  env$fitCount <- 0L
  env$fitArgs <- list()
  newObject <- function() {
    obj <- new.env(parent = emptyenv())
    obj$object <- NULL
    obj$dependOn <- function(...) invisible(NULL)
    obj$addCitation <- function(...) invisible(NULL)
    obj$setData <- function(x) obj$data <- x
    obj$setError <- function(x) obj$error <- x
    obj
  }
  env$.mock_encodeColNames <- identity
  env$.mock_createJaspState <- newObject
  env$.mock_createJaspContainer <- newObject
  env$.mock_createJaspPlot <- function(...) newObject()
  env$.fit <- function(...) {
    env$fitCount <- env$fitCount + 1L
    env$fitArgs <- list(...)
    GCEstim::cv.lmgce(...)
  }
  env$.wfit <- function(...) {
    env$fitCount <- env$fitCount + 1L
    env$fitArgs <- list(...)
    GCEstim::lmgce(...)
  }
  replace <- function(x) {
    if (missing(x) || !is.call(x)) return(x)
    if (identical(x, quote(GCEstim::cv.lmgce))) return(as.name(".fit"))
    if (identical(x, quote(GCEstim::lmgce))) return(as.name(".wfit"))
    if (identical(x[[1]], as.name("::")) && identical(x[[2]], as.name("jaspBase")))
      return(as.name(paste0(".mock_", as.character(x[[3]]))))
    for (i in seq_along(x)) {
      if (identical(x[i], alist(a = ))) next
      x[i] <- list(replace(x[[i]]))
    }
    x
  }
  for (key in ls(env, all.names = TRUE)) {
    fn <- env[[key]]
    if (is.function(fn) && identical(environment(fn), env)) {
      body(fn) <- replace(body(fn))
      env[[key]] <- fn
    }
  }
  env$.wgceTable <- function(results, key, title, columns) {
    obj <- newObject(); obj$columns <- columns; obj$title <- title
    results[[key]] <- obj
    obj
  }
  env$.wgceSaveColumn <- function(container, name, values, rows, totalRows) {
    stopifnot(length(values) == length(rows))
    aligned <- rep(NA_real_, totalRows); aligned[rows] <- values
    container[[name]] <- aligned
  }
  env
}
env <- loadAnalysis(root)
validate <- env$.gceOptionalTrueCoefficients
for (input in list(NULL, NA_character_, "", "bad", "1,", "1,,2", "Inf,2", "1,2")) {
  stopifnot(is.null(validate(input, 3L, FALSE)$warning))
  v <- validate(input, 3L, TRUE)
  stopifnot(is.null(v$values), grepl("skipped", v$warning))
}
stopifnot(identical(validate("1,1,2", 3L, TRUE)$values, c(1,1,2)))
ids <- c("`A space`", "A space", "`Group name`B", "(Intercept)")
labels <- env$.gceCoefficientLabels(ids)
stopifnot(identical(names(labels), ids), !anyDuplicated(unname(labels)), labels[3] == "Group nameB")

data <- data.frame(x = seq(-1, 1, length.out = 24), z = cos(1:24))
data$y <- 1 + 2 * data$x + sin(1:24) / 4
data$group <- factor(rep(c("A", "B", "C"), 8))
data$y[4] <- NA_real_
defaults <- function(kind, e = env) {
  x <- lapply(formals(e[[kind]]), eval)
  x[c("data", "version")] <- NULL
  x$run <- TRUE; x$dependent <- "y"; x$covariates <- c("x", "z"); x$factors <- character()
  x$saveFitted <- x$saveResiduals <- x$saveW <- TRUE
  x$plot1 <- FALSE
  if (kind != "wgce") {
    x$M <- "3"; x$J <- "3"; x$weight <- "0.5"; x$cvNfolds <- 3L
    x$supportSignalVectorN <- 3L; x$supportSignalVectorMin <- 1; x$supportSignalVectorMax <- 4
    x$twostepsN <- 0L; x$errorMeasureWhich <- "min"
    for (name in c(paste0("plot", 1:7), "plotCV", "plotRidge"))
      if (name %in% names(x)) x[[name]] <- FALSE
    if (kind == "tarwgce") x$ridgeLambdaN <- 10L
  }
  x
}
run <- function(kind, options, e = env, results = new.env(), dataset = data) {
  suppressWarnings(e[[paste0(kind, "Internal")]](results, dataset, options))
  if (!is.null(results$modelSummary$error)) stop(kind, " (intercept=", options$intercept,
    ", factors=", paste(options$factors, collapse=","), "): ", results$modelSummary$error)
  results
}
for (kind in c("tarwgce", "taswgce")) {
  opts <- defaults(kind)
  opts$plot1 <- TRUE; opts$plot5 <- TRUE; opts$trueCoef <- "bad"
  count <- env$fitCount
  results <- run(kind, opts)
  stopifnot(env$fitCount == count + 1L, nrow(results$coefficients$data) == 3L)
  stopifnot(grepl("Precision-error plots skipped", tail(results$modelSummary$data$value, 1L)))
  stopifnot(is.null(results$plot5), inherits(results$plot1$plotObject, "ggplot"))
  stopifnot(nrow(results$signalProbabilities$data) == 3L, nrow(results$cvResults$data) == 1L)
  stopifnot(is.na(results$savedColumns[[paste0(toupper(kind), "_fitted")]][4]))
  stopifnot(results$coefficients$columns[[5]]$title == "SE")
  stopifnot(results$signalProbabilities$columns[[2]]$title == "p (point 1)")
  stopifnot("Asymptotic normal" %in% results$modelSummary$data$value)
  # Correcting only optional text reuses the existing fitted model.
  opts$trueCoef <- "1,1,2"
  results <- run(kind, opts, results = results)
  stopifnot(env$fitCount == count + 1L, inherits(results$plot5$plotObject, "ggplot"))
  stopifnot(!any(grepl("skipped", results$modelSummary$data$value)))
  # Checked but unavailable plots must ignore stale/invalid optional text.
  opts$plot7 <- TRUE; opts$twostepsN <- 0L; opts$supportSignalVectorN <- 1L
  opts$trueCoef <- "bad"; opts$plot1 <- FALSE
  results <- run(kind, opts)
  stopifnot(is.null(results$plot5), is.null(results$plot7),
            !any(grepl("skipped", results$modelSummary$data$value)))
  # Factor/intercept changes determine the expected vector length from the model matrix.
  opts <- defaults(kind); opts$supportSignalVectorN <- 1L; opts$twostepsN <- 1L
  opts$factors <- "group"; opts$plot7 <- TRUE
  opts$trueCoef <- "1,1,2"
  results <- run(kind, opts)
  stopifnot(nrow(results$coefficients$data) == 5L, is.null(results$plot7),
            any(grepl("5 true coefficients", results$modelSummary$data$value)))
}
# Validate no-intercept dimensions without invoking the engine's unsupported
# standardized ridge/no-intercept configuration.
count <- ncol(stats::model.matrix(y ~ x + z + group - 1, data))
stopifnot(count == 5L, length(validate("1,1,1,1,1", count, TRUE)$values) == 5L)
stopifnot(grepl("5 true coefficients", validate("1,1,1", count, TRUE)$warning))
opts <- defaults("wgce"); opts$bootstrap <- TRUE; opts$bootB <- 10L
results <- run("wgce", opts)
stopifnot(nrow(results$coefficients$data) == 3L,
          results$signalProbabilities$columns[[2]]$title == "p (point 1)")
stopifnot(!"sd" %in% names(results$coefficients$data))
opts$bootstrap <- FALSE
results <- run("wgce", opts)
stopifnot(results$coefficients$columns[[5]]$title == "SE", "sd" %in% names(results$coefficients$data))

# Optional baseline supplied by the development runner: compare actual numerical
# outputs against the reviewed GitHub source, including W-GCE bootstrap intervals.
baseline <- Sys.getenv("STEP1_BASELINE_DIR")
if (nzchar(baseline)) {
  old <- loadAnalysis(baseline)
  for (kind in c("wgce", "tarwgce", "taswgce")) {
    opts <- defaults(kind)
    if (kind == "wgce") { opts$bootstrap <- TRUE; opts$bootB <- 10L }
    RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(230676)
    before <- run(kind, opts, e = old)
    RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(230676)
    after <- run(kind, opts)
    for (key in c("coefficients", "signalSupports", "signalProbabilities", "cvResults")) {
      a <- before[[key]]$data; b <- after[[key]]$data
      if (is.null(a)) next
      columns <- setdiff(names(a), c("term", "time"))
      stopifnot(isTRUE(all.equal(a[columns], b[columns], tolerance = 1e-12)))
    }
    savedNames <- grep("^(WGCE|TARWGCE|TASWGCE)_", ls(before$savedColumns), value = TRUE)
    for (name in savedNames)
      stopifnot(identical(before$savedColumns[[name]], after$savedColumns[[name]]))
  }
}
cat("PASS: optional input, applicable plots, warnings, retained model results, cache reuse, table labels, factors, missing rows and bootstrap.\n")
