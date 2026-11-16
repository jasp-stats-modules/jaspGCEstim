# GCEstim for JASP

GCEstim provides entropy-based linear regression and ridge regression diagnostics in JASP.

## Available analyses

- **W-GCE**: weighted generalized cross-entropy linear regression.
- **TARW-GCE**: adaptive W-GCE regression with ridge-based support selection.
- **TASW-GCE**: adaptive W-GCE regression with standardized supports.
- **Ridge Trace**: explore how ridge regression coefficients and prediction errors change with the penalty parameter.

## Getting started

1. Open your data in JASP and choose an analysis from the **GCEstim** menu.
2. Assign a dependent variable and covariates or factors, then choose the model options.
3. Select **Fit and update model** to view the results.

The regression analyses provide coefficient estimates, confidence intervals, support probabilities and diagnostic plots. Fitted values, residuals and noise probabilities can be saved to the dataset.

True coefficients are optional and are needed only for precision-error plots.

## Ridge Trace

Use an automatic or custom lambda grid and select a penalty using minimum prediction error, the 1-SE rule or a manual grid position. Tables and plots show coefficient paths, prediction errors, coefficient ranges and stability across cross-validation folds.

Coefficient ranges describe variation over the lambda grid; they are not confidence intervals. See the analysis help for the available options and limitations of standardized cross-validation.

## Help

Open the help for each analysis in JASP for explanations of its options, results and limitations.

GCEstim is developed by Jorge Cabral and uses the [GCEstim R package](https://CRAN.R-project.org/package=GCEstim).
