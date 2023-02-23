trigger AppealTrigger on Appeal__c (before insert, before update) {
    if (Trigger.isBefore) {
       if (Trigger.isInsert || Trigger.isUpdate) {
            AppealTriggerHandler.beforeInsertAndUpdateAppeal(Trigger.isUpdate, Trigger.new, Trigger.oldMap);
       }
    }
}