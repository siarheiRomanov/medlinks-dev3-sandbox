import {LightningElement, api} from 'lwc';

const GREY_FONT = 'step-name-grey';
const NORMAL_FONT = 'step-name-normal';
const BOLD_FONT = 'step-name-bold';

export default class ProgressStep extends LightningElement {
    @api stepName;
    @api renderedStep = 0; // when only all steps names are rendered

    _stepNumber;

    progress = 50;

    get stepNameStyle() {
        return (this.isStepDone) ?
            NORMAL_FONT : (
                (this.isCurrentStep) ? BOLD_FONT : GREY_FONT
            );
    }

    get isStepDone() {
        return (this._stepNumber > this.renderedStep);
    }

    get isCurrentStep() {
        return (this._stepNumber === this.renderedStep);
    }

    @api get stepNumber() {
        return this._stepNumber;
    }

    set stepNumber(stepNumber) {
        this._stepNumber = stepNumber + 1; // in orderBlankDocFromTemplate comp-t steps start from 0
    }
}