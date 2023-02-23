@IsTest
private class AppealDetailCtrlTest {
    @TestSetup
    static void setup() {
        Date     todayDate     = Date.today();
        Datetime todayDatetime = Datetime.now();

        User user1 = TestDataFactory.createUser(
            TestDataFactory.getSystemAdministratorProfileId(),
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
            TestDataFactory.LOCALE_SID_KEY_US_LA,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            false
        );
        User user2 = TestDataFactory.createUser(
            TestDataFactory.getSystemAdministratorProfileId(),
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.TEST_NAME + '2' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '2' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
            TestDataFactory.LOCALE_SID_KEY_US_LA,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            true
        );

        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user1) {
            insert new PermissionSetAssignment(AssigneeId = user1.Id, PermissionSetId = permissionSetId);
        }

        System.runAs(user2) {
            insert new PermissionSetAssignment(AssigneeId = user2.Id, PermissionSetId = permissionSetId);
        }

        Id accountId = TestDataFactory.createAccount(
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.ACCOUNT_TYPE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            false
        ).Id;
        Id clientAccountId = TestDataFactory.createAccount(
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.ACCOUNT_TYPE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            true
        ).Id;
        Id contactId = TestDataFactory.createContact(TestDataFactory.TEST_NAME, TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME).Id;

        Id appeal1Id = TestDataFactory.createAppeal(
            TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            accountId,
            TestDataFactory.PAYER_TYPE_TEST_VALUE,
            clientAccountId,
            accountId,
            contactId,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            todayDate.addYears(-5),
            TestDataFactory.TEST_NAME + '123',
            todayDate,
            todayDate.addDays(1),
            user1.Id,
            user1.Id,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            contactId,
            todayDatetime,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            contactId,
            accountId,
            user1.Id,
            false
        ).Id;

        insert new Event(
            Subject           = TestDataFactory.TEST_NAME,
            Description       = TestDataFactory.TEST_NAME,
            WhatId            = appeal1Id,
            DurationInMinutes = 10,
            StartDateTime     = todayDatetime.date().addDays(-1),
            ActivityDate      = todayDate
        );

        TestDataFactory.createNote(
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            appeal1Id
        );

