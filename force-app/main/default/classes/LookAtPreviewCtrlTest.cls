@IsTest
private class LookAtPreviewCtrlTest {
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
                Blob.valueOf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + TestDataFactory.FILE_TYPE_DOCX,
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE
            );
        }
    }

    @IsTest
    static void getAttachmentsInfoTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            System.assert(LookAtPreviewCtrl.getAttachmentsInfo(appealId, TestDataFactory.LETTER_TYPE_TEST_VALUE).values().size() == 3);

            TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + LookAtPreviewCtrl.FILE_TYPE_PDF.toLowerCase(),
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            System.assert(LookAtPreviewCtrl.getAttachmentsInfo(appealId, TestDataFactory.LETTER_TYPE_TEST_VALUE).values().size() == 6);

            Test.startTest();
            TestDataFactory.createContentVersion(
                    Blob.toPdf(TestDataFactory.TEST_NAME),
                    TestDataFactory.TEST_NAME + '.' + LookAtPreviewCtrl.FILE_TYPE_PDF.toLowerCase(),
                    '/' + TestDataFactory.TEST_NAME,
                    appealId,
                    true,
                    TestDataFactory.LETTER_TYPE_TEST_VALUE2,
                    ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            TestDataFactory.createContentVersion(
                    Blob.valueOf(TestDataFactory.TEST_NAME),
                    TestDataFactory.TEST_NAME + '.' + TestDataFactory.FILE_TYPE_DOCX,
                    '/' + TestDataFactory.TEST_NAME,
                    appealId,
                    true,
                    TestDataFactory.LETTER_TYPE_TEST_VALUE2,
                    AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE
            );
            Test.stopTest();

            System.assert(LookAtPreviewCtrl.getAttachmentsInfo(appealId, TestDataFactory.LETTER_TYPE_TEST_VALUE2).values().size() == 6);
        }
    }

    @IsTest
    static void getSizeTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            System.assert(LookAtPreviewCtrl.getSize(null) == '');
            System.assert(LookAtPreviewCtrl.getSize(1000) != '');
            System.assert(LookAtPreviewCtrl.getSize(1000000) != '');
            System.assert(LookAtPreviewCtrl.getSize(1000000000) != '');
            System.assert(LookAtPreviewCtrl.getSize(2147483647) != '');
        }
    }
}