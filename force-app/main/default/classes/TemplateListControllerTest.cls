@IsTest
private class TemplateListControllerTest {
    @TestSetup
    static void setup() {
        Date todayDate       = Date.today();
        Id   appealId        = TestDataFactory.createTestAppealData(todayDate).Id;
        User user            = [
            SELECT Id
            FROM   User
            WHERE  Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME
            LIMIT  1
        ];
        Id permissionSetId = [
            SELECT Id
            FROM   PermissionSet
            WHERE  Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER
            LIMIT  1
        ].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        System.runAs(user) {
            TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                '/' + TestDataFactory.TEST_NAME,
                 appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            ContentWorkspace testWorkspace = new ContentWorkspace(Name = TestDataFactory.TEST_NAME, DeveloperName = TestDataFactory.TEST_NAME);

            insert testWorkspace;
        }
    }

    @IsTest
    static void getTemplatesTest() {
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];

        System.runAs(user) {
            Id appealId           = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id contentWorkSpaceId = [SELECT Id FROM ContentWorkspace WHERE Name = :TestDataFactory.TEST_NAME].Id;
            Id contentDocumentId  = [SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :appealId].ContentDocumentId;

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId   = contentDocumentId;
            contentDocumentLink.ShareType           = 'I';
            contentDocumentLink.Visibility          = 'AllUsers';
            contentDocumentLink.LinkedEntityId      = contentWorkSpaceId;

            insert contentDocumentLink;

            System.assert(TemplateListController.getTemplates(appealId) != null);
        }
        Test.stopTest();
    }

    @IsTest
    static void deleteContentDocumentTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];

        System.runAs(user) {
            Id appealId          = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :appealId].ContentDocumentId;

            TemplateListController.deleteContentDocument(contentDocumentId);
            System.assert([SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId].isEmpty());
        }
    }

    @IsTest
    static void updateTemplateTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];

        System.runAs(user) {
            Id             appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            ContentVersion cv       = [SELECT ContentDocumentId, Title FROM ContentVersion WHERE FirstPublishLocationId = :appealId];
            String         newTitle = cv.Title + '1';

            TemplateListController.updateTemplate(cv.ContentDocumentId, newTitle);

            System.assertEquals(newTitle, [SELECT Title FROM ContentDocument WHERE Id = :cv.ContentDocumentId].Title);
        }
    }
}