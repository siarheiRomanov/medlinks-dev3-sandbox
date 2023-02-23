({
    doInit : function (component, event, helper) {
        helper.doInit(component, event, helper);
    },

    handleSort : function (component, event, helper) {
        helper.handleSortHelper(component, event);
    },

    handleRowAction : function (component, event, helper) {
        helper.handleRowActionHelper(component, event);
    },
});