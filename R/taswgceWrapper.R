taswgce <- function(data = NULL, version = "0.0.3",
    run = FALSE,
    dependent = list(types = list(), value = list()),
    covariates = list(types = list(), value = list()),
    factors = list(types = list(), value = list()),
    intercept = TRUE,
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
    trueCoef = "",
    saveFitted = FALSE,
    saveResiduals = FALSE,
    saveW = FALSE
) {
  supplied <- as.list(match.call())[-1L]
  supplied <- lapply(supplied, eval, envir = parent.frame())
  options <- lapply(formals(taswgce), eval)
  options[names(supplied)] <- supplied
  options[c("data", "version")] <- NULL
  if (!jaspBase::jaspResultsCalledFromJasp() && !is.null(data))
    jaspBase::storeDataSet(data)
  jaspBase::runWrappedAnalysis("jaspGCEstim", "taswgce", "Taswgce.qml",
                               options, version, TRUE)
}
