@isTest
private class Test_AuditReportExporter {
	
	@isTest static void testSend() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('testCalloutMoq');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		Test.setMock(HttpCalloutMock.class, mock);
		AuditReportGoogleDriveExporter exporter = new AuditReportGoogleDriveExporter(null);
		exporter.send('name','body');
	}
		
}