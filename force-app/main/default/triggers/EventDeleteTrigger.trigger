trigger EventDeleteTrigger on Event (before delete) {

//	List<String> GUIDList = new List<String>();
//	String APPEAL_ERROR_MESSAGE = 'Cannot delete calendar entries for Appeal Exit events';
	String AUDIT_ERROR_MESSAGE  = 'Cannot delete calendar entries for Audit Exit events';

	for (Event ev : Trigger.old) {
		if (ev.AuditGUID__c != null) {	// Find all Exit Events being deleted directly from the calendar (if from Audit, the GUID is NULL)
			//
			// CHANGED 01/12: User updates to calendar exit events WILL NOT cause an update to the Audit. The
			// original proposed exit date can only be changed via Audit edit. As such, trying to delete a
			// calendar entry for an exit is now prohibited, and will throw an error			
			// GUIDList.add(ev.AuditGUID__c); //NO UPDATE
			ev.addError(AUDIT_ERROR_MESSAGE);
		}

//		if (ev.AppealGUID__c != null) {	// Find all Exit Events being deleted directly from the calendar (if from Appeal, the GUID is NULL)
//			ev.addError(APPEAL_ERROR_MESSAGE);
//		}
	}
	//if (!GUIDList.IsEmpty()) {		// Get Audit recs, if any ** ALWAYS NULL as of 01/12
	//	List<Audit__c> auditlist = new List<Audit__c>([SELECT Id, EventGUID__c, Date_Proposed_Exit__c, SkipEventUpdate__c FROM Audit__c WHERE EventGUID__c IN :GUIDList]);
	//	for (Audit__c audit : auditlist) {			
	//		audit.EventGUID__c = Null;			// Kill the event
	//		audit.Date_Proposed_Exit__c = Null; // Kill the exit date			
	//		audit.SkipEventUpdate__c = True;	// Ensure that we don't recurse on triggers						
	//	}
	//	update auditlist;
	//}	
}