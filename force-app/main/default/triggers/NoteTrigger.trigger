trigger NoteTrigger on Note (before update, before delete, before insert, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            NoteTriggerHandler.checkLockedRelatedRecord(Trigger.new);
        }

        if (Trigger.isDelete) {
            NoteTriggerHandler.checkLockedRelatedRecord(Trigger.old);
        }

        if (Trigger.isInsert) {
            NoteTriggerHandler.checkOverreadCompleteToLockRelatedRecord(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            NoteTriggerHandler.createNewNoteNotification(Trigger.new);
        }
    }
}