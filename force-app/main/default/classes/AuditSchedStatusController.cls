public class AuditSchedStatusController {
	
	private Map<Id, Event> emap;
	private List<EventAttendee> atlist;
	private Map<Id, Audit__c> audmap;
	private Set<ID> eset = new Set<ID>();
	private Set<Id> nonset = new Set<ID>();
	private Set<Id> blockset = new Set<ID>();
	private Set<Id> reqset = new Set<ID>();
	
	public AuditSchedStatusController () {
		audmap = new Map<Id, Audit__c>([SELECT Id from Audit__c WHERE Audit_Stage__c = 'Scheduled'
		 AND Need_Opposing__c = true]);
		emap = new Map<Id, Event>([SELECT Id, WhatId, WhoId, Who.Name FROM Event WHERE AuditGUID__c != Null]);
		atlist = new List<EventAttendee>([SELECT Id, EventID, Status FROM EventAttendee ]);
		for (Event ev: emap.Values()) {
			if (audmap.keySet().contains(ev.WhatId))	// If it is in the 'Scheduled' set, save the event id
				eset.add(ev.ID); 
		}
		nonset = eset.clone();	// Get a copy of all Audit Event IDs
		for (EventAttendee a: atlist) {
			if (eset.contains(a.EventId))	// If event has an attendee, remove it from the set			
				nonset.remove(a.EventId);	// What remains are all the non-invited events
		}
		for (ID i: nonset) {
			if (emap.get(i).Who.Name.contains('To Be Determined'))
				blockset.add(i);
			else
				reqset.add(i);
		} 
				
	}
	
	public Integer getnotSched () {		
		return ([SELECT Count() from Audit__c WHERE Audit_Stage__c = 'Pending']);		
	}
	public PageReference getnotSchedView() {
		// return (new PageReference('/apex/AuditSchedStandardViews?listid=00BE0000000xUSK'));
		return (new PageReference('/apex/AuditSchedStandardViews?listid=00BA00000072oAP'));
	}
	public Integer gettotSched () {
		return (audmap.keySet().size());
	}
	public PageReference gettotSchedView() {
		// return (new PageReference('/apex/AuditSchedStandardViews?listid=00BE0000000xUSP'));
		return (new PageReference('/apex/AuditSchedStandardViews?listid=00BA00000072okw'));
	}
	
	public Integer getinviteBlock () {
		return blockset.size();	// What remains is the non-invited ones...		
	}
	public PageReference getinviteBlockView() {
		return (new PageReference('/apex/AuditSchedSpecialViews?view=0'));
	}
	
	public Integer getinviteReq () {
		return reqset.size();	// What remains is the non-invited ones...		
	}
	public PageReference getinviteReqView() {
		return (new PageReference('/apex/AuditSchedSpecialViews?view=1'));
	}
	
	public Integer getinviteWait () {
		Set<Id> atset = new Set<Id>();
		for (EventAttendee a: atlist) {
			if (eset.contains(a.EventId) && a.Status == 'New')			// New is no response
				atset.add(a.EventId);
		}
		return atset.size(); 
	}
	public PageReference getinviteWaitView() {
		return (new PageReference('/apex/AuditSchedSpecialViews?view=2'));
	}
	
	public Integer getinviteDec () {
		Set<Id> atset = new Set<Id>();
		for (EventAttendee a: atlist) {
			if (eset.contains(a.EventId) && a.Status == 'Declined')	
				atset.add(a.EventId);
		}
		return atset.size(); 
	}
	public PageReference getinviteDecView() {
		return (new PageReference('/apex/AuditSchedSpecialViews?view=3'));
	}
	
	public Integer getinviteAcc () {
		Set<Id> atset = new Set<Id>();
		for (EventAttendee a: atlist) {
			if (eset.contains(a.EventId) && a.Status == 'Accepted')	
				atset.add(a.EventId);
		}
		return atset.size(); 
	}
	public PageReference getinviteAccView() {
		return (new PageReference('/apex/AuditSchedSpecialViews?view=4'));
	}
	

}