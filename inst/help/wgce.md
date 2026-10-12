# W-GCE Linear Model

W-GCE fits a weighted generalized cross entropy linear regression using the GCEstim R package. Select one numeric dependent variable and at least one covariate or factor. The model uses observations with complete values for the selected variables.

## Variables

- **Covariates:** Numeric predictors.
- **Factors:** Categorical predictors. Each non-reference level has its own coefficient.
- **Intercept:** Include an intercept in the model.

## Signal support

The lower and upper limits define the range of possible values for each coefficient. Enter one limit per field to use it for every coefficient, or enter comma-separated limits for individual coefficients. Include the intercept, when selected, and each non-reference factor level. Every lower limit must be below its upper limit.

**Signal support points** sets the number of equally spaced points in each coefficient’s support; use an odd integer of at least 3. **Uniform signal prior** assigns equal prior probabilities. Clear it to enter one probability per point, for example `1/4, 1/2, 1/4`.

## Noise support

**Noise support points** sets the number of noise support points; use an odd 
integer of at least 3. **Uniform noise prior** assigns equal prior probabilities. 
Clear it to specify one probability per point.

**Noise weight** must be strictly between 0 and 1. **3 sigma noise support** 
calculates symmetric noise limits automatically; clear it to enter lower and 
upper limits yourself.

## Estimation and confidence intervals

Choose an optimization method and confidence level. The default optimizer is 
**Dual: lbfgsb3c**. Enable **Bootstrap** to choose the number of samples, 
resampling method, and confidence interval method. The seed controls 
reproducibility of random sampling.

## Results and plot

The results show model settings, signal support limits, coefficient estimates 
and confidence intervals, and estimated signal support probabilities (*p*). 
Without bootstrap, the coefficients table also shows standard deviation, z, 
and p. The estimates plot can include ordinary least squares (OLS) estimates 
for comparison.

## Saved columns

Under **Save**, select fitted values, residuals, or estimated noise support 
probabilities (*w*) to add them to the data set. Observations excluded because 
of missing model variables have missing saved values.

## Reference

Cabral, J. (2026). *GCEstim: Regression Coefficients Estimation Using the Generalized Cross Entropy*. R package. https://CRAN.R-project.org/package=GCEstim