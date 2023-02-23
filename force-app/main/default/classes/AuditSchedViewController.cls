public class AuditSchedViewController {

	private Map<Id, Event> evmap;
	private Map<Id, EventAttendee> atmap;
	private Map<Id, Audit__c> audmap;
	private Set<Id> evset = new Set<Id>();
	private Set<Id> atset = new Set<Id>();
	private Set<Id> nonset = new Set<Id>();
	
	public String vname { get; private set; }	
	public class SchedItem {
		public Audit__c audit { get; private set; }
		public PageReference audlink { get; private set; }	
		public String evdate { get; private set; }
		public PageReference evlink { get; private set; }
	}

	public List<SchedItem> SchedViewList { get; private set; }
	
	
	public AuditSchedViewController () {
		SchedViewList = new List<SchedItem>();		
		SchedItem sv;
		String view = ApexPages.currentPage().getParameters().get('view'); // View type is 1,2,3, or 4
		audmap = new Map<Id, Audit__c>([SELECT Id, Name, Audit_Type__c, Account__c, Date_LOI__c, Patient_Name__c,
		  Patient_Account__c, Audit_Amount__c, Date_Proposed_Exit__c, Assigned_Auditor__c, Opposing_Auditor__c,
		  Opposing_Scheduler__c from Audit__c WHERE Audit_Stage__c = 'Scheduled' AND Need_Opposing__c = true]);
		  
		evmap = new Map<Id, Event>([SELECT Id, StartDateTime, WhatId, WhoID, Who.Name FROM Event WHERE AuditGUID__c != Null]);
		atmap = new Map<Id, EventAttendee>([SELECT Id, EventID, Status FROM EventAttendee ]);
		for (Event ev: evmap.Values()) {
			if (audmap.keySet().contains(ev.WhatId)) // If event's audit ref is in 'Scheduled' set, save the event id
				evset.add(ev.ID); 
		}
		nonset = evset.clone();	// Get a copy of all Audit Event IDs
		for (EventAttendee a: atmap.Values()) {
			if (evset.contains(a.EventId))	// If event has an attendee, remove it from the set			
				nonset.remove(a.EventId);	// What remains are all the non-invited events
		}
		
		if (view == '0') {
			vname = 'Invite Blocked - Auditor To Be Determined';
			// Invite required
			for (ID i: nonset) {
				if (evmap.get(i).Who.Name.contains('To Be Determined'))
					atset.add(i);
			}			
		}
		if (view == '1') {
			vname = 'Invite Required';
			// Invite required
			for (ID i: nonset) {
				if (!evmap.get(i).Who.Name.contains('To Be Determined'))
					atset.add(i);
			}			
		}
		else if (view == '2') {
			vname = 'No Response to Invite';
			// Awaiting response from invitee
			for (EventAttendee a: atmap.Values()) {
				if (evset.contains(a.EventId) && a.Status == 'New')	// New is no response
					atset.add(a.EventId);
			}
		}		
		else if (view == '3') {
			vname = 'Invite Declined';
			// Invitee declined
			for (EventAttendee a: atmap.Values()) {
				if (evset.contains(a.EventId) && a.Status == 'Declined')
					atset.add(a.EventId);
			}
		}
		else if (view == '4') {
			vname = 'Invite Accepted';
			// Invitee accepted
			for (EventAttendee a: atmap.Values()) {
				if (evset.contains(a.EventId) && a.Status == 'Accepted')
					atset.add(a.EventId);
			}
		}
		// Generate list of audits based on generated set of Events in atset
		
		List<String> sortlist = new List<String>();
		Map<String, ID> sortmapaud = new Map<String, Id>();
		Map<String, ID> sortmapev = new Map<String, Id>();
		
		for (ID eid: atset) {
			Event e = evmap.get(eid);
			Audit__c a = audmap.get(e.WhatId);
			sortlist.add(a.Name);	// Jump through hoops to get a sorted list...
			sortmapaud.put(a.Name, a.Id);
			sortmapev.put(a.Name, eid);
			
		}
		sortlist.sort();
		for (Integer i = 0; i < sortlist.size(); i++) {
			sv = new SchedItem();
			sv.audit = new Audit__c();
			sv.audit = audmap.get(sortmapaud.get(sortlist[i]));  // Audit rec associated with Event...
			sv.audlink = new ApexPages.Standardcontroller(sv.audit).view();
			Event e = evmap.get(sortmapev.get(sortlist[i]));
			sv.evlink = new ApexPages.Standardcontroller(e).view();	// Link to event
			sv.evdate = e.StartDateTime.format('MM-dd-yyyy h:mm a');			
			SchedViewList.add(sv);
		}
	}

}