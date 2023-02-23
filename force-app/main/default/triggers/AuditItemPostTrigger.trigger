trigger AuditItemPostTrigger on AuditItem__c (after insert) {
	
	Boolean needupdate = False;
	
	Set<Id> auditIDs = new Set<Id>();
	For (AuditItem__c item: Trigger.new ) {		// Get the batch of unique Audit master ids
		if (item.Bill_Qty__c <> 0) {			// Skip any 'unbilled' inserts
			auditIDs.add(item.Audit_Master__c);		
		}
		
	}
	
	// Now fetch the  Audit masters to a List, with the fields we need
	
	if (!auditIDs.isEmpty()) {		// Only if we have some
			
		List <Audit__c> auditList = new List<Audit__c>(
			[SELECT Name, Bill_Uploaded__c from Audit__c where ID in :auditIDs]);
		
		// Iterate through the Audit masters and set the Bill Uploaded flag if not already set
		
		for (Audit__c master : auditList ) { 			// For each Audit ID in the set
		
			// Set the flag that will fire off workflow
		
			if (master.Bill_Uploaded__c == null || master.Bill_Uploaded__c == False) {
				master.Bill_Uploaded__c = True;
				needupdate = True;
			}
		}
		if (needupdate) {
			update auditList;
		}
	}
}