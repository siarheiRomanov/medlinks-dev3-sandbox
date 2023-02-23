import {LightningElement, api} from 'lwc';

export default class ProgressRing extends LightningElement {
    _value;

    @api get value() {
        return this._value;
    }

    set value(value) {
        //this._value = value;
        //this._value = (value * 20) + 20;
        this._value = value * 20;
        this.setAttribute('value', this._value);
    }

    renderedCallback() {
        this.changeProgress(this._value);
    }

    changeProgress(value) {
        this.template.querySelector('.ring circle:nth-child(2)').style.strokeDashoffset = 785 - (785 * value) / 100;
    }
}