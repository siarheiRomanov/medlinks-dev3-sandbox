import {LightningElement, api} from 'lwc';

export default class App extends LightningElement {

    @api get selected() {
        return this._selected;
    };

    set selected(value) {
        this._selected = (value === undefined) ? false : value;
    }

    @api label;
    @api value;

    _selected;


    handleSelect(event) {
        this._selected = !this._selected;
        if (this._selected === true) {
            this.sendEvent('add');
        } else {
            this.sendEvent('remove');
        }
    }

    sendEvent(eventName) {
        this.dispatchEvent(new CustomEvent(eventName, {detail: {value: this.value}}));
    }
}