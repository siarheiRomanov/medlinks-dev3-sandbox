import {LightningElement, track, api, wire} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import getTemplateId from '@salesforce/apex/TemplateHelper.getTemplateId';
import getImageId from '@salesforce/apex/TemplateHelper.getImageId';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';

import THIRD_PARTY_FIRM_FIELD from '@salesforce/schema/Appeal__c.Third_Party_Firm__c';
import OPPOSING_SCHEDULER_FIELD from '@salesforce/schema/Appeal__c.Opposing_Scheduler__c';
import OPPOSING_SPECIALIST_FIELD from '@salesforce/schema/Appeal__c.Opposing_Appeals_Specialist__c';
import APPEAL_SCHEDULER_FIELD from '@salesforce/schema/Appeal__c.Appeal_Scheduler__c';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const NOT_REQUIRED_LOOKUP_FIELDS = [THIRD_PARTY_FIRM_FIELD, OPPOSING_SCHEDULER_FIELD, OPPOSING_SPECIALIST_FIELD, APPEAL_SCHEDULER_FIELD];
const DELAY_IN_MILLISECONDS      = 1600;

export default class DisplayApiFields extends NavigationMixin(LightningElement) {
    @api recordId;
    @track options;
    imageUrl;
    templateUrl;
    imageId;
    value;
    selectedFacilityAccountField = '';
    selectedClientAccountField = '';
    selectedPayerAccountField = '';
    selectedAppealField = '';
    selectedNoteField = '';
    selectedOverreadContactField = '';
    selectedFacilityPrimaryContactField = '';
    selectedThirdPartyFirmAccountField = '';
    selectedOpposingSchedulerContactField = '';
    selectedOpposingSpecialistContactField = '';
    selectedAppealSchedulerUserField = '';
    selectedAssignedPMUserField = '';
    selectedAppealSpecialistUserField = '';
    firstInvocation = true;
    @track appeal;
    showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: NOT_REQUIRED_LOOKUP_FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            console.log('error: ', error);
        } else if (data) {
            this.appeal = data;
        }
    };

    get existThirdPartyFirm() {
        return getFieldValue(this.appeal, THIRD_PARTY_FIRM_FIELD);
    }

    get existOpposingScheduler() {
        return getFieldValue(this.appeal, OPPOSING_SCHEDULER_FIELD);
    }

    get existOpposingSpecialist() {
        return getFieldValue(this.appeal, OPPOSING_SPECIALIST_FIELD);
    }

    get existAppealScheduler() {
        return getFieldValue(this.appeal, APPEAL_SCHEDULER_FIELD);
    }

    renderedCallback() {
        if (this.firstInvocation) {
            this.getTemplateAndImage();
            this.firstInvocation = false;
        }
    }

    getTemplateAndImage() {
        this.showSpinner = true;
        getTemplateId({recordId : this.recordId})
            .then(result => {
                this.templateUrl = '/sfc/servlet.shepherd/document/download/' + result.ContentDocumentId;
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
            }).finally(() => {
                setTimeout(() => {
                    this.showSpinner = false;
                }, DELAY_IN_MILLISECONDS);
            });
        getImageId()
            .then(result => {
                this.imageId =  result.ContentDocumentId;
                this.imageUrl = '/sfc/servlet.shepherd/document/download/' + this.imageId;
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
            }).finally(() => {
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

    previewHandler() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName:'filePreview'
            },
            state: {
                selectedRecordId: this.imageId
            }
        })
    }

    handleFacilityAccountOptionChange(event) {
        this.selectedFacilityAccountField = event.detail.value;
    }

    handleClientAccountOptionChange(event) {
        this.selectedClientAccountField = event.detail.value;
    }

    handlePayerAccountOptionChange(event) {
        this.selectedPayerAccountField = event.detail.value;
    }

    handleAppealOptionChange(event) {
        this.selectedAppealField = event.detail.value;
    }

    handleNoteOptionChange(event) {
        this.selectedNoteField = event.detail.value;
    }

    handleOverreadContactOptionChange(event) {
        this.selectedOverreadContactField = event.detail.value;
    }

    handleFacilityPrimaryContactOptionChange(event) {
        this.selectedFacilityPrimaryContactField = event.detail.value;
    }

    handleThirdPartyFirmOptionChange(event) {
        this.selectedThirdPartyFirmAccountField = event.detail.value;
    }

    handleOpposingSchedulerContactOptionChange(event) {
        this.selectedOpposingSchedulerContactField = event.detail.value;
    }

    handleOpposingSpecialistContactOptionChange(event) {
        this.selectedOpposingSpecialistContactField = event.detail.value;
    }

    handleAppealSchedulerUserOptionChange(event) {
        this.selectedAppealSchedulerUserField = event.detail.value;
    }

    handleAssignedPMUserOptionChange(event) {
        this.selectedAssignedPMUserField = event.detail.value;
    }

    handleAppealSpecialistUserOptionChange(event) {
        this.selectedAppealSpecialistUserField = event.detail.value;
    }

    copyToClipboard(event) {
        const selector = event.currentTarget.dataset.label;
        let inp = this.template.querySelector(selector);
        inp.disabled = false;
        inp.select();
        document.execCommand('copy');
        inp.disabled = true;
    }
}