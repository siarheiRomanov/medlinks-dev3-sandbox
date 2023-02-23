public with sharing class EmailNotificationHandler {
    public static void sendEmailByIds(List<Id> recipientUserIds, List<Id> recipientContactIds, Id appealId, String ContactEmailTemplateName, String UserEmailTemplateName) {
        List<EmailTemplate> emailTemplates = [
            SELECT   Id
            FROM     EmailTemplate
            WHERE    Name = :ContactEmailTemplateName
               OR    Name = :UserEmailTemplateName
            ORDER BY Name ASC
            LIMIT 2
        ];

        if (recipientContactIds != null) {
            sendEmailByIds(recipientContactIds, emailTemplates[0].Id, appealId);
        }

        if (recipientUserIds != null) {
            sendEmailByIds(recipientUserIds, emailTemplates[(emailTemplates.size() - 1)].Id, appealId);
        }
    }

    private static void sendEmailByIds(List<Id> recipientIds, Id emailTemplateId, Id appealId) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Id recipientId : recipientIds) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (isUserById(recipientId)) {
                mail.saveAsActivity = false;
            }

            mail.setTargetObjectId(recipientId);
            mail.setTemplateId(emailTemplateId);
            mail.setWhatId(appealId);

            mails.add(mail);
        }

        Messaging.sendEmail(mails);
    }

    private static Boolean isUserById(Id recordId) {
        return (String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(User.getSObjectType().getDescribe().name));
    }
}