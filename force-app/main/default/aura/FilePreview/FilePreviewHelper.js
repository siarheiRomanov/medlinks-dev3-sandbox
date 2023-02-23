({
    COLUMNS: [
        {
            label:          'Title',
            fieldName:      'Title',
            type:           'String',
            sortable:       true,
            cellAttributes: { alignment: 'left' },
        },
    ],

    doInit : function (component, event, helper) {
        component.set('v.columns', this.COLUMNS);

        const tokenAction  = component.get('c.getContentDocumentsThroughToken');
        const currentToken = window.location.href.includes('?token=')
            ? decodeURIComponent(window.location.href.split('?token=')[1].replaceAll('%20', '+'))
            : null;

        tokenAction.setParams({ token : currentToken });

        helper.doRequest(component, tokenAction, function(result) {
            if (result.length !== 0) {
                component.set('v.isValidToken', true);
                component.set('v.contentDocIdToContentVersionTitle', Object.keys(result).reduce((accumulator, currentValue) => {
                    accumulator.push({'Id': currentValue, 'Title': result[currentValue]});

                    return accumulator;
                }, []));
                component.set('v.contentDocumentIds', Object.keys(result));

                const shareAction = component.get('c.shareDocToUser');

                console.log('!!!!!! ', component.get('v.contentDocumentIds'));
                shareAction.setParams({contentDocumentIds: component.get('v.contentDocumentIds')});

                helper.doRequest(component, shareAction, function (result) {
                    component.set('v.showSpinner', false);
                });
            } else {
                component.set('v.showSpinner', false);
            }
        });
    },


    handleSortHelper: function(component, event) {
        const sortedBy      = event.getParam('fieldName');
        const sortDirection = event.getParam('sortDirection');
        const cloneData     = component.get('v.contentDocIdToContentVersionTitle');

        cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc')));

        component.set('v.contentDocIdToContentVersionTitle', cloneData);
        component.set('v.sortDirection',                     sortDirection);
        component.set('v.sortedBy',                          sortedBy);
    },

    sortBy: function(field, reverse) {
        return reverse
            ? function (a, b) {
                if (a[field] > b[field]) {
                    return 1;
                }

                if (a[field] < b[field]) {
                    return -1;
                }

                return 0;
            }
            : function (a, b) {
                if (a[field] < b[field]) {
                    return 1;
                }

                if (a[field] > b[field]) {
                    return -1;
                }

                return 0;
            }
    },

    handleRowActionHelper : function (component, event, helper) {
        component.set("v.selectedDocumentIds", event.getParam("selectedRows").reduce((accumulator, currentValue) => {
            accumulator.push({title: currentValue["Title"], docId: currentValue[["Id"]]});

            return accumulator;
        }, []));
    },

    doRequest: function (component, action, callBack) {
        action.setCallback(this, function(response) {
            const state = response.getState();

            if (state === component.get('v.successLabelUpperCase')) {
                const result = response.getReturnValue();
                callBack(result);
            } else {
                component.set('v.showSpinner', false);
                component.set('v.isValidToken', false);
                console.log('error: ', response.getError())
            }
        });

        $A.enqueueAction(action);
    },
});