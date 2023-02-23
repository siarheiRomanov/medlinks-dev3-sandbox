import {LightningElement, api} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getAttachmentsInfo from "@salesforce/apex/LookAtPreviewCtrl.getAttachmentsInfo"
import FILES from "@salesforce/resourceUrl/Appeal_Resources";

const DELAY_IN_MILLISECONDS = 1600;

export default class LookAtPreview extends NavigationMixin(LightningElement) {
    @api url;
    @api recordId;
    @api fileName;
    @api docId;
    @api pdfId;
    @api downloadDocUrl;
    @api downloadPDFUrl;
    @api isCreating = false;
    @api letterType;

    isPdfCreated;
    docName;
    docDate;
    docSize;
    pdfName;
    pdfDate;
    pdfSize;
    showSpinner = false;

    fileIcon = FILES + '/fileIcon/fileIcon.png';

    connectedCallback() {
        this.getAttachments();
    }

    getAttachments() {
        this.showSpinner = true;
        getAttachmentsInfo({recordId: this.recordId, letterType : this.letterType})
            .then(result => {
                this.isPdfCreated = (Object.keys(result).length == 6);
                this.docName = result['docName'];
                this.docSize = result['docSize'];
                this.docDate = result['docDate'];
                this.pdfName = result['pdfName'];
                this.pdfSize = result['pdfSize'];
                this.pdfDate = result['pdfDate'];
                if (!this.isPdfCreated) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: 'Creating pdf-file takes suspiciously much time. If you really need it click button "Create PDF" again, please.',
                            variant: 'warning',
                            mode: 'sticky'
                        }),
                    );
                }
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

    previewHandler(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName:'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }
}