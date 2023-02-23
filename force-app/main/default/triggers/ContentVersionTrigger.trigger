trigger ContentVersionTrigger on ContentVersion (after insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            ContentVersionTriggerHandler.beforeUpdateContentVersion(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContentVersionTriggerHandler.afterInsertContentVersion(Trigger.new);
        }
    }
}