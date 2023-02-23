public with sharing class NoteTriggerHandler {
    public static final String NOTE_ERROR_MESSAGE                  = 'Analysis Complete - Editing Disabled!';
    public static final String NOTE_OVERREAD_ERROR_MESSAGE         = 'Overread Complete - Creating Disabled!';
    public static final String APPEAL_SPECIALIST_USER              = 'Appeal_Specialist_User';
    public static final String NEW_NOTE_EMAIL_TEMPLATE_FOR_CONTACT = 'New Note Email Template For Contact';
    public static final String NEW_NOTE_EMAIL_TEMPLATE_FOR_USER    = 'New Note Email Template For User';

    public static void checkLockedRelatedRecord(List<Note> newNotes) {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        if (
            [
                SELECT COUNT()
                FROM   PermissionSetAssignment
                WHERE  PermissionSet.Name = :APPEAL_SPECIALIST_USER
                   AND AssigneeId         = :UserInfo.getUserId()
            ] == 0
        ) {
            return;
        }

        Set<Id> appealIdSet = new Set<Id>();

        for (Note note : newNotes) {
            if (ContentVersionTriggerHandler.isAppealById(note.ParentId)) {
                appealIdSet.add(note.ParentId);
            }
        }

        Map<Id, Boolean> appealIdToAnalysisComplete = new Map<Id, Boolean>();

        for (Appeal__c appeal : [SELECT Analysis_Complete__c FROM Appeal__c WHERE Id IN :appealIdSet WITH SECURITY_ENFORCED]) {
            appealIdToAnalysisComplete.put(appeal.Id, appeal.Analysis_Complete__c);
        }

        for (Note note : newNotes) {
            if (appealIdToAnalysisComplete.get(note.ParentId)) {
                note.addError(NOTE_ERROR_MESSAGE);
            }
        }
    }

    public static void checkOverreadCompleteToLockRelatedRecord(List<Note> newNotes) {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        if (
            [
                SELECT COUNT()
                FROM   PermissionSetAssignment
                WHERE  PermissionSet.Name = :APPEAL_SPECIALIST_USER
                   AND AssigneeId         = :UserInfo.getUserId()
            ] == 0
        ) {
            return;
        }

        Set<Id> appealIdSet = new Set<Id>();

        for (Note note : newNotes) {
            if (ContentVersionTriggerHandler.isAppealById(note.ParentId)) {
                appealIdSet.add(note.ParentId);
            }
        }

        Map<Id, Boolean> appealIdToAnalysisComplete = new Map<Id, Boolean>();

        for (Appeal__c appeal : [SELECT Overread_Complete__c FROM Appeal__c WHERE Id IN :appealIdSet WITH SECURITY_ENFORCED]) {
            appealIdToAnalysisComplete.put(appeal.Id, appeal.Overread_Complete__c);
        }

        for (Note note : newNotes) {
            if (appealIdToAnalysisComplete.get(note.ParentId)) {
                note.addError(NOTE_OVERREAD_ERROR_MESSAGE);
            }
        }
    }

    public static void createNewNoteNotification(List<Note> newNotes) {
        Set<Id> appealIdSet = new Set<Id>();

        for (Note note : newNotes) {
            if (ContentVersionTriggerHandler.isAppealById(note.ParentId)) {
                appealIdSet.add(note.ParentId);
            }
        }

        for (Appeal__c appeal : [
            SELECT Assigned_Appeals_Specialist__c,       Appeal_Scheduler__c,                  Assigned_Scheduler__c,
                   Overread_By__c,                       Opposing_Appeals_Specialist__c,       Opposing_Scheduler__c,
                   Assigned_Appeals_Specialist__r.Email, Appeal_Scheduler__r.Email,            Assigned_Scheduler__r.Email,
                   Overread_By__r.Email,                 Opposing_Appeals_Specialist__r.Email, Opposing_Scheduler__r.Email
            FROM   Appeal__c
            WHERE  Id IN :appealIdSet
            WITH SECURITY_ENFORCED
        ]) {
            List<Id> recipientUserIds = new List<Id>{};

            if (appeal.Assigned_Appeals_Specialist__c != null && appeal.Assigned_Appeals_Specialist__r.Email != null) {
                recipientUserIds.add(appeal.Assigned_Appeals_Specialist__c);
            }

            if (appeal.Assigned_Scheduler__c != null && appeal.Assigned_Scheduler__r.Email != null) {
                recipientUserIds.add(appeal.Assigned_Scheduler__c);
            }

            if (appeal.Appeal_Scheduler__c != null && appeal.Appeal_Scheduler__r.Email != null) {
                recipientUserIds.add(appeal.Appeal_Scheduler__c);
            }

            List<Id> recipientContactIds = new List<Id>{};

            if (appeal.Overread_By__c != null && appeal.Overread_By__r.Email != null) {
                recipientContactIds.add(appeal.Overread_By__c);
            }

            if (appeal.Opposing_Appeals_Specialist__c != null && appeal.Opposing_Appeals_Specialist__r.Email != null) {
                recipientContactIds.add(appeal.Opposing_Appeals_Specialist__c);
            }

            if (appeal.Opposing_Scheduler__c != null && appeal.Opposing_Scheduler__r.Email != null) {
                recipientContactIds.add(appeal.Opposing_Scheduler__c);
            }

            EmailNotificationHandler.sendEmailByIds(
                recipientUserIds,
                recipientContactIds,
                appeal.Id,
                NEW_NOTE_EMAIL_TEMPLATE_FOR_CONTACT,
                NEW_NOTE_EMAIL_TEMPLATE_FOR_USER
            );
        }
    }
}