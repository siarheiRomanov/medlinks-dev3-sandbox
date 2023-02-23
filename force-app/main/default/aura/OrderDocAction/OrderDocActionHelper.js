({
    initHelper : function(component) {
        const pageReference = component.get("v.pageReference");

        component.set("v.refRecordId", pageReference.state.c__refRecordId);
    },

    handleFilesChangeHelper : function(component, event) {
        component.set("v.File", event.getParam("files"));
        component.set("v.isButtonUnactive", false);
        component.set("v.isFileLoaded", event.getParam("isFileLoaded"));
    },

    handleOnSuccessHelper : function(component) {
        component.set("v.secondScreen",  false);
        component.set("v.thirdScreen",   true);
    },

    handleOnLetterTypeHelper : function(component, event) {
        component.set("v.letterType", event.getParam('letterType'));
        component.set("v.isButtonUnactive", false);
    },

    toSecondScreenHelper : function(component) {
        component.set("v.firstScreen",  false);
        component.set("v.secondScreen", true);
        component.set("v.current",      '1');
    },

    toThirdScreenHelper : function(component) {
        component.find('appealFieldSetInput').submitHandler();
        component.set("v.current", '2');
    },

    createAttachHelper : function(component) {
        component.set("v.openLWS",     true);
        component.set("v.thirdScreen", false);
    },

    getValueFromLwcHelper : function(component, event) {
        component.set("v.docxDocumentId",                event.getParam("docxDocID"));
        component.set("v.pdfDocumentId",                 event.getParam("pdfDocID"));
        component.set("v.thirdScreen",             false);
        component.set("v.fourthScreen",            true);
        component.set("v.isButtonUnactive",        true);
        component.set("v.openLWS",                 false);
        component.set("v.secondScreenWasAchieved", true);
        component.set("v.current",                 '3');
    },

    handleFinishHelper : function(component) {
        const urlAction = component.get('c.getBackToAppealUrl');

        urlAction.setParams({ recordId : component.get('v.refRecordId') });

        urlAction.setCallback(this, function(response) {
            const state = response.getState();

            if (state === 'SUCCESS') {
                window.location.href = response.getReturnValue();
            } else {
                this.displayToast(state, response.getError()[0].message, state.toLowerCase());
            }
        });

        $A.enqueueAction(urlAction);
    },

    setTemplateUrlHelper : function(component, event) {
        const templateId = event.getParam("templateId");

        component.set("v.isButtonUnactive", false);
        component.set("v.templateUrl",            templateId);
    },

    handleTabHelper : function(component) {
        component.set("v.thirdTab",         false);
        component.set("v.isButtonUnactive", true);
        component.find("templateList").handleTabChange();
    },

    handleThirdTabHelper : function(component) {
        component.set("v.thirdTab", true);
    },

    previousToTheFirstScreenHelper : function(component) {
        component.set("v.firstScreen",  true);
        component.set("v.secondScreen", false);
        component.set("v.current",      '0');
    },

    previousToTheSecondScreenHelper : function(component) {
        component.set("v.secondScreen", true);
        component.set("v.thirdScreen",  false);
        component.set("v.current",      '1');
    },

    previousToTheThirdScreenHelper : function(component) {
        component.set("v.thirdScreen",  true);
        component.set("v.fourthScreen", false);
        component.set("v.current",      '2');
    },

    handleSecondTabHelper : function(component) {
        component.set("v.thirdTab", false);
        component.set("v.isButtonUnactive", !component.get("v.isFileLoaded"));
    },

    removeFile : function(component) {
        component.set("v.isFileLoaded",     false);
        component.set("v.isButtonUnactive", true);
    },

    displayToast: function (title, message, type) {
        const toast = $A.get('e.force:showToast');

        if (!toast) {
            alert(`${title}: ${message}`);

            return;
        }

        toast.setParams({
            'type'    : type,
            'title'   : title,
            'message' : message
        });

        toast.fire();
    },
})