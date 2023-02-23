public with sharing class ContentDownloadHandler implements Sfc.ContentDownloadHandlerFactory {

    public Sfc.ContentDownloadHandler getContentDownloadHandler(List<Id> ids, Sfc.ContentDownloadContext context) {
//        System.debug('ContentDownloadHandler!!!');
//        System.debug('contentdocs: ' + [SELECT Id, Title FROM ContentDocument WHERE Id IN :ids]);
//        System.debug('contentvers: ' + [SELECT Id, Title, FirstPublishLocationId FROM ContentVersion WHERE Id IN :ids]);
//        Set<Id> cdIds = new Set<Id>();
//
//        for (ContentVersion cv : [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :ids]) {
//            cdIds.add(cv.ContentDocumentId);
//        }
//
//        System.debug('ContentDocumentLink: ' + [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds]);
//
//        Set<Id> appealIds = new Set<Id>();
//
//        for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds]) {
//            if ((String.valueOf(cdl.LinkedEntityId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
//                appealIds.add(cdl.LinkedEntityId);
//            }
//        }
//
//        Appeal__c appeal = [SELECT Assigned_Appeals_Specialist__c FROM Appeal__c WHERE Id IN :appealIds LIMIT 1];
//
//
//
//        System.debug('ContentVersionHistory from cv: ' + [SELECT Id, Field FROM ContentVersionHistory WHERE ContentVersionId IN :ids]);
//        System.debug('ContentVersionHistory from cd: ' + [SELECT Id, Field FROM ContentVersionHistory WHERE ContentVersion.ContentDocumentId IN :ids]);
//
//        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
//
//
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//
//
//        mail.saveAsActivity = false;
//
//
//        Id emailTemplateId = [
//            SELECT   Id
//            FROM     EmailTemplate
//            WHERE    Name = :ContentVersionTriggerHandler.NEW_FILE_EMAIL_TEMPLATE_FOR_USER
//            ORDER BY Name ASC
//            LIMIT 1
//        ].Id;
//
//        mail.setTargetObjectId(appeal.Assigned_Appeals_Specialist__c);
//        mail.setTemplateId(emailTemplateId);
//        mail.setWhatId(appeal.Id);
//
//        mails.add(mail);
//
//
////        Messaging.sendEmail(mails);
//
        Sfc.ContentDownloadHandler contentDownloadHandler = new Sfc.ContentDownloadHandler();
//
////        if (context == Sfc.ContentDownloadContext.MOBILE) {
////            contentDownloadHandler.isDownloadAllowed = false;
////            contentDownloadHandler.downloadErrorMessage = 'Downloading a file from a mobile device isn\'t allowed.';
////
////            return contentDownloadHandler;
////        }
        contentDownloadHandler.isDownloadAllowed = true;
////        contentDownloadHandler.isDownloadAllowed = false;
////        contentDownloadHandler.downloadErrorMessage = 'This file needs to be IRM controlled. You\'re not allowed to download it';
////        contentDownloadHandler.redirectUrl ='/apex/AppealNewView?id=' + appeal.Id;
        return contentDownloadHandler;
    }

}