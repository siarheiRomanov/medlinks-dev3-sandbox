@IsTest
private class DynamicWrapperClassTest {
    @TestSetup
    static void setup() {
        Date todayDate = Date.today();
        Id   appealId  = TestDataFactory.createTestAppealData(todayDate).Id;

        TestDataFactory.createNote(
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1',
            appealId
        );
        TestDataFactory.createNote(
            TestDataFactory.TEST_NAME + '2',
            TestDataFactory.TEST_NAME + '2',
            appealId
        );

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }
    }

    @IsTest
    static void getWrapperTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            DynamicWrapperClass dynamicWrapper = DynamicWrapperClass.getWrapper(appealId);

            System.assert(dynamicWrapper.objectFields != null);
            System.assert(dynamicWrapper.listObjectFields != null);
        }
    }
}