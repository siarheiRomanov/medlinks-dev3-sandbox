import {api, track, LightningElement} from 'lwc';
import getFieldList from '@salesforce/apex/AppealFieldSetCtrl.getFieldList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY_IN_MILLISECONDS = 1400;

export default class AppealFieldSetInput extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @track fieldSetFields = [];
    showSpinner = false;

    connectedCallback() {
        this.getFieldSetFieldList();
    }

    getFieldSetFieldList() {
        this.showSpinner = true;
        getFieldList({fieldSetName : this.fieldSetName})
            .then(response => {
                this.fieldSetFields = response;
            })
            .catch(error => {
                console.log(error);
                this.showToast('Error', error.message, 'error');
            })
            .finally(() => {
                setTimeout(() => {
                    this.showSpinner = false;
                }, DELAY_IN_MILLISECONDS);
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

    @api
    submitHandler() {
        const buttonSave = this.template.querySelector( ".hidden" );

        if (buttonSave){
            this.showSpinner = true;
            buttonSave.click();
        }

    }

    handleSuccess() {
        this.showSpinner = false;

        this.showToast('Success!', 'The record has been updated successfully', 'success');
        this.dispatchEvent(new CustomEvent('success'));
    }

    handleError(event) {
        this.showSpinner = false;

        this.showToast('Error!', event.getParam("error").message, 'error');
    }
}