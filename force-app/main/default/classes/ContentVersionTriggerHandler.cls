public with sharing class ContentVersionTriggerHandler {
    public static final String DOCUMENT_TYPE_MAIN                          = 'Main';
    public static final String FILE_TYPE_PDF                               = 'PDF';
    public static final String ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT        = 'You can specify only PDF Client\'s Copy document!';
    public static final String ERROR_MESSAGE_ONLY_TWO_LETTER_TYPE_DOCUMENT = 'You can add only two documents of any letter type!';
    public static final String FIELD_NAME_CONTENT_DOCUMENT_ID              = String.valueOf(ContentVersion.fields.ContentDocumentId);
    public static final String FIELD_NAME_LINKED_ENTITY_ID                 = String.valueOf(ContentDocumentLink.fields.LinkedEntityId);
    public static final String OBJECT_NAME_CONTENT_DOCUMENT_LINK           = String.valueOf(ContentDocumentLink.getSObjectType().getDescribe().name);
    public static final String FIELD_NAME_LETTER_TYPE                      = String.valueOf(ContentVersion.fields.Letter_Type__c);
    public static final String NEW_FILE_EMAIL_TEMPLATE_FOR_CONTACT         = 'New File Email Template For Contact';
    public static final String NEW_FILE_EMAIL_TEMPLATE_FOR_USER            = 'New File Email Template For User';

    private static final String ALGORITHM_NAME                    = 'SHA-512';
    private static final String LINK_TO_MAIN_DOCUMENT             = String.valueOf(Appeal_Settings__c.getInstance().Email_Security_Portal_Url__c);
    private static final String TOKEN                             = '?token=';
    private static final String SELECT_STR                        = 'SELECT';
    private static final String FROM_STR                          = 'FROM';
    private static final String WHERE_STR                         = 'WHERE';
    private static final String OR_STR                            = 'OR';
    private static final String AND_STR                           = 'AND';

    public static void afterInsertContentVersion(List<ContentVersion> newContentVersions) {
        List<ContentVersion> appealContentVersions = getAppealContentVersions(newContentVersions);

        if (!appealContentVersions.isEmpty() && checkCountDocumentsOfLetterType(true, appealContentVersions, null)) {
            List<Appeal__c> updatedAppeals = getAppealsForUpdate(true, appealContentVersions, null);

            SObjectAccessDecision securityDecision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                updatedAppeals
            );

            update securityDecision.getRecords();
        }

        uploadFileNotification(newContentVersions);
    }

    public static void uploadFileNotification(List<ContentVersion> newContentVersions) {
        Set<Id> appealIdsFromContentVersions = getAppealIdsFromContentVersions(newContentVersions);

        if (!appealIdsFromContentVersions.isEmpty()) {
            for (Appeal__c appeal : [
                SELECT Assigned_Appeals_Specialist__c, Appeal_Scheduler__c, Assigned_Scheduler__c,
                       Overread_By__c, Opposing_Appeals_Specialist__c, Opposing_Scheduler__c,
                       Assigned_Appeals_Specialist__r.Email, Appeal_Scheduler__r.Email, Assigned_Scheduler__r.Email,
                       Overread_By__r.Email, Opposing_Appeals_Specialist__r.Email, Opposing_Scheduler__r.Email
                FROM   Appeal__c
                WHERE  Id IN :appealIdsFromContentVersions
                WITH SECURITY_ENFORCED
            ]) {
                List<Id> recipientUserIds = new List<Id>{
                };

                if (appeal.Assigned_Appeals_Specialist__c != null && appeal.Assigned_Appeals_Specialist__r.Email != null) {
                    recipientUserIds.add(appeal.Assigned_Appeals_Specialist__c);
                }

                if (appeal.Assigned_Scheduler__c != null && appeal.Assigned_Scheduler__r.Email != null) {
                    recipientUserIds.add(appeal.Assigned_Scheduler__c);
                }

                if (appeal.Appeal_Scheduler__c != null && appeal.Appeal_Scheduler__r.Email != null) {
                    recipientUserIds.add(appeal.Appeal_Scheduler__c);
                }

                List<Id> recipientContactIds = new List<Id>{
                };

                if (appeal.Overread_By__c != null && appeal.Overread_By__r.Email != null) {
                    recipientContactIds.add(appeal.Overread_By__c);
                }

                if (appeal.Opposing_Appeals_Specialist__c != null && appeal.Opposing_Appeals_Specialist__r.Email != null) {
                    recipientContactIds.add(appeal.Opposing_Appeals_Specialist__c);
                }

                if (appeal.Opposing_Scheduler__c != null && appeal.Opposing_Scheduler__r.Email != null) {
                    recipientContactIds.add(appeal.Opposing_Scheduler__c);
                }

                EmailNotificationHandler.sendEmailByIds(
                    recipientUserIds,
                    recipientContactIds,
                    appeal.Id,
                    NEW_FILE_EMAIL_TEMPLATE_FOR_CONTACT,
                    NEW_FILE_EMAIL_TEMPLATE_FOR_USER
                );
            }
        }
    }

    private static Set<Id> getAppealIdsFromContentVersions(List<ContentVersion> contentVersions) {
        Set<Id> appealIdsFromContentVersions = new Set<Id>();

        for (ContentDocumentLink cdl : getContentDocumentLinks(contentVersions)) {
            if ((String.valueOf(cdl.LinkedEntityId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
                appealIdsFromContentVersions.add(cdl.LinkedEntityId);
            }
        }

        return appealIdsFromContentVersions;
    }

    public static void beforeUpdateContentVersion(List<ContentVersion> newContentVersions, Map<Id, ContentVersion> oldContentVersionsMap) {
        List<ContentVersion>    appealContentVersions    = getAppealContentVersions(newContentVersions);
        Map<Id, ContentVersion> appealContentVersionsMap = getAppealContentVersionsMap(appealContentVersions, oldContentVersionsMap);

        if (!appealContentVersions.isEmpty() && checkCountDocumentsOfLetterType(false, appealContentVersions, appealContentVersionsMap)) {
            List<Appeal__c>    updatedAppeals                       = getAppealsForUpdate(false, appealContentVersions, appealContentVersionsMap);
            Map<Id,Id>         contentDocumentToAppealIdsMap        = getContentDocumentToAppealIdsMap(appealContentVersions);
            Map<Id, List<Id>>  appealsWithExistMainContentVersions  = getAppealIdToExistMainContentVersions(contentDocumentToAppealIdsMap.values());
            Map<Id, List<Id>>  appealsWithMainContentVersions       = new Map<Id, List<Id>>();

            for (ContentVersion contentVersion : appealContentVersions) {
                if (contentVersion.Document_Type__c != DOCUMENT_TYPE_MAIN && appealContentVersionsMap.get(contentVersion.Id).Document_Type__c == DOCUMENT_TYPE_MAIN) {
                    contentVersion.Hash__c = null;

                    if (appealsWithMainContentVersions.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)) != null) {
                        appealsWithMainContentVersions.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)).add(contentVersion.Id);
                    } else {
                        appealsWithMainContentVersions.put(
                            contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId),
                            new List<Id>{contentVersion.Id}
                        );
                    }
                }
            }

            if (!appealsWithMainContentVersions.isEmpty()) {
                for (Id appealId : appealsWithExistMainContentVersions.keySet()) {
                    Map<Id, Appeal__c> updatedAppealsMap = new Map<Id, Appeal__c>(updatedAppeals);

                    if (appealsWithExistMainContentVersions.get(appealId).size() == appealsWithMainContentVersions.get(appealId).size()) {
                        if (updatedAppealsMap.get(appealId) != null) {
                            updatedAppealsMap.get(appealId).Link_To_Main_Document__c = null;
                        }
                    } else if (!appealsWithMainContentVersions.get(appealId).isEmpty()) {
                        Map<Id, Map<Id, String>> appealIdToContentVersionIdToHashMap  = new Map<Id, Map<Id, String>>();

                        appealIdToContentVersionIdToHashMap.putAll(getExistAppealIdToContentVersionIdToHashMap(contentDocumentToAppealIdsMap.values()));

                        for (Id existAppealId : appealIdToContentVersionIdToHashMap.keySet()) {
                            if (appealsWithMainContentVersions.keySet().contains(existAppealId) && !appealsWithMainContentVersions.get(existAppealId).isEmpty()) {
                                for (Id cvId : appealsWithMainContentVersions.get(existAppealId)) {
                                    if (!appealsWithMainContentVersions.get(existAppealId).isEmpty() && appealIdToContentVersionIdToHashMap.get(appealId).keySet().contains(cvId)) {
                                        appealIdToContentVersionIdToHashMap.get(existAppealId).remove(cvId);
                                    }
                                }
                            }
                        }

                        if (updatedAppealsMap.get(appealId) != null) {
                            updatedAppealsMap.get(appealId).Link_To_Main_Document__c = LINK_TO_MAIN_DOCUMENT +
                                TOKEN + getToken(appealIdToContentVersionIdToHashMap.get(appealId));
                        }
                    }
                }
            }

            if (!updatedAppeals.isEmpty()) {
                SObjectAccessDecision securityDecision = Security.stripInaccessible(
                    AccessType.UPDATABLE,
                    updatedAppeals
                );

                update securityDecision.getRecords();
            }
        }
    }

    private static Map<Id, List<Id>> getAppealIdToExistMainContentVersions(List<Id> appealIds) {
        Map<Id, List<Id>> appealsWithExistMainContentVersions = new Map<Id, List<Id>>();
        Set<Id>           appealContentDocumentIds            = new Set<Id>();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :appealIds]) {
            appealContentDocumentIds.add(cdl.ContentDocumentId);
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        List<ContentVersion> existMainContentVersions = [
            SELECT ContentDocumentId
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :appealContentDocumentIds
               AND IsLatest           = TRUE
               AND Document_Type__c   = :DOCUMENT_TYPE_MAIN
        ];

        Map<Id,Id> contentDocumentToAppealIdsMap = getContentDocumentToAppealIdsMap(existMainContentVersions);

        for (ContentVersion cv : existMainContentVersions) {
            if (appealsWithExistMainContentVersions.get(contentDocumentToAppealIdsMap.get(cv.ContentDocumentId)) != null) {
                appealsWithExistMainContentVersions.get(contentDocumentToAppealIdsMap.get(cv.ContentDocumentId)).add(cv.Id);
            } else {
                appealsWithExistMainContentVersions.put(
                    contentDocumentToAppealIdsMap.get(cv.ContentDocumentId),
                    new List<Id>{cv.Id}
                );
            }
        }

        return appealsWithExistMainContentVersions;
    }


    private static Map<Id, Id> getContentDocumentToAppealIdsMap(List<ContentVersion> contentVersionList) {
        Map<Id, Id> contentDocumentToAppealIdsMap = new Map<Id, Id>();

        for (ContentDocumentLink cdl : getContentDocumentLinks(contentVersionList)) {
            if (isAppealById(cdl.LinkedEntityId)) {
                contentDocumentToAppealIdsMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
        }

        return contentDocumentToAppealIdsMap;
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(List<ContentVersion> contentVersionList) {
        Set<String> contentDocIds = new Set<String>();

        for (ContentVersion cv : contentVersionList) {
            contentDocIds.add(String.valueOf(cv.ContentDocumentId));
        }

        String query = getQuery(
            new List<String>{
                FIELD_NAME_LINKED_ENTITY_ID,
                FIELD_NAME_CONTENT_DOCUMENT_ID
            },
            OBJECT_NAME_CONTENT_DOCUMENT_LINK,
            new Map<String, List<String>>{
                FIELD_NAME_CONTENT_DOCUMENT_ID => new List<String>(contentDocIds)
            }
        );

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return Database.query(query);
    }

    private static List<ContentVersion> getAppealContentVersions(List<ContentVersion> contentVersionList) {
        Set<Id>              appealContentDocIds   = new Set<Id>();
        List<ContentVersion> appealContentVersions = new List<ContentVersion>();

        for (ContentDocumentLink cdl : getContentDocumentLinks(contentVersionList)) {
            if (isAppealById(cdl.LinkedEntityId)) {
                appealContentDocIds.add(cdl.ContentDocumentId);
            }
        }

        for (ContentVersion cv : contentVersionList) {
            if (appealContentDocIds.contains(cv.ContentDocumentId)) {
                appealContentVersions.add(cv);
            }
        }

        return appealContentVersions;
    }

    public static Boolean isAppealById(Id recordId) {
        return (String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name));
    }

    public static String getQuery(List<String> fieldsList, String sobjectName, Map<String, List<String>> fieldToValuesMap) {
        String query = SELECT_STR + ' ';

        query += String.join(fieldsList, ', ');
        query += ' ' + FROM_STR + ' ' + sobjectName;

        if (fieldToValuesMap != null) {
            if (fieldToValuesMap.keySet().size() > 0) {
                query += ' ' + WHERE_STR + ' ';

                List<String> fieldNames = new List<String>(fieldToValuesMap.keySet());

                query += fieldNames[0] + ' = \'';
                query += String.join(fieldToValuesMap.get(fieldNames[0]), '\' ' + OR_STR + ' ' + fieldNames[0] + ' = \'');
                query += '\'';

                for (Integer i = 1; i < fieldNames.size(); i++) {
                    query += ' ' + AND_STR + ' ' + fieldNames[i] + ' = \'';
                    query += String.join(fieldToValuesMap.get(fieldNames[i]), '\' ' + OR_STR + ' ' + fieldNames[i] + ' = \'');
                    query += '\'';
                }
            }
        }

        return query;
    }

    private static Map<Id, ContentVersion> getAppealContentVersionsMap(List<ContentVersion> appealVersionList, Map<Id, ContentVersion> contentVersionsMap) {
        Map<Id, ContentVersion> appealContentVersionsMap = new Map<Id, ContentVersion>();

        for (ContentVersion cv : appealVersionList) {
            appealContentVersionsMap.put(cv.Id, contentVersionsMap.get(cv.Id));
        }

        return appealContentVersionsMap;
    }

    private static Boolean checkCountDocumentsOfLetterType(Boolean isInsert, List<ContentVersion> newContentVersions, Map<Id, ContentVersion> oldContentVersionsMap) {
        Boolean                       isSuccess                              = true;
        Map<Id, Map<String, Integer>> appealIdToLetterTypeToDocumentLimitMap = new Map<Id, Map<String, Integer>>();
        Map<Id,Id>                    contentDocumentToAppealIdsMap          = getContentDocumentToAppealIdsMap(newContentVersions);
        Set<Id>                       existContentDocumentIds                = getExistContentDocumentIds();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        contentDocumentToAppealIdsMap.putAll(getContentDocumentToAppealIdsMap([
            SELECT ContentDocumentId
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :existContentDocumentIds
        ]));

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (AggregateResult mainDocument : [
            SELECT   Letter_Type__c, ContentDocumentId
            FROM     ContentVersion
            WHERE    Letter_Type__c    != NULL
                 AND IsLatest           = TRUE
                 AND ContentDocumentId IN :existContentDocumentIds

            GROUP BY Letter_Type__c, ContentDocumentId
        ]) {
            if (appealIdToLetterTypeToDocumentLimitMap.get(String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID))))) != null) {
                if (appealIdToLetterTypeToDocumentLimitMap.get(String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID))))).get(String.valueOf(mainDocument.get(FIELD_NAME_LETTER_TYPE))) != null) {
                    appealIdToLetterTypeToDocumentLimitMap.get(String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID))))).put(
                        String.valueOf(mainDocument.get(FIELD_NAME_LETTER_TYPE)),
                        appealIdToLetterTypeToDocumentLimitMap.get(String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID))))).get(String.valueOf(mainDocument.get(FIELD_NAME_LETTER_TYPE))) + 1
                    );
                } else {
                    appealIdToLetterTypeToDocumentLimitMap.get(String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID))))).put(
                        String.valueOf(mainDocument.get(FIELD_NAME_LETTER_TYPE)),
                        1
                    );
                }
            } else {
                appealIdToLetterTypeToDocumentLimitMap.put(
                    String.valueOf(contentDocumentToAppealIdsMap.get(String.valueOf(mainDocument.get(FIELD_NAME_CONTENT_DOCUMENT_ID)))),
                    new Map<String, Integer>{
                        String.valueOf(mainDocument.get(FIELD_NAME_LETTER_TYPE)) => 1
                    }
                );
            }
        }

        for (ContentVersion contentVersion : newContentVersions) {
            Boolean thereIsAnotherFileWithTheSameLetterTypeForTheAppeal = (
                appealIdToLetterTypeToDocumentLimitMap.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)) != null &&
                appealIdToLetterTypeToDocumentLimitMap.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)).get(contentVersion.Letter_Type__c) != null &&
                appealIdToLetterTypeToDocumentLimitMap.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)).get(contentVersion.Letter_Type__c) > 1 &&
                (
                    isInsert
                        ? !existContentDocumentIds.contains(contentVersion.ContentDocumentId)
                        : oldContentVersionsMap.get(contentVersion.Id).Letter_Type__c != contentVersion.Letter_Type__c
                )
            );
            if (thereIsAnotherFileWithTheSameLetterTypeForTheAppeal) {
                isSuccess = false;
                contentVersion.addError(ERROR_MESSAGE_ONLY_TWO_LETTER_TYPE_DOCUMENT);
            }
        }

        return isSuccess;
    }

    private static Set<Id> getExistContentDocumentIds() {
        Set<Id> existContentDocumentIds = new Set<Id>();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId IN :getExistAppealIds()
        ]) {
            existContentDocumentIds.add(cdl.ContentDocumentId);
        }

        return existContentDocumentIds;
    }

    private static Set<Id> getExistAppealIds() {
        Set<Id> existAppealIds = new Set<Id>();

        for (Appeal__c appeal : [SELECT Id FROM Appeal__c WITH SECURITY_ENFORCED LIMIT 50000]) {
            existAppealIds.add(appeal.Id);
        }

        return existAppealIds;
    }

    private static List<Appeal__c> getAppealsForUpdate(Boolean isInsert, List<ContentVersion> newContentVersions, Map<Id, ContentVersion> oldContentVersionsMap) {
        Map<Id,Id> contentDocumentToAppealIdsMap = getContentDocumentToAppealIdsMap(newContentVersions);
        Set<Id>    mainDocumentAppealIds         = new Set<Id>();
        Set<Id>    updatedContentVersionIds      = new Set<Id>();

        mainDocumentAppealIds.addAll(contentDocumentToAppealIdsMap.values());

        Map<Id, Appeal__c>       appealsOfInsertedContentDocumentsMap = new Map<Id, Appeal__c>([
            SELECT Link_To_Main_Document__c
            FROM   Appeal__c
            WHERE  Id IN :mainDocumentAppealIds
            WITH SECURITY_ENFORCED
        ]);

        List<Appeal__c>          updatedAppeals                       = new List<Appeal__c>();
        Map<Id, Map<Id, String>> appealIdToContentVersionIdToHashMap  = new Map<Id, Map<Id, String>>();

        appealIdToContentVersionIdToHashMap.putAll(getExistAppealIdToContentVersionIdToHashMap(contentDocumentToAppealIdsMap.values()));

        for (ContentVersion contentVersion : newContentVersions) {
            Boolean isPdfMainDocument = (contentVersion.Document_Type__c == DOCUMENT_TYPE_MAIN && !contentVersion.Title.endsWithIgnoreCase(FILE_TYPE_PDF));

            if (!isInsert) {
                isPdfMainDocument = isPdfMainDocument && (contentVersion.Document_Type__c == DOCUMENT_TYPE_MAIN && oldContentVersionsMap.get(contentVersion.Id).Document_Type__c != DOCUMENT_TYPE_MAIN);
            }

            if (isPdfMainDocument) {
                if (isInsert) {
                    NullPointerException except = new NullPointerException();
                    except.setMessage(ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT);

                    throw except;
                } else {
                    contentVersion.addError(ERROR_MESSAGE_ONLY_PDF_MAIN_DOCUMENT);
                }
            } else if (contentVersion.Document_Type__c == DOCUMENT_TYPE_MAIN) {
                if (isInsert) {
                    updatedContentVersionIds.add(contentVersion.Id);
                } else {
                    contentVersion.Hash__c = EncodingUtil.base64Encode(Crypto.generateDigest(ALGORITHM_NAME, Blob.valueOf(contentVersion.Title)));
                }

                if (appealIdToContentVersionIdToHashMap.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)) != null) {
                    appealIdToContentVersionIdToHashMap.get(contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId)).put(contentVersion.Id, contentVersion.Hash__c);
                } else {
                    appealIdToContentVersionIdToHashMap.put(
                        contentDocumentToAppealIdsMap.get(contentVersion.ContentDocumentId),
                        new Map<Id, String>{contentVersion.Id => contentVersion.Hash__c}
                    );
                }
            }
        }

        for (Id appealId : appealIdToContentVersionIdToHashMap.keySet()) {
            appealsOfInsertedContentDocumentsMap.get(appealId).Link_To_Main_Document__c = LINK_TO_MAIN_DOCUMENT +
                TOKEN + getToken(appealIdToContentVersionIdToHashMap.get(appealId));
            updatedAppeals.add(appealsOfInsertedContentDocumentsMap.get(appealId));
        }


        if (isInsert && !updatedContentVersionIds.isEmpty()) {
            List<ContentVersion> updatedContentVersions = new List<ContentVersion>();

            for (ContentVersion cv : [SELECT Title, Hash__c FROM ContentVersion WHERE Id IN :updatedContentVersionIds]) {
                cv.Hash__c = EncodingUtil.base64Encode(Crypto.generateDigest(ALGORITHM_NAME, Blob.valueOf(cv.Title)));
                updatedContentVersions.add(cv);
            }

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            update updatedContentVersions;
        }

        return updatedAppeals;
    }

    private static Map<Id, Map<Id, String>> getExistAppealIdToContentVersionIdToHashMap(List<Id> existingAppealIds) {
        Map<Id, Map<Id, String>> existAppealIdToContentVersionIdToHashMap = new Map<Id, Map<Id, String>>();
        Set<Id>                  existedContentDocumentIds                = new Set<Id>();
        Map<Id, Id>              contentDocumentIdToAppealIdMap           = new Map<Id, Id>();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId IN :existingAppealIds
        ]) {
            existedContentDocumentIds.add(cdl.ContentDocumentId);
            contentDocumentIdToAppealIdMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentVersion cv : [
            SELECT ContentDocumentId, Hash__c
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :existedContentDocumentIds
               AND Document_Type__c   = :DOCUMENT_TYPE_MAIN
               AND IsLatest           = TRUE
        ]) {
            if (existAppealIdToContentVersionIdToHashMap.get(contentDocumentIdToAppealIdMap.get(cv.ContentDocumentId)) != null) {
                existAppealIdToContentVersionIdToHashMap.get(contentDocumentIdToAppealIdMap.get(cv.ContentDocumentId)).put(cv.Id, cv.Hash__c);
            } else {
                existAppealIdToContentVersionIdToHashMap.put(
                    contentDocumentIdToAppealIdMap.get(cv.ContentDocumentId),
                    new Map<Id, String>{cv.Id => cv.Hash__c}
                );
            }
        }

        return existAppealIdToContentVersionIdToHashMap;
    }

    public static String getToken(Map<Id, String> contentVersionIdToHashMap) {
        AppealTokenWrapper appealToken            = new AppealTokenWrapper(contentVersionIdToHashMap);
        String             jsonAppealTokenWrapper = JSON.serialize(appealToken);
        Blob               encryptedData          = Crypto.encryptWithManagedIV(
            AppealTokenWrapper.ALGORITHM_NAME,
            EncodingUtil.base64Decode(AppealTokenWrapper.CRYPTO_KEY),
            Blob.valueOf(jsonAppealTokenWrapper)
        );

        return EncodingUtil.base64Encode(encryptedData);
    }
}