import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import appealResources from '@salesforce/resourceUrl/Appeal_Resources';

export default class SearchTemplates extends LightningElement {
    @api classes;
    @api label;
    @api placeholder;
    @api value;    
    @track isFocussed = false;

    filteredOptions = [];
    _options = [];
    

    renderedCallback() {
        Promise.all([
            loadStyle(this, appealResources + '/searchTemplatesStyle.css')
        ]);        
    }


    @api get options() {
        return this.filteredOptions;
    }

    set options(value) {       
        this.filteredOptions = [...value].map((item) => Object.assign({}, item));   
        this._options = [...value].map((item) => Object.assign({}, item));
    }

    filterOptions(event) {
        let filterText = event.detail.value;        
        this.filteredOptions = this._options.filter(option => {
            return option.label.toLowerCase().includes(filterText.toLowerCase());
        });
    }

    handleSelectOption(event) {
        this.value = event.currentTarget.dataset.label;
        const custEvent = new CustomEvent(
            'selectoption', {
                detail: {
                    value: event.currentTarget.dataset.value,
                    label: event.currentTarget.dataset.label,
                    // body: event.currentTarget.dataset.Body
                }
            }
        );
        this.dispatchEvent(custEvent);
        
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
        setTimeout(() => { this.isFocussed = false; }, 200);
    }
}