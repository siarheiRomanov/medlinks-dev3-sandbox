public with sharing class LookAtPreviewCtrl {
    public static final String PDF_NAME      = 'pdfName';
    public static final String PDF_DATE      = 'pdfDate';
    public static final String PDF_SIZE      = 'pdfSize';
    public static final String DOC_NAME      = 'docName';
    public static final String DOC_DATE      = 'docDate';
    public static final String DOC_SIZE      = 'docSize';
    public static final String B_UNIT        = 'B';
    public static final String KB_UNIT       = 'KB';
    public static final String MB_UNIT       = 'MB';
    public static final String GB_UNIT       = 'GB';
    public static final String DATE_FORMAT   = 'yyyy-MMM-dd';
    public static final String FILE_TYPE_PDF = 'pdf';

    @AuraEnabled
    public static Map<String, Object> getAttachmentsInfo(Id recordId, String letterType) {
        Map<String, Object> attachmentsInfo = new Map<String, Object>();

        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            if (recordId != null) {
                Set<Id> contentDocumentIds = new Set<Id>();

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                    contentDocumentIds.add(cdl.ContentDocumentId);
                }

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                List<ContentVersion> createdAttachments = [
                    SELECT   ContentDocumentId, CreatedDate, Title, ContentSize
                    FROM     ContentVersion
                    WHERE    ContentDocumentId IN :contentDocumentIds
                         AND Letter_Type__c = :letterType
                         AND IsLatest = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT    2
                ];

                if (createdAttachments != null) {
                    ContentVersion cvPdf = new ContentVersion();
                    ContentVersion cvDoc = new ContentVersion();
                    List<String> format1 = createdAttachments[0].Title.split('\\.');
                    List<String> format2 = null;

                    if (createdAttachments.size() == 2) {
                        format2 = createdAttachments[1].Title.split('\\.');
                    }
                    System.debug('format1: ' + format1);
                    System.debug('format2: ' + format2);

                    if (format2 != null && format1.get(format1.size() - 1) == FILE_TYPE_PDF && format2.get(format2.size() - 1) != FILE_TYPE_PDF) {
                        cvPdf = createdAttachments[0];
                        cvDoc = createdAttachments[1];
                    } else if (format2 != null && format2.get(format2.size() - 1) == FILE_TYPE_PDF && format1.get(format1.size() - 1) != FILE_TYPE_PDF) {
                        cvPdf = createdAttachments[1];
                        cvDoc = createdAttachments[0];
                    } else {
                        cvDoc = createdAttachments[0];
                        cvPdf = null;
                    }

                    if (cvPdf != null) {
                        attachmentsInfo.put(PDF_NAME, cvPdf.Title);
                        attachmentsInfo.put(PDF_DATE, cvPdf.CreatedDate.format(DATE_FORMAT));
                        attachmentsInfo.put(PDF_SIZE, getSize(cvPdf.ContentSize));
                        attachmentsInfo.put(DOC_NAME, cvDoc.Title);
                        attachmentsInfo.put(DOC_DATE, cvDoc.CreatedDate.format(DATE_FORMAT));
                        attachmentsInfo.put(DOC_SIZE, getSize(cvDoc.ContentSize));
                    } else {
                        attachmentsInfo.put(DOC_NAME, cvDoc.Title);
                        attachmentsInfo.put(DOC_DATE, cvDoc.CreatedDate.format(DATE_FORMAT));
                        attachmentsInfo.put(DOC_SIZE, getSize(cvDoc.ContentSize));
                    }
                }
            }
        }

        return attachmentsInfo;
    }

    @AuraEnabled
    public static String getSize(Integer size) {
        String sizeWithUnit = '';

        if (size < 1024) {
            sizeWithUnit = String.valueOf(size) + ' ' + B_UNIT;
        } else if (size >= 1024 && size < Math.pow(1024, 2)) {
            sizeWithUnit = String.valueOf(Decimal.valueOf(size).divide(1024, 0)) + ' ' + KB_UNIT;
        } else if (size >= Math.pow(1024, 2) && size < Math.pow(1024, 3)) {
            sizeWithUnit = String.valueOf(Decimal.valueOf(size).divide(Math.pow(1024, 2), 0)) + ' ' + MB_UNIT;
        } else if (size >= Math.pow(1024, 3)) {
            sizeWithUnit = String.valueOf(Decimal.valueOf(size).divide(Math.pow(1024, 3), 2)) + ' ' + GB_UNIT;
        }

        return sizeWithUnit;
    }
}