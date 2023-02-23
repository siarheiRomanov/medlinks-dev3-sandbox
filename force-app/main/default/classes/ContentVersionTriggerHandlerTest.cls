@IsTest
public with sharing class ContentVersionTriggerHandlerTest {
    @TestSetup
    static void setup() {
        Date     todayDate     = Date.today();
        Datetime todayDatetime = Datetime.now();
        TestDataFactory.createTestAppealData(todayDate);

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
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
            todayDate.addDays(1),
            user.Id,
            user.Id,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            contactId,
            todayDatetime,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            contactId,
            contactId,
            accountId,
            user.Id,
            false
        );
    }

    @IsTest
    static void afterInsertAndBeforeUpdateContentVersionTest() {
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [SELECT Id FROM Appeal__c LIMIT 1];
            List<ContentVersion> contentVersionList = new List<ContentVersion>();

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            ));

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE
            ));

            insert contentVersionList;

            System.assert([SELECT Link_To_Main_Document__c FROM Appeal__c LIMIT 1].Link_To_Main_Document__c != null);

            contentVersionList[1].Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN;

            try {
                update contentVersionList[1];
            } catch (Exception e) {
                System.assert(e.getMessage().contains(ContentVersionTriggerHandler.ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT));
            }

            contentVersionList[0].Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;

            update contentVersionList[0];

            System.assertEquals(null, [SELECT Hash__c FROM ContentVersion WHERE Id = :contentVersionList[0].Id].Hash__c);

            ContentVersion errorMainContentVersion = new ContentVersion();

            errorMainContentVersion.VersionData = Blob.valueOf(TestDataFactory.TEST_NAME);
            errorMainContentVersion.Title = TestDataFactory.TEST_NAME + ContentVersionTriggerHandler.FILE_TYPE_PDF;
            errorMainContentVersion.PathOnClient = '/' + TestDataFactory.TEST_NAME;
            errorMainContentVersion.FirstPublishLocationId = appeal.Id;
            errorMainContentVersion.IsMajorVersion = true;
            errorMainContentVersion.Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE;
            errorMainContentVersion.Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;

            errorMainContentVersion.Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE2;

            insert errorMainContentVersion;

            errorMainContentVersion.Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE;

            try {
                update errorMainContentVersion;
            } catch (Exception e) {
                System.assert(e.getMessage().contains(ContentVersionTriggerHandler.ERROR_MESSAGE_ONLY_TWO_LETTER_TYPE_DOCUMENT));
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void afterInsertAndBeforeUpdateContentVersionBulkTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [SELECT Id FROM Appeal__c LIMIT 1];
            List<ContentVersion> contentVersionList = new List<ContentVersion>();

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = null
            ));

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE2,
                Document_Type__c = null
            ));

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = null
            ));

            insert contentVersionList;

            contentVersionList[0].Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN;
            contentVersionList[1].Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN;
            contentVersionList[2].Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN;

            update contentVersionList;

            System.assert([SELECT Link_To_Main_Document__c FROM Appeal__c LIMIT 1].Link_To_Main_Document__c != null);

            contentVersionList[2].Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE2;

            update contentVersionList;

            contentVersionList[0].Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;
            contentVersionList[1].Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;

            update contentVersionList;

            System.assert([SELECT Link_To_Main_Document__c FROM Appeal__c LIMIT 1].Link_To_Main_Document__c != null);

            contentVersionList[2].Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;

            update contentVersionList;

            System.assert([SELECT Link_To_Main_Document__c FROM Appeal__c LIMIT 1].Link_To_Main_Document__c == null);
        }
    }

    @IsTest
    static void afterInsertAndBeforeUpdateContentVersionNegativeTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [SELECT Id FROM Appeal__c LIMIT 1];
            ContentVersion cv = new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            try {
                insert cv;
            } catch (Exception e) {
                System.assert(e.getMessage().contains(ContentVersionTriggerHandler.ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT));
            }

            cv.Title += '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF;
            cv.Document_Type__c = AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE;

            insert cv;

            cv.Title = cv.Title.remove('.' + ContentVersionTriggerHandler.FILE_TYPE_PDF);
            cv.Document_Type__c = ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN;

            try {
                update cv;
            } catch (Exception e) {
                System.assert(e.getMessage().contains(ContentVersionTriggerHandler.ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT));
            }
        }
    }

    @IsTest
    static void getQueryTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [SELECT Id FROM Appeal__c LIMIT 1];
            List<ContentVersion> contentVersionList = new List<ContentVersion>();

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = null
            ));

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE2,
                Document_Type__c = null
            ));

            contentVersionList.add(new ContentVersion(
                VersionData = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion = true,
                Letter_Type__c = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c = null
            ));

            insert contentVersionList;

            Set<String> contentDocIds = new Set<String>();

            for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion]) {
                contentDocIds.add(String.valueOf(cv.ContentDocumentId));
            }

            String query = ContentVersionTriggerHandler.getQuery(
                new List<String>{
                        ContentVersionTriggerHandler.FIELD_NAME_LINKED_ENTITY_ID, ContentVersionTriggerHandler.FIELD_NAME_CONTENT_DOCUMENT_ID
                },
                ContentVersionTriggerHandler.OBJECT_NAME_CONTENT_DOCUMENT_LINK,
                new Map<String, List<String>>{
                        ContentVersionTriggerHandler.FIELD_NAME_CONTENT_DOCUMENT_ID => new List<String>(contentDocIds),
                        ContentVersionTriggerHandler.FIELD_NAME_LINKED_ENTITY_ID => new List<String>(contentDocIds)
                }
            );

            System.assert(query != null);
        }
    }

    @IsTest
    private static void uploadFileNotificationTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [
                SELECT Id
                FROM   Appeal__c
                WHERE  Assigned_Appeals_Specialist__c != NULL
                   AND Assigned_Scheduler__c          != NULL
                   AND Appeal_Scheduler__c            != NULL
                   AND Overread_By__c                 != NULL
                   AND Opposing_Appeals_Specialist__c != NULL
                LIMIT  1
            ];

            insert new ContentVersion(
                VersionData            = Blob.valueOf(TestDataFactory.TEST_NAME),
                Title                  = TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                PathOnClient           = '/' + TestDataFactory.TEST_NAME,
                FirstPublishLocationId = appeal.Id,
                IsMajorVersion         = true,
                Letter_Type__c         = TestDataFactory.LETTER_TYPE_TEST_VALUE,
                Document_Type__c       = null
            );

            System.assertEquals(2, Limits.getEmailInvocations());
        }
    }
}