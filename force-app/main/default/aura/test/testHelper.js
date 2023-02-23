({
    doInitHelper : function (cmp, event, helper) {
        var currentStatItems = cmp.getReference("v.statItems");

        $A.createComponent(
            "forceContent:statsPanel",
            {recordId: '0697A000001IFebQAG',
                statItems: currentStatItems},
            function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                    console.log('SUCCESS')
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                } else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                }
            }
        );
    }
});