import { LightningElement, api } from 'lwc';

export default class ProgressIndicator extends LightningElement {
    path;

    renderedCallback(){
    }

    @api
    get pathStep() {
        return this.path;
    }
    set pathStep(value) {
        this.handleValueChange(value);
    }

    handleValueChange(value) {
        const first   = this.template.querySelector('[data-id="0"]');
        const second  = this.template.querySelector('[data-id="1"]');
        const third   = this.template.querySelector('[data-id="2"]');
        const fourth  = this.template.querySelector('[data-id="3"]');

        if (first) {
            this.removeClasses(first);
            this.removeClasses(second);
            this.removeClasses(third);
            this.removeClasses(fourth);

            switch (value) {
                case '0':
                    this.setActive(first);
                    this.setIncomplete(second);
                    this.setIncomplete(third);
                    this.setIncomplete(fourth);
                    break;
                case '1':
                    this.setComplete(first);
                    this.setActive(second);
                    this.setIncomplete(third);
                    this.setIncomplete(fourth);
                    break;
                case '2':
                    this.setComplete(first);
                    this.setComplete(second);
                    this.setActive(third);
                    this.setIncomplete(fourth);
                    break;
                case '3':
                    this.setComplete(first);
                    this.setComplete(second);
                    this.setComplete(third);
                    this.setActive(fourth);
            }
        }
    }

    removeClasses(object) {
        object.classList.remove('slds-is-active');
        object.classList.remove('slds-is-current');
        object.classList.remove('slds-is-complete');
        object.classList.remove('slds-is-incomplete');
    }

    setComplete(object) {
        object.classList.add('slds-is-complete');
    }

    setIncomplete(object) {
        object.classList.add('slds-is-incomplete');
    }

    setActive(object) {
        object.classList.add('slds-is-current');
        object.classList.add('slds-is-active');
    }
}