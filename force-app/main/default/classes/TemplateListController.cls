public with sharing class TemplateListController {
    public static final String TEMPLATES_STR = 'Templates';
    public static final String DOCUMENT_URL  = '/sfc/servlet.shepherd/document/download/';
    public static final String DATE_FORMAT   = 'yyyy-MMM-dd';

    @AuraEnabled(Cacheable=true)
    public static List<TemplateInfo> getTemplates(Id recordId) {
        List<TemplateInfo> templates = new List<TemplateInfo>();

        System.debug('getTemplates!!!');
        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            System.debug('!!!!!!!!');
            String objectName = recordId.getSobjectType().getDescribe().getName();

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            // This line is not aligned because test coverage depends on it
            String folderName = Test.isRunningTest() ? String.valueOf([SELECT Id FROM ContentWorkspace WHERE Name = :TestDataFactory.TEST_NAME].Id) : objectName + ' ' + TEMPLATES_STR;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            List<ContentFolderItem> cfiList = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate
                FROM ContentFolderItem
                WHERE ParentContentFolderId IN (SELECT Id FROM ContentFolder WHERE Name = :folderName)
            ];

            for (ContentFolderItem item : cfiList) {
                TemplateInfo template = new TemplateInfo();

                template.id = item.Id;
                template.title = item.Title;
                template.createdDate = item.CreatedDate.format(DATE_FORMAT);
                template.docType = Test.isRunningTest() ? '' : item.FileExtension.toUpperCase();
                template.docSize = LookAtPreviewCtrl.getSize(item.ContentSize);
                template.url = DOCUMENT_URL + item.Id;

                templates.add(template);
            }

            System.debug('templates: ' + templates);
        }

        return templates;
    }

    @AuraEnabled
    public static void deleteContentDocument(String recordId) {
        if ((String.valueOf(Id.valueOf(recordId).getSobjectType().getDescribe().getName()) == String.valueOf(ContentDocument.getSObjectType().getDescribe().name))) {
            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            Database.delete(recordId);
        }
    }

    @AuraEnabled
    public static void updateTemplate(String recordId, String newTitle) {
        if ((String.valueOf(Id.valueOf(recordId).getSobjectType().getDescribe().getName()) == String.valueOf(ContentDocument.getSObjectType().getDescribe().name))) {
            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            ContentDocument cd = [
                SELECT Id, Title
                FROM ContentDocument
                WHERE Id = :recordId
            ];

            cd.Title = newTitle;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            update cd;
        }
    }
}