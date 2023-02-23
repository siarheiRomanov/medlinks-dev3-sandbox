@IsTest
private class DocGeneratorCtrlTest {
    @TestSetup
    static void setup() {
        Date todayDate = Date.today();
        Id   appealId  = TestDataFactory.createTestAppealData(todayDate).Id;

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
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );
        }

        ContentWorkspace testWorkspace1 = new ContentWorkspace(Name=TestDataFactory.TEST_NAME, DeveloperName=TestDataFactory.TEST_NAME);

        System.runAs(user) {
            insert testWorkspace1;
        }
    }

    @IsTest
    static void createAttachmentTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            System.assert(DocGeneratorCtrl.createAttachment(appealId, TestDataFactory.TEST_NAME, TestDataFactory.LETTER_TYPE_TEST_VALUE) != null);
            System.assert(DocGeneratorCtrl.createAttachment(appealId, TestDataFactory.TEST_NAME, TestDataFactory.LETTER_TYPE_TEST_VALUE) != null);
            System.assert(DocGeneratorCtrl.createAttachment(appealId, null, TestDataFactory.LETTER_TYPE_TEST_VALUE) == null);
        }
    }

    @IsTest
    static void getTemplateTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :appealId].ContentDocumentId;

            System.assert(DocGeneratorCtrl.getTemplate(contentDocumentId) != null);
        }
    }

    @IsTest
    static void uploadFileTest() {
        User user     = [SELECT Id,IsActive FROM User WHERE Email = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];
        Id   appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

        System.runAs(user) {
            System.assert(DocGeneratorCtrl.uploadFile(EncodingUtil.base64Encode(Blob.toPdf(TestDataFactory.TEST_NAME)), TestDataFactory.TEST_NAME, appealId) != null);
        }
    }

    @IsTest
    static void getBackToAppealUrlTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            System.assertEquals(Url.getOrgDomainUrl().toExternalForm() + '/' + appealId, DocGeneratorCtrl.getBackToAppealUrl(appealId));
        }
    }
}