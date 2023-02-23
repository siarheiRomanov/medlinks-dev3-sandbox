public with sharing class AppealTriggerHandler {
    public static final String PERMISSION_SET_APPEAL_SPECIALIST_USER  = 'Appeal_Specialist_User';
    public static final String ERROR_MESSAGE_CHANGE_ANALYSIS_COMPLETE = 'You cannot change Analysis Complete and Overread Complete fields. Please contact Project Manager!';
    public static final String ERROR_MESSAGE_EDITING_DISABLED         = 'Analysis Complete - Editing Disabled!';

    public static void beforeInsertAndUpdateAppeal(Boolean isUpdate, List<Appeal__c> newAppeals, Map<Id, Appeal__c> oldAppealsMap) {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        Boolean isAppealSpecialistUser = [
            SELECT COUNT()
            FROM   PermissionSetAssignment
            WHERE  PermissionSet.Name = :PERMISSION_SET_APPEAL_SPECIALIST_USER
               AND AssigneeId         = :UserInfo.getUserId()
        ] != 0;

        for (Appeal__c appeal : newAppeals) {
            appeal.Date_Analysis_Complete__c = !appeal.Analysis_Complete__c
                ? null
                : Datetime.now();
            appeal.Overread_Date__c = !appeal.Overread_Complete__c
                ? null
                : Datetime.now();

            if (isUpdate && isAppealSpecialistUser) {
                if (
                    (!appeal.Analysis_Complete__c && oldAppealsMap.get(appeal.Id).Analysis_Complete__c)
                 || (!appeal.Overread_Complete__c && oldAppealsMap.get(appeal.Id).Overread_Complete__c)
                ) {
                    appeal.addError(ERROR_MESSAGE_CHANGE_ANALYSIS_COMPLETE);
                }

                Boolean checkEditingAbility = (
                    appeal.Analysis_Complete__c && oldAppealsMap.get(appeal.Id).Analysis_Complete__c
                     && (
                            appeal.Denial_Reason__c                  != oldAppealsMap.get(appeal.Id).Denial_Reason__c
                         || appeal.Payer_Due_Date__c                 != oldAppealsMap.get(appeal.Id).Payer_Due_Date__c
                         || appeal.Auditor_Invoice__c                != oldAppealsMap.get(appeal.Id).Auditor_Invoice__c
                         || appeal.Primary_Root_Cause__c             != oldAppealsMap.get(appeal.Id).Primary_Root_Cause__c
                         || appeal.Secondary_Root_Cause__c           != oldAppealsMap.get(appeal.Id).Secondary_Root_Cause__c
                         || appeal.Primary_Actual_Denial_Reason__c   != oldAppealsMap.get(appeal.Id).Primary_Actual_Denial_Reason__c
                         || appeal.Secondary_Actual_Denial_Reason__c != oldAppealsMap.get(appeal.Id).Secondary_Actual_Denial_Reason__c
                         || appeal.Time_Spent_Initial_Submission__c  != oldAppealsMap.get(appeal.Id).Time_Spent_Initial_Submission__c
                        )
                );

                if (checkEditingAbility) {
                    appeal.addError(ERROR_MESSAGE_EDITING_DISABLED);
                }
            }
        }
    }
}