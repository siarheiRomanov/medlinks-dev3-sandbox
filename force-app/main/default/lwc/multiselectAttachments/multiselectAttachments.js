import {LightningElement, track, api} from 'lwc';

export default class App extends LightningElement {

    @api get allAttachments() {
        return this._allAttachments;
    }

    set allAttachments(value) {
        this._allAttachments = [...value].map((item) => Object.assign({}, item));
        this.populateSelectedValuesOnInit();
    }

    @api getAttachmentsToSend() {
        let attachmentsToSendIds = [];
        for (let item of this.selectedValues) {
            attachmentsToSendIds.push(item.value);
        }
        return attachmentsToSendIds;
    }

    @track _allAttachments;
    @track selectedValues = [];

    showDropdown = false;

    populateSelectedValuesOnInit() {
        const selectedAttachments = [];

        this._allAttachments.forEach((attachmentItem) => {
            if (attachmentItem.selected === true) {
                selectedAttachments.push(this._allAttachments[this.findIndexById(this._allAttachments, attachmentItem.value)]);
            }
        });

        this.selectedValues = selectedAttachments;
    }

    handleLeave() {
        if (this.showDropdown === true) {
            this.showDropdown = false;
        }
    }

    handleShowDropdown() {
        this.showDropdown = this.showDropdown !== true;
    }

    onAddItem(event) {
        this.changeAllAttachmentArray(event.detail.value, true);
        this.selectedValues.push(this._allAttachments[this.findIndexById(this._allAttachments, event.detail.value)]);
    }

    onRemoveItem(event) {
        this.changeAllAttachmentArray(event.detail.value, false);
        this.selectedValues.splice(this.findIndexById(this.selectedValues, event.detail.value), 1);
    }

    handleAttachRemoved(event) {
        this.changeAllAttachmentArray(event.detail.value, false);
        this.selectedValues.splice(this.findIndexById(this.selectedValues, event.detail.value), 1);
    }

    changeAllAttachmentArray(id, selected) {
        this.showDropdown = false;
        this._allAttachments[this.findIndexById(this._allAttachments, id)].selected = selected;
    }

    findIndexById(array, id) {
        return array.findIndex((item) => item.value === id);
    }

}