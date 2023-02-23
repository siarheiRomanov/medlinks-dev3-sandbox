@IsTest global class HttpCalloutMockImpl implements HttpCalloutMock {
	global HttpResponse respond(HttpRequest req) {
		HttpResponse resp = new HttpResponse();
		resp.setStatus('OK');
		resp.setStatusCode(200);
		resp.setHeader('Content-Type', 'application/pdf');
		resp.setBodyAsBlob(Blob.valueOf('Blob body'));
		return resp;
	}
}