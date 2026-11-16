#' W-GCE Linear Model
#'
#' Fit weighted generalized cross-entropy linear regression through the JASP interface.
#'
#' @param data Data frame to analyze when the wrapper is called from R.
#' @param version JASP module version used to interpret the analysis options.
#' @param run Whether to fit and update the model.
#' @param dependent Dependent-variable selection in JASP option format.
#' @param covariates Covariate selections in JASP option format.
#' @param factors Factor selections in JASP option format.
#' @param intercept Whether to include an intercept.
#' @param lowerLimits Comma-separated lower signal-support limits.
#' @param upperLimits Comma-separated upper signal-support limits.
#' @param M Number of signal-support points; for adaptive analyses, comma-separated candidate counts.
#' @param uniformSignalPrior Whether to use uniform signal prior probabilities.
#' @param signalPriorWeights Comma-separated signal prior probabilities, as decimals or fractions.
#' @param J Number of noise-support points; for adaptive analyses, comma-separated candidate counts.
#' @param uniformNoisePrior Whether to use uniform noise prior probabilities.
#' @param noisePriorWeights Comma-separated noise prior probabilities, as decimals or fractions.
#' @param weight Noise weight; for adaptive analyses, comma-separated candidate weights.
#' @param threeSigma Whether to use three-sigma noise-support limits.
#' @param noiseLower Lower limit for custom noise support.
#' @param noiseUpper Upper limit for custom noise support.
#' @param method Optimization method passed to GCEstim.
#' @param confLevel Confidence level for coefficient intervals.
#' @param bootstrap Whether to compute bootstrap confidence intervals.
#' @param bootB Number of bootstrap samples.
#' @param bootMethod Bootstrap resampling method.
#' @param bootCIMethod Bootstrap confidence-interval method.
#' @param seed Random seed.
#' @param plot1 Whether to show coefficient estimates and confidence intervals.
#' @param OLS Whether to show the ordinary least-squares comparison.
#' @param saveFitted Whether to save fitted values to the dataset.
#' @param saveResiduals Whether to save residuals to the dataset.
#' @param saveW Whether to save noise probabilities to the dataset.
#' @return JASP analysis results when called from R, or parsed analysis options when called by JASP.
#' @details Variable selections and analysis controls are interpreted by the corresponding JASP form. See the analysis help in JASP for the available options and limitations.
#' @export
wgce <- function(
    data = NULL,
    version = "1.0.0",
    run = FALSE,
    dependent = list(types = list(), value = list()),
    covariates = list(types = list(), value = list()),
    factors = list(types = list(), value = list()),
    intercept = TRUE,
    lowerLimits = "-10",
    upperLimits = "10",
    M = 3,
    uniformSignalPrior = TRUE,
    signalPriorWeights = "1/4, 1/2, 1/4",
    J = 3,
    uniformNoisePrior = TRUE,
    noisePriorWeights = "1/3, 1/3, 1/3",
    weight = 0.5,
    threeSigma = TRUE,
    noiseLower = -10,
    noiseUpper = 10,
    method = "dual.lbfgsb3c",
    confLevel = 0.95,
    bootstrap = FALSE,
    bootB = 100,
    bootMethod = "residuals",
    bootCIMethod = "percentile",
    seed = 230676,
    plot1 = TRUE,
    OLS = FALSE,
    saveFitted = FALSE,
    saveResiduals = FALSE,
    saveW = FALSE
) {
  supplied <- as.list(match.call())[-1L]
  supplied <- lapply(supplied, eval, envir = parent.frame())
  
  defaults <- lapply(formals(wgce), eval)
  options <- defaults
  options[names(supplied)] <- supplied
  options[c("data", "version")] <- NULL
  
  if (!jaspBase::jaspResultsCalledFromJasp() && !is.null(data))
    jaspBase::storeDataSet(data)
  
  jaspBase::runWrappedAnalysis(
    "jaspGCEstim", "wgce", "Wgce.qml",
    options, version, TRUE
  )
}