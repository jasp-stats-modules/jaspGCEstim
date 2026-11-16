#' TARW-GCE Linear Model
#'
#' Fit adaptive W-GCE regression with ridge-derived supports and cross-validation through the JASP interface.
#'
#' @param data Data frame to analyze when the wrapper is called from R.
#' @param run Whether to fit and update the model.
#' @param dependent Dependent-variable selection in JASP option format.
#' @param covariates Covariate selections in JASP option format.
#' @param factors Factor selections in JASP option format.
#' @param intercept Whether to include an intercept.
#' @param ridgeSignalSupport Symmetric or asymmetric ridge-derived signal supports.
#' @param ridgeLambdaMin Minimum lambda for ridge-derived supports.
#' @param ridgeLambdaMax Maximum lambda for ridge-derived supports.
#' @param ridgeLambdaN Number of lambda values for ridge-derived supports.
#' @param M Number of signal-support points; for adaptive analyses, comma-separated candidate counts.
#' @param J Number of noise-support points; for adaptive analyses, comma-separated candidate counts.
#' @param weight Noise weight; for adaptive analyses, comma-separated candidate weights.
#' @param cvNfolds Number of cross-validation folds.
#' @param cvTableRows Maximum number of cross-validation result rows to display.
#' @param errorMeasure Prediction-error measure.
#' @param errorMeasureWhich Support-selection rule: minimum error or within one standard error.
#' @param supportSignalVectorMin Minimum flexibility parameter for candidate support spaces.
#' @param supportSignalVectorMax Maximum flexibility parameter for candidate support spaces.
#' @param supportSignalVectorN Number of candidate support spaces.
#' @param supportSignal Flexibility parameter when using a single support space.
#' @param noiseSupportMethod Noise-support specification.
#' @param twostepsN Number of post-GCE re-estimations.
#' @param seed Random seed.
#' @param OLS Whether to show the ordinary least-squares comparison.
#' @param NormEnt Whether to display normalized entropy.
#' @param bootstrap Whether to compute bootstrap confidence intervals.
#' @param bootB Number of bootstrap samples.
#' @param bootMethod Bootstrap resampling method.
#' @param bootCIMethod Bootstrap confidence-interval method.
#' @param bootConfLevel Confidence level for coefficient intervals.
#' @param method Optimization method passed to GCEstim.
#' @param plot1 Whether to show coefficient estimates and confidence intervals.
#' @param plot2 Whether to show supports versus prediction error.
#' @param plot3 Whether to show supports versus coefficient estimates.
#' @param plot4 Whether to show supports versus entropy.
#' @param plot5 Whether to show supports versus precision error.
#' @param plot6 Whether to show re-estimations versus entropy.
#' @param plot7 Whether to show re-estimations versus precision error.
#' @param plotCV Whether to show the cross-validation error plot.
#' @param plotRidge Whether to show the ridge trace for support selection.
#' @param trueCoef Comma-separated true coefficients for selected precision-error plots.
#' @param saveFitted Whether to save fitted values to the dataset.
#' @param saveResiduals Whether to save residuals to the dataset.
#' @param saveW Whether to save noise probabilities to the dataset.
#' @return JASP analysis results when called from R, or parsed analysis options when called by JASP.
#' @details Variable selections and analysis controls are interpreted by the corresponding JASP form. See the analysis help in JASP for the available options and limitations.
#' @export
tarwgce <- function(data = NULL, version = "1.0.0",
    run = FALSE,
    dependent = list(types = list(), value = list()),
    covariates = list(types = list(), value = list()),
    factors = list(types = list(), value = list()),
    intercept = TRUE,
    ridgeSignalSupport = "symm",
    ridgeLambdaMin = 0.001,
    ridgeLambdaMax = 1000,
    ridgeLambdaN = 100,
    M = "3, 5, 7",
    J = "3, 5, 7",
    weight = "0.3, 0.5, 0.7",
    cvNfolds = 5,
    cvTableRows = 10,
    errorMeasure = "RMSE",
    errorMeasureWhich = "1se",
    supportSignalVectorMin = 0.3,
    supportSignalVectorMax = 20,
    supportSignalVectorN = 5,
    supportSignal = 1,
    noiseSupportMethod = "sigma3",
    twostepsN = 1,
    seed = 230676,
    OLS = FALSE,
    NormEnt = FALSE,
    bootstrap = FALSE,
    bootB = 100,
    bootMethod = "residuals",
    bootCIMethod = "percentile",
    bootConfLevel = 0.95,
    method = "dual.lbfgsb3c",
    plot1 = FALSE,
    plot2 = TRUE,
    plot3 = FALSE,
    plot4 = FALSE,
    plot5 = FALSE,
    plot6 = FALSE,
    plot7 = FALSE,
    plotCV = TRUE,
    plotRidge = FALSE,
    trueCoef = "",
    saveFitted = FALSE,
    saveResiduals = FALSE,
    saveW = FALSE
) {
  supplied <- as.list(match.call())[-1L]
  supplied <- lapply(supplied, eval, envir = parent.frame())
  options <- lapply(formals(tarwgce), eval)
  options[names(supplied)] <- supplied
  options[c("data", "version")] <- NULL
  if (!jaspBase::jaspResultsCalledFromJasp() && !is.null(data))
    jaspBase::storeDataSet(data)
  jaspBase::runWrappedAnalysis("jaspGCEstim", "tarwgce", "Tarwgce.qml",
                               options, version, TRUE)
}
