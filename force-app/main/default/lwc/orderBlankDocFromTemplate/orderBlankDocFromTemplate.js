import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {loadScript} from 'lightning/platformResourceLoader';
import {NavigationMixin} from "lightning/navigation";

import createAttachment from '@salesforce/apex/DocGeneratorCtrl.createAttachment';
import getWrapper from '@salesforce/apex/DynamicWrapperClass.getWrapper';
import createPDFAttachment from '@salesforce/apex/CreateRequestForPdf.createPDFAttachment';
import getUrl from '@salesforce/apex/CreateRequestForPdf.getUrl';

import appealResources from '@salesforce/resourceUrl/Appeal_Resources';

export default class OrderBlankDocFromTemplate extends NavigationMixin(LightningElement) {
    @api recordId;
    @api contractFormDocFromUser
    @api docVersion;
    @api templateUrl;
    @api letterType;

    docxInitialized = false;
    wrapper;
    url;
    urlPDF;
    stepNumber = 0;
    fileContents;
    fileReader;
    content;

    renderedCallback() {
        if (this.docxInitialized) {
            return;
        }

        this.today = new Date();


        Promise.all([
            loadScript(this, appealResources + '/docxtemplater.js'),
            loadScript(this, appealResources + '/pizzip.js'),
            loadScript(this, appealResources + '/pizzip_utils.js')
        ])
            .then(() => {

                this.initializeDocx();
            })
            .catch(error => {
                this.showToast(
                    'Error1', error.message, 'error'
                );
            });
    }

    initializeDocx() {
        this.docxInitialized = true;

        getWrapper({recordId: this.recordId}).then(async result => {
            this.wrapper = result;
            this.handleBlankDownload();
        }).catch(error => {
            this.showToast('Error2', error.message, 'error');
        })
    }

    loadFile(url, callback) {
        PizZipUtils.getBinaryContent(url, callback);
    }

    generate(data) {
        if (this.templateUrl) {
            var reader = new FileReader();
            reader.readAsArrayBuffer(this.templateUrl)
            reader.onload = (event) => {
                const content = event.target.result;
                this.processContent(content, data);
            };

        } else if (this.contractFormDocFromUser) {
            var reader = new FileReader();
            reader.readAsBinaryString(this.contractFormDocFromUser[0]);
            reader.onload = (event) => {
                const content = event.target.result;
                this.processContent(content, data);
            };
        }
    }

    processContent(content, data) {
        let zip = new PizZip(content);
        let doc;
        try {
            doc = new window.docxtemplater(zip, {paragraphLoop: true, linebreaks: true});
        } catch (error) {
            this.errorHandler(error);
        }

        doc.setData(data);
        try {
            doc.render();
        } catch (error) {
            this.errorHandler(error);
        }

        let out = doc.getZip().generate({
            type: "blob",
            mimeType: "text/plain",
        });

        this.saveFile(out);
    }

    saveFile(out) {
        this.fileReader = new FileReader();
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            let base64 = 'base64,';
            this.content = this.fileContents.indexOf(base64) + base64.length;
            this.fileContents = this.fileContents.substring(this.content);
            this.attachDocument();
        });
        this.fileReader.readAsDataURL(out);
    }

    attachDocument() {
        createAttachment({
            recordId: this.recordId,
            file: encodeURIComponent(this.fileContents),
            letterType: this.letterType
        })
            .then(result => {
                this.createPDFonClick(result);

            }).catch(error => {
            console.log('error ', error);
        });
    }

    replaceErrors(key, value) {
        if (value instanceof Error) {
            return Object.getOwnPropertyNames(value).reduce(function (error, key) {
                error[key] = value[key];
                return error;
            }, {});
        }
        return value;
    }

    errorHandler(error) {
        if (error.properties && error.properties.errors instanceof Array) {
            const errorMessages = error.properties.errors.map(function (error) {
                return error.properties.explanation;
            }).join("\n");
            this.showToast('Wrong Template', errorMessages, 'error');
        }
        throw error;
    }

    handleBlankDownload() {
        try {
            let dataForGenerator = {};
            let itemsList = [];

            for (let i = 0; i < Object.keys(this.wrapper.listObjectFields).length; i++) {
                let iterationData = {};

                for (const [key, value] of Object.entries(this.wrapper.listObjectFields[i])) {
                    for (const [api, apiValue] of Object.entries(value)) {
                        if (api != undefined) {
                            iterationData[api] = apiValue;
                        }
                    }
                }

                itemsList.push(iterationData);
            }

            dataForGenerator['items'] = itemsList;

            for (const [key, value] of Object.entries(this.wrapper.objectFields)) {
                for (const [api, apiValue] of Object.entries(value)) {
                    if (api != undefined) {
                        const regexDate = /^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$/;

                        if (typeof apiValue === 'string' && apiValue.length >= 10 && regexDate.test(apiValue.substring(0, 10))) {
                            dataForGenerator[api] = new Date(apiValue).toLocaleDateString('en-us', {
                                year: 'numeric',
                                month: '2-digit',
                                day: '2-digit'
                            }).toString().replaceAll('/', '-');
                        } else {
                            dataForGenerator[api] = apiValue;
                        }
                    }
                }
            }

            this.generate(dataForGenerator);
        } catch(error) {
            this.showToast('Error3', error.message, 'error');
        }
    }

    createPDFonClick(docID) {
        let cycle = 0;
        let pdfPreview = setInterval(() => {
            if (!this.urlPDF && cycle < 10) {
                this.getUrl(docID);
                cycle++;

                if (this.stepNumber < 5) {
                    this.stepNumber++;
                }
            } else if (!this.urlPDF) {
                clearInterval(pdfPreview);
                const valueChangeEvent = new CustomEvent("valuechange", {
                    detail: {
                        docxDocID: docID
                    }
                });
                this.dispatchEvent(valueChangeEvent);
            } else {
                clearInterval(pdfPreview);
                this.createPDF(docID);
            }
        }, 2000);
    }

    createPDF(docID) {
        createPDFAttachment({
            parentId: this.recordId,
            url: this.urlPDF,
            letterType: this.letterType,
        }).then(result => {
            const valueChangeEvent = new CustomEvent("valuechange", {
                detail: {
                    pdfDocID: result,
                    docxDocID: docID
                }
            });
            this.showToast('Success', 'Document Version was created successfully', 'success');
            this.dispatchEvent(valueChangeEvent);
        }).catch(error => {
            console.log('error ', error);
            this.showToast('Error', error.message, 'error');
        });
    }

    getUrl(docID) {
        getUrl({contentDocumentId: docID})
            .then(url => {
                this.urlPDF = url
            }).catch(error => {
                console.log('error ', error);
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
}