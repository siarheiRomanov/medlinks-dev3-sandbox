@IsTest
private class ContentDocumentTriggerHandlerTest {
    @TestSetup
    static void setup() {
        Date todayDate = Date.today();
        TestDataFactory.createTestAppealData(todayDate);

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }
    }

    @IsTest
    static void beforeDeleteContentDocumentTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            ContentVersion cv = TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            delete [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

            System.assertEquals([SELECT Link_To_Main_Document__c FROM Appeal__c LIMIT 1].Link_To_Main_Document__c, null);

            ContentVersion deletedCv = [SELECT Document_Type__c, Hash__c FROM ContentVersion WHERE Id = :cv.Id LIMIT 1 ALL ROWS];

            System.assert(deletedCv.Document_Type__c == null);
            System.assert(deletedCv.Hash__c == null);
        }
    }
}