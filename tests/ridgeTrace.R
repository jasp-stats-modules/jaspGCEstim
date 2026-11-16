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
    obj$addFootnote <- function(...) invisible(NULL)
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
  env$.rfit <- function(...) {
    env$fitCount <- env$fitCount + 1L
    env$fitArgs <- list(...)
    GCEstim::ridgetrace(...)
  }
  replace <- function(x) {
    if (missing(x) || !is.call(x)) return(x)
    if (identical(x, quote(GCEstim::ridgetrace))) return(as.name(".rfit"))
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
opts <- lapply(formals(env$ridgeTrace), eval); opts[c("data", "version")] <- NULL
opts$run <- TRUE; opts$dependent <- "y"; opts$covariates <- c("x", "z"); opts$factors <- character()
opts$lambdaN <- 12L; opts$cvNfolds <- 3L; opts$showLambdaTable <- TRUE
for (key in c("plotPaths", "plotCV", "plotRanges", "plotSensitivity", "plotFolds", "plotStability")) opts[[key]] <- TRUE
opts$plotSample <- "show"
data <- data.frame(x = seq(-2, 2, length.out=36), z = cos(1:36))
data$y <- -2 - 3 * data$x + .8 * data$z + sin(1:36)/3
data$group <- factor(rep(c("A", "B", "C"), 12)); data$y[4] <- NA_real_
run <- function(o=opts, dataset=data, results=new.env(), error=NULL) {
  suppressWarnings(env$ridgeTraceInternal(results, dataset, o))
  if (is.null(error)) {
    if (!is.null(results$modelSummary$error)) stop(results$modelSummary$error)
    for (key in ls(results)) if (!is.null(results[[key]]$error)) stop(key, ": ", results[[key]]$error)
  } else stopifnot(grepl(error, results$modelSummary$error, fixed=TRUE))
  results
}
r <- run(); cache <- r$ridgeTraceState$object; f <- cache$fit
direct <- do.call(GCEstim::ridgetrace, env$fitArgs)
stopifnot(isTRUE(all.equal(unname(f$coefficients), unname(direct$coef.lambda), check.attributes=FALSE)))
mean <- colMeans(f$cvErrors); se <- apply(f$cvErrors, 2, sd)/sqrt(3)
imin <- which.min(mean); i1se <- max(which(mean <= mean[imin]+se[imin]))
stopifnot(r$selectedLambda$data$selected == f$lambda[imin])
stopifnot(isTRUE(all.equal(r$lambdaResults$data$cvSE, se, check.attributes=FALSE)))
count <- env$fitCount
o <- opts; o$selection <- "1se"; r <- run(o, results=r)
stopifnot(env$fitCount == count, r$selectedLambda$data$selected == f$lambda[i1se])
o$selection <- "manual"; o$manualIndex <- 4L; o$displayTerms <- "x"; o$axisScale <- "linear"
r <- run(o, results=r)
stopifnot(env$fitCount == count, identical(r$ridgeTraceState$object, cache), r$selectedLambda$data$selected == f$lambda[4])
o$seed <- opts$seed+1; run(o, results=r); stopifnot(env$fitCount == count+1)
o <- opts; o$cv <- FALSE; o$selection <- "1se"; o$cvNfolds <- -1; o$seed <- -1
r0 <- run(o); stopifnot(is.null(r0$plotCV), is.null(r0$plotFolds), !is.null(r0$plotSample))
stopifnot(grepl("Minimum in-sample", r0$selectedLambda$data$rule))
o$intercept <- FALSE; r0 <- run(o); stopifnot(!env$fitArgs$standardize, nrow(r0$coefficients$data)==2)
o <- opts; o$covariates <- "x"; run(o, error="not currently supported")
o$standardize <- FALSE; run(o)
o <- opts; o$factors <- "group"; rf <- run(o); stopifnot(nrow(rf$coefficients$data)==5)
o <- opts; o$customGrid <- TRUE; o$lambdaValues <- "1.2e-9,1.1e-9"; o$selection <- "manual"; o$manualIndex <- 2L
rc <- run(o); stopifnot(rc$selectedLambda$data$selected==1.2e-9)
for (bad in c("1,1", "1,", "0,1", "NaN,1", "-1,2")) { o$lambdaValues <- bad; run(o,error="Custom lambda") }
o <- opts; o$displayTerms <- "unknown"; run(o,error="Unknown coefficient")
stopifnot(identical(env$.ridgeResolveTerms(c("`a,b`", "x"), '"a,b"'), "`a,b`"))
for (measure in c("MSE", "MAE", "sMAPE")) { o <- opts; o$errorMeasure <- measure; run(o) }
o <- opts; bad <- data; bad$x[1] <- Inf; run(o,bad,error="finite numeric")
o$manualIndex <- 99L; o$selection <- "manual"; run(o,error="Manual grid position")
fake <- f; fake$cvErrors[,] <- NA_real_
stopifnot(is.na(env$.ridgeSelection(fake,"min",f$lambda[1],TRUE)$index),
  env$.ridgeSelection(fake,"manual",f$lambda[2],TRUE)$index==2L)
fake$cvErrors <- f$cvErrors; fake$cvErrors[1,1] <- NA_real_
stopifnot(is.na(env$.ridgeSelection(fake,"min",f$lambda[1],TRUE)$mean[1]))
stopifnot(identical(env$.ridgeNumberLabels(c(-2,-.5,1)), c("\u22122","\u22120.5","1")))
palette <- env$.ridgeColours(list(coefficients=matrix(1,9,2,dimnames=list(letters[1:9],NULL))))
stopifnot(length(unique(palette))==9)
# A failed renderer must leave tables and the other plots usable.
originalPlot <- env$.ridgePlot
env$.ridgePlot <- function(cache,state,...) { if(state$key=="plotPaths") stop("Injected plot error"); originalPlot(cache,state,...) }
failed <- new.env(); env$ridgeTraceInternal(failed,data,opts)
stopifnot(grepl("Injected",failed$plotPaths$error), !is.null(failed$plotCV$plotObject), !is.null(failed$coefficients$data))
env$.ridgePlot <- originalPlot
# Export all seven plots for visual review when requested.
destination <- Sys.getenv("RIDGE_PLOT_DIR")
if (nzchar(destination)) {
  dir.create(destination, recursive=TRUE, showWarnings=FALSE)
  r <- run()
  for (key in c("plotPaths","plotCV","plotSample","plotRanges","plotSensitivity","plotFolds","plotStability")) {
    p <- r[[key]]$plotObject
    ggplot2::ggsave(file.path(destination,paste0(key,".png")),p,width=9,height=6,dpi=110)
  }
}
cat("Standalone Ridge Trace regression checks passed.\n")
