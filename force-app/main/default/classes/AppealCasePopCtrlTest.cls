@IsTest
public with sharing class AppealCasePopCtrlTest {
    @TestSetup
    static void setup() {
        Date      todayDate = Date.today();
        Appeal__c appeal    = TestDataFactory.createTestAppealData(todayDate);

        User user = TestDataFactory.createUser(
            TestDataFactory.getSystemAdministratorProfileId(),
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '1' + TestDataFactory.TEST_EMAIL_END_NAME,
            TestDataFactory.TEST_NAME + '1',
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
            TestDataFactory.LOCALE_SID_KEY_US_LA,
            TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
            false
        );

        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        TestDataFactory.createNote(
            TestDataFactory.TEST_NAME,
            TestDataFactory.TEST_NAME,
            appeal.Id
        );
    }

    @IsTest
    static void appealCasePopTest() {
        Test.setCurrentPage(Page.AppealCasePop);

        User user = [
                SELECT Id
                FROM User
                WHERE Alias = :TestDataFactory.TEST_NAME + '1'
                LIMIT 1
        ];

        System.runAs(user) {
            Appeal__c appeal = [
                    SELECT Name, Facility__c, Patient_First_Name__c, Patient_Last_Name__c, Patient_Account__c
                    FROM Appeal__c
                    LIMIT 1
            ];

            ApexPages.StandardController stdController = new ApexPages.StandardController(appeal);
            AppealCasePopCtrl controller = new AppealCasePopCtrl(stdController);
            String nextPage = controller.SaveReportPage().getUrl();
            Map<String, String> header = controller.SaveReportPage().getHeaders();


            System.assert(header.get(TestDataFactory.CONTENT_DISPOSITION) != null);
            System.assertEquals(TestDataFactory.APPEAL_CASE_REPORT_URL + appeal.Id, nextPage);

            nextPage = controller.DisplayReportPage().getUrl();

            System.assertEquals(TestDataFactory.APPEAL_CASE_REPORT_URL + appeal.Id, nextPage);

            System.assertEquals([SELECT COUNT() FROM Note WHERE ParentId = :appeal.Id], controller.getAppealNotes().size());
        }
    }

    @IsTest
    static void AppealCaseReportTest() {
        Test.setCurrentPage(Page.AppealCaseReport);

        User user = [
                SELECT Id
                FROM User
                WHERE Alias = :TestDataFactory.TEST_NAME + '1'
                LIMIT 1
        ];

        System.runAs(user) {
            Appeal__c appeal = [
                    SELECT Name, Facility__c, Patient_First_Name__c, Patient_Last_Name__c, Patient_Account__c
                    FROM Appeal__c
                    LIMIT 1
            ];

            ApexPages.StandardController stdController = new ApexPages.StandardController(appeal);
            AppealCasePopCtrl controller = new AppealCasePopCtrl(stdController);

            System.assert(controller != null);

            System.assertEquals([SELECT COUNT() FROM Note WHERE ParentId = :appeal.Id], controller.getAppealNotes().size());
        }
    }

    @IsTest
    static void getOffsetTest() {
        Test.setCurrentPage(Page.AppealCaseReport);

        User user = [
            SELECT Id
            FROM User
            WHERE Alias = :TestDataFactory.TEST_NAME + '1'
            LIMIT 1
        ];

        System.runAs(user) {
            Appeal__c appeal = [
                SELECT Name, Facility__c, Patient_First_Name__c, Patient_Last_Name__c, Patient_Account__c
                FROM Appeal__c
                LIMIT 1
            ];

            ApexPages.StandardController stdController = new ApexPages.StandardController(appeal);
            AppealCasePopCtrl            controller    = new AppealCasePopCtrl(stdController);

            System.assertNotEquals(null, controller.getOffset());
        }
    }
}