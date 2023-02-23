@IsTest
private class FilePreviewAndDownloadCtrlTest {
    @TestSetup
    static void setup() {
        Date todayDate = Date.today();
        TestDataFactory.createTestAppealData(todayDate);

        User user            = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];
        Id   permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :TestDataFactory.PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER LIMIT 1].Id;

        System.runAs(user) {
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSetId);
        }

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;

            TestDataFactory.createContentVersion(
                Blob.toPdf(TestDataFactory.TEST_NAME),
                TestDataFactory.TEST_NAME + '.' + ContentVersionTriggerHandler.FILE_TYPE_PDF,
                '/' + TestDataFactory.TEST_NAME,
                appealId,
                true,
                TestDataFactory.LETTER_TYPE_TEST_VALUE,
                ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN
            );

            Id userId = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME].Id;

            insert new Contact(
                LastName = TestDataFactory.TEST_NAME,
                Email = TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME,
                OwnerId = userId
            );
        }
    }

    @IsTest
    static void shareDocToUserTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME LIMIT 1];

        System.runAs(user) {
            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :appealId].ContentDocumentId;
            Integer countContentDocumentLinks = [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocumentId];

            FilePreviewAndDownloadCtrl.shareDocToUser(new List<String>{
                contentDocumentId
            });

            System.assertEquals([SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocumentId], countContentDocumentLinks + 1);

            FilePreviewAndDownloadCtrl.shareDocToUser(new List<String>{
                contentDocumentId
            });

            System.assertEquals([SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocumentId], countContentDocumentLinks + 1);
        }
    }

    @IsTest
    static void getContentDocumentIdThroughTokenTest() {
        User user = [SELECT Id FROM User WHERE Username = :TestDataFactory.TEST_NAME + TestDataFactory.TEST_EMAIL_END_NAME];

        System.runAs(user) {
            String fakeToken = TestDataFactory.TEST_NAME;

            try {
                FilePreviewAndDownloadCtrl.getContentDocumentsThroughToken(fakeToken);
            } catch (Exception e) {
                System.assertEquals(FilePreviewAndDownloadCtrl.MESSAGE_INCORRECT_TOKEN, e.getMessage());
            }

            Id appealId = [SELECT Id FROM Appeal__c LIMIT 1].Id;
            ContentVersion cv = [SELECT ContentDocumentId, Hash__c, Title FROM ContentVersion WHERE FirstPublishLocationId = :appealId];

            String token = ContentVersionTriggerHandler.getToken(new Map<Id, String>{
                cv.Id => cv.Hash__c
            });

            Map<String, String> contentVersionTitleToContentDocIdMap = FilePreviewAndDownloadCtrl.getContentDocumentsThroughToken(token);

            System.assert(contentVersionTitleToContentDocIdMap.containsKey(cv.ContentDocumentId.to15()));
            System.assert(contentVersionTitleToContentDocIdMap.values().contains(cv.Title));

            String tokenWithoutHash = ContentVersionTriggerHandler.getToken(new Map<Id, String>{
                cv.Id => null
            });

            try {
                FilePreviewAndDownloadCtrl.getContentDocumentsThroughToken(tokenWithoutHash);
            } catch (Exception e) {
                System.assertEquals(FilePreviewAndDownloadCtrl.MESSAGE_INCORRECT_TOKEN, e.getMessage());
            }
        }
    }
}