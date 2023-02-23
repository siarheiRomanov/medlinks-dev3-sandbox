/**
* This batch sends Audit reports to Google Drive
*/
public class AuditPdfReportsExportBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

	private static final AuditReportSettings__c auditReportSettings = AuditReportSettings__c.getOrgDefaults();
	private static final String URL_ENCODING = 'UTF-8';
	private static final Integer HTTP_OK_CODE = 200;
	//private static final String AUDIT_QUERY = 'SELECT Id, Name, (SELECT Shortname__c FROM Account__r)  FROM Audit__c LIMIT 10000';

	private IAuditReportExporter auditExporter;
	private AuditReportUploadLog uploadLog = new AuditReportUploadLog();
	//private String email;

	/**
	* Session id of user to get PDF report and avoid authentication
	*/
	public String sessionId {get; set;}

	/**
	* Email of the user who ran batch
	*/
	public String ownerEmail {get; set;}

	/**
	* Google Drive access token
	*/
	public String accessToken {get; set;}

	/**
	* Filter specified query
	*/
	public String query {get; set;}
	/**
	*
	*/
	public Boolean startPurgeAutomatically {get; set;}

	/**
	* Send request to VF page that generates PDF report
	* using sessionId as OAuth access token to VF service
	*/
	private HttpResponse getReportPdfContent(String auditId, String authSessionId) {
		HttpRequest request = new HttpRequest();
		String endpoint;
		endpoint = auditReportSettings.AuditReportUrl__c + '?id=' + auditId;
		request.setEndpoint(endpoint);
		request.setMethod('GET');
		request.setHeader('Authorization', 'OAuth ' + authSessionId);
		Http binding = new Http();
		HttpResponse response = binding.send(request);
		return response;
	}

	/**
	* Generate name as in AuditCaseReport
	*/
	private String generateReportPdfFileName(Audit__c audit) {
		String fileName = audit.Account__r.Shortname__c + '_' + audit.Name + '_' + audit.Patient_Name__c + '_';
		integer nb = fileName.indexOf(' ');
		if (nb != -1) {
			fileName = fileName.substring(0, nb) + fileName.substring(nb + 1); // Get rid of blank in name
		}
		if (String.isNotBlank(audit.Patient_Account__c)) {
			fileName += audit.Patient_Account__c.substring(audit.Patient_Account__c.length() - 3);
		} else {
			fileName += '###';
		}
		fileName += '.pdf';
		return fileName;
	}

	/**
	* Send result to email
	*/
	private void sendUploadResultToUserEmail(Set<Id> failed, Set<Id> success) {

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] {ownerEmail});
		mail.setSubject('Audit upload to Google Drive complete!');
		String message = '';
		if (failed.size() > 0) {
			message += 'Failed to upload records count : ' + failed.size() + '\n';
		}
		if (success.size() > 0) {
			message += 'Uploaded successfully records count : ' + success.size() + '\n';
		}
		if (failed.size() == 0 && success.size() == 0) {
			message = 'Nothing uploaded to Google drive';
		}
		mail.setPlainTextBody(message);


		Messaging.sendEmail(new Messaging.Email[] {mail}, false);

	}

	/**
	* Transfer googledrive access token to ctor
	*/
	public AuditPdfReportsExportBatch(String accessToken) {
		this.accessToken = accessToken;
		auditExporter = new AuditReportGoogleDriveExporter(accessToken);
	}

	/**
	* Prepare querylocator for batch
	*/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		if (String.isNotBlank(query)) {
			return Database.getQueryLocator(query);
		} else {
			return Database.getQueryLocator([SELECT Id, Name, Patient_Name__c,
			                                 Patient_Account__c,
			                                 Patient_MR__c, Account__r.Shortname__c, IsUploaded__c FROM Audit__c ]);
		}
	}

	/**
	* Sends chunk of reports to drive
	*/
	public void execute(Database.BatchableContext BC, List<Audit__c> scope) {
		List<Audit__c> uploadedAudits = new List<Audit__c>();
		for (Audit__c audit : scope) {
			try {
				HttpResponse response = getReportPdfContent(audit.Id, sessionId);
				if (response.getStatusCode() == HTTP_OK_CODE) {
					String result = auditExporter.send(generateReportPdfFileName(audit), EncodingUtil.base64Encode(response.getBodyAsBlob()));
					//processGoogleDriveResult(result);
					uploadLog.logSuccess(audit.Id);
					if (audit.IsUploaded__c == null || !audit.IsUploaded__c) {
						audit.IsUploaded__c = true;
						uploadedAudits.add(audit);
					}
				} else {
					uploadLog.logError(audit.Id);
					if (audit.IsUploaded__c) {
						audit.IsUploaded__c = false;
						uploadedAudits.add(audit);
					}
				}
			} catch (Exception exc) {
				uploadLog.logError(audit.Id);
				if (audit.IsUploaded__c) {
					audit.IsUploaded__c = false;
					uploadedAudits.add(audit);
				}
			}
		}
		update uploadedAudits;
	}

	/**
	* Start purgification of records
	*/
	public void finish(Database.BatchableContext BC) {
		Set<Id> failed = uploadLog.getFailedToUploadAudits();
		Set<Id> success = uploadLog.getSuccessfulyUploadedAudits();
		sendUploadResultToUserEmail(failed, success);
		if (startPurgeAutomatically != null && startPurgeAutomatically) {
			AuditPurgeBatch purgeBatch = new AuditPurgeBatch();

			purgeBatch.auditsToPurge = success;
			purgeBatch.ownerEmail = this.ownerEmail;
			Database.executeBatch(purgeBatch);
		}
	}
}