public interface IAuditReportExporter {

	/**
	* @return Body of the response or result of the sending
	*/
	String send(String fileName, String body) ;
}