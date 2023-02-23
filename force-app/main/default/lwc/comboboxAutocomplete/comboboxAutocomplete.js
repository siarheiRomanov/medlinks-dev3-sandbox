import {LightningElement, api, track} from 'lwc';
import getWrapper from '@salesforce/apex/DynamicWrapperClass.getWrapper';

export default class ComboboxAutocomplete extends LightningElement {

    @api classes;
    @api label;
    @api placeholder;
    @api value;
    @track options;
    firstInvocation = true;
    @track isFocussed = false;
    @track filteredOptions = [];
    @api recordId;
    @api searchElement;


    renderedCallback() {
        if (this.firstInvocation) {
            this.firstInvocation = false;
            this.getOptions();
        }     
    }

    getOptions() {
        getWrapper({recordId : this.recordId})
            .then(result => {
                let options = [];
                let objectFields = result.objectFields;
                let listObjectFields = result.listObjectFields;

                for (const [key, value] of Object.entries(objectFields)) {
                    for (const [key1, value1] of Object.entries(value)) {
                        if (key1 != undefined) {
                            let option = { label: key, value: '{' + key1 + '}' };
                            options.push(option);
                        }
                    }
                }

                if (listObjectFields.length != 0) {
                    for (const [key, value] of Object.entries(listObjectFields[0])) {
                        for (const [key1, value1] of Object.entries(value)) {
                            let option = { label: key, value: '{' + key1 + '}' };
                            options.push(option);
                        }
                    }
                }

                this.options = options.filter(option => option.label.includes(this.searchElement));
                this.filteredOptions = this.options;
            });
    }

    filterOptions(event) {
        const filterText = event.detail.value;
        this.filteredOptions = this.options.filter(option => {
            return option.label.toLowerCase().includes(filterText.toLowerCase());
        });
    }

    handleSelectOption(event) {
        this.value = event.currentTarget.dataset.label;
        const custEvent = new CustomEvent(
            'selectoption', {
            detail: {
                value: event.currentTarget.dataset.value,
                label: event.currentTarget.dataset.label
            }
        });
        this.dispatchEvent(custEvent);

        // Close the picklist options
        this.isFocussed = false;
    }

    get noOptions() {
        return this.filteredOptions.length === 0;
    }

    get dropdownClasses() {

        let dropdownClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

        // Show dropdown list on focus
        if (this.isFocussed) {
            dropdownClasses += ' slds-is-open';
        }

        return dropdownClasses;
    }

    handleFocus() {
        this.isFocussed = true;
    }

    handleBlur() {
        // Timeout to ensure click event is captured before the
        // options are hidden
        setTimeout(() => { this.isFocussed = false; }, 500);
    }
}