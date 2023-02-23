trigger EventTrigger on Event (before insert, before update) {
		
//	Map<String, Event> GUIDMap = new Map<String, Event>();
	
	for (Event ev : Trigger.new) {
		
		// For now, we just handle updates of Events already bound to Audit Exits. Perhaps in the future
		// we will handle new Events and bind them to Audits...
		
//		if ((Trigger.isUpdate && ev.AuditGUID__c != null && !ev.SkipAuditUpdate__c) || (Trigger.isUpdate && ev.AppealGUID__c != null && !ev.SkipAppealUpdate__c)) {
		if (Trigger.isUpdate && ev.AuditGUID__c != null && !ev.SkipAuditUpdate__c) {
			Datetime priorStart   = Trigger.oldMap.get(ev.Id).StartDateTime;
			Integer priorDuration = Trigger.oldMap.get(ev.Id).DurationInMinutes;
			String priorLoc       = Trigger.oldMap.get(ev.Id).Location;

			if (priorStart != ev.StartDateTime || priorDuration != ev.DurationInMinutes || priorLoc != ev.Location) {								
				// AUDIT UPDATE DISABLED 01/12: Calendar updates WILL NOT change Proposed Exit Date on Audit or Appeal
				//GUIDMap.put(ev.AuditGUID__c, ev);
				if (priorStart != ev.StartDateTime) {
					ev.Date_Exit_Changed__c = Datetime.now();	// Time stamp the change
					ev.Date_Prior_Exit__c   = priorStart;			// Save the old date
					ev.Changed_by_User__c   = UserInfo.getName();	// and identify the user
				}
			}
		}

		ev.SkipAuditUpdate__c = false;	// Reset recursive trigger semaphore
//		ev.SkipAppealUpdate__c = false;	// Reset recursive trigger semaphore
	}
	
	//if (!GUIDMap.IsEmpty()) {		// Get Audit recs, if any ** WILL ALWAYS BE NULL as of 01/12
		//List<Audit__c> auditlist = new List<Audit__c>([SELECT Id, EventGUID__c, Date_Proposed_Exit__c, Exit_Duration__c, Exit_Mode__c, SkipEventUpdate__c FROM Audit__c WHERE EventGUID__c IN :GUIDMap.KeySet()]);
		//for (Audit__c audit : auditlist) {
		//	Event ev = GUIDMap.get(audit.EventGUID__c);		// Get update values for this audit rec
		//	if (ev.IsAllDayEvent) {
		//		audit.Exit_Duration__c = 'All Day';
		//	}
		//	else {
		//		if (ev.DurationInMinutes < 60) {
		//			audit.Exit_Duration__c = String.ValueOf(ev.DurationInMinutes) + ' Minutes';
		//		}
		//		else {
		//			Integer h = ev.DurationInMinutes/60;
		//			audit.Exit_Duration__c = (h == 1)? '1 Hour': String.ValueOf(h) + ' Hours'; 
		//		}
		//	}
		//	if (ev.Subject.Contains('Meeting')) {
		//		 audit.Exit_Mode__c = 'In Person - ' + ev.Location;
		//	}
		//	audit.Date_Proposed_Exit__c = ev.StartDateTime;			
		//	audit.SkipEventUpdate__c = True;	// Ensure that we don't recurse on triggers						
		//}
		//update auditlist;
	//}	
}