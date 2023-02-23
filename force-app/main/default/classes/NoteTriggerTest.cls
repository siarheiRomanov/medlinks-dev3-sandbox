@IsTest
public with sharing class NoteTriggerTest {
    @TestSetup
    static void setup() {
        Date      todayDate = Date.today();
        Appeal__c appeal1   = TestDataFactory.createTestAppealData(todayDate);

        User user = TestDataFactory.createUser(
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
            false
        );

        TestDataFactory.createAppeal(
            TestDataFactory.APPEAL_STAGE_TEST_VALUE,
            TestDataFactory.APPEAL_TYPE_TEST_VALUE,
            appeal1.Payer__c,
            TestDataFactory.PAYER_TYPE_TEST_VALUE,
            appeal1.Client_Account__c,
            appeal1.Facility__c,
            appeal1.Facility_Contact_Primary__c,
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            todayDate.addYears(-5),
            TestDataFactory.TEST_NAME + '123',
            todayDate,
            todayDate,
            user.Id,
            user.Id,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            appeal1.Overread_By__c,
            appeal1.Overread_Date__c,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            null,
            null,
            null,
            null,
            true
        );

        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :AppealTriggerHandler.PERMISSION_SET_APPEAL_SPECIALIST_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        User user3 = TestDataFactory.createUser(
            TestDataFactory.getSystemAdministratorProfileId(),
            TestDataFactory.TEST_NAME + '3',
            TestDataFactory.TEST_NAME + '3',
            TestDataFactory.TEST_NAME + '3',
            TestDataFactory.TEST_NAME + '3' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '3' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '3',
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
            TestDataFactory.LOCALE_SID_KEY_US_LA,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            false
        );

        Id permissionSetPMId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user3) {
            insert new List<PermissionSetAssignment>{
                new PermissionSetAssignment(AssigneeId = user3.Id, PermissionSetId = permissionSetPMId),
                new PermissionSetAssignment(AssigneeId = appeal1.Assigned_Scheduler__c, PermissionSetId = permissionSetPMId)
            };
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
            user3.Id,
            user3.Id,
            TestDataFactory.DENIAL_REASON_TEST_VALUE,
            1,
            12,
            contactId,
            null,
            TestDataFactory.ACTUAL_DENIAL_REASON_TEST_VALUE,
            TestDataFactory.ROOT_CAUSE_TEST_VALUE,
            TestDataFactory.TEST_NAME,
            contactId,
            contactId,
            accountId,
            user3.Id,
            false
        );
    }

    @IsTest
    public static void checkLockedRelatedRecordTest() {
        List<Note>      notes   = new List<Note>();
        List<User>      users   = [
            SELECT   Id, IsActive
            FROM     User
            WHERE    Email = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME
                  OR Email = :TestDataFactory.TEST_NAME + '2' + TestDataFactory.TEST_EMAIL_END_NAME
            ORDER BY Name
        ];
        Set<Id>         userIds = new Map<Id, User>(users).keySet();

        List<Appeal__c> appeals = [SELECT Id FROM Appeal__c WHERE Assigned_Scheduler__c IN :userIds ORDER BY Analysis_Complete__c ASC LIMIT 2];

        for (Appeal__c appeal : appeals) {
            notes.add(new Note(Body = TestDataFactory.TEST_NAME, Title = TestDataFactory.TEST_NAME, ParentId = appeal.Id));
        }

        System.runAs(users[1]) {
            insert notes;
        }

        System.assert([SELECT COUNT() FROM Note] == 2);

        notes[1].Body += TestDataFactory.TEST_NAME;

        System.runAs(users[0]) {
            update notes[1];
        }

        System.runAs(users[1]) {
            try {
                update notes[1];
            } catch (Exception e) {
                System.assert(e.getMessage().indexOf(NoteTriggerHandler.NOTE_ERROR_MESSAGE) != -1);
            }

            try {
                delete notes[0];
            } catch (Exception e) {
                System.assert(e.getMessage().indexOf(NoteTriggerHandler.NOTE_ERROR_MESSAGE) != -1);
            }
        }
    }

    @IsTest
    public static void checkOverreadCompleteToLockRelatedRecordTest() {
        Note       note   = new Note();
        Appeal__c  appeal = [SELECT Id FROM Appeal__c WHERE Analysis_Complete__c = TRUE LIMIT 1];
        List<User> users  = [
            SELECT Id, IsActive, Email
            FROM   User
            WHERE  Email = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME
                OR Email = :TestDataFactory.TEST_NAME + '2' + TestDataFactory.TEST_EMAIL_END_NAME
            ORDER BY Name
            LIMIT 2
        ];
        User appealSpecialistUser = new User();
        User generalUser          = new User();

        for (User user : users) {
            if (user.Email == TestDataFactory.TEST_NAME + '2' + TestDataFactory.TEST_EMAIL_END_NAME) {
                appealSpecialistUser = user;
            } else {
                generalUser = user;
            }
        }

        appeal.Overread_Complete__c = true;

        update appeal;

        note = new Note(Body = TestDataFactory.TEST_NAME, Title = TestDataFactory.TEST_NAME, ParentId = appeal.Id);

        System.runAs(appealSpecialistUser) {
            try {
                insert note;
            } catch (Exception e) {
                System.assert(e.getMessage().indexOf(NoteTriggerHandler.NOTE_OVERREAD_ERROR_MESSAGE) != -1);
            }
        }

        System.runAs(generalUser) {
            insert note;
        }
    }

    @IsTest
    private static void createNewNoteNotificationTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + '3' + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [
                SELECT Id
                FROM   Appeal__c
                WHERE  Assigned_Appeals_Specialist__c != NULL
                  AND  Assigned_Scheduler__c          != NULL
                  AND  Appeal_Scheduler__c            != NULL
                  AND  Overread_By__c                 != NULL
                  AND  Opposing_Appeals_Specialist__c != NULL
                LIMIT  1
            ];

            insert new Note(Body = TestDataFactory.TEST_NAME, Title = TestDataFactory.TEST_NAME, ParentId = appeal.Id);

            System.assertEquals(2, Limits.getEmailInvocations());
        }
    }
}