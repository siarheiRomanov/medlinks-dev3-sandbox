public with sharing class TemplateHelper {
    public static String BASIC_TEMPLATE            = 'basicTemplate';
    public static String TEMPLATE_HELPER_IMAGE_JPG = 'TemplateHelperImageJPG';

    @AuraEnabled
    public static ContentVersion getTemplateId(Id recordId) {
        ContentVersion contentVersion = null;

        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            String objectName    = recordId.getSobjectType().getDescribe().getName();
            String templateTitle = BASIC_TEMPLATE + objectName;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            contentVersion = [SELECT ContentDocumentId, Title FROM ContentVersion WHERE Title = :templateTitle LIMIT 1];
        }

        return contentVersion;
    }

    @AuraEnabled
    public static ContentVersion getImageId() {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Title = :TEMPLATE_HELPER_IMAGE_JPG LIMIT 1];
    }
}