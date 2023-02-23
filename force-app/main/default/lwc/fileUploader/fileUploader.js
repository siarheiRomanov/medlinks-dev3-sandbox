import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {loadStyle} from 'lightning/platformResourceLoader';

import uploadFile from '@salesforce/apex/DocGeneratorCtrl.uploadFile';
import getSize from '@salesforce/apex/LookAtPreviewCtrl.getSize';
import appealResources from '@salesforce/resourceUrl/Appeal_Resources';
import pubsub from 'c/pubsub';

const TYPE_FILE = 'DOCX';

export default class FileUploader extends LightningElement {
    @api recordId;
    fileData   = null;
    isDisabled = true;
    isSaved    = false;
    @track error;

    renderedCallback() {
        Promise.all([
            loadStyle(this, appealResources + '/fileUploaderStyle.css')
        ]);
    }

    openFileUpload(event) {
        const fileIsUploaded = new CustomEvent("fileuploaded", {
            detail: {
                files: event.target.files,
                isFileLoaded: true
            }
        });
        this.dispatchEvent(fileIsUploaded);

        const file = event.target.files[0];
        let reader = new FileReader();
        reader.onload = () => {
            let base64 = reader.result.split(',')[1];

            getSize({size: file.size})
                .then(result => {

                    this.fileData = {
                        'filename': file.name,
                        'base64': base64,
                        'recordId': this.recordId,
                        'filelastModifiedDate': this.formatDate(file.lastModifiedDate),
                        'filetype': TYPE_FILE,
                        'filesize': result
                    }

                })

        }
        reader.readAsDataURL(file);

        this.isDisabled = false;


    }

    handleClickSave() {
        const {base64, filename, recordId} = this.fileData;
        uploadFile({ base64, filename, recordId })
            .then(result => {
                pubsub.fire('fileSavedEvent', null);
            });
        this.showToast('Success', 'Template successfully saved', 'success');
        this.isSaved = true;

    }

    handleClickRemove() {
        this.fileData = null;
        this.isSaved = false;
        this.showToast('Info', 'File removed', 'info');
        this.dispatchEvent(new CustomEvent("removefile"));
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


    formatDate(date) {
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        let year = date.getFullYear();
        let month = monthNames[date.getMonth()];
        let day = date.getDate();
        return  year + '-' + month + '-' + day;
    }
}