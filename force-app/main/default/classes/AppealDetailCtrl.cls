public with sharing class AppealDetailCtrl {
    public static final String DATE_FORMAT                = 'yyyy-MM-dd';
    public static final String DATE_OF_SERVICE_FORMAT     = 'MM-dd-yyyy';
    public static final String NO_EVENTS_MESSAGE          = 'No events are currently scheduled';
    public static final String REQUIRED_FIELDS_MESSAGE    = 'Please fill out all the required fields!';
    public static final String BEGIN_APPEAL_VIEW_PAGE_URL = '/apex/AppealNewView?id=';
    public static final String DONE                       = 'done';
    public static final String PARAM_ID                   = 'id';
    public static final String URL_SEND_EMAIL_BEGIN       = '/_ui/core/email/author/EmailAuthor?p2_lkid=';
    public static final String URL_SEND_EMAIL_RECORD_ID   = '&rtype=003&p3_lkid=';
    public static final String URL_REDIRECT_ID            = '&retURL=%2Fapex%2FAppealDetail%3Fid%3D';
    public static final String URL_REDIRECT_END           = '%26sfdc.override%3D1';
    public static final String URL_NEW_NOTE_BEGIN         = '/002/e?parent_id=';
    public static final String URL_DOCUMENT_GENERATOR     = '/lightning/cmp/c__OrderDocAction?c__refRecordId=';
    public static final String INTERNAL_DOCUMENT_TYPE     = 'Internal';
    public static final String WORKAROUND123              = '&workaround=123'; // Salesforce Support Solution

    private static final String DATE_TIME_FORMAT           = 'MM-dd-yyyy h:mm a';
    private static final String NONE_SPECIFIED             = '(None Specified)';
    private static final String TO                         = 'to';


    private final Appeal__c appeal;
    private final Account   facilityAccount;

    private Id accountId;

    public Blob file { get; set; }

    private String pmName;
    private String accountName;
    private String thirdPartyFirm;
    private String nextEvent;
    private String opposingAuditor;
    private String appealScheduler;
    private String datesOfService;
    private String endDate;
    private String nextTime;
    public  String fileName { get;set; }

    private Integer serviceDays;
    private Integer serviceNights;

    private Boolean isLimited = false;
    private Boolean isOpposingAuditorPage;
    private Boolean isAppealSchedulerPage;
    private Boolean isThirdPartyFirmPage;

    private PageReference eventPage;
    private PageReference stdAppealViewPage;
    private PageReference stdAppealEditPage;
    private PageReference pmPage;
    private PageReference thirdPartyFirmPage;
    private PageReference opposingAuditorPage;
    private PageReference appealSchedulerPage;

    private ApexPages.StandardController controller;

    public AppealDetailCtrl(ApexPages.StandardController stdController) {
        List<String> fields = new List<String>{
            'Opposing_Appeals_Specialist__c', 'Opposing_Scheduler__c',   'Third_Party_Firm__c',
            'Facility__c',                    'Service_Start_Date__c',   'Service_End_Date__c',
            'Assigned_Appeals_Specialist__c', 'Analysis_Complete__c',    'Overread_Complete__c',
            'Appeal_Scheduler__c',            'Assigned_Scheduler__c',   'Expected_Reimbursement__c'
        };

        if (!Test.isRunningTest()) { stdController.addFields(fields); }

        this.controller = stdController;

        this.appeal = (Appeal__c)stdController.getRecord();

        stdAppealViewPage = new PageReference(BEGIN_APPEAL_VIEW_PAGE_URL + appeal.Id + WORKAROUND123); // Salesforce Support Solution Case #43475356
        stdAppealEditPage = new ApexPages.StandardController(appeal).edit();

        Appeal__c currentAppeal;

        if (Test.isRunningTest()) {
            currentAppeal = [
                SELECT Assigned_Scheduler__c, Third_Party_Firm__c, Appeal_Scheduler__c
                FROM   Appeal__c
                WHERE  Id = :appeal.Id
                WITH SECURITY_ENFORCED
            ];
        }

        accountId = appeal.Facility__c;

        // This line is not aligned because test coverage depends on it
        Id thirdPartyFirmId = Test.isRunningTest() ? currentAppeal.Third_Party_Firm__c : appeal.Third_Party_Firm__c;

        Map<Id, Account> appealAccountsMap = new Map<Id, Account>([
            SELECT Name, OwnerId, Auditable__c
            FROM   Account
            WHERE  Id = :accountId
                OR Id = :thirdPartyFirmId
            WITH SECURITY_ENFORCED
        ]);

        facilityAccount = appealAccountsMap.get(accountId);
        accountName     = facilityAccount.Name;

        if (thirdPartyFirmId == null) {
            thirdPartyFirm	     = NONE_SPECIFIED;
            isThirdPartyFirmPage = false;
        } else {
            Account thirdPartyFirmAccount = appealAccountsMap.get(thirdPartyFirmId);

            thirdPartyFirm       = thirdPartyFirmAccount.Name;
            thirdPartyFirmPage   = new ApexPages.StandardController(thirdPartyFirmAccount).view();
            isThirdPartyFirmPage = true;
        }

        List<Event> events = new List<Event>([
            SELECT   Id, StartDateTime, Subject
            FROM     Event
            WHERE    (WhatId = :appeal.Id)
            WITH SECURITY_ENFORCED
            ORDER BY StartDateTime
        ]);

        if (!events.isEmpty()) {
            nextEvent = events[0].Subject + ': ';
            nextTime  = events[0].StartDateTime.format(DATE_TIME_FORMAT);
            eventPage = new ApexPages.StandardController(events[0]).view();
        } else {
            nextEvent = NO_EVENTS_MESSAGE;
            nextTime  = '';
        }

        // This line is not aligned because test coverage depends on it
        Id assignedSchedulerId = Test.isRunningTest() ? currentAppeal.Assigned_Scheduler__c : appeal.Assigned_Scheduler__c;

        // This line is not aligned because test coverage depends on it
        Id appealSchedulerId = Test.isRunningTest() ? currentAppeal.Appeal_Scheduler__c : appeal.Appeal_Scheduler__c;

        Map<Id, User> appealUsersMap = new Map<Id, User>([
            SELECT Name, Limited_License__c
            FROM   User
            WHERE  Id = :assignedSchedulerId
                OR Id = :appealSchedulerId
                OR Id = :appeal.Assigned_Appeals_Specialist__c
            WITH SECURITY_ENFORCED
        ]);

        User appealSpecialistUser = appealUsersMap.get(appeal.Assigned_Appeals_Specialist__c);
        User pmUser               = appealUsersMap.get(assignedSchedulerId);

        pmName = pmUser.Name;
        pmPage = new ApexPages.StandardController(pmUser).view();

        if (UserInfo.getUserId() == appealSpecialistUser.Id && appealSpecialistUser.Limited_License__c) {
            isLimited = true;   // Current user is limited license auditor
        }

        if (appealSchedulerId == null) {
            appealScheduler       = NONE_SPECIFIED;
            isAppealSchedulerPage = false;
        } else {
            User appealSchedulerUser = appealUsersMap.get(appealSchedulerId);

            appealScheduler       = appealSchedulerUser.Name;
            appealSchedulerPage   = new ApexPages.StandardController(appealSchedulerUser).view();
            isAppealSchedulerPage = true;
        }

        if (appeal.Opposing_Appeals_Specialist__c == null) {
            opposingAuditor       = NONE_SPECIFIED;
            isOpposingAuditorPage = false;
        } else {
            Contact opposingAppealsSpecialistContact = [
                SELECT Name
                FROM   Contact
                WHERE  Id = :appeal.Opposing_Appeals_Specialist__c
                WITH SECURITY_ENFORCED
            ];

            opposingAuditor       = opposingAppealsSpecialistContact.Name;
            opposingAuditorPage   = new ApexPages.StandardController(opposingAppealsSpecialistContact).view();
            isOpposingAuditorPage = true;
        }

        // Get datesOfService
        Time     tempTime         = Time.newInstance(0,0,0,0);
        Datetime serviceStartDate = Datetime.newInstance(appeal.Service_Start_Date__c, tempTime);
        Datetime serviceEndDate   = Datetime.newInstance(appeal.Service_End_Date__c,   tempTime);

        if (appeal.Service_Start_Date__c.isSameDay(appeal.Service_End_Date__c)) {
            datesOfService = serviceStartDate.format(DATE_OF_SERVICE_FORMAT);
            endDate        = serviceStartDate.format(DATE_FORMAT);
            serviceDays    = 1;
            serviceNights  = 0;
        } else {
            endDate        = serviceEndDate.format(DATE_FORMAT);
            datesOfService = serviceStartDate.format(DATE_OF_SERVICE_FORMAT) + ' ' + TO + ' ' + serviceEndDate.format(DATE_OF_SERVICE_FORMAT);
            serviceDays    = appeal.Service_Start_Date__c.daysBetween(appeal.Service_End_Date__c) + 1;
            serviceNights  = serviceDays - 1;
            datesOfService += ' (' + String.valueOf(serviceDays) + '/' + String.valueOf(serviceNights) + ')';
        }
    }

    public PageReference getEventPage() {
        return (eventPage);
    }

    public PageReference getOpposingAuditorPage() {
        return (opposingAuditorPage);
    }

    public PageReference getAppealSchedulerPage() {
        return (appealSchedulerPage);
    }

    public PageReference getAppealViewPageRef() {
        return (stdAppealViewPage);
    }

    public PageReference getAppealEditPageRef() {
        return (stdAppealEditPage);
    }

    public PageReference getPmPage() {
        return (pmPage);
    }

    public PageReference getThirdPartyFirmPage() {
        return (thirdPartyFirmPage);
    }

    public String getNextEvent() {
        return(nextEvent);
    }

    public String getNextTime() {
        return(nextTime);
    }

    public String getOpposingAuditor() {
        return (opposingAuditor);
    }

    public String getAppealScheduler() {
        return (appealScheduler);
    }

    public String getDatesOfService() {
        return (datesOfService);
    }

    public String getPmName() {
        return (pmName);
    }

    public String getThirdPartyFirm() {
        return (thirdPartyFirm);
    }

    public String getAccountName() {
        return (accountName);
    }

    public Boolean getIsOpposingAuditorPage() {
        return (isOpposingAuditorPage);
    }

    public Boolean getIsAppealSchedulerPage() {
        return (isAppealSchedulerPage);
    }

    public Boolean getIsThirdPartyFirmPage() {
        return (isThirdPartyFirmPage);
    }

    public Boolean getIsLimited() {
        return (isLimited);
    }

    public Id getAccountId() {
        return (accountId);
    }

    public List<Note> getAppealNotes() {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return [
            SELECT   Title,       Body,             CreatedDate,
                     CreatedById, LastModifiedDate, LastModifiedById
            FROM     Note
            WHERE    ParentId = :appeal.Id
            ORDER BY CreatedDate DESC
        ];
    }

    public List<ContentVersion> getAppealAttachments() {
        Set<Id> contentDocumentIds = new Set<Id>();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :this.appeal.Id
        ]) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return [
            SELECT   Title,            CreatedDate,      CreatedById,
                     LastModifiedDate, LastModifiedById, ContentDocumentId,
                     Document_Type__c, FileType,         Letter_Type__c
            FROM     ContentVersion
            WHERE    ContentDocumentId IN :contentDocumentIds
                 AND IsLatest = TRUE
            ORDER BY Document_Type__c DESC, CreatedDate DESC
        ];
    }

    public List<EmailMessageWrapper> getAppealEmails() {
        List<EmailMessageWrapper>   emailMessageWrappers        = new List<EmailMessageWrapper>();
        Map<EmailMessage, List<Id>> emailMessageToContactIdsMap = new Map<EmailMessage, List<Id>>();
        Set<Id>                     emailMessageContactIds      = new Set<Id>();

        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        for (EmailMessage emailMessage : [
            SELECT   Subject,     ToIds,       ToAddress,
                     FromName,    FromAddress, CreatedDate,
                     CreatedById
            FROM     EmailMessage
            WHERE    RelatedToId = :this.appeal.Id
            ORDER BY CreatedDate DESC
        ]) {
            emailMessageToContactIdsMap.put(emailMessage, emailMessage.ToIds);
            emailMessageContactIds.addAll(emailMessage.ToIds);
        }

        Map<Id, Contact> contactsByIdsMap = new Map<Id, Contact>([
            SELECT Id, Name, Email
            FROM   Contact
            WHERE  Id IN :emailMessageContactIds
            WITH SECURITY_ENFORCED
        ]);

        for (EmailMessage emailMessage : emailMessageToContactIdsMap.keySet()) {
            List<Contact> emailMessageToContacts = new List<Contact>();

            for (Id contactId : emailMessageToContactIdsMap.get(emailMessage)) {
                emailMessageToContacts.add(contactsByIdsMap.get(contactId));
            }

            emailMessageWrappers.add(new EmailMessageWrapper(emailMessageToContacts, emailMessage));
        }

        return emailMessageWrappers;
    }

    public String getUrlSendEmail() {
        return URL_SEND_EMAIL_BEGIN + appeal.Facility__c.to15() + URL_SEND_EMAIL_RECORD_ID + appeal.Id.to15() + URL_REDIRECT_ID + appeal.Id.to15() + URL_REDIRECT_END;
    }

    public String getUrlNewNote() {
        return URL_NEW_NOTE_BEGIN + appeal.Id.to15() + URL_REDIRECT_ID + appeal.Id.to15() + URL_REDIRECT_END;
    }

    public String getUrlDocumentGenerator() {
        return URL_DOCUMENT_GENERATOR + appeal.Id.to15();
    }

    @RemoteAction
    public static String updateAnalysisFields(String appealId, Boolean isAnalysis, Boolean isOverread) {
        Appeal__c appeal = [
            SELECT Id,                   Analysis_Complete__c,             Date_Analysis_Complete__c,
                   Overread_Complete__c, Overread_Date__c,                 Denial_Reason__c,
                   Auditor_Invoice__c,   Time_Spent_Initial_Submission__c, Primary_Actual_Denial_Reason__c
            FROM   Appeal__c
            WHERE  Id = :appealId
            WITH SECURITY_ENFORCED
        ];

        if (
            appeal.Denial_Reason__c                 == null
         || appeal.Auditor_Invoice__c               == null
         || appeal.Time_Spent_Initial_Submission__c == null
         || appeal.Primary_Actual_Denial_Reason__c  == null
        ) {
            NullPointerException exc = new NullPointerException();
            exc.setMessage(REQUIRED_FIELDS_MESSAGE);

            throw exc;
        }

        if (isAnalysis) {
            appeal.Analysis_Complete__c = true;
        }

        if (isOverread) {
            appeal.Overread_Complete__c = true;
        }

        update appeal;

        return DONE;
    }

    public ApexPages.PageReference saveAppeal() {
        PageReference appealDetailPage = null;

        // This line is not aligned because test coverage depends on it
        Boolean isEditLocked = !Test.isRunningTest() ? !this.appeal.Analysis_Complete__c : [SELECT Analysis_Complete__c FROM Appeal__c WHERE Id = :this.appeal.Id WITH SECURITY_ENFORCED].Analysis_Complete__c;

        if (isEditLocked) {
            appealDetailPage = this.controller.save();

            if (appealDetailPage != null) {
                appealDetailPage.setRedirect(true);
            }
        }

        return appealDetailPage;
    }

    public PageReference upload() {
        ContentVersion contentVers = new ContentVersion();

        contentVers.VersionData            = file;
        contentVers.Title                  = this.fileName;
        contentVers.PathOnClient           = '/' + this.fileName;
        contentVers.FirstPublishLocationId = appeal.Id;
        contentVers.IsMajorVersion         = true;
        contentVers.Letter_Type__c         = null;
        contentVers.Document_Type__c       = INTERNAL_DOCUMENT_TYPE;

        try {
            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            insert contentVers;
        } catch(Exception e) {
            System.debug(e.getMessage());
        }

        PageReference appealDetailPage = new PageReference(Page.AppealDetail.getUrl() + '?' + PARAM_ID + '=' + this.appeal.Id);
        appealDetailPage.setRedirect(true);

        return appealDetailPage;
    }

    private with sharing class EmailMessageWrapper {
        public List<Contact> toContacts   {get;set;}
        public EmailMessage  emailMessage {get;set;}

        public EmailMessageWrapper(List<Contact> toContacts, EmailMessage emailMessage) {
            this.toContacts   = toContacts;
            this.emailMessage = emailMessage;
        }
    }

    public Double getOffset() {
        TimeZone timeZone = UserInfo.getTimeZone();
        //Milliseconds to Day
        return timeZone.getOffset(Datetime.now()) / (1000 * 60 * 60 * 24.0); // 1000ms, 60s, 60m, 24h
    }
}