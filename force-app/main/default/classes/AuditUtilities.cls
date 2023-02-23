public class AuditUtilities {

	//@future
	/**
	* Moved to sync mode because of batch
	*/
	public static void deleteExitEventsSync(Set<Id> events) {
		List<Event> eventlist = [SELECT Id FROM Event WHERE Id in :events];
		Database.delete(eventlist, False);
	}
	@future
	public static void deleteExitEvents(Set<Id> events) {
		deleteExitEventsSync(events);
	}
	//@future
	/**
	* Moved to sync mode because of batch
	*/
	public static void bindExitEventsSync(Set<Id> events) {
		Set<String> GUIDs = new Set<String>();
		Map<String, Id> gmap = new Map<String, Id>();
		Map<Id, String> nmap = new Map<Id, String>();
		List<Event> eventlist = [SELECT Id, WhatID, AuditGUID__C, SkipAuditUpdate__c, Subject, Description FROM Event WHERE Id in :events];
		for (Event ev : eventlist) {
			if (ev.WhatId == null && ev.AuditGUID__c != null) {
				//system.debug('Adding GUID: '+ ev.AuditGUID__c);
				GUIDs.add(ev.AuditGUID__c); // Get batch of GUIDs for the accounts
			}
		}
		if (!GUIDs.isEmpty()) {
			List<Audit__c> audits = [SELECT Id, Name, EventGUID__c from Audit__C WHERE EventGUID__c in :GUIDs];
			for (Audit__c a : audits) {
				gmap.put(a.EventGUID__c, a.Id);
				nmap.put(a.Id, a.Name);
			}
			for (Event ev : eventlist) {
				if (ev.WhatId == null && ev.AuditGUID__c != null) {
					//system.debug('Setting Id for GUID: ' + ev.AuditGUID__c);
					ev.WhatId = gmap.get(ev.AuditGUID__c);	// Fix the Audit Id for this event
					String n = nmap.get(ev.WhatId);
					if (n != null && ev.Subject != null && ev.Description != null) {			// Fix the Audit Name (case number) for this event
						ev.Subject = ev.Subject.replace('null', n);
						ev.Description = ev.Description.replace('null', n);
						ev.SkipAuditUpdate__c = true;
					}
				}
			}
			Database.update(eventlist);
		}
	}

	@future
	public static void bindExitEvents(Set<Id> events) {
		bindExitEventsSync(events);
	}

	@future
	public static void bindExitTasks(Set<Id> tasks) {
		bindExitTasksSync(tasks);
	}
	
	/**
	* Moved to sync mode because of batch
	*/
	public static void bindExitTasksSync(Set<Id> tasks) {
		Set<String> GUIDs = new Set<String>();
		Map<String, Id> gmap = new Map<String, Id>();

		List<Task> tasklist = [SELECT Id, WhatID, AuditGUID__C FROM Task WHERE Id in :tasks];
		for (Task st : tasklist) {
			if (st.WhatId == null && st.AuditGUID__c != null) {
				GUIDs.add(st.AuditGUID__c); // Get batch of GUIDs for the accounts
			}
		}
		if (!GUIDs.isEmpty()) {	// Get associated Audits
			List<Audit__c> audits = [SELECT Id, EventGUID__c from Audit__c WHERE EventGUID__c in :GUIDs];
			for (Audit__c a : audits) {
				gmap.put(a.EventGUID__c, a.Id);
			}
			for (Task st : tasklist) {
				st.WhatId = gmap.get(st.AuditGUID__c);	// Fix the Audit Id for this event
			}
			Database.update(tasklist);
		}

	}
	public static void updateAccountAuditTotals(Account acct, String oldstage, String newstage, Decimal oldamt, Decimal newamt) {
		if (oldstage == newstage && oldamt == newamt) {
			return;
		}
		if (oldstage != Null) {
			if (oldstage == 'Pending') {
				acct.Audits_NumPending__c -= 1;
				acct.Audits_AmtPending__c -= oldamt;
			} else if (oldstage == 'Scheduled') {
				acct.Audits_NumScheduled__c -= 1;
				acct.Audits_AmtScheduled__c -= oldamt;
			} else if (oldstage == 'Exit Completed') {
				acct.Audits_NumExited__c -= 1;
				acct.Audits_AmtExited__c -= oldamt;
			} else if (oldstage == 'In Dispute') {
				acct.Audits_NumDisputed__c -= 1;
				acct.Audits_AmtDisputed__c -= oldamt;
			} else if (oldstage == 'Appealed') {
				acct.Audits_NumAppealed__c -= 1;
				acct.Audits_AmtAppealed__c -= oldamt;
			} else if (oldstage == 'Closed') {
				acct.Audits_NumClosed__c -= 1;
				acct.Audits_AmtClosed__c -= oldamt;
			} else if (oldstage == 'Canceled') {
				acct.Audits_NumCanceled__c -= 1;
				acct.Audits_AmtCanceled__c -= oldamt;
			}
		}
		if (newstage != Null) {
			if (newstage == 'Pending') {
				acct.Audits_NumPending__c += 1;
				acct.Audits_AmtPending__c += newamt;
			} else if (newstage == 'Scheduled') {
				acct.Audits_NumScheduled__c += 1;
				acct.Audits_AmtScheduled__c += newamt;
			} else if (newstage == 'Exit Completed') {
				acct.Audits_NumExited__c += 1;
				acct.Audits_AmtExited__c += newamt;
			} else if (newstage == 'In Dispute') {
				acct.Audits_NumDisputed__c += 1;
				acct.Audits_AmtDisputed__c += newamt;
			} else if (newstage == 'Appealed') {
				acct.Audits_NumAppealed__c += 1;
				acct.Audits_AmtAppealed__c += newamt;
			} else if (newstage == 'Closed') {
				acct.Audits_NumClosed__c += 1;
				acct.Audits_AmtClosed__c += newamt;
			} else if (newstage == 'Canceled') {
				acct.Audits_NumCanceled__c += 1;
				acct.Audits_AmtCanceled__c += newamt;
			}
		}
	}
}