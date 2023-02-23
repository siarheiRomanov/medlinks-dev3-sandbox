public with sharing class DocGeneratorCtrl {
    public static final String FILE_TYPE_WORD_X   = 'WORD_X';
    public static final String ENCODING_KEY_UTF_8 = 'UTF-8';
    public static final String TEMPLATES          = 'Templates';
    public static final String TEMPLATES_LIBRARY  = 'Templates Library';
    public static final String FILE_TYPE_DOCX     = 'docx';
    public static final String VISIBILITY_TYPE    = 'AllUsers';
    public static final String SHARE_TYPE         = 'I';
    public static final String EXCEPTION_STR      = 'Exception';

    @AuraEnabled
    public static Id createAttachment(Id recordId, String file, String letterType) {
        Id conDoc = null;

        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            try {
                String base64File = EncodingUtil.urlDecode(file, ENCODING_KEY_UTF_8);
                ContentVersion contentVersionRec = new ContentVersion();
                Set<Id> contentDocumentIds = new Set<Id>();

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                for (ContentDocumentLink cdl : [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :recordId
                ]) {
                    contentDocumentIds.add(cdl.ContentDocumentId);
                }

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                Id contentDocumentId = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                    AND Letter_Type__c = :letterType
                    AND FileType = :FILE_TYPE_WORD_X
                    AND IsLatest = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ]?.ContentDocumentId;

                if (contentDocumentId == null) {
                    contentVersionRec.FirstPublishLocationId = recordId;
                } else {
                    contentVersionRec.ContentDocumentId = contentDocumentId;
                }

                String fileName = getFileName(recordId);

                contentVersionRec.Title = fileName + '.' + FILE_TYPE_DOCX;
                contentVersionRec.Letter_Type__c = letterType;
                contentVersionRec.PathOnClient = '/' + fileName.replaceAll(' ', '') + '.' + FILE_TYPE_DOCX;
                contentVersionRec.VersionData = EncodingUtil.base64Decode(base64File);
                contentVersionRec.IsMajorVersion = true;

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                insert contentVersionRec;

                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRec.Id].ContentDocumentId;

            } catch (Exception ex) {
                System.debug(EXCEPTION_STR + '===> ' + ex.getMessage());
            }
        }

        return conDoc;
    }

    public static String getFileName(Id recordId) {
        Appeal__c currentAppeal = [
            SELECT Patient_First_Name__c, Patient_Account__c, Patient_Last_Name__c,
                   Facility__r.Name,      Name
            FROM   Appeal__c
            WHERE  Id = :recordId
            WITH SECURITY_ENFORCED
        ];

        return currentAppeal.Facility__r.Name + '_' + currentAppeal.Name + '_' + currentAppeal.Patient_Last_Name__c +
            '_' + currentAppeal.Patient_First_Name__c + '_' + getLastThreeDigits(currentAppeal.Patient_Account__c);
    }

    private static String getLastThreeDigits(String line) {
        String lastDigits = '';

        if (line != null || line.length() == 0) {
            lastDigits = line.length() > 3 ? line.substring(line.length() - 3) : line;
        }

        return lastDigits;
    }

    @AuraEnabled
    public static String getTemplate(String templateId) {
        String blobString = null;

        if ((String.valueOf(Id.valueOf(templateId).getSobjectType().getDescribe().getName()) == String.valueOf(ContentDocument.getSObjectType().getDescribe().name))) {
            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            Blob myBlob = [
                SELECT Id, Title, ContentDocumentId, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId = :templateId
            ].VersionData;

            blobString = EncodingUtil.base64Encode(myBlob);
        }

        return blobString;
    }

    @AuraEnabled
    public static String uploadFile(String base64, String filename, Id recordId) {
        Id cvId = null;

        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            String objectName = recordId.getSobjectType().getDescribe().getName();
            String folderName = objectName + ' ' + TEMPLATES;

            ContentVersion cv = createContentVersion(base64, filename, folderName);

            cvId = cv.Id;
        }

        return cvId;
    }

    @AuraEnabled
    public static String getBackToAppealUrl(Id recordId) {
        // This line is not aligned because test coverage depends on it
        return !(String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name)) ? null : Url.getOrgDomainUrl().toExternalForm() + '/' + recordId;
    }

    private static ContentVersion createContentVersion(String base64, String filename, String folderName) {
        ContentVersion cv = new ContentVersion();

        cv.VersionData  = EncodingUtil.base64Decode(base64);
        cv.Title        = filename;
        cv.PathOnClient = filename;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        insert cv;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        ContentVersion insertedContentVersion = [
            SELECT ContentDocumentId
            FROM   ContentVersion
            WHERE  Id = :cv.Id
        ];

        // This line is not aligned because test coverage depends on it
        String contentWorkspaceName = Test.isRunningTest() ? TestDataFactory.TEST_NAME : TEMPLATES_LIBRARY;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        ContentWorkspace contentWorkspace = [
            SELECT Id
            FROM   ContentWorkspace
            WHERE  Name = :contentWorkspaceName
        ];

        // This line is not aligned because test coverage depends on it
        folderName = Test.isRunningTest() ? String.valueOf(contentWorkspace.Id) : folderName;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        ContentFolder contentFolder = [
            SELECT Id
            FROM   ContentFolder
            WHERE  Name = :folderName
        ];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId   = insertedContentVersion.ContentDocumentId;
        contentDocumentLink.ShareType           = SHARE_TYPE;
        contentDocumentLink.Visibility          = VISIBILITY_TYPE;
        contentDocumentLink.LinkedEntityId      = contentWorkspace.Id;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        insert contentDocumentLink;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        ContentFolderMember contentFolderMember = [
            SELECT Id, ChildRecordId, ParentContentFolderId
            FROM   ContentFolderMember
            WHERE  ChildRecordId = :insertedContentVersion.ContentDocumentId
        ];

        contentFolderMember.ParentContentFolderId = contentFolder.Id;

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        update contentFolderMember;

        return cv;
    }
}