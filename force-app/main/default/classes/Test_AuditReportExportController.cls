@isTest(SeeAllData = true)
private class Test_AuditReportExportController {
	@isTest static void testAuditModel() {
		Audit__c audit = new Audit__c();
		Audit auditModel = new Audit(audit);
	}
	@isTest static void testController() {
		AuditReportExportController controller = new AuditReportExportController();
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('testCalloutMoq');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		Test.setMock(HttpCalloutMock.class, mock);

		controller.authenticatGoogleDrive();
		controller.isAuthenticated = true;
		controller.authResult = new AuditReportExportController.GoogleDriveAuthResult();
		//controller.authResult.acces_token = 'Test';
		//controller.runBatch();
		controller.getAccessToken();
	}

	@isTest static void testRunBatch() {
		AuditReportExportController controller = new AuditReportExportController();

		controller.isAuthenticated = true;
		controller.authResult = new AuditReportExportController.GoogleDriveAuthResult();
		//controller.authResult.acces_token = 'Test';
		controller.runBatch();
//		controller.getAccessToken();
	}


	@isTest static void testPrepareAuditMetadata() {
		System.assertNotEquals(AuditReportExportController.prepareAuditsMetadata(), null);
	}

	@isTest static void testLoadFilteredAudits() {
		String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';
		System.assertNotEquals(AuditReportExportController.loadFilteredAudits(criteriaJson, '10', '1'), null);
	}

	@isTest static void testRunAuditPurgeBatch() {
		String criteriaJson = '[{"value":"true","prefix":"OR","operator":{"value":"=","label":null},"id":"1","field":{"isReference":false,"fieldName":"IsUploaded__c","fieldLabel":"IsUploaded","fieldDataType":"BOOLEAN","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"}]}},{"value":"100000","prefix":"OR","operator":{"value":"<=","label":null},"id":"2","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';
		System.assertNotEquals(AuditReportExportController.runAuditPurgeBatch(criteriaJson), null);
	}

	@isTest static void testGetAuditsCount() {
		String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';
		System.assertNotEquals(AuditReportExportController.getAuditsCount(criteriaJson), null);
	}

	@isTest static void testSaveFilter() {
		String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';
		System.assertNotEquals(AuditReportExportController.saveFilter(criteriaJson), null);
	}

	@isTest static void testSaveFilterNoCriterias() {
		String criteriaJson = '[]';
		System.assertNotEquals(AuditReportExportController.saveFilter(criteriaJson), null);
	}
}