#' Standalone Ridge Trace
#'
#' Explore ridge coefficient paths, lambda selection and cross-validation diagnostics through the JASP interface.
#'
#' @param data Data frame to analyze when the wrapper is called from R.
#' @param run Whether to fit and update the model.
#' @param dependent Dependent-variable selection in JASP option format.
#' @param covariates Covariate selections in JASP option format.
#' @param factors Factor selections in JASP option format.
#' @param intercept Whether to include an intercept.
#' @param standardize Whether to standardize variables when an intercept is included.
#' @param penalizeIntercept Whether to penalize the intercept when standardization is disabled.
#' @param customGrid Whether to use custom lambda values.
#' @param lambdaMin Minimum lambda for the automatic geometric grid.
#' @param lambdaMax Maximum lambda for the automatic geometric grid.
#' @param lambdaN Number of values in the automatic lambda grid.
#' @param lambdaValues Comma-separated, distinct positive lambda values for the custom grid.
#' @param cv Whether to use cross-validation.
#' @param cvNfolds Number of cross-validation folds.
#' @param seed Random seed.
#' @param errorMeasure Prediction-error measure.
#' @param selection Lambda-selection rule: minimum error, one standard error, or manual grid position.
#' @param manualIndex Ascending lambda-grid position used for manual selection.
#' @param showLambdaTable Whether to show the per-lambda results table.
#' @param tableRows Maximum number of lambda-result rows to display.
#' @param axisScale Logarithmic or linear lambda-axis scale.
#' @param showIntercept Whether to include the intercept in coefficient plots.
#' @param extrema Whether to mark coefficient extrema.
#' @param facet Whether to facet coefficient paths.
#' @param displayTerms Coefficient names to display, separated by commas; quote names containing commas.
#' @param seBars Whether to show one-standard-error bars for mean CV error.
#' @param foldMean Whether to overlay the mean fold error.
#' @param plotPaths Whether to show ridge coefficient paths.
#' @param plotCV Whether to show the cross-validation error plot.
#' @param plotSample In-sample error plot visibility: automatic, show, or hide.
#' @param plotRanges Whether to show descriptive coefficient ranges.
#' @param plotSensitivity Whether to show local coefficient sensitivity.
#' @param plotFolds Whether to show fold-specific CV errors.
#' @param plotStability Whether to show coefficient stability across CV folds.
#' @return JASP analysis results when called from R, or parsed analysis options when called by JASP.
#' @details Variable selections and analysis controls are interpreted by the corresponding JASP form. See the analysis help in JASP for the available options and limitations.
#' @export
ridgeTrace <- function(data = NULL, version = "1.0.0",
    run = FALSE,
    dependent = list(types = list(), value = list()),
    covariates = list(types = list(), value = list()),
    factors = list(types = list(), value = list()),
    intercept = TRUE,
    standardize = TRUE,
    penalizeIntercept = TRUE,
    customGrid = FALSE,
    lambdaMin = 0.001,
    lambdaMax = 1000,
    lambdaN = 100,
    lambdaValues = "0.001, 0.01, 0.1, 1, 10, 100, 1000",
    cv = TRUE,
    cvNfolds = 5,
    seed = 230676,
    errorMeasure = "RMSE",
    selection = "min",
    manualIndex = 1,
    showLambdaTable = FALSE,
    tableRows = 100,
    axisScale = "log",
    showIntercept = TRUE,
    extrema = FALSE,
    facet = FALSE,
    displayTerms = "",
    seBars = TRUE,
    foldMean = TRUE,
    plotPaths = TRUE,
    plotCV = TRUE,
    plotSample = "auto",
    plotRanges = FALSE,
    plotSensitivity = FALSE,
    plotFolds = FALSE,
    plotStability = FALSE
) {
  supplied <- as.list(match.call())[-1L]
  supplied <- lapply(supplied, eval, envir = parent.frame())
  options <- lapply(formals(ridgeTrace), eval)
  options[names(supplied)] <- supplied
  options[c("data", "version")] <- NULL
  if (!jaspBase::jaspResultsCalledFromJasp() && !is.null(data)) jaspBase::storeDataSet(data)
  jaspBase::runWrappedAnalysis("jaspGCEstim", "ridgeTrace", "RidgeTrace.qml", options, version, TRUE)
}
