import {api, LightningElement, track, wire} from 'lwc';

import getTemplates from '@salesforce/apex/TemplateListController.getTemplates';
import deleteDocument from '@salesforce/apex/TemplateListController.deleteContentDocument';
import updateTemplate from '@salesforce/apex/TemplateListController.updateTemplate';
import getTemplate from '@salesforce/apex/DocGeneratorCtrl.getTemplate';
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import pubsub from 'c/pubsub';
import {refreshApex} from "@salesforce/apex";

export default class TemplateList extends NavigationMixin(LightningElement) {
    ourBlob;
    @api recordId;
    @track templateItems = [];
    selectedTemplate;
    @track filteredItems = [];
    numberOfTemplates;
    selectedTemplateTitle;
    refreshInfo;
    showSpinner = false;

    connectedCallback() {
        this.showSpinner = true;
        this.register();
    }

    register() {
        pubsub.register('fileSavedEvent', this.handleEvent.bind(this));
    }

    handleEvent() {
        refreshApex(this.refreshInfo)
            .then(result => {
                console.log('updated');
            });
    }

    @api
    handleTabChange() {
        let selectedDiv = this.template.querySelector(".selected");

        if (selectedDiv) {
            selectedDiv.classList.remove('selected');
            selectedDiv.classList.add('div_hover');
        }
    }

    @wire(getTemplates, {recordId: '$recordId'})
    getTemplates(result) {
        this.refreshInfo = result;

        if (result.data) {
            this.templateItems = result.data.map(function (template) {
                return {
                    label: template.title,
                    value: template.id,
                    docType: template.docType,
                    docSize: template.docSize,
                    docDate: template.createdDate,
                    url: template.url,
                }
            });

            this.filteredItems = result.data.map(function (template) {
                return {
                    label: template.title,
                    value: template.id,
                    docType: template.docType,
                    docSize: template.docSize,
                    docDate: template.createdDate,
                    url: template.url,
                }
            });

            this.numberOfTemplates = this.templateItems.length;
        }

        this.showSpinner = false;
    }

    handleTemplateClick(event) {
        this.selectedTemplate = event.currentTarget.dataset.id;
        this.getTemplate(this.selectedTemplate);
        let selectedDiv = this.template.querySelector(".selected");

        if (selectedDiv) {
            selectedDiv.classList.remove('selected');
            selectedDiv.classList.add('div_hover');
        }

        let div = event.currentTarget;
        div.classList.add('selected');
        div.classList.remove('div_hover');

    }

    filterTemplates(event) {
        const filterText = event.detail.value;
        this.filteredItems = this.templateItems.filter(templateItem => {
            return templateItem.label.toLowerCase().includes(filterText.toLowerCase());
        });
        this.numberOfTemplates = this.filteredItems.length;
    }

    previewHandler(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName:'filePreview'
            },
            state: {
                selectedRecordId: event.currentTarget.dataset.id
            }
        })
    }

    handleDeleteTemplate(event) {
        let templateToDelete = event.currentTarget.dataset.id;
        let title = this.filteredItems.find(item => item.value === templateToDelete).label;
        this.showSpinner = true;
        deleteDocument({
            recordId : templateToDelete
        })
            .then(result => {
                refreshApex(this.refreshInfo)
                    .then(result => {
                        console.log('deleted');
                    });
                this.showToast("Success", title + " was successfully deleted", "Success");
            })
            .catch(error => {
                console.error('**** error **** \n ',error)
            })
            .finally(() => {
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

    handleEditClick(event) {
        let templateToEdit = event.currentTarget.dataset.id;
        this.selectedTemplateTitle = this.filteredItems.find(item => item.value === templateToEdit).label;
        let input = this.template.querySelector(`[data-value="${templateToEdit}"]`);
        input.classList.remove("slds-is-collapsed");
        let title = this.template.querySelector(`[data-label="${templateToEdit}"]`);
        title.classList.add("slds-is-collapsed");
        let edit = this.template.querySelector(`[data-button="${templateToEdit}"]`);
        edit.classList.add("slds-is-collapsed");
    }

    handleTitleChange(event) {
        this.selectedTemplateTitle = event.target.value;
    }

    handleCheckClick(event) {
        this.showSpinner = true;
        updateTemplate({
            recordId : this.selectedTemplate,
            newTitle: this.selectedTemplateTitle
        })
            .then(result => {
                let templateToEdit = this.selectedTemplate;
                let input = this.template.querySelector(`[data-value="${templateToEdit}"]`);
                input.classList.add("slds-is-collapsed");
                let title = this.template.querySelector(`[data-label="${templateToEdit}"]`);
                title.textContent = this.selectedTemplateTitle;
                title.classList.remove("slds-is-collapsed");
                let edit = this.template.querySelector(`[data-button="${templateToEdit}"]`);
                edit.classList.remove("slds-is-collapsed");
                this.showToast("Success", "Title was successfully changed", "Success");
            })
            .catch(error => {
                console.error('**** error **** \n ',error)
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleCancelClick(event) {
        let templateToEdit = this.selectedTemplate;
        let input = this.template.querySelector(`[data-value="${templateToEdit}"]`);
        input.classList.add("slds-is-collapsed");
        let title = this.template.querySelector(`[data-label="${templateToEdit}"]`);
        title.classList.remove("slds-is-collapsed");
        let edit = this.template.querySelector(`[data-button="${templateToEdit}"]`);
        edit.classList.remove("slds-is-collapsed");
    }

    
    getTemplate(attID) {
        this.showSpinner = true;
        getTemplate({templateId: attID})
            .then(myBlob => {
                this.ourBlob  = this.b64toBlob(myBlob);
                const valueChangeEvent = new CustomEvent("templatechange", {
                    detail: {
                        templateId: this.ourBlob,
                    }
                });
                this.dispatchEvent(valueChangeEvent);
            }).catch(error => {
                console.log('error ', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    b64toBlob(b64Data, contentType, sliceSize) {
        contentType = contentType || 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        sliceSize = sliceSize || 512;
        var byteCharacters = atob(b64Data);
        var byteArrays = [];
        for (var offset = 0; offset < byteCharacters.length; offset += sliceSize) {
          var slice = byteCharacters.slice(offset, offset + sliceSize);
          var byteNumbers = new Array(slice.length);
          for (var i = 0; i < slice.length; i++) {
            byteNumbers[i] = slice.charCodeAt(i);
          }
          var byteArray = new Uint8Array(byteNumbers);
          byteArrays.push(byteArray);
        }
      
        var blob = new Blob(byteArrays, {type: contentType});
        return blob;
      }
}