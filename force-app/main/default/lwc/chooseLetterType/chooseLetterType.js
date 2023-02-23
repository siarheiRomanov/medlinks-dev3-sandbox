import {LightningElement, track} from 'lwc';
import getLetterTypes from '@salesforce/apex/AppealFieldSetCtrl.getLetterTypes';
import LETTER_TYPE_FIELD from '@salesforce/schema/ContentVersion.Letter_Type__c';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class ChooseLetterType extends LightningElement {
    @track options;
    value;
    showSpinner = false;

    connectedCallback() {
        this.getLetterTypesValues();
    }

    getLetterTypesValues() {
        this.showSpinner = true;
        getLetterTypes({fieldApiName : LETTER_TYPE_FIELD.fieldApiName})
            .then(response => {
                this.options     = response;
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
            }).finally(() => {
                this.showSpinner = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }),
        );
    }

    handleChange(event) {
        this.value = event.detail.value;
        const letterType = this.value;

        this.dispatchEvent(new CustomEvent('lettertype', {
            detail: {letterType},
        }));
    }
}