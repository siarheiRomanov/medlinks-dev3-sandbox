@IsTest
private class CreateRequestForPdfTest {
    @TestSetup
    static void setup() {
        Date      todayDate = Date.today();
        Appeal__c appeal    = TestDataFactory.createTestAppealData(todayDate);

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        System.runAs(user) {
            TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                '/' + TestDataFactory.TEST_NAME,
                appeal.Id,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );
        }
    }

    @IsTest
    static void getUrlTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId          = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :appealId].ContentDocumentId;

            Test.setMock(HttpCalloutMock.class, new CreatePDFAttachmentHttpCalloutMock());
            Test.startTest();
            System.assertEquals(TestDataFactory.TEST_NAME, CreateRequestForPdf.getUrl(contentDocumentId));
            Test.stopTest();
        }
    }

    @IsTest
    static void createPDFAttachmentTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            Test.setMock(HttpCalloutMock.class, new CreatePDFAttachmentHttpCalloutMock());
            Test.startTest();
            System.assert(CreateRequestForPdf.createPDFAttachment(appealId, TestDataFactory.TEST_NAME, TestDataFactory.LETTER_TYPE_TEST_VALUE) != null);
            Test.stopTest();
        }
    }

    @IsTest
    static void createPDFAttachmentNegativeTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            Test.setMock(HttpCalloutMock.class, new CreatePDFAttachmentHttpCalloutMock());
            Test.startTest();
            System.assert(CreateRequestForPdf.createPDFAttachment(appealId, TestDataFactory.TEST_NAME, TestDataFactory.LETTER_TYPE_TEST_VALUE2) != null);
            Test.stopTest();
        }
    }
}