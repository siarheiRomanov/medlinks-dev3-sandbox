public with sharing class EmailHandler {
    @AuraEnabled
    public static List<Map<String, Object>> getAttachments(String recordId) {
        List<Map<String, Object>> attachmentsList = new List<Map<String, Object>>();
        List<ContentDocumentLink> cdlList         = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate, ContentDocument.ContentSize
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY ContentDocument.CreatedDate DESC
        ];

        for (ContentDocumentLink cdl : cdlList) {
            attachmentsList.add(new Map<String, Object>{
                'label' => cdl.ContentDocument.Title,
                'value' => cdl.ContentDocumentId,
                'date' => cdl.ContentDocument.CreatedDate.format('yyyy-MMM-dd'),
                'size' => SecondScreen.getSize(cdl.ContentDocument.ContentSize)
            });
        }

        return attachmentsList;
    }

    private static List<ContentDocumentLink> reverseList(List<ContentDocumentLink> cdList) {
        List<ContentDocumentLink> reversedList = new List<ContentDocumentLink>();

        for (Integer i = cdList.size() - 1; i >= 0; i--) {
            reversedList.add(cdList[i]);
        }

        return reversedList;
    }
}