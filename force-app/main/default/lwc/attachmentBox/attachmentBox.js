import {LightningElement, api} from 'lwc';

export default class AttachmentBox extends LightningElement {
    @api itemData;

    handleRemove() {
        this.dispatchEvent(new CustomEvent('attachremoved',
            {
                detail: {value: this.itemData.value},
                bubbles: true,
                composed: true
            }));
    }
}