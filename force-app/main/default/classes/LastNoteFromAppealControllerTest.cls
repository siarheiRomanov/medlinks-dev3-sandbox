@IsTest
public with sharing class LastNoteFromAppealControllerTest {
    @TestSetup
    static void setup() {
        Date      todayDate       = Date.today();
        Appeal__c appeal          = TestDataFactory.createTestAppealData(todayDate);
        User      user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id        permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :AppealTriggerHandler.PERMISSION_SET_APPEAL_SPECIALIST_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        List<Note> notes = new List<Note>{
            new Note(Body = TestDataFactory.TEST_NAME + '1', Title = TestDataFactory.TEST_NAME + '1', ParentId = appeal.Id),
            new Note(Body = TestDataFactory.TEST_NAME + '2', Title = TestDataFactory.TEST_NAME + '2', ParentId = appeal.Id)
        };

        System.runAs(user) {
            insert notes;

            Test.setCreatedDate(notes[0].Id, Datetime.now() - 1);
        }
    }

    @IsTest
    private static void getNotesTest() {
        Test.startTest();
        Test.setCurrentPage(Page.AppealDetail);

        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            Appeal__c appeal = [
                SELECT Id, (SELECT Id FROM Notes ORDER BY CreatedDate DESC)
                FROM   Appeal__c
                LIMIT  1
            ];

            LastNoteFromAppealController controller = new LastNoteFromAppealController();

            controller.currentAppealId = appeal.Id;

            System.assertEquals(appeal.Notes[0].Id, controller.getNotes()[0].Id);
        }

        Test.stopTest();
    }
}