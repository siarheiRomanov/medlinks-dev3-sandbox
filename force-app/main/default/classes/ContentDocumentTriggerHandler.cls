public with sharing class ContentDocumentTriggerHandler {
    public static void beforeDeleteContentDocument(List<ContentDocument> oldContentDocuments) {
        List<ContentVersion> mainContentVersionsToDeleteHash = new List<ContentVersion>();

        for (ContentVersion cv : getAppealMainLastContentVersions(oldContentDocuments)) {
            cv.Document_Type__c = null;
            mainContentVersionsToDeleteHash.add(cv);
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        update mainContentVersionsToDeleteHash;
    }

    private static List<ContentVersion> getAppealMainLastContentVersions(List<ContentDocument> contentDocumentList) {
        Set<Id>              appealContentDocIds           = new Set<Id>();
        List<ContentVersion> appealMainLastContentVersions = new List<ContentVersion>();

        for (ContentDocumentLink cdl : getContentDocumentLinks(contentDocumentList)) {
            if (ContentVersionTriggerHandler.isAppealById(cdl.LinkedEntityId)) {
                appealContentDocIds.add(cdl.ContentDocumentId);
            }
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentVersion cv : [
            SELECT Document_Type__c
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :appealContentDocIds
               AND IsLatest = TRUE
        ]) {
            if (cv.Document_Type__c == ContentVersionTriggerHandler.DOCUMENT_TYPE_MAIN) {
                appealMainLastContentVersions.add(cv);
            }
        }

        return appealMainLastContentVersions;
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(List<ContentDocument> contentDocumentList) {
        Set<String> contentDocIds = new Set<String>();

        for (ContentDocument cd : contentDocumentList) {
            contentDocIds.add(String.valueOf(cd.Id));
        }

        String query = ContentVersionTriggerHandler.getQuery(
            new List<String>{
                ContentVersionTriggerHandler.FIELD_NAME_LINKED_ENTITY_ID,
                ContentVersionTriggerHandler.FIELD_NAME_CONTENT_DOCUMENT_ID
            },
            ContentVersionTriggerHandler.OBJECT_NAME_CONTENT_DOCUMENT_LINK,
            new Map<String, List<String>>{
                ContentVersionTriggerHandler.FIELD_NAME_CONTENT_DOCUMENT_ID => new List<String>(contentDocIds)
            }
        );

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return Database.query(query);
    }
}