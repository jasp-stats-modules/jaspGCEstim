# GCEstim for JASP: first development milestone

This separate JASP module starts with **W-GCE**. It calls `GCEstim::lmgce()`
with user-entered signal support limits, optional fixed noise support, and no
cross-validation or two-stage re-estimation. It displays the model summary,
support limits, coefficients and asymptotic 95% confidence intervals, and signal
support probabilities. TARW-GCE, TASW-GCE, plotting, bootstrap, and saved data
columns are later milestones. This starter is not the jamovi module.

## First local test on Windows

1. Copy this folder to a separate project directory, for example
   `C:\Users\jorge\OneDrive\Desktop\jaspGCEstim`.
2. Make sure `GCEstim` and JASP's `jaspBase` package are available to the R
   installation used for development. Run `R CMD INSTALL .` from a terminal
   in this project folder. JASP provides its own R environment; ordinary
   RStudio installation alone may not satisfy its module dependencies.
3. In JASP, open **Preferences → Advanced**, enable **Developer mode**, select
   the R library path where this package was installed, and enter
   `jaspGCEstim` as the development module name. Refresh the module after
   reinstalling it. See the [JASP module tutorial](https://github.com/jasp-stats/jasp-desktop/blob/development/Docs/development/jasp-modules-tutorial.md)
   for the version-specific developer workflow.
4. Select a numeric outcome and at least one covariate or factor. Start with
   `GCEstim::dataThesis` (`y` and `X001`–`X004`) if it is available in your JASP
   data set.

The current folder was checked structurally, but could not be run inside JASP
in this environment. Start by confirming that the menu and W-GCE table appear,
then compare its estimates with `GCEstim::lmgce()` on the same complete cases.
