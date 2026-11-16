# Ridge Trace

Explore how ridge regression coefficients change with the penalty lambda. This analysis is independent of the W-GCE, TARW-GCE and TASW-GCE analyses.

## Model and lambda grid

Assign one scale dependent variable and at least one covariate or factor. Rows with missing selected variables are omitted. Include an intercept if required. Standardization is available with an intercept; the intercept is reconstructed afterward and is not penalized. Without standardization, intercept penalization can be selected separately. Standardization is disabled when the intercept is omitted.

Choose a positive geometric grid, or enter at least two distinct positive lambda values separated by commas. Custom values are sorted ascending. Select **Fit and update model** to run the analysis.

## Cross-validation and selection

Choose folds, seed and RMSE, MSE, MAE or sMAPE. The minimum rule chooses the smallest returned error (mean fold error for CV). The 1-SE rule chooses the largest lambda whose mean CV error is no greater than the minimum mean plus its standard error. All fold errors must be finite for a lambda to enter automatic CV selection. Manual selection uses an exact grid position, without interpolation or refitting.

With CV disabled, minimum in-sample error is descriptive; a stored 1-SE preference falls back to this minimum. CV-only plots are unavailable.

**GCEstim 1.1.0 limitation:** standardization uses the complete dataset before constructing CV folds, rather than independent fold-specific preprocessing. Standardized CV with an intercept and one predictor column is unsupported; disable standardization or CV for this model. Seeds do not guarantee identical results across software environments with different RNG settings.

## Tables

- Model Summary: model, settings, engine version, fit time and relevant notes.
- Selected Lambda: evaluated limits, selected lambda and rule.
- Coefficients: estimates at the selected lambda, in original units.
- Coefficient Ranges: minimum, maximum and maximum absolute coefficient over the evaluated grid, with the selected estimate. These are descriptive ranges, not confidence intervals.
- Lambda Results (optional): grid position, lambda, in-sample error, CV mean/SE where available, and selection markers. CV SE describes variation across folds, not a confidence interval.

## Plots

Coefficient paths, CV errors, in-sample errors, coefficient ranges, local sensitivity per change in log10(lambda), fold-specific CV errors, and coefficient stability across fold-training fits are available. Minimum-error and 1-SE references use dotted and dashed vertical lines. Manual selection uses a solid line. Plot options include logarithmic/linear lambda axes, intercept visibility, extrema, faceting, CV SE bars and fold-mean overlays.

To filter coefficient plots, enter the displayed coefficient names separated by commas. Enclose a name containing a comma in double quotes. Filtering affects coefficient plots only; tables retain all coefficients. Numeric negative plot labels use the mathematical minus sign.

Selection and display changes reuse this analysis's fitted ridge path; numerical settings refit it. Existing GCE analyses and their states are independent.
