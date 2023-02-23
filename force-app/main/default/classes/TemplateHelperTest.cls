@IsTest
private class TemplateHelperTest {
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
                TemplateHelper.BASIC_TEMPLATE + Appeal__c.getSObjectType().getDescribe().name,
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE
            );

            TestDataFactory.createContentVersion(
                Blob.valueOf(TestDataFactory.TEST_NAME),
                TemplateHelper.TEMPLATE_HELPER_IMAGE_JPG,
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                AppealDetailCtrl.INTERNAL_DOCUMENT_TYPE
            );
        }
    }

    @IsTest
    static void getTemplateIdTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id cvId = [
                SELECT Id
                FROM ContentVersion
                WHERE FirstPublishLocationId = :appealId AND
                Title = :TemplateHelper.BASIC_TEMPLATE + Appeal__c.getSObjectType().getDescribe().name
                LIMIT 1
            ].Id;

            System.assertEquals(cvId, TemplateHelper.getTemplateId(appealId).Id);
        }
    }

    @IsTest
    static void getImageIdTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id cvId = [
                SELECT Id
                FROM ContentVersion
                WHERE FirstPublishLocationId = :appealId AND Title = :TemplateHelper.TEMPLATE_HELPER_IMAGE_JPG
                LIMIT 1
            ].Id;

            System.assertEquals(cvId, TemplateHelper.getImageId().Id);
        }
    }
}