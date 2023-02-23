trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            ContentDocumentTriggerHandler.beforeDeleteContentDocument(Trigger.old);
        }
    }
}