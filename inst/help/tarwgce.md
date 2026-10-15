# TARW-GCE Linear Model

TARW-GCE uses ridge-derived signal supports and cross-validation to select signal-point counts, noise-point counts, and noise weights. It delegates fitting to GCEstim::cv.lmgce() and reports the selected model.

Select a scale dependent variable and at least one covariate or factor. Configure the model, then select **Fit and update model**. This checkbox enables estimation; changing estimation settings while it is selected may refit the model. Clear it before making several costly changes.

Signal and noise candidate point counts are comma-separated odd integers of at least three. Noise weights are comma-separated values between zero and one. The cross-validation fold count cannot exceed the number of complete cases.

With one support space, the flexibility parameter is passed to GCEstim. With multiple spaces, the specified flexibility-parameter range and number of spaces define the support search. Symmetric or asymmetric ridge supports and either three-sigma or maximum-ridge-residual noise supports are available.

The one-standard-error selection rule may choose a model other than the first displayed CV row. The CV table is sorted by mean CV error; estimates always come from the package-selected model.

Bootstrap confidence intervals hide asymptotic standard deviation, z, and p columns. Precision-error plots require true coefficients in model-matrix order, including the intercept when present and expanded factor coefficients. Support-search plots require multiple support spaces; re-estimation plots require at least one post-GCE re-estimation. The CV plot follows the jamovi implementation and is available when multiple signal-point counts are supplied.

Saved fitted values, residuals, and selected-model noise probabilities use TARWGCE-prefixed names. Excluded cases receive missing values in the original row positions.

Display settings reuse the cached fit when model settings and data are unchanged. Plot failures are reported on the affected plot. This development version requires validation in JASP against the working jamovi implementation.

CV table headings name the selected error measure, for example In-sample RMSE and CV RMSE. Existing JASP plots and cache behavior are retained.
