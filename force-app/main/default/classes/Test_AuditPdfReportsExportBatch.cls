@isTest(SeeAllData = true)
private class Test_AuditPdfReportsExportBatch {

	@isTest static void testBatchStartToken() {
		String token = '';
		/*StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('testCalloutMoq');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');*/
		Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
		AuditPdfReportsExportBatch auditBatch = new AuditPdfReportsExportBatch(token);
		//Database.executeBatch(auditBatch, 1);
		String objectName = 'Audit__c';

		String criteriaJson = '[]';

		//auditFilter.setCriterias(criterias);
		
		String[] fieldSet = new String[] {'Id', 'Name', 'Patient_Name__c',
		                                  'Patient_Account__c',
		                                  'Patient_MR__c', 'Account__r.Shortname__c', 'IsUploaded__c'
		                                 };
		Filter auditFilter = new Filter(objectName, fieldSet);
		auditFilter.filterSize = 5;
		auditFilter.setCriterias((List<Filter.Criteria>)JSON.deserialize(criteriaJson, List<Filter.Criteria>.class));
		String purgeQuery = auditFilter.getQuery();
		auditBatch.sessionId = UserInfo.getSessionId();
		auditBatch.query = purgeQuery;
		System.System.debug(loggingLevel.Error, '*** SOQL: ' + purgeQuery);
		auditBatch.start(null);
		auditBatch.execute(null, Database.query(purgeQuery));
		auditBatch.finish(null);
	}

	@isTest static void testBatchStart() {
		String token = '';
		/*StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('testCalloutMoq');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');*/

		Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
		AuditPdfReportsExportBatch auditBatch = new AuditPdfReportsExportBatch(token);
		//Database.executeBatch(auditBatch, 1);
		String objectName = 'Audit__c';
		String[] fieldSet = new String[] {'Id', 'Name', 'Patient_Name__c',
		                                  'Patient_Account__c',
		                                  'Patient_MR__c', 'Account__r.Shortname__c', 'IsUploaded__c'
		                                 };
		Filter auditFilter = new Filter(objectName,fieldSet);
		String criteriaJson = '[]';

		//auditFilter.setCriterias(criterias);
		auditFilter.filterSize = 5;
		auditFilter.setCriterias((List<Filter.Criteria>)JSON.deserialize(criteriaJson, List<Filter.Criteria>.class));
		String purgeQuery = auditFilter.getQuery();
		//auditBatch.query = purgetQuery;
		auditBatch.sessionId = UserInfo.getSessionId();
		auditBatch.start(null);
		auditBatch.execute(null, Database.query(purgeQuery));
		auditBatch.finish(null);
	}
}