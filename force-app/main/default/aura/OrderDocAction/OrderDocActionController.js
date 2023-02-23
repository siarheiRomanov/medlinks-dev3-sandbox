({
    init : function(component, event, helper) {
        helper.initHelper(component);
    },

    handleFilesChange : function(component, event, helper) {
        helper.handleFilesChangeHelper(component, event);
    },

    handleOnSuccess : function(component, event, helper) {
        helper.handleOnSuccessHelper(component);
    },

    handleOnLetterType : function(component, event, helper) {
        helper.handleOnLetterTypeHelper(component, event);
    },

    toSecondScreen: function(component, event, helper) {
        helper.toSecondScreenHelper(component);
    },
    toThirdScreen: function(component, event, helper) {
        helper.toThirdScreenHelper(component);
    },

    createAttach : function(component, event, helper) {
        helper.createAttachHelper(component);
    },

    getValueFromLwc : function(component, event, helper) {
        helper.getValueFromLwcHelper(component, event);
    },

    handleFinish: function(component, event, helper) {
        helper.handleFinishHelper(component);
    },

    handleCancel: function(component, event, helper) {
        helper.deleteDocsHelper(component);
        helper.handleFinishHelper(component);
    },

    setTemplateUrl: function(component, event, helper) {
        helper.setTemplateUrlHelper(component, event);
    },

    handleTab: function(component, event, helper) {
        helper.handleTabHelper(component);
    },

    handleThirdTab: function(component, event, helper) {
        helper.handleThirdTabHelper(component);
    },

    previousToTheFirstScreen : function(component, event, helper) {
        helper.previousToTheFirstScreenHelper(component);
    },

    previousToTheSecondScreen : function(component, event, helper) {
        helper.previousToTheSecondScreenHelper(component);
    },

    previousToTheThirdScreen : function(component, event, helper) {
        helper.previousToTheThirdScreenHelper(component);
    },

    handleSecondTab : function(component, event, helper) {
        helper.handleSecondTabHelper(component);
    },

    removeFile: function(component, event, helper) {
        helper.removeFile(component);
    }
})