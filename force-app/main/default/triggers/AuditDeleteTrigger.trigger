trigger AuditDeleteTrigger on Audit__c (before delete) {
	
	List<String> GUIDList = new List<String>();
	Set<Id> acctIDs = new Set<Id>();
	
	For (Audit__c audit : Trigger.old) {
		if (audit.EventGUID__c != Null) {	// Check if any have Exit Events
			GUIDList.add(audit.EventGUID__c);
		}
		acctIDs.add(audit.Account__c);		// Fetch ALL Account IDs related to this audit and read into a map
		if (audit.Client_Audit_Account__c != Null) {
			acctIDs.add(audit.Client_Audit_Account__c);
		}
		if (audit.Opposing_Audit_Account__c != Null) {
			acctIDs.add(audit.Opposing_Audit_Account__c);
		}
	}
	Map<Id, Account> acctMap = new Map<Id, Account> ([Select Id, Name,
	 Audits_NumAppealed__c, Audits_NumExited__c, Audits_NumDisputed__c, Audits_NumPending__c,
	 Audits_NumScheduled__c, Audits_NumClosed__c, Audits_NumCanceled__c,
	 Audits_AmtAppealed__c, Audits_AmtExited__c, Audits_AmtDisputed__c, Audits_AmtPending__c,
	 Audits_AmtScheduled__c, Audits_AmtClosed__c, Audits_AmtCanceled__c 	 
	 FROM Account WHERE Id in :acctIDs]);
	
	For (Audit__c audit : Trigger.old) {
		
		// Update the count and dollar totals on account(s) related to this Audit rec
		
		String oldstage = audit.Audit_Stage__c;
		Decimal oldamt = audit.Audit_Amount__c;
		String newstage = null;
		Decimal newamt = 0;
		// Update facility account
		AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Account__c), oldstage, newstage, oldamt, newamt);
		// Update client and opp account totals
		if (audit.Client_Audit_Account__c != Null && audit.Client_Audit_Account__c != audit.Account__c) {
			AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Client_Audit_Account__c), oldstage, newstage, oldamt, newamt);
		}
		if (audit.Opposing_Audit_Account__c != Null) {
			AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Opposing_Audit_Account__c), oldstage, newstage, oldamt, newamt);
		}
	}
	update acctMap.Values();		// Update the accounts
	
	if (!GUIDList.IsEmpty()) {		// Get Event recs, if any
		List <Event> evlist = new List <Event>([Select ID, SkipAuditUpdate__c, DeleteAfterUpdate__c, AuditGUID__c from Event WHERE AuditGUID__c IN :GUIDList]);
		for (Event ev : evlist) {
    		ev.AuditGUID__c = Null;
    		ev.SkipAuditUpdate__c = True;
    		ev.DeleteAfterUpdate__c = True; // Force event to kill itself after it clears the GUID
		}
		update evlist;
	}
}