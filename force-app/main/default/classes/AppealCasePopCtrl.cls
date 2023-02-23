public with sharing class AppealCasePopCtrl {
    public static String CONTENT_DISPOSITION = 'Content-Disposition';
    public static String ATTACHMENT          = 'attachment';
    public static String FILE_NAME           = 'filename';
    public static String PDF                 = 'pdf';
    public static String PARAM_ID            = 'id';

    private final Appeal__c appeal;
    private final Account   account;

    public AppealCasePopCtrl(ApexPages.StandardController stdController) {
        List<String> fields = new List<String> {
            'Notes',                             'Notes.Title',                         'Notes.CreatedDate',
            'Notes.CreatedBy',                   'Notes.CreatedBy.Name',                'Notes.Body',
            'Notes.LastModifiedDate',            'Notes.LastModifiedBy',                'Notes.LastModifiedBy.Name',
            'Total_Billed__c',                   'Facility__r.Facility_City__c',        'Facility__r.Facility_State__c',
            'Facility__r.Facility_Zip__c',       'Facility__r.Facility_Street__c',      'Facility_Contact_Primary__r',
            'Facility_Contact_Primary__r.Name',  'Appeal_Stage__c',                     'Payer__r.Name',
            'Denied__c',                         'Recovered__c',                        'Name',
            'Appeal_Type__c',                    'Denied_Date__c',                      'Denial_Upheld_Date__c',
            'Payer_Type__c',                     'Subscriber_ID__c',                    'Appeal_Due_Date__c',
            'Denial_Reason__c',                  'Primary_Root_Cause__c',               'Denial_Overturned_Date__c',
            'Claim_ID__c',                       'Patient_First_Name__c',               'Patient_Last_Name__c',
            'Patient_Account__c',                'Patient_DOB__c',                      'Patient_MR__c',
            'Client_Account__r.Name',            'Assigned_Appeals_Specialist__r.Name', 'Overread_By__r.Name',
            'Primary_Actual_Denial_Reason__c',   'Opposing_Appeals_Specialist__r.Name', 'Facility__r.Name',
            'Service_Start_Date__c',             'Service_End_Date__c',                 'Expected_Reimbursement__c',
            'Third_Party_Firm__r',               'Third_Party_Firm__r.Name',            'Total_Recovered_Rate__c',
            'Secondary_Actual_Denial_Reason__c', 'Secondary_Root_Cause__c'
        };

        if (!Test.isRunningTest()) { stdController.addFields(fields); }

        this.appeal = (Appeal__c)stdController.getRecord();

        Id accountId = appeal.Facility__c;

        account = [
            SELECT Id,                        Name,                      Shortname__c,
                   Prefs_Include_Disputed__c, Prefs_Include_Unbilled__c, Facility_Street__c,
                   Facility_City__c,          Facility_State__c,         Facility_Zip__c,
                   BillingStreet,             BillingCity,               BillingState,
                   BillingPostalCode
            FROM   Account
            WHERE  Id = :accountId
            WITH SECURITY_ENFORCED
        ];
    }

    public PageReference SaveReportPage() {
        PageReference pageReference = Page.AppealCaseReport;
        pageReference.getParameters().put(PARAM_ID, appeal.Id);

        String  fileName         = account.Shortname__c + '_' + appeal.Name + '_' + appeal.Patient_First_Name__c + ', ' +  appeal.Patient_Last_Name__c + '_';
        Integer blankIndexOfName = fileName.indexOf(' ');

        if (blankIndexOfName != -1) {
            fileName = fileName.substring(0, blankIndexOfName) + fileName.substring(blankIndexOfName + 1); // Get rid of blank in name
        }

        String patientAccount = appeal.Patient_Account__c;

        fileName += patientAccount.substring(patientAccount.length() - 3);

        pageReference.getHeaders().put(CONTENT_DISPOSITION + ':', ATTACHMENT + '; ' + FILE_NAME + '=\"' +
            String.escapeSingleQuotes(fileName.replace('\n', '').replace('\r', '')) + '.' + PDF + '\";');
        pageReference.setRedirect(false);

        return pageReference;
    }

    public PageReference DisplayReportPage() {
        PageReference pageReference = Page.AppealCaseReport;

        pageReference.getParameters().put(PARAM_ID, appeal.Id);
        pageReference.setRedirect(false);

        return pageReference;
    }

    public List<Note> getAppealNotes() {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return [
            SELECT   Title,          Body,             CreatedDate,
                     CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name
            FROM     Note
            WHERE    ParentId = :appeal.Id
            ORDER BY CreatedDate DESC
        ];
    }

    public Double getOffset() {
        TimeZone timeZone = UserInfo.getTimeZone();
        //Milliseconds to Day
        return timeZone.getOffset(Datetime.now()) / (1000 * 60 * 60 * 24.0); // 1000ms, 60s, 60m, 24h
    }
}