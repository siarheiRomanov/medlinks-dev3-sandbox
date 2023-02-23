public with sharing class AuditReportGoogleDriveExporter implements IAuditReportExporter {
	/**
	* thrown when token passed to google drive was invalidated
	* HTTP Status 401
	*/
	public class UnauthorizedTokenException extends Exception {}

	/**
	* thrown when HTTP Status is not 200
	*/
	public class UnknownException extends Exception {}
	//TODO add boundary generation
	private static final String BOUNDARY = '----------9889464542212';
	private static final String DELIMITER = '\r\n--' + BOUNDARY + '\r\n';
	private static final String END_OF_BODY = '\r\n--' + BOUNDARY + '--';
	private static final String REPORT_MIME_TYPE = 'application/pdf';
	//TODO maybe store in custom settings
	private static final String GOOGLE_DRIVE_API_URL = 'https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart';
	//private static final String API_TOKEN = 'ya29.6QFUJe739VFwf97AHaIbNbLVpoUzfiftMpRLdfATY1EnOai0wisy3Ltl_Al2osbxe7Y2';


	private String accessToken;


//TODO find better way
	public AuditReportGoogleDriveExporter(String accessToken) {
		this.accessToken = accessToken;
	}

	private HttpRequest createRequest(String body) {
		HttpRequest driveRequest = new HttpRequest();
		driveRequest.setEndpoint(GOOGLE_DRIVE_API_URL);
		driveRequest.setMethod('POST');
		driveRequest.setHeader('Content-Length', body.length() + '');
		driveRequest.setHeader('Content-Type', 'multipart/related; boundary="' + BOUNDARY + '"');
		driveRequest.setHeader('Authorization', 'Bearer ' + accessToken);
		driveRequest.setBody(body);
		return driveRequest;
	}

	private String formRequestBody(String fileName, String body) {
		//String fileBody = EncodingUtil.base64Encode(body);
		String requestBody = DELIMITER + 'Content-Type: application/json\r\n\r\n' +
		                     '{ "title" : "' + fileName + '",' + ' "mimeType" : "' + REPORT_MIME_TYPE + '" }'
		                     + DELIMITER + 'Content-Type: ' + REPORT_MIME_TYPE + ' \r\n'
		                     + 'Content-Transfer-Encoding: base64\r\n\r\n' + body + END_OF_BODY;
		return requestBody;
	}

	/**
	* Send report file to google drive
	*/
	public String send(String fileName, String body) {
		String requestBody = formRequestBody(fileName, body);
		HttpRequest driveRequest = createRequest(requestBody);
		Http binding = new Http();
		HttpResponse response = binding.send(driveRequest);
		//System.debug(response);
		//System.debug(response.getBody());
		if (response.getStatusCode() == 401) {
			throw new UnauthorizedTokenException();
		}

		if (response.getStatusCode() != 200) {
			throw new UnknownException();
		}
		return response.getBody();
	}
}