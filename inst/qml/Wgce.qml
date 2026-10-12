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

    Section {
        title: qsTr("Signal Support")
        columns: 1
        TextField {
            name: "lowerLimits"
            label: qsTr("Lower limits (comma separated)")
            defaultValue: "-10"
            fieldWidth: 180
        }
        TextField {
            name: "upperLimits"
            label: qsTr("Upper limits (comma separated)")
            defaultValue: "10"
            fieldWidth: 180
        }
        IntegerField { name: "M"; label: qsTr("Signal support points"); defaultValue: 3; min: 3; max: 99 }
        CheckBox { id: uniformSignalPrior; name: "uniformSignalPrior"; label: qsTr("Uniform signal prior"); checked: true }
        TextField {
            name: "signalPriorWeights"
            label: qsTr("Signal prior probabilities (comma separated)")
            defaultValue: "1/3, 1/3, 1/3"
            fieldWidth: 200
            enabled: !uniformSignalPrior.checked
        }
    }

    Section {
        title: qsTr("Noise Support")
        columns: 1
        IntegerField { name: "J"; label: qsTr("Noise support points"); defaultValue: 3; min: 3; max: 99 }
        CheckBox { id: uniformNoisePrior; name: "uniformNoisePrior"; label: qsTr("Uniform noise prior"); checked: true }
        TextField {
            name: "noisePriorWeights"
            label: qsTr("Noise prior probabilities (comma separated)")
            defaultValue: "1/3, 1/3, 1/3"
            fieldWidth: 200
            enabled: !uniformNoisePrior.checked
        }
        DoubleField { name: "weight"; label: qsTr("Noise weight"); defaultValue: 0.5; min: 0; max: 1 }
        CheckBox { id: threeSigma; name: "threeSigma"; label: qsTr("3 sigma noise support"); checked: true }
        DoubleField { name: "noiseLower"; label: qsTr("Lower limit"); defaultValue: -10; negativeValues: true; enabled: !threeSigma.checked }
        DoubleField { name: "noiseUpper"; label: qsTr("Upper limit"); defaultValue: 10; negativeValues: true; enabled: !threeSigma.checked }
    }

    Section {
        title: qsTr("Estimation")
        columns: 1
        DropDown {
            name: "method"
            label: qsTr("Optimization method")
            values: [
                { label: qsTr("Dual: BFGS"), value: "dual.BFGS" },
                { label: qsTr("Dual: lbfgsb3c"), value: "dual.lbfgsb3c" },
                { label: qsTr("Primal: solnl"), value: "primal.solnl" },
                { label: qsTr("Primal: solnp"), value: "primal.solnp" },
                { label: qsTr("Dual: CG"), value: "dual.CG" },
                { label: qsTr("Dual: L-BFGS-B"), value: "dual.L-BFGS-B" },
                { label: qsTr("Dual: Rcgmin"), value: "dual.Rcgmin" },
                { label: qsTr("Dual: bobyqa"), value: "dual.bobyqa" },
                { label: qsTr("Dual: newuoa"), value: "dual.newuoa" },
                { label: qsTr("Dual: nlminb"), value: "dual.nlminb" },
                { label: qsTr("Dual: nlm"), value: "dual.nlm" },
                { label: qsTr("Dual: lbfgs"), value: "dual.lbfgs" },
                { label: qsTr("Dual: optimParallel"), value: "dual.optimParallel" }
            ]
            startValue: "dual.lbfgsb3c"
        }
    }

    Section {
        title: qsTr("Confidence Intervals")
        columns: 1
        DoubleField { name: "confLevel"; label: qsTr("Confidence level"); defaultValue: 0.95; min: 0.01; max: 0.99 }
        CheckBox { id: bootstrap; name: "bootstrap"; label: qsTr("Bootstrap"); checked: false }
        IntegerField { name: "bootB"; label: qsTr("Number of bootstrap samples"); defaultValue: 100; min: 10; enabled: bootstrap.checked }
        DropDown {
            name: "bootMethod"
            label: qsTr("Bootstrap method")
            values: [
                { label: qsTr("Residual"), value: "residuals" },
                { label: qsTr("Case"), value: "cases" },
                { label: qsTr("Wild"), value: "wild" }
            ]
            startValue: "residuals"
            enabled: bootstrap.checked
        }
        DropDown {
            name: "bootCIMethod"
            label: qsTr("Bootstrap confidence interval method")
            values: [
                { label: qsTr("Percentile"), value: "percentile" },
                { label: qsTr("Basic"), value: "basic" }
            ]
            startValue: "percentile"
            enabled: bootstrap.checked
        }
        IntegerField { 
            name: "seed"
            label: qsTr("Seed")
            defaultValue: 230676
            min: 1
            fieldWidth: 90
        }
    }

    Section {
        title: qsTr("Plots")
        columns: 1
        CheckBox {
            name: "plot1"
            label: qsTr("Estimates and confidence intervals")
            checked: true
        }
        CheckBox { name: "OLS"; label: qsTr("Include OLS estimates in plot"); checked: false }
    }

    Section {
        title: qsTr("Save")
        columns: 1
        CheckBox { name: "saveFitted"; label: qsTr("Fitted values"); checked: false }
        CheckBox { name: "saveResiduals"; label: qsTr("Residuals"); checked: false }
        CheckBox { name: "saveW"; label: qsTr("Noise support probabilities (w)"); checked: false }
    }
}
