# GCEstim for JASP — development version 0.0.3

This source module contains W-GCE, TARW-GCE, and TASW-GCE. Existing W-GCE and TARW-GCE R files, wrappers, QML forms, and help are preserved unchanged from the previous delivered version.

TASW-GCE follows the supplied jamovi implementation: standardized-coefficient symmetric signal supports, three-sigma noise supports, cross-validation, selected-model tables and probabilities, confidence intervals, plots, and saved outputs. There are no ridge settings or ridge trace plot in TASW-GCE.

Use the folder with your existing JASP module development workflow. The package name remains jaspGCEstim. Install/reload the combined module to add TASW-GCE alongside the existing analyses. The ZIP contains source files, not a compiled JASP binary. Copying only taswgce.R will not register the new analysis: its wrapper, form, NAMESPACE exports, and Description.qml registration are also required.

Set variables and options before selecting Fit and update model. Clear that checkbox before changing several costly estimation settings. See inst/help/taswgce.md for details and VALIDATION.md for the limits of testing.
