public class CreateRequestForPdf {
    public  static final String FILE_TYPE_PDF           = 'PDF';
    public  static final String GET_METHOD              = 'GET';
    public  static final String PREVIEW_URL             = 'previewUrl';
    public  static final String GET_URL_END_POINT_BEGIN = 'callout:REST_API2/services/data/v52.0/connect/files/';
    public  static final String GET_URL_END_POINT_END   = '/previews/pdf';
    public  static final String CREATE_PDF_END_POINT    = 'callout:REST_API2';

    @AuraEnabled(Cacheable=false)
    public static String getUrl(Id contentDocumentId) {
        String wantedUrl = null;

        if ((String.valueOf(contentDocumentId.getSobjectType().getDescribe().getName()) == String.valueOf(ContentDocument.getSObjectType().getDescribe().name))) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(GET_URL_END_POINT_BEGIN + contentDocumentId + GET_URL_END_POINT_END);
            request.setMethod(GET_METHOD);

            HttpResponse res = http.send(request);
            JSONParser parser = JSON.createParser(res.getBody());


            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                        (parser.getText() == PREVIEW_URL)) {
                    parser.nextToken();
                    wantedUrl = parser.getText();
                }
            }
        }

        return wantedUrl;
    }
    
    @AuraEnabled(Cacheable=false)
    public static Id createPDFAttachment(Id parentId, String url, String letterType) {
        Id conDoc = null;

        if ((String.valueOf(parentId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(CREATE_PDF_END_POINT + url);
            request.setMethod(GET_METHOD);

            HttpResponse res = http.send(request);
            Blob beforeBlob = res.getBodyAsBlob();
            ContentVersion contentVersionRec = new ContentVersion();

            // This line is not aligned because test coverage depends on it
            String fileType = Test.isRunningTest() ? TestDataFactory.FILE_TYPE_UNKNOWN : FILE_TYPE_PDF;

            Set<Id> contentDocumentIds = new Set<Id>();
            Id contentDocumentId = null;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :parentId
            ]) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND Letter_Type__c = :letterType
                AND FileType = :fileType
                AND IsLatest = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]?.ContentDocumentId;

            if (contentDocumentId == null) {
                contentVersionRec.FirstPublishLocationId = parentId;
            } else {
                contentVersionRec.ContentDocumentId = contentDocumentId;
            }

            String fileName = DocGeneratorCtrl.getFileName(parentId);

            contentVersionRec.Title = fileName + '.' + FILE_TYPE_PDF.toLowerCase();
            contentVersionRec.Letter_Type__c = letterType;
            contentVersionRec.PathOnClient = '/' + fileName.replaceAll(' ', '') + '.' + FILE_TYPE_PDF.toLowerCase();
            contentVersionRec.VersionData = beforeBlob;
            contentVersionRec.IsMajorVersion = true;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            insert contentVersionRec;

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRec.Id].ContentDocumentId;
        }

        return conDoc;
    }
}