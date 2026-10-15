# TASW-GCE Linear Model

TASW-GCE uses symmetric signal supports based on standardized coefficients and three-sigma noise supports. GCEstim::cv.lmgce() selects a model across candidate signal-point counts, noise-point counts, and noise weights.

Select a scale dependent variable and at least one covariate or factor. Set the options, then select **Fit and update model**. This checkbox enables fitting. Clear it before changing several expensive estimation settings.

Signal and noise point counts must be comma-separated odd integers of at least three. Candidate noise weights must be between zero and one. The number of cross-validation folds must be at least two and cannot exceed the number of complete cases.

With one support space, the flexibility parameter is used. With multiple spaces, the flexibility-parameter range and space count define the search. TASW-GCE has no ridge parameters or ridge trace plot.

The Model Summary is followed by the CV plot, Cross-validation Results, Signal Supports, Estimated Signal Support Probabilities, Coefficients, and the remaining plots. Optional outputs appear only when selected and applicable. Time is shown to two decimal places. The CV table sorts rows by mean CV error; coefficients and probabilities come from the package-selected model, which may differ from the minimum-error row under the one-standard-error rule.

Bootstrap interval choices are percentile and basic, with residual, case, or wild resampling. Asymptotic standard deviation, z, and p columns are hidden with bootstrap intervals. Precision-error plots require true coefficients in model-matrix order, including the intercept when present and expanded factor terms.

Support-search plots require multiple support spaces. Re-estimation plots require at least one post-GCE re-estimation. As in jamovi, the CV plot requires more than one candidate signal-point count.

Saved columns use TASWGCE-prefixed names. Fitted values, residuals, and noise probabilities from the selected model are aligned to the original rows; excluded cases receive missing values. Display-only changes reuse the fitted model when data and estimation settings are unchanged.

CV table headings name the selected error measure, for example In-sample RMSE and CV RMSE. Existing JASP plots and cache behavior are retained.
