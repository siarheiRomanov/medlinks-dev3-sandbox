@IsTest
public with sharing class TestDataFactory {
    public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR          = 'System Administrator';
    public static final String PERMISSION_SET_APPEAL_PROJECT_MANAGER_USER = 'Appeal_Project_Manager_User';
    public static final String PROFILE_CUSTOMER_COMMUNITY_USER            = 'Customer Community User';
    public static final String FILE_TYPE_DOCX                             = 'DOCX';
    public static final String TEST_NAME                                  = 'test';
    public static final String TEST_EMAIL_END_NAME                        = '@test-appeal-test.com';
    public static final String LANGUAGE_LOCALE_KEY_EN_US                  = 'en_US';
    public static final String EMAIL_ENCODING_KEY_UTF_8                   = 'UTF-8';
    public static final String LOCALE_SID_KEY_US_LA                       = 'America/Los_Angeles';
    public static final String ACCOUNT_TYPE_TEST_VALUE                    = 'Hospital';
    public static final String APPEAL_STAGE_TEST_VALUE                    = Appeal__c.Appeal_Stage__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String APPEAL_TYPE_TEST_VALUE                     = Appeal__c.Appeal_Type__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String DENIAL_REASON_TEST_VALUE                   = Appeal__c.Denial_Reason__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String ACTUAL_DENIAL_REASON_TEST_VALUE            = Appeal__c.Primary_Actual_Denial_Reason__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String ROOT_CAUSE_TEST_VALUE                      = Appeal__c.Primary_Root_Cause__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String PAYER_TYPE_TEST_VALUE                      = Appeal__c.Payer_Type__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String LETTER_TYPE_TEST_VALUE                     = ContentVersion.Letter_Type__c.getDescribe().getPicklistValues()[0].getValue();
    public static final String LETTER_TYPE_TEST_VALUE2                    = ContentVersion.Letter_Type__c.getDescribe().getPicklistValues()[1].getValue();
    public static final String APPEAL_FIELDSET_TEST_VALUE                 = Schema.SObjectType.Appeal__c.fieldSets.getMap().values()[0].name;
    public static final String CONTENT_DISPOSITION                        = 'Content-Disposition';
    public static final String APPEAL_CASE_REPORT_URL                     = '/apex/appealcasereport?id=';
    public static final String FILE_TYPE_UNKNOWN                          = 'UNKNOWN';

    public static User createUser(Id profileId, String firstName, String lastName, String alias, String email,
        String userName, String communityNickname, String languageLocaleKey, String emailEncodingKey,
        String timeZoneSidKey, String localeSidKey, Boolean isLimitedLicense
    ) {
        User user = new User(
            FirstName          = firstName,
            LastName           = lastName,
            Alias              = alias,
            Email              = email,
            Username           = userName,
            CommunityNickname  = communityNickname,
            ProfileId          = profileId,
            LanguageLocaleKey  = languageLocaleKey,
            EmailEncodingKey   = emailEncodingKey,
            TimeZoneSidKey     = timeZoneSidKey,
            LocaleSidKey       = localeSidKey,
            Limited_License__c = isLimitedLicense
        );

        insert user;

        return user;
    }

    public static Id getSystemAdministratorProfileId() {
        return [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_SYSTEM_ADMINISTRATOR LIMIT 1].Id;
    }

    public static Account createAccount(String name, String type, String shortname, String facilityCity,
        String facilityState, String facilityStreet, String facilityZip, Boolean auditClient
    ) {
        Account account = new Account(
            Name               = name,
            Type               = type,
            Shortname__c       = shortname,
            Facility_City__c   = facilityCity,
            Facility_State__c  = facilityState,
            Facility_Street__c = facilityStreet,
            Facility_Zip__c    = facilityZip,
            Audit_Client__c    = auditClient
        );

        insert account;

        return account;
    }

    public static Contact createContact(String lastName, String email) {
        Contact contact = new Contact(LastName = lastName, Email = email);

        insert contact;

        return contact;
    }

    public static Contact createContact(String lastName, String email, String accountId) {
        Contact contact = new Contact(LastName = lastName, Email = email, AccountId = accountId);

        insert contact;

        return contact;
    }

    public static Appeal__c createAppeal(
        String  appealStage,                String  appealType,                  Id      payerId,                  String   payerType,
        String  clientAccountId,            Id      facilityId,                  Id      facilityContactPrimaryId, String   patientFirstName,
        String  patientLastName,            Date    patientDOB,                  String  patientAccount,           Date     serviceStartDate,
        Date    serviceEndDate,             Id      assignedAppealsSpecialistId, Id      assignedSchedulerId,      String   denialReason,
        Decimal timeSpentInitialSubmission, Decimal auditorAppealRate,           Id      overreadById,             Datetime overreadDate,
        String  primaryActualDenialReason,  String  primaryRootCause,            String  auditorInvoice,           Id       opposingAppealSpecialistId,
        Id      thirdPartyFirmId,           Id      appealSchedulerId,           Boolean isAnalysisComplete
    ) {
        Appeal__c appeal = new Appeal__c(
            Appeal_Stage__c                  = appealStage,
            Appeal_Type__c                   = appealType,
            Payer__c                         = payerId,
            Payer_Type__c                    = payerType,
            Client_Account__c                = clientAccountId,
            Facility__c                      = facilityId,
            Facility_Contact_Primary__c      = facilityContactPrimaryId,
            Patient_First_Name__c            = patientFirstName,
            Patient_Last_Name__c             = patientLastName,
            Patient_DOB__c                   = patientDOB,
            Patient_Account__c               = patientAccount,
            Service_Start_Date__c            = serviceStartDate,
            Service_End_Date__c              = serviceEndDate,
            Assigned_Appeals_Specialist__c   = assignedAppealsSpecialistId,
            Assigned_Scheduler__c            = assignedSchedulerId,
            Denial_Reason__c                 = denialReason,
            Time_Spent_Initial_Submission__c = timeSpentInitialSubmission,
            Auditor_Appeal_Rate__c           = auditorAppealRate,
            Overread_By__c                   = overreadById,
            Overread_Date__c                 = overreadDate,
            Primary_Actual_Denial_Reason__c  = primaryActualDenialReason,
            Primary_Root_Cause__c            = primaryRootCause,
            Auditor_Invoice__c               = auditorInvoice,
            Opposing_Appeals_Specialist__c   = opposingAppealSpecialistId,
            Third_Party_Firm__c              = thirdPartyFirmId,
            Appeal_Scheduler__c              = appealSchedulerId,
            Analysis_Complete__c             = isAnalysisComplete
        );

        insert appeal;

        return appeal;
    }

    public static Appeal__c createAppeal(
        String   appealStage,                String  appealType,                  Id      payerId,                     String   payerType,
        String   clientAccountId,            Id      facilityId,                  Id      facilityContactPrimaryId,    String   patientFirstName,
        String   patientLastName,            Date    patientDOB,                  String  patientAccount,              Date     serviceStartDate,
        Date     serviceEndDate,             Id      assignedAppealsSpecialistId, Id      assignedSchedulerId,         String   denialReason,
        Decimal  timeSpentInitialSubmission, Decimal auditorAppealRate,           Id      overreadById,                Datetime overreadDate,
        String   primaryActualDenialReason,  String  primaryRootCause,            String  auditorInvoice,              Id       opposingAppealSpecialistId,
        Id       opposingSchedulerId,        Id      thirdPartyFirmId,            Id      appealSchedulerId,           Boolean  isAnalysisComplete
    ) {
        Appeal__c appeal = new Appeal__c(
                Appeal_Stage__c                  = appealStage,
                Appeal_Type__c                   = appealType,
                Payer__c                         = payerId,
                Payer_Type__c                    = payerType,
                Client_Account__c                = clientAccountId,
                Facility__c                      = facilityId,
                Facility_Contact_Primary__c      = facilityContactPrimaryId,
                Patient_First_Name__c            = patientFirstName,
                Patient_Last_Name__c             = patientLastName,
                Patient_DOB__c                   = patientDOB,
                Patient_Account__c               = patientAccount,
                Service_Start_Date__c            = serviceStartDate,
                Service_End_Date__c              = serviceEndDate,
                Assigned_Appeals_Specialist__c   = assignedAppealsSpecialistId,
                Assigned_Scheduler__c            = assignedSchedulerId,
                Denial_Reason__c                 = denialReason,
                Time_Spent_Initial_Submission__c = timeSpentInitialSubmission,
                Auditor_Appeal_Rate__c           = auditorAppealRate,
                Overread_By__c                   = overreadById,
                Overread_Date__c                 = overreadDate,
                Primary_Actual_Denial_Reason__c  = primaryActualDenialReason,
                Primary_Root_Cause__c            = primaryRootCause,
                Auditor_Invoice__c               = auditorInvoice,
                Opposing_Appeals_Specialist__c   = opposingAppealSpecialistId,
                Opposing_Scheduler__c            = opposingSchedulerId,
                Third_Party_Firm__c              = thirdPartyFirmId,
                Appeal_Scheduler__c              = appealSchedulerId,
                Analysis_Complete__c             = isAnalysisComplete
        );

        insert appeal;

        return appeal;
    }

    public static Note createNote(String title, String Body, Id parentId) {
        Note note = new Note(
            Title    = title,
            Body     = Body,
            ParentId = parentId
        );

        insert note;

        return note;
    }

    public static Appeal__c createTestAppealData(Date todayDate) {
        Datetime todayDatetime = Datetime.now();

        Id userId = createUser(
            getSystemAdministratorProfileId(),
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME + TEST_EMAIL_END_NAME,
            TEST_NAME + TEST_EMAIL_END_NAME,
            TEST_NAME,
            LANGUAGE_LOCALE_KEY_EN_US,
            EMAIL_ENCODING_KEY_UTF_8,
            LOCALE_SID_KEY_US_LA,
            LANGUAGE_LOCALE_KEY_EN_US,
            false
        ).Id;
        Id accountId = createAccount(
            TEST_NAME,
            ACCOUNT_TYPE_TEST_VALUE,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            false
        ).Id;
        Id clientAccountId = createAccount(
            TEST_NAME,
            ACCOUNT_TYPE_TEST_VALUE,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            TEST_NAME,
            true
        ).Id;
        Id contactId = createContact(TEST_NAME, TEST_NAME + TEST_EMAIL_END_NAME).Id;

        return createAppeal(
            APPEAL_STAGE_TEST_VALUE,
            APPEAL_TYPE_TEST_VALUE,
            accountId,
            PAYER_TYPE_TEST_VALUE,
            clientAccountId,
            accountId,
            contactId,
            TEST_NAME,
            TEST_NAME,
            todayDate.addYears(-5),
            TEST_NAME + '123',
            todayDate,
            todayDate.addDays(1),
            userId,
            userId,
            DENIAL_REASON_TEST_VALUE,
            1,
            12,
            contactId,
            todayDatetime,
            ACTUAL_DENIAL_REASON_TEST_VALUE,
            ROOT_CAUSE_TEST_VALUE,
            TEST_NAME,
            null,
            null,
            null,
            false
        );
    }

    public static ContentVersion createContentVersion(Blob versionData, String title, String pathOnClient,
        Id firstPublishLocationId, Boolean isMajorVersion, String letterType, String documentType
    ) {
        ContentVersion contentVers = new ContentVersion(
            VersionData            = versionData,
            Title                  = title,
            PathOnClient           = pathOnClient,
            FirstPublishLocationId = firstPublishLocationId,
            IsMajorVersion         = isMajorVersion,
            Letter_Type__c         = letterType,
            Document_Type__c       = documentType
        );

        insert contentVers;

        return contentVers;
    }

    public static User createCommunityUser(String contactId, String profId, String firstName, String lastName, String accountId) {
        User tempUser = prepareUser('', profId, firstName, lastName);
        tempUser.ContactId = contactId;

        insert tempUser;

        return tempUser;
    }

    private static User prepareUser(String roleId, String profId, String firstName, String lastName) {
        String  orgId      = UserInfo.getOrganizationId();
        String  dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt  = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String  uniqueName = orgId + dateString + randomInt;
        User    tempUser   = new User(
            FirstName         = firstName,
            LastName          = lastName,
            Email             = uniqueName + '@sfdc' + orgId + '.org',
            Username          = uniqueName + '@sfdc' + orgId + '.org',
            EmailEncodingKey  = 'ISO-8859-1',
            Alias             = uniqueName.substring(18, 23),
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId         = profId
        );

        if (String.isBlank(roleId) == false) {
            tempUser.UserRoleId = roleId;
        }

        return tempUser;
    }
}