// SysML v2: structural model, laboratory work 1, variant 18.
package CakeCalculator {


    part def CalculatorModel {
        attribute input : InputData;
        attribute result : CalculationResult;
        port calculate;
        port notify;
    }

    part def MainView {
        port listen;
        port userAction;
        port showError;
    }

    part def CalculatorController {
        port handle;
        port validationError;
    }

}
