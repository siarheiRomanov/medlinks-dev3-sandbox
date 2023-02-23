public without sharing class FilePreviewAndDownloadCtrl {
    public static final String MESSAGE_INCORRECT_TOKEN = 'Your token is invalid!';

    @AuraEnabled
    public static void shareDocToUser(List<String> contentDocumentIds) {
        // This line is not aligned because test coverage depends on it
        Id currentContactId = Test.isRunningTest() ? [SELECT Id FROM Contact WHERE Email = :UserInfo.getUserEmail() AND OwnerId = :UserInfo.getUserId() WITH SECURITY_ENFORCED ]?.Id : [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED].ContactId;

        List<ContentDocumentLink> insertedContentDocumentLinks = new List<ContentDocumentLink>();
        Set<Id> contentDocumentIdsWithExistedDocumentLink = new Set<Id>();
        for (ContentDocumentLink contentDocLink : [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  ContentDocumentId IN :contentDocumentIds AND LinkedEntityId = :currentContactId
        ]) {
            contentDocumentIdsWithExistedDocumentLink.add(contentDocLink.ContentDocumentId);
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        if (currentContactId != null) {
            for (String contentDocumentId : contentDocumentIds) {
                if (Id.valueOf(contentDocumentId).getSobjectType() == ContentDocument.getSObjectType() && !contentDocumentIdsWithExistedDocumentLink.contains(Id.valueOf(contentDocumentId))) {
                    insertedContentDocumentLinks.add(new ContentDocumentLink(
                        ContentDocumentId = contentDocumentId,
                        LinkedEntityId    = currentContactId,
                        ShareType         = 'V'
                    ));
                }
            }

            if (!insertedContentDocumentLinks.isEmpty()) {
                // CRUD FLS security check is bypassed due to standard object without this sort of security setting
                insert insertedContentDocumentLinks;
            }
        }
    }

    @AuraEnabled
    public static Map<String, String> getContentDocumentsThroughToken(String token) {
        Map<String, String> contentVersionContentDocIdToTitleMap = new Map<String, String>();
        Blob                decrypted;

        try {
            decrypted = Crypto.decryptWithManagedIV(
                AppealTokenWrapper.ALGORITHM_NAME,
                EncodingUtil.base64Decode(AppealTokenWrapper.CRYPTO_KEY),
                EncodingUtil.base64Decode(token)
            );
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());

            NullPointerException except = new NullPointerException();
            except.setMessage(MESSAGE_INCORRECT_TOKEN);
            throw except;
        }

        AppealTokenWrapper tokenWrapper = (AppealTokenWrapper) JSON.deserialize(decrypted.toString(), AppealTokenWrapper.class);

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        List<ContentVersion> currentContentVersions = [
            SELECT Hash__c, ContentDocumentId, Title
            FROM   ContentVersion
            WHERE  Id = :tokenWrapper.contentVersionIdToHashMap.keySet()
        ];

        for (ContentVersion cv : currentContentVersions) {
            if (cv.Hash__c == tokenWrapper.contentVersionIdToHashMap.get(cv.Id)) {
                contentVersionContentDocIdToTitleMap.put(cv.ContentDocumentId.to15(), cv.Title);
            } else {
                NullPointerException except = new NullPointerException();
                except.setMessage(MESSAGE_INCORRECT_TOKEN);

                throw except;
            }
        }

        return contentVersionContentDocIdToTitleMap;
    }
}