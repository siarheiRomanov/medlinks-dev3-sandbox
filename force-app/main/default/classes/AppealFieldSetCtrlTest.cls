@IsTest
private class AppealFieldSetCtrlTest {
    @IsTest
    static void getFieldListTest() {
        System.assert(AppealFieldSetCtrl.getFieldList(TestDataFactory.APPEAL_FIELDSET_TEST_VALUE) != null);
    }

    @IsTest
    static void getLetterTypesTest() {
        System.assert(AppealFieldSetCtrl.getLetterTypes(ContentVersion.Letter_Type__c.getDescribe().name) != null);
    }
}