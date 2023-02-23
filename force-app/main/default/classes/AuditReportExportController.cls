/**
* Controls authentification to Google drive and starts batch
*/
public class AuditReportExportController {

    private static final AuditReportSettings__c AUDIT_REPORT_SETTINGS = AuditReportSettings__c.getOrgDefaults();
    private static final String NO_FILTER = 'no_filter';
    private static final String[] AUDIT_FIELDS = new String[] {'Id', 'NAME', 'Audit_Stage__c',
            'Patient_Account__c', 'Account__r.Name', 'Audit_Type__c', 'Audit_Amount__c', 'Patient_Name__c',
            'Patient_MR__c', 'Account__r.Shortname__c', 'IsUploaded__c'/*,
                                          'AUDIT_TYPE__C', 'BILL_ANALYSIS_COMPLETE__C', 'BILL_UPLOADED__C', 'CLIENT_AUDIT_ACCOUNT__C', 'DATE_ACTUAL_EXIT__C',
                                          'DATE_AUDIT_COMPLETED__C', 'DATE_BILL_RECEIVED__C', 'DATE_BILL_REQUESTED__C', 'DATE_CHART_PULL_REQUESTED__C', 'DATE_LOI__C',
                                          'DATE_PROPOSED_EXIT__C', 'EVENTGUID__C', 'EXIT_DURATION__C', 'EXIT_MODE__C', 'FACILITY_BILLING_CONTACT__C', 'FACILITY_IS_CLIENT__C',
                                          'FACILITY_MR_CONTACT__C', 'OPPOSING_AUDIT_ACCOUNT__C', 'OPPOSING_AUDITOR__C', 'OPPOSING_SCHEDULER__C', 'PATIENT_ACCOUNT__C', 'PATIENT_DOB__C',
                                          'PATIENT_DOBEDIT__C', 'PATIENT_FIRST_NAME__C', 'PATIENT_LAST_NAME__C', 'PATIENT_MR__C', 'PATIENT_NAME__C', 'PAYER_TYPE__C', 'PAYER__C',
                                          'SERVICE_END_DATE__C', 'SERVICE_START_DATE__C', 'SKIPEVENTUPDATE__C', 'TAMT_ADJ__C', 'TAMT_REVISED__C', 'TAMT_SUMOVER__C', 'TAMT_SUMUNDER__C',
                                          'TOTAL_SERVICE_DAYS__C',
                                          'XFLAG__C', 'XN1__C', 'XN2__C', 'XN3__C', 'XN4__C', 'XPA__C', 'XPD__C', 'XPM__C', 'XPN__C',
                                          'FLAGGED_ITEMS__C', 'TAMT_BILLED__C', 'TAMT_DISALLOWED__C', 'TAMT_DISPUTED__C', 'TAMT_OTHER__C', 'TAMT_OVER__C', 'TAMT_UNBILL__C', 'TAMT_UNDER__C', 'TAMT_NOMD__C', 'TOT_ITEMS__C', 'AUDIT_CONTRACTOR_EXPENSE__C', 'AUDIT_GROSS_REVENUE__C', 'AUDIT_NET_REVENUE__C', 'PATIENT_AUTH_DATE__C', 'PERCENT_DISALLOWED__C', 'PERCENT_DISPUTED__C', 'PERCENT_NET_ADJ__C', 'PERCENT_OVER__C', 'PERCENT_UNDER__C', 'PRE_AUDIT_DIS__C', 'TOTAL_DISP_ADJ__C', 'DATE_AUDIT_RESULTS_DELIVERED__C', 'DATE_BILL_ANALYSIS_COMPLETE__C', 'DATE_CHART_PULL_CONFIRMED__C', 'CURRENTUSERROLES__C', 'BILL_ATTACHED_AS_IMAGE__C', 'DATE_AUDIT_CANCELED__C', 'NEED_OPPOSING__C', 'OPPOSING_AUDIT_CASE_ID__C', 'INVOICE_NUMBER__C', 'EXIT_PAST_DUE_DAYS__C', 'PERCENT_TOT_ERR__C', 'APPROVED__C', 'NOT_APPROVED__C', 'DATE_LOI_SENT__C', 'DRG_VALIDATION_OK__C', 'DRG_VALIDATION_ALTERED__C', 'COMMENTS__C', 'AUDIT_POLICY_SENT_DATE__C'
                                        */
                                                              };

    private String code;

    @TestVisible private GoogleDriveAuthResult authResult;

    /**
    * Status of the buthc runnig process
    */
    public String status {get; set;}

    /**
    * Flags that authentificated to Google drive
    */
    public boolean isAuthenticated {get; set;}
    /**
    *
    */
    public boolean isPurgeAutomatically {get; set;}
    /**
    * Google authentification result
    */
    @TestVisible private class GoogleDriveAuthResult {
        @TestVisible public String access_token {get; set;}
        @TestVisible public String token_type {get; set;}
        @TestVisible public String expires_in {get; set;}
    }