        TestDataFactory.createAppeal(
            TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            accountId,
            TestDataFactory.PAYER_TYPE_TEST_VALUE,
            clientAccountId,
            accountId,
            contactId,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            todayDate.addYears(-5),
            TestDataFactory.TEST_NAME + '123',
            todayDate,
            todayDate,
            user2.Id,
            user2.Id,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            contactId,
            todayDatetime,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            null,
            null,
            null,
            null,
            false
        );
    }

    @IsTest
    static void AppealDetailCtrlTest() {
        Test.startTest();

        Test.setCurrentPage(Page.AppealDetail);

        List<User> users = [
            SELECT Id
            FROM User
            WHERE Alias = :TestDataFactory.TEST_NAME + '1' OR Alias = :TestDataFactory.TEST_NAME + '2'
            ORDER BY LastName ASC
        ];

        System.runAs(users[0]) {
            Appeal__c appeal1 = [
                SELECT Name, Facility__c, Assigned_Appeals_Specialist__c, Third_Party_Firm__c, Third_Party_Firm__r.Name,
                    Opposing_Appeals_Specialist__r.Name, Opposing_Appeals_Specialist__c, Service_Start_Date__c,
                    Service_End_Date__c, Assigned_Appeals_Specialist__r.Name, Facility__r.Name, Appeal_Scheduler__c,
                    Appeal_Scheduler__r.Name, Assigned_Scheduler__r.Name, Facility_Contact_Primary__c,
                    (SELECT Id FROM Notes),
                    Primary_Actual_Denial_Reason__c, Primary_Root_Cause__c
                FROM Appeal__c
                WHERE Opposing_Appeals_Specialist__c != NULL
                LIMIT 1
            ];

            ApexPages.StandardController stdController1 = new ApexPages.StandardController(appeal1);
            AppealDetailCtrl controller1 = new AppealDetailCtrl(stdController1);

            String opposingAuditorPageUrl = controller1.getOpposingAuditorPage().getUrl();
            System.assertEquals(opposingAuditorPageUrl, '/' + String.valueOf(appeal1.Opposing_Appeals_Specialist__c).substring(0, 15));

            String AppealViewPageUrl = controller1.getAppealViewPageRef().getUrl();
            System.assertEquals(AppealViewPageUrl, AppealDetailCtrl.BEGIN_APPEAL_VIEW_PAGE_URL + appeal1.Id + AppealDetailCtrl.WORKAROUND123);

            String AppealEditPageUrl = controller1.getAppealEditPageRef().getUrl();
            System.assert(AppealEditPageUrl != null);

            String opposingAuditor = controller1.getOpposingAuditor();
            System.assertEquals(opposingAuditor, appeal1.Opposing_Appeals_Specialist__r.Name);

            String datesOfService = controller1.getDatesOfService();
            System.assert(datesOfService.indexOf(String.valueOf(Datetime.newInstance(appeal1.Service_Start_Date__c, Time.newInstance(0,0,0,0)).format(AppealDetailCtrl.DATE_OF_SERVICE_FORMAT))) != -1);
            System.assert(datesOfService.indexOf(String.valueOf(Datetime.newInstance(appeal1.Service_End_Date__c, Time.newInstance(0,0,0,0)).format(AppealDetailCtrl.DATE_OF_SERVICE_FORMAT))) != -1);

            String accountName = controller1.getAccountName();
            System.assertEquals(accountName, appeal1.Facility__r.Name);

            System.assert(controller1.getIsOpposingAuditorPage());
            System.assert(!controller1.getIsLimited());

            Id accountId = controller1.getAccountId();
            System.assertEquals(accountId, appeal1.Facility__c);

            appeal1.Appeal_Stage__c = Appeal__c.Appeal_Stage__c.getDescribe().getPicklistValues()[1].getValue();

            update appeal1;

            System.assertEquals(controller1.saveAppeal(), null);

            String result = AppealDetailCtrl.updateAnalysisFields(appeal1.Id, true, true);

            Appeal__c appeal = [
                SELECT Analysis_Complete__c, Date_Analysis_Complete__c
                FROM Appeal__c
                WHERE Opposing_Appeals_Specialist__c != NULL
                LIMIT 1
            ];

            System.assertEquals(appeal.Analysis_Complete__c, true);
            System.assert(appeal.Date_Analysis_Complete__c != null);

            System.assertEquals(result, AppealDetailCtrl.DONE);

            System.assertEquals(controller1.saveAppeal().getUrl(), '/' + appeal1.Id.to15());

            controller1.file = Blob.valueOf(TestDataFactory.TEST_NAME);
            System.assertEquals(controller1.upload().getUrl(), Page.AppealDetail.getUrl() + '?' + AppealDetailCtrl.PARAM_ID + '=' + appeal1.Id);

            System.assertEquals(new ApexPages.StandardController(users[0]).view().getUrl(), controller1.getAppealSchedulerPage().getUrl());
            System.assertEquals(new ApexPages.StandardController(users[0]).view().getUrl(), controller1.getPmPage().getUrl());
            System.assertEquals(new ApexPages.StandardController([SELECT Id FROM Account WHERE Id = :appeal1.Third_Party_Firm__c]).view().getUrl(), controller1.getThirdPartyFirmPage().getUrl());

            System.assertEquals(appeal1.Appeal_Scheduler__r.Name, controller1.getAppealScheduler());
            System.assertEquals(appeal1.Assigned_Scheduler__r.Name, controller1.getPmName());
            System.assertEquals(appeal1.Third_Party_Firm__r.Name, controller1.getThirdPartyFirm());

            System.assertEquals(appeal1.Appeal_Scheduler__c != null, controller1.getIsAppealSchedulerPage());
            System.assertEquals(appeal1.Third_Party_Firm__c != null, controller1.getIsThirdPartyFirmPage());

            System.assertEquals(appeal1.Notes.size(), controller1.getAppealNotes().size());

            TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                '/' + TestDataFactory.TEST_NAME,
                appeal1.Id,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            System.assertEquals([SELECT Id FROM ContentVersion WHERE FirstPublishLocationId = :appeal1.Id].size(), controller1.getAppealAttachments().size());

            System.assertEquals(AppealDetailCtrl.URL_SEND_EMAIL_BEGIN + appeal1.Facility__c.to15() + AppealDetailCtrl.URL_SEND_EMAIL_RECORD_ID + appeal1.Id.to15() + AppealDetailCtrl.URL_REDIRECT_ID + appeal1.Id.to15() + AppealDetailCtrl.URL_REDIRECT_END, controller1.getUrlSendEmail());
            System.assertEquals(AppealDetailCtrl.URL_NEW_NOTE_BEGIN + appeal1.Id.to15() + AppealDetailCtrl.URL_REDIRECT_ID + appeal1.Id.to15() + AppealDetailCtrl.URL_REDIRECT_END, controller1.getUrlNewNote());
            System.assertEquals(AppealDetailCtrl.URL_DOCUMENT_GENERATOR + appeal1.Id.to15(), controller1.getUrlDocumentGenerator());

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setTargetObjectId(appeal1.Facility_Contact_Primary__c);
            mail.setWhatId(appeal1.Id);
            mail.setSubject(TestDataFactory.TEST_NAME);
            mail.plainTextBody = TestDataFactory.TEST_NAME;

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { mail });

            System.assert(results[0].success);

            System.assertEquals([SELECT Id FROM EmailMessage WHERE RelatedToId = :appeal1.Id].size(), controller1.getAppealEmails().size());

        }

        System.runAs(users[1]) {
            Appeal__c appeal2 = [
                SELECT Name, Facility__c, Assigned_Appeals_Specialist__c,
                    Opposing_Appeals_Specialist__c, Service_Start_Date__c, Service_End_Date__c,
                    Assigned_Appeals_Specialist__r.Name, Facility__r.Name
                FROM Appeal__c
                WHERE Opposing_Appeals_Specialist__c = NULL
                LIMIT 1
            ];

            ApexPages.StandardController stdController2 = new ApexPages.StandardController(appeal2);
            AppealDetailCtrl controller2 = new AppealDetailCtrl(stdController2);

            PageReference eventPage = controller2.getEventPage();
            System.assert(eventPage == null);

            String AppealViewPageUrl = controller2.getAppealViewPageRef().getUrl();
            System.assertEquals(AppealViewPageUrl, AppealDetailCtrl.BEGIN_APPEAL_VIEW_PAGE_URL + appeal2.Id + AppealDetailCtrl.WORKAROUND123);

            String AppealEditPageUrl = controller2.getAppealEditPageRef().getUrl();
            System.assert(AppealEditPageUrl != null);

            String nextEvent = controller2.getNextEvent();
            System.assertEquals(nextEvent, AppealDetailCtrl.NO_EVENTS_MESSAGE);

            String nextTime = controller2.getNextTime();
            System.assertEquals(nextTime, '');

            String datesOfService = controller2.getDatesOfService();
            System.assert(datesOfService.indexOf(String.valueOf(Datetime.newInstance(appeal2.Service_Start_Date__c, Time.newInstance(0,0,0,0)).format(AppealDetailCtrl.DATE_OF_SERVICE_FORMAT))) != -1);
            System.assert(datesOfService.indexOf(String.valueOf(Datetime.newInstance(appeal2.Service_End_Date__c, Time.newInstance(0,0,0,0)).format(AppealDetailCtrl.DATE_OF_SERVICE_FORMAT))) != -1);

            String accountName = controller2.getAccountName();
            System.assertEquals(accountName, appeal2.Facility__r.Name);

            Id accountId = controller2.getAccountId();
            System.assertEquals(accountId, appeal2.Facility__c);

            System.assertEquals(controller2.saveAppeal(), null);

            try {
                AppealDetailCtrl.updateAnalysisFields(appeal2.Id, true, true);
            } catch(Exception e) {
                System.assertEquals(AppealDetailCtrl.REQUIRED_FIELDS_MESSAGE, e.getMessage());
            }

            controller2.file = null;
            System.assertEquals(controller2.upload().getUrl(), Page.AppealDetail.getUrl() + '?' + AppealDetailCtrl.PARAM_ID + '=' + appeal2.Id);
        }

        Test.stopTest();
    }

    @IsTest
    static void getOffsetTest() {
        Test.setCurrentPage(Page.AppealDetail);

        User user = [
            SELECT Id
            FROM User
            WHERE Alias = :TestDataFactory.TEST_NAME + '1'
            LIMIT 1
        ];

        System.runAs(user) {
            Appeal__c appeal = [
                SELECT Name, Facility__c, Assigned_Appeals_Specialist__c, Third_Party_Firm__c, Third_Party_Firm__r.Name,
                       Opposing_Appeals_Specialist__r.Name, Opposing_Appeals_Specialist__c, Service_Start_Date__c,
                       Service_End_Date__c, Assigned_Appeals_Specialist__r.Name, Facility__r.Name, Appeal_Scheduler__c,
                       Appeal_Scheduler__r.Name, Assigned_Scheduler__r.Name, Facility_Contact_Primary__c,
                       (SELECT Id FROM Notes),
                       Primary_Actual_Denial_Reason__c, Primary_Root_Cause__c
                FROM   Appeal__c
                WHERE  Opposing_Appeals_Specialist__c != NULL
                LIMIT  1
            ];

            ApexPages.StandardController stdController = new ApexPages.StandardController(appeal);
            AppealDetailCtrl             controller    = new AppealDetailCtrl(stdController);

            System.assertNotEquals(null, controller.getOffset());
        }
    }
}