@IsTest
private class AppealTriggerHandlerTest {

    @TestSetup
    static void Setup() {
        Date      todayDate = Date.today();
        Appeal__c appeal1   = TestDataFactory.createTestAppealData(todayDate);

        TestDataFactory.createAppeal(
            TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            appeal1.Payer__c,
            TestDataFactory.PAYER_TYPE_TEST_VALUE,
            appeal1.Client_Account__c,
            appeal1.Facility__c,
            appeal1.Facility_Contact_Primary__c,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            todayDate.addYears(-5),
            TestDataFactory.TEST_NAME + '123',
            todayDate,
            todayDate,
            appeal1.Assigned_Appeals_Specialist__c,
            appeal1.Assigned_Scheduler__c,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            appeal1.Overread_By__c,
            null,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            null,
            null,
            null,
            false
        );

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :AppealTriggerHandler.PERMISSION_SET_APPEAL_SPECIALIST_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }
    }

    @IsTest
    static void beforeInsertAndUpdateAppealTest() {
        List<Account>   accounts            = [SELECT Id FROM Account WHERE Facility_Zip__c = :TestDataFactory.TEST_NAME ORDER BY Name ASC LIMIT 2];
        Contact         contact             = [SELECT Id, IsScheduler__c, AccountId FROM Contact WHERE LastName = :TestDataFactory.TEST_NAME LIMIT 1];
        User            user                = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];
        List<Appeal__c> appealsExitDuration = new List<Appeal__c>();

        appealsExitDuration.add(new Appeal__c(
            Appeal_Stage__c                  = TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            Appeal_Type__c                   = TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            Payer__c                         = accounts[0].Id,
            Payer_Type__c                    = TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            Client_Account__c                = accounts[1].Id,
            Facility__c                      = accounts[0].Id,
            Facility_Contact_Primary__c      = contact.Id,
            Patient_First_Name__c            = TestDataFactory.TEST_NAME,
            Patient_Last_Name__c             = TestDataFactory.TEST_NAME,
            Patient_DOB__c                   = Date.today().addYears(-5),
            Patient_Account__c               = TestDataFactory.TEST_NAME + '123',
            Service_Start_Date__c            = Date.today(),
            Service_End_Date__c              = Date.today().addDays(1),
            Assigned_Appeals_Specialist__c   = user.Id,
            Assigned_Scheduler__c            = user.Id,
            Denial_Reason__c                 = TestDataFactory.DENIAL_REASON_TEST_VALUE,
            Time_Spent_Initial_Submission__c = 1,
            Opposing_Appeals_Specialist__c   = contact.Id,
            Auditor_Appeal_Rate__c           = 12,
            Overread_By__c                   = contact.Id,
            Overread_Date__c                 = Datetime.now()
        ));

        appealsExitDuration.add(new Appeal__c(
            Appeal_Stage__c                  = TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            Appeal_Type__c                   = TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            Payer__c                         = accounts[0].Id,
            Payer_Type__c                    = TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            Client_Account__c                = accounts[1].Id,
            Facility__c                      = accounts[0].Id,
            Facility_Contact_Primary__c      = contact.Id,
            Patient_First_Name__c            = TestDataFactory.TEST_NAME,
            Patient_Last_Name__c             = TestDataFactory.TEST_NAME,
            Patient_DOB__c                   = Date.today().addYears(-5),
            Patient_Account__c               = TestDataFactory.TEST_NAME + '123',
            Service_Start_Date__c            = Date.today(),
            Service_End_Date__c              = Date.today().addDays(1),
            Assigned_Appeals_Specialist__c   = user.Id,
            Assigned_Scheduler__c            = user.Id,
            Denial_Reason__c                 = TestDataFactory.DENIAL_REASON_TEST_VALUE,
            Time_Spent_Initial_Submission__c = 1,
            Opposing_Appeals_Specialist__c   = contact.Id,
            Auditor_Appeal_Rate__c           = 500,
            Overread_By__c                   = contact.Id,
            Overread_Complete__c             = true,
            Analysis_Complete__c             = true
        ));

        Test.startTest();
        System.runAs(user) {
            insert appealsExitDuration;

            Appeal__c appealNoEdit = appealsExitDuration[1];

            appealNoEdit.Time_Spent_Initial_Submission__c += 1;

            try {
                update appealNoEdit;
            } catch (Exception e) {
                System.assert(e.getMessage().indexOf(AppealTriggerHandler.ERROR_MESSAGE_EDITING_DISABLED) != -1);
            }

            appealNoEdit.Analysis_Complete__c = false;

            try {
                update appealNoEdit;
            } catch (Exception e) {
                System.assert(e.getMessage().indexOf(AppealTriggerHandler.ERROR_MESSAGE_CHANGE_ANALYSIS_COMPLETE) != -1);
            }
        }
        Test.stopTest();
    }
}