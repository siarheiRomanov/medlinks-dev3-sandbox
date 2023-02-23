public with sharing class AppealFieldSetCtrl {
    @AuraEnabled(Cacheable=true)
    public static List<String> getFieldList(String fieldSetName) {
        List<String> fieldSetFields = new List<String>();

        for (Schema.FieldSetMember fieldSetMember : Schema.SObjectType.Appeal__c.fieldSets.getMap().get(fieldSetName).getFields()) {
            fieldSetFields.add(fieldSetMember.getFieldPath());
        }

        return fieldSetFields;
    }

    @AuraEnabled(Cacheable=true)
    public static List<PickListOption> getLetterTypes(String fieldApiName) {
        List<PickListOption> pickListOptions = new List<PickListOption>();

        if (fieldApiName == String.valueOf(ContentVersion.Letter_Type__c.getDescribe().name)) {
            for (Schema.PicklistEntry picklistEntry : Schema.SObjectType.ContentVersion.fields.getMap().get(fieldApiName).getDescribe().getPicklistValues()) {
                pickListOptions.add(new PickListOption(picklistEntry.getLabel(), picklistEntry.getValue()));
            }
        }

        return pickListOptions;
    }

    public with sharing class PickListOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        PickListOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}