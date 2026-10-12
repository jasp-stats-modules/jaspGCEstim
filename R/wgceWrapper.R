wgce <- function(
    data = NULL,
    version = "0.0.1",
    dependent = list(types = list(), value = list()),
    covariates = list(types = list(), value = list()),
    factors = list(types = list(), value = list()),
    intercept = TRUE,
    lowerLimits = "-10",
    upperLimits = "10",
    M = 3,
    uniformSignalPrior = TRUE,
    signalPriorWeights = "1/3, 1/3, 1/3",
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