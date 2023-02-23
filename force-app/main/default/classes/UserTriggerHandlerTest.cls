@IsTest
private class UserTriggerHandlerTest {
    @TestSetup
    static void setup() {
        User user = TestDataFactory.createUser(
            TestDataFactory.getSystemAdministratorProfileId(),
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
            TestDataFactory.LOCALE_SID_KEY_US_LA,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            false
        );

        Id userRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1].Id;
        user.UserRoleId = userRoleId;

        update user;

        System.runAs(user) {
            TestDataFactory.createAccount(
            TestDataFactory.TEST_NAME,
            TestDataFactory.ACCOUNT_TYPE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            false
            );
        }
    }

    @IsTest
    static void afterInsertUserTest() {
        User     user        = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME];
        Id       profileId   = [SELECT Id FROM Profile WHERE Name = :TestDataFactory.PROFILE_CUSTOMER_COMMUNITY_USER].Id;
        Id       accountId   = [SELECT Id FROM Account WHERE Name = :TestDataFactory.TEST_NAME].Id;

        Id communityUserId;

        System.runAs(user) {
            Id contactId = TestDataFactory.createContact(TestDataFactory.TEST_NAME, TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME, accountId).Id;

            communityUserId = TestDataFactory.createCommunityUser(contactId, profileId, TestDataFactory.TEST_NAME, TestDataFactory.TEST_NAME, accountId).Id;
        }

        Id communityPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.PERMISSION_SET_COMMUNITY_USER LIMIT 1].Id;

        System.assert([SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetId = :communityPermissionSetId AND AssigneeId = :communityUserId] > 0);
    }
}