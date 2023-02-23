import {LightningElement, api, wire, track} from 'lwc';
import sendEmail from '@salesforce/apex/EmailHandler.sendEmail';
import getTemplates from '@salesforce/apex/EmailHandler.getTemplates';
import getAttachments from '@salesforce/apex/EmailHandler.getAttachments';
import getAttachmentsInfo from '@salesforce/apex/SecondScreen.getAttachmentsInfo'
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

export default class ThirdScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @track templateItems = [];
    @track checkBoxItems = [];
    firstAttachments = [];
    allAttachments = [];
    showButton = false;
    showAllAttachments = false;
    @track selectedAttachments = [];
    selectedContact;
    value;
    body;
    firstInvocation = true;
    defaultAttachmentsInfo = {};

    @wire(getTemplates)
    wiredTemplates({data}) {
        if (data) {
            this.templateItems = data.map(function (template) {
                return {
                    label: template.Name,
                    value: template.Id,
                    body: template.Body
                }
            });
        }
    }

    renderedCallback() {
        if (this.firstInvocation) {
            this.firstInvocation = false;
            this.getAttachments();
        }
    }

    getAttachments() {

        getAttachments({recordId: this.recordId})
            .then(result => {
                this.allAttachments = result.map(function (attachment) {
                    return {
                        label: attachment.label,
                        value: attachment.value,
                        date: attachment.date,
                        size: attachment.size,
                    }
                });
            });

        getAttachmentsInfo({recordId: this.recordId})
            .then(result => {

                this.defaultAttachmentsInfo.isPdfCreated = (Object.keys(result).length === 6);
                this.defaultAttachmentsInfo.docName = result['docName'];
                this.defaultAttachmentsInfo.docSize = result['docSize'];
                this.defaultAttachmentsInfo.docDate = result['docDate'];
                this.defaultAttachmentsInfo.pdfName = result['pdfName'];
                this.defaultAttachmentsInfo.pdfSize = result['pdfSize'];
                this.defaultAttachmentsInfo.pdfDate = result['pdfDate'];

                if (this.defaultAttachmentsInfo.isPdfCreated) {
                    this.allAttachments[0].selected = true;
                    this.allAttachments[1].selected = true;
                } else {
                    this.allAttachments[0].selected = true;
                }
            });
    }

    previewHandler(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }

    handleCheckBoxChange(event) {
        const value = event.target.value;
        const checked = event.target.checked;

        if (checked) {
            this.selectedAttachments.push(value);
        } else {
            this.selectedAttachments = this.selectedAttachments.filter(item => item !== value);
        }
    }

    handleLookupChange(event) {
        this.selectedContact = event.target.value;
    }

    handleListChange(event) {
        const selectedOption = event.detail.value;
        console.log(selectedOption);
        console.log(this.items);
        const template = this.templateItems.find(item => item.value === selectedOption);
        console.log(template.body);
        this.body = template.body;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    sendEmailHandler() {

        this.selectedAttachments = this.template.querySelector('c-multiselect-attachments').getAttachmentsToSend();

        sendEmail({
            contactId: this.selectedContact,
            body: this.body,
            attachments: this.selectedAttachments
        })
            .then(result => {
                if (result) {
                    this.showToast('Success', 'Email sent successfully', 'success');
                } else {
                    this.showToast('Error', 'We were unable to send your email', 'error');
                }
            });

    }

    get templateOptions() {
        return this.templateItems;
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

    showButtonHandler(event) {
        if (this.showAllAttachments) {
            event.target.label = "Show more"
            this.showAllAttachments = false;
        } else {
            event.target.label = "Show less";
            this.showAllAttachments = true;
        }
    }
}