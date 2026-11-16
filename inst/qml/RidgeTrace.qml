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


    Section {
        title: qsTr("Model")
        expanded: true
        columns: 1
        CheckBox { id: includeIntercept; name: "intercept"; label: qsTr("Include intercept"); checked: true }
        CheckBox { id: standardize; name: "standardize"; label: qsTr("Standardize variables"); checked: true; enabled: includeIntercept.checked }
        CheckBox { name: "penalizeIntercept"; label: qsTr("Penalize intercept"); checked: true; enabled: includeIntercept.checked && !standardize.checked }
        CheckBox { name: "run"; label: qsTr("Fit and update model"); checked: false }
    }
    Section {
        title: qsTr("Lambda Grid")
        columns: 1
        CheckBox { id: customGrid; name: "customGrid"; label: qsTr("Use custom lambda values"); checked: false }
        DoubleField { name: "lambdaMin"; label: qsTr("Minimum lambda"); defaultValue: 0.001; min: 1e-12; enabled: !customGrid.checked }
        DoubleField { name: "lambdaMax"; label: qsTr("Maximum lambda"); defaultValue: 1000; min: 1e-12; enabled: !customGrid.checked }
        IntegerField { name: "lambdaN"; label: qsTr("Number of lambda values"); defaultValue: 100; min: 2; enabled: !customGrid.checked }
        TextField { name: "lambdaValues"; label: qsTr("Custom lambda values (comma separated)"); defaultValue: "0.001, 0.01, 0.1, 1, 10, 100, 1000"; fieldWidth: 260; enabled: customGrid.checked }
    }
    Section {
        title: qsTr("Cross-Validation")
        columns: 1
        CheckBox { id: useCV; name: "cv"; label: qsTr("Cross-validation"); checked: true }
        IntegerField { name: "cvNfolds"; label: qsTr("Number of folds"); defaultValue: 5; min: 2; enabled: useCV.checked }
        IntegerField { name: "seed"; label: qsTr("Random seed"); defaultValue: 230676; min: 1; enabled: useCV.checked; fieldWidth: 120 }
        DropDown { name: "errorMeasure"; label: qsTr("Error measure"); values: [{label: qsTr("RMSE"), value: "RMSE"}, {label: qsTr("MSE"), value: "MSE"}, {label: qsTr("MAE"), value: "MAE"}, {label: qsTr("sMAPE"), value: "sMAPE"}]; startValue: "RMSE" }
    }
    Section {
        title: qsTr("Lambda Selection")
        columns: 1
        DropDown { id: selectionRule; name: "selection"; label: qsTr("Lambda selection rule"); values: [{label: qsTr("Minimum error"), value: "min"}, {label: qsTr("1-SE rule"), value: "1se"}, {label: qsTr("Manual (grid position)"), value: "manual"}]; startValue: "min" }
        IntegerField { name: "manualIndex"; label: qsTr("Manual lambda grid position (ascending order)"); defaultValue: 1; min: 1; enabled: selectionRule.value === "manual" }
    }
    Section {
        title: qsTr("Tables")
        columns: 1
        CheckBox { id: showLambdaTable; name: "showLambdaTable"; label: qsTr("Lambda results table"); checked: false }
        IntegerField { name: "tableRows"; label: qsTr("Maximum lambda rows to display"); defaultValue: 100; min: 1; enabled: showLambdaTable.checked }
    }
    Section {
        title: qsTr("Plots")
        columns: 1
        CheckBox { name: "plotPaths"; label: qsTr("Ridge Coefficient Paths"); checked: true }
        CheckBox { name: "plotCV"; label: qsTr("Cross-Validation Error"); checked: true; enabled: useCV.checked }
        DropDown { name: "plotSample"; label: qsTr("In-Sample Error"); values: [{label: qsTr("Show when CV is disabled"), value: "auto"}, {label: qsTr("Show"), value: "show"}, {label: qsTr("Hide"), value: "hide"}]; startValue: "auto" }
        CheckBox { name: "plotRanges"; label: qsTr("Coefficient Ranges"); checked: false }
        CheckBox { name: "plotSensitivity"; label: qsTr("Local Coefficient Sensitivity"); checked: false }
        CheckBox { name: "plotFolds"; label: qsTr("Fold-Specific CV Errors"); checked: false; enabled: useCV.checked }
        CheckBox { name: "plotStability"; label: qsTr("Coefficient Stability Across CV Folds"); checked: false; enabled: useCV.checked }
    }
    Section {
        title: qsTr("Plot Options")
        columns: 1
        DropDown { name: "axisScale"; label: qsTr("Lambda axis"); values: [{label: qsTr("Log10"), value: "log"}, {label: qsTr("Linear"), value: "linear"}]; startValue: "log" }
        CheckBox { name: "showIntercept"; label: qsTr("Include intercept in coefficient plots"); checked: true }
        CheckBox { name: "extrema"; label: qsTr("Mark coefficient extrema"); checked: false }
        CheckBox { name: "facet"; label: qsTr("Facet coefficient paths"); checked: false }
        TextField { name: "displayTerms"; label: qsTr("Coefficient names to display (comma separated; quote names containing commas)"); defaultValue: ""; fieldWidth: 260 }
        CheckBox { name: "seBars"; label: qsTr("CV mean \u00b1 1 SE"); checked: true; enabled: useCV.checked }
        CheckBox { name: "foldMean"; label: qsTr("Overlay mean fold error"); checked: true; enabled: useCV.checked }
    }
}
