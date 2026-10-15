# GCEstim for JASP ? development version 0.0.4

The module provides W-GCE, TARW-GCE, and TASW-GCE linear regression using GCEstim. Version 0.0.4 adapts the current jamovi module's non-plot changes while retaining the existing JASP plot implementation and cache logic.

Use this source folder with your existing JASP development-module workflow. The package name remains jaspGCEstim. Reload/install the complete updated module so that its R code, wrappers, and forms are updated together. This ZIP contains source, not a compiled JASP binary.

Select variables, set options, and select **Fit and update model**. W-GCE now has this control too. Clear it before making several expensive estimation changes.

TARW-GCE and TASW-GCE use **flexibility parameter** labels for the single-space value and search limits. Their CV tables identify the selected prediction-error measure in the column headings. W-GCE's custom signal-prior default is 1/4, 1/2, 1/4; the default fit still uses a uniform signal prior.
