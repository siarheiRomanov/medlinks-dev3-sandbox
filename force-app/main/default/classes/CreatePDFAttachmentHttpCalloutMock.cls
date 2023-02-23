@IsTest
global with sharing class CreatePDFAttachmentHttpCalloutMock implements HttpCalloutMock {
    private static final String OK_STR           = 'OK';
    private static final String CONTENT_TYPE     = 'Content-Type';
    private static final String APPLICATION_PDF  = 'application/pdf';
    private static final String TEST_JSON_OBJECT = '{"previewUrls":[{"previewUrl":"test"}]}';

    global HttpResponse respond(HttpRequest req) {
        HttpResponse resp = new HttpResponse();

        resp.setStatus(OK_STR);
        resp.setStatusCode(200);
        resp.setHeader(CONTENT_TYPE, APPLICATION_PDF);
        resp.setBodyAsBlob(Blob.valueOf(TEST_JSON_OBJECT));

        return resp;
    }
}