    /**
    * Get url of the current page
    */
    private String getCurrentUrl() {
        return 'https://' + ApexPages.currentPage().getHeaders().get('Host') + Page.AuditReportExport.getUrl();
    }

    private void initParamsFromUri() {
        String urlParam = ApexPages.currentPage().getParameters().get('state');
        if (String.isNotBlank(urlParam)) {
            filterId = EncodingUtil.urlDecode(ApexPages.currentPage().getParameters().get('state'), 'UTF-8');
            //filterId = params[0];
            //system.debug('###params### ' + params);
            //isPurgeAutomatically =  params[1].equalsIgnoreCase('true');
        }
    }

    /**
    * Id of filter
    */
    public String filterId {get; set;}

    /**
    * Controller
    */
    public AuditReportExportController() {
        status = '';
        code = ApexPages.currentPage().getParameters().get('code') ;
        this.initParamsFromUri();
        if (code != '' && code != null) {
            getAccessToken();
        }
    }

    /**
    * Send goolge drive oauth request
    */
    public PageReference authenticatGoogleDrive() {
        PageReference googleAuthRequest = new PageReference(createGoogleDriveAuthUrl(AUDIT_REPORT_SETTINGS.GoogleDriveKey__c, getCurrentUrl())) ;
        return googleAuthRequest;
    }

    /**
    * Forms drive auth url
    */
    public String createGoogleDriveAuthUrl(String Clientkey, String redirectUrl) {
        AuditReportSettings__c mc = AuditReportSettings__c.getValues('Default');
        String key = EncodingUtil.urlEncode(Clientkey, 'UTF-8');
        String uri = EncodingUtil.urlEncode(redirectUrl, 'UTF-8');
        String authuri = '';
        authuri = String.format(Label.GoogleAuthUri, new String[] {key, uri, ApexPages.currentPage().getParameters().get('state')});
        /*'https://accounts.google.com/o/oauth2/auth?' +
        'client_id=' + key +
        '&response_type=code' +
        '&scope=https://www.googleapis.com/auth/drive' +
        '&redirect_uri=' + uri +
        '&state=' + ApexPages.currentPage().getParameters().get('state') +
        '&access_type=offline';*/
        return authuri;
    }

    /**
    * Runs audit report pdf export batch
    */
    public PageReference runBatch() {
        if (authResult != null && (isAuthenticated != null && isAuthenticated)) {

            AuditPdfReportsExportBatch exportBatch = new AuditPdfReportsExportBatch(authResult.access_token);
            exportBatch.sessionId = UserInfo.getSessionId();
            exportBatch.ownerEmail = UserInfo.getUserEmail();

            if (String.isNotBlank(filterId)) {
                try {
                    Filter auditFilter = null;
                    if (!filterId.equalsIgnoreCase(NO_FILTER)) {
                        AuditFilterLog__c auditFilterLog = [SELECT Name, CriteriaJSON__c FROM AuditFilterLog__c WHERE Id = :filterId];
                        auditFilter = (Filter)JSON.deserialize(auditFilterLog.CriteriaJSON__c, Filter.class);
                        auditFilter.filterSize = null;

                        exportBatch.query = auditFilter.getQuery();
                    }
                    //turned off due to requirements
                    //exportBatch.startPurgeAutomatically = isPurgeAutomatically;
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Export started. You will be notified by email when it finished.'));
                    //status = 'Export started. You will be notified by email when it finished.';
                    system.debug('###Query #### ' +  exportBatch.query);
                } catch (Exception exc) {
                    system.debug('###FILTER_EXCEPTION FILTER ID #### ' + filterId);
                    system.debug('###FILTER_EXCEPTION#### ' + exc.getMessage());
                    system.debug('###FILTER_EXCEPTION#### ' + exc.getStackTraceString());
                }
            }
            if (!Test.isRunningTest()) {
                String triggerId = Database.executeBatch(exportBatch, 1);
                status = 'Audit upload batch is started. You will be emailed on finish. Batch ID is ' + triggerId + '';
            }
            system.debug(status);
        } else {
            if (String.isNotBlank(filterId)) {
                return authenticatGoogleDrive();
            } else {
                //status = 'Token not found batch not started';
            }
        }
        return null;
    }

    /**
    * sends final oauth request
    */
    public void getAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code=' + code + '&client_id=' + AUDIT_REPORT_SETTINGS.GoogleDriveKey__c + '&client_secret=' + AUDIT_REPORT_SETTINGS.GoogleDriveSecret__c + '&redirect_uri=' + getCurrentUrl()
                             + '&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60 * 1000);

        Http h = new Http();
        String resp;
        HttpResponse res = h.send(req);
        resp = res.getBody();

