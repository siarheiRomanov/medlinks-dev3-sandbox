trigger CDMTrigger on CDM__c (before insert, before update) {
	
	Set<Id> aid = new set<Id>();
	Map<Id, Date> dates = new Map<Id, Date>();
	
	// Iterate the CDMs and stow the Account Id and CDM date
	for (CDM__c cdm : Trigger.new) {
		aid.add(cdm.Facility__c);
		dates.put(cdm.Facility__c, cdm.Effective_Date_Start__c);		
	}
	// Iterate the Accounts and update the CDM date if newer
	List<Account> accts = new List<Account>([SELECT Id, CDM_Start_Date__c from Account WHERE Id in :aid]);
	for (Account acc: accts) {
		if (acc.CDM_Start_Date__c == Null || acc.CDM_Start_Date__c < dates.get(acc.Id)) {
			acc.CDM_Start_Date__c = dates.get(acc.Id);
		}		
	}
	update accts;
}