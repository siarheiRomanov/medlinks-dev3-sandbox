@isTest
private class Test_AuditReportUploadLog {

	@isTest static void testAuditReportUploadLog() {
		// Implement test code
		AuditReportUploadLog log = new AuditReportUploadLog();
		log.logSuccess('001m000000D7npbAAB');
		log.logError('001m000000D7npbAAB');
		log.getSuccessfulyUploadedAudits();
		log.getFailedToUploadAudits();
	}



}