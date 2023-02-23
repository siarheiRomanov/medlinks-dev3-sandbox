/**
* Batch is used to delete records
*/
public class AuditPurgeBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Integer deletedCount = 0;
	private Integer failedToDeleteCount = 0;

	/**
	* Id's of audits to purge
	*/
	public Set<Id> auditsToPurge {get; set;}

	/**
	* User who runs batch
	*/
	public String ownerEmail {get; set;}

	/**
	* Query to override standard
	*/
	public String customQuery {get; set;}

	/**
	* Prepare query
	*/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		if (String.isNotBlank(customQuery)) {
			return Database.getQueryLocator(customQuery);
		}
		return Database.getQueryLocator([SELECT Id, IsUploaded__c FROM Audit__c WHERE Id IN :auditsToPurge]);
	}

	public void execute(Database.BatchableContext BC, List<Audit__c> scope) {

		List<Audit__c> auditsToDelete = new List<Audit__c>();
		for (Audit__c a : scope) {
			if (a.IsUploaded__c) {
				auditsToDelete.add(a);
			}
		}
		List<Database.DeleteResult> deleteResults = Database.delete(auditsToDelete, false);
		for (Database.DeleteResult deleteResult : deleteResults) {
			if (deleteResult.isSuccess()) {
				deletedCount += 1;
			} else {
				failedToDeleteCount += 1;
			}

		}
	}

	public void finish(Database.BatchableContext BC) {
		//if (auditsToPurge.size() > 0) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] {ownerEmail});
		mail.setSubject('Audit purge complete!');
		String textBody = '';
		if (deletedCount != 0) {
			textBody += 'Successfuly deleted : ' + deletedCount;
		}
		if (failedToDeleteCount != 0) {
			textBody += '\nFailed to delete : ' + failedToDeleteCount;
		}
		if (String.isBlank(textBody)) {
			textBody = 'Nothing was delete';
		}
		mail.setPlainTextBody(textBody);
		system.debug('#failedToDeleteCount ' + failedToDeleteCount + '#deletedCount ' + '##textBody ' + textBody);
		system.debug(Messaging.sendEmail(new Messaging.Email[] {mail}, false));
		//}
	}
}