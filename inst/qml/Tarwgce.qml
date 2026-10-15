import QtQuick
import QtQuick.Layouts
import JASP.Controls
import JASP.Widgets

Form {
    VariablesForm {
        AvailableVariablesList { name: "availableVariables" }
        AssignedVariablesList {
            name: "dependent"
            label: qsTr("Dependent Variable")
            allowedColumns: ["scale"]
            singleVariable: true
        }
        AssignedVariablesList {
            name: "covariates"
            label: qsTr("Covariates")
            allowedColumns: ["scale"]
        }
        AssignedVariablesList {
            name: "factors"
            label: qsTr("Factors")
            allowedColumns: ["ordinal", "nominal"]
        }
    }

    CheckBox { name: "intercept"; label: qsTr("Intercept"); checked: true }
    CheckBox { name: "run"; label: qsTr("Fit and update model"); checked: false }
    Section {
        title: qsTr("Signal Support")
        columns: 1
        DropDown { name: "ridgeSignalSupport"; label: qsTr("Signal support specification"); values: [{ label: qsTr("Symmetric"), value: "symm" }, { label: qsTr("Asymmetric"), value: "asymm" }]; startValue: "symm" }
        DoubleField { name: "ridgeLambdaMin"; label: qsTr("Minimum ridge lambda"); defaultValue: 0.001; min: 0.000000000001 }
        DoubleField { name: "ridgeLambdaMax"; label: qsTr("Maximum ridge lambda"); defaultValue: 1000; min: 0.000000000001 }
        IntegerField { name: "ridgeLambdaN"; label: qsTr("Number of ridge lambda values"); defaultValue: 100; min: 2 }
        TextField { name: "M"; label: qsTr("Signal support points"); defaultValue: "3, 5, 7"; fieldWidth: 240 }
        IntegerField { id: supportSignalVectorN; name: "supportSignalVectorN"; label: qsTr("Number of signal support spaces"); defaultValue: 5; min: 1 }
        DoubleField { name: "supportSignal"; label: qsTr("Flexibility parameter (single support space)"); defaultValue: 1; min: 0.000001; enabled: supportSignalVectorN.value === 1 }
        DoubleField { name: "supportSignalVectorMin"; label: qsTr("Minimum flexibility parameter"); defaultValue: 0.3; min: 0.01; enabled: supportSignalVectorN.value > 1 }
        DoubleField { name: "supportSignalVectorMax"; label: qsTr("Maximum flexibility parameter"); defaultValue: 20; min: 0.01; enabled: supportSignalVectorN.value > 1 }
    }
    Section {
        title: qsTr("Noise Support")
        columns: 1
        TextField { name: "J"; label: qsTr("Noise support points"); defaultValue: "3, 5, 7"; fieldWidth: 240 }
        TextField { name: "weight"; label: qsTr("Noise weight values"); defaultValue: "0.3, 0.5, 0.7"; fieldWidth: 240 }
        DropDown { name: "noiseSupportMethod"; label: qsTr("Noise support specification"); values: [{ label: qsTr("3 sigma"), value: "sigma3" }, { label: qsTr("Maximum absolute ridge residuals"), value: "maxres" }]; startValue: "sigma3" }
    }
    Section {
        title: qsTr("Cross-Validation")
        columns: 1
        IntegerField { name: "cvNfolds"; label: qsTr("Number of CV folds"); defaultValue: 5; min: 2 }
        DropDown { name: "errorMeasure"; label: qsTr("Error measure"); values: [{ label: qsTr("RMSE"), value: "RMSE" }, { label: qsTr("MSE"), value: "MSE" }, { label: qsTr("MAE"), value: "MAE" }, { label: qsTr("MAPE"), value: "MAPE" }, { label: qsTr("sMAPE"), value: "sMAPE" }, { label: qsTr("MASE"), value: "MASE" }]; startValue: "RMSE" }
        DropDown { name: "errorMeasureWhich"; label: qsTr("Error selection rule"); values: [{ label: qsTr("Within one standard error"), value: "1se" }, { label: qsTr("Minimum error"), value: "min" }]; startValue: "1se" }
        IntegerField { name: "cvTableRows"; label: qsTr("Number of CV results to display"); defaultValue: 10; min: 1 }
    }
    Section {
        title: qsTr("Estimation")
        columns: 1
        DropDown { name: "method"; label: qsTr("Optimization method"); values: [{ label: qsTr("Dual: BFGS"), value: "dual.BFGS" }, { label: qsTr("Dual: lbfgsb3c"), value: "dual.lbfgsb3c" }, { label: qsTr("Dual: L-BFGS-B"), value: "dual.L-BFGS-B" }, { label: qsTr("Dual: lbfgs"), value: "dual.lbfgs" }, { label: qsTr("Dual: CG"), value: "dual.CG" }, { label: qsTr("Dual: Rcgmin"), value: "dual.Rcgmin" }, { label: qsTr("Dual: bobyqa"), value: "dual.bobyqa" }, { label: qsTr("Dual: newuoa"), value: "dual.newuoa" }, { label: qsTr("Dual: nlminb"), value: "dual.nlminb" }, { label: qsTr("Dual: nlm"), value: "dual.nlm" }, { label: qsTr("Primal: solnl"), value: "primal.solnl" }, { label: qsTr("Primal: solnp"), value: "primal.solnp" }]; startValue: "dual.lbfgsb3c" }
        IntegerField { name: "twostepsN"; label: qsTr("Number of post-GCE re-estimations"); defaultValue: 1; min: 0 }
        IntegerField { name: "seed"; label: qsTr("Seed"); defaultValue: 230676; min: 1; fieldWidth: 90}
    }
    Section {
        title: qsTr("Confidence Intervals")
        columns: 1
        DoubleField { name: "bootConfLevel"; label: qsTr("Confidence level"); defaultValue: 0.95; min: 0.50; max: 0.99 }
        CheckBox { id: bootstrap; name: "bootstrap"; label: qsTr("Bootstrap"); checked: false }
        IntegerField { name: "bootB"; label: qsTr("Number of bootstrap samples"); defaultValue: 100; min: 10; enabled: bootstrap.checked }
        DropDown { name: "bootMethod"; label: qsTr("Bootstrap method"); values: [{ label: qsTr("Residual"), value: "residuals" }, { label: qsTr("Case"), value: "cases" }, { label: qsTr("Wild"), value: "wild" }]; startValue: "residuals"; enabled: bootstrap.checked }
        DropDown { name: "bootCIMethod"; label: qsTr("Bootstrap confidence interval method"); values: [{ label: qsTr("Percentile"), value: "percentile" }, { label: qsTr("Basic"), value: "basic" }]; startValue: "percentile"; enabled: bootstrap.checked }
    }
    Section {
        title: qsTr("Plots")
        columns: 1
        CheckBox { name: "plotRidge"; label: qsTr("Ridge trace"); checked: false }
        CheckBox { name: "plotCV"; label: qsTr("Cross-validation error by support combination"); checked: true }
        CheckBox { name: "plot1"; label: qsTr("Estimates and confidence intervals"); checked: false }
        CheckBox { name: "plot2"; label: qsTr("Supports vs prediction error"); checked: true }
        CheckBox { name: "plot3"; label: qsTr("Supports vs estimates"); checked: false }
        CheckBox { name: "plot4"; label: qsTr("Supports vs normalized entropy"); checked: false }
        CheckBox { name: "plot5"; label: qsTr("Supports vs precision error"); checked: false }
        CheckBox { name: "plot6"; label: qsTr("GCE re-estimation vs prediction error"); checked: false }
        CheckBox { name: "plot7"; label: qsTr("GCE re-estimation vs precision error"); checked: false }
        TextField { name: "trueCoef"; label: qsTr("True coefficients"); defaultValue: ""; fieldWidth: 240 }
        CheckBox { name: "OLS"; label: qsTr("OLS comparison"); checked: false }
        CheckBox { name: "NormEnt"; label: qsTr("Normalized entropy"); checked: false }
    }
    Section {
        title: qsTr("Save")
        columns: 1
        CheckBox { name: "saveFitted"; label: qsTr("Fitted values"); checked: false }
        CheckBox { name: "saveResiduals"; label: qsTr("Residuals"); checked: false }
        CheckBox { name: "saveW"; label: qsTr("Estimated noise support probabilities (w)"); checked: false }
    }
}