        if (res.getStatusCode() == 200) {
            authResult = (GoogleDriveAuthResult)JSON.deserialize(res.getBody(), GoogleDriveAuthResult.class);
            isAuthenticated = true;
        } else {
            isAuthenticated = false;
            status = 'Google authentication failed';
        }
    }


    @RemoteAction
    public static List<Audit> loadFilteredAudits(String criteriasJson, String numberOfRecords, String startNumber) {
        system.debug(criteriasJson);
        criteriasJson = criteriasJson.replace('&quot;', '"');
        criteriasJson = criteriasJson.replace('&gt;', '>');
        criteriasJson = criteriasJson.replace('&lt;', '<');
        List<Filter.Criteria> criterias = (List<Filter.Criteria>)JSON.deserialize(criteriasJson, List<Filter.Criteria>.class);

        try {
            String objectName = 'Audit__c';
            Filter auditFilter = new Filter(objectName, AUDIT_FIELDS);
            auditFilter.setCriterias(criterias);
            String queryAudits = auditFilter.getQuery();
            system.debug('####SOQL###' + queryAudits);
            auditFilter.filterSize = 10000;
            ApexPages.StandardSetController standardSetController = new ApexPages.StandardSetController(Database.query(queryAudits));
            standardSetController.setPageSize(Integer.valueOf(numberOfRecords));
            standardSetController.setPageNumber(Integer.valueOf(startNumber));
            List<Audit__c> audits = standardSetController.getRecords();//(List<Audit__c>)Database.query(queryAudits + ' LIMIT 10');
            List<Audit> result = new List<Audit>();
            for (Audit__c a : audits) {
                result.add(new Audit(a));
            }
            return result;
        } catch (Exception exc) {
            return new List<Audit>();
        }
        return  new List<Audit>();
    }

    @RemoteAction
    public static String runAuditPurgeBatch(String criteriasJson) {
        system.debug(criteriasJson);
        criteriasJson = criteriasJson.replace('&quot;', '"');
        criteriasJson = criteriasJson.replace('&gt;', '>');
        criteriasJson = criteriasJson.replace('&lt;', '<');
        List<Filter.Criteria> criterias = (List<Filter.Criteria>)JSON.deserialize(criteriasJson, List<Filter.Criteria>.class);
        try {
            Boolean isAndFilter = true;
            Boolean isUploadedAudits = false;
            for (Filter.Criteria criteria : criterias) {
                if (!'AND'.equalsIgnoreCase(criteria.prefix)) {
                    isAndFilter = false;
                }
                if ('IsUploaded__c'.equalsIgnoreCase(criteria.field.fieldName)) {
                    isUploadedAudits = true;
                }
            }
            if (isAndFilter && isUploadedAudits) {
                AuditPurgeBatch purgeBatch = new AuditPurgeBatch();
                String objectName = 'Audit__c';
                Filter auditFilter = new Filter(objectName, AUDIT_FIELDS);
                auditFilter.setCriterias(criterias);
                auditFilter.filterSize = null;
                String purgeQuery = auditFilter.getQuery();
                purgeBatch.customQuery = purgeQuery;
                system.debug('$$$resulte### ' + purgeQuery);
                purgeBatch.ownerEmail = UserInfo.getUserEmail();
                system.debug('$$$resulte### ' + purgeBatch);
                Database.executeBatch(purgeBatch);
                return 'ok';
            }
            return 'exception';
        } catch (Exception exc) {
            return 'exception';
        }
        return 'exception';
    }
    @RemoteAction
    public static ObjectMetadata prepareAuditsMetadata() {
        return new ObjectMetadata('Audit__c');
    }

    @RemoteAction
    public static Integer getAuditsCount(String criteriasJson) {
        system.debug(criteriasJson);
        criteriasJson = criteriasJson.replace('&quot;', '"');
        criteriasJson = criteriasJson.replace('&gt;', '>');
        criteriasJson = criteriasJson.replace('&lt;', '<');
        String objectName = 'Audit__c';
        List<Filter.Criteria> criterias = (List<Filter.Criteria>)JSON.deserialize(criteriasJson, List<Filter.Criteria>.class);
        Filter auditFilter = new Filter(objectName, new String[] {'COUNT()'});
        auditFilter.setCriterias(criterias);
        //List<AggregateResult> results = [SELECT COUNT() FROM Audit__c];
        system.debug('$$$resulte### ' + auditFilter.getQuery());
        return (Integer)Database.countQuery(auditFilter.getQuery());
    }

    @RemoteAction
    public static String saveFilter(String criteriasJson) {
        system.debug(criteriasJson);
        criteriasJson = criteriasJson.replace('&quot;', '"');
        criteriasJson = criteriasJson.replace('&gt;', '>');
        criteriasJson = criteriasJson.replace('&lt;', '<');
        List<Filter.Criteria> criterias = (List<Filter.Criteria>)JSON.deserialize(criteriasJson, List<Filter.Criteria>.class);
        if (criterias.size() > 0) {
            String objectName = 'Audit__c';
            Filter auditFilter = new Filter(objectName, AUDIT_FIELDS);
            auditFilter.setCriterias(criterias);
            AuditFilterLog__c auditFilterLog = new AuditFilterLog__c(
                Name = ' #' + Datetime.now(),
                CriteriaJSON__c = JSON.serialize(auditFilter)
            );
            insert auditFilterLog;
            return auditFilterLog.Id;
        } else {
            return NO_FILTER;
        }
    }

}