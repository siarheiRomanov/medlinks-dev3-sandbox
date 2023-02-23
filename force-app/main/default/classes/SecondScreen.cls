public with sharing class SecondScreen {
    @AuraEnabled
    public static Map<String, Object> getAttachmentsInfo(Id recordId) {
        Map<String, Object> AttachmentsInfo = new Map<String, Object>();

        if (recordId != null) {
            List<ContentDocumentLink> createdAttachments = [
                SELECT ContentDocumentId, ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.ContentSize
                FROM ContentDocumentLink
                WHERE  LinkedEntityId = :recordId
                ORDER BY ContentDocument.LastModifiedDate DESC
                LIMIT 2
            ];

            List<String> format = createdAttachments[0].ContentDocument.Title.split('\\.');

            if (format.get(format.size() - 1) == 'pdf') {
                AttachmentsInfo.put('pdfName', createdAttachments[0].ContentDocument.Title);
                AttachmentsInfo.put('pdfDate', createdAttachments[0].ContentDocument.CreatedDate.format('yyyy-MMM-dd'));
                AttachmentsInfo.put('pdfSize', getSize(createdAttachments[0].ContentDocument.ContentSize));
                AttachmentsInfo.put('docName', createdAttachments[1].ContentDocument.Title);
                AttachmentsInfo.put('docDate', createdAttachments[1].ContentDocument.CreatedDate.format('yyyy-MMM-dd'));
                AttachmentsInfo.put('docSize', getSize(createdAttachments[1].ContentDocument.ContentSize));
            }
            else {
                AttachmentsInfo.put('docName', createdAttachments[0].ContentDocument.Title);
                AttachmentsInfo.put('docDate', createdAttachments[0].ContentDocument.CreatedDate.format('yyyy-MMM-dd'));
                AttachmentsInfo.put('docSize', getSize(createdAttachments[0].ContentDocument.ContentSize));
            }
        }

        return AttachmentsInfo;
    }

    @AuraEnabled
    public static String getSize(Integer size) {
        if (size < 1024) {
            return String.valueOf(size) + ' B';
        }
        else if (size >= 1024 && size < Math.pow(1024, 2)) {
            return String.valueOf(Decimal.valueOf(size).divide(1024, 0)) + ' KB';
        }
        else if (size >= Math.pow(1024, 2) && size < Math.pow(1024, 3)) {
            return String.valueOf(Decimal.valueOf(size).divide(Math.pow(1024, 2), 0)) + ' MB';
        }
        else {
            return String.valueOf(Decimal.valueOf(size).divide(Math.pow(1024, 3), 2)) + ' GB';
        }
    }
}