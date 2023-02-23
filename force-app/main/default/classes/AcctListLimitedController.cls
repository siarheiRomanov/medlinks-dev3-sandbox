public class AcctListLimitedController {
	
	public class mylist {
		public PageReference flink { get; private set; }
		public String fname { get; private set; }
		public String ftype { get; private set; }
		public Integer myPending { get; private set; }
		public Integer myScheduled { get; private set; }
		public Integer myExited { get; private set; }
		public Boolean isClient { get; private set; }		
		public String oname { get; private set; }
		public PageReference olink { get; private set; }
		public String street { get; private set; }
		public String city { get; private set; }
		public String state { get; private set; }
		public String zip { get; private set; }
	}
	public mylist m;
	public List<mylist> myAccountList { get; set; }

	public PageReference testLimited() {	// Action test upon page load
		ID cuid = UserInfo.getUserId();
        User curu = [Select Id, Limited_License__c, User_is_Auditor__c from User WHERE id = : cuid];     
		if (curu.Limited_License__c) {
			return null;	// Use the limited page (ONLY AUDITORS FOR NOW)
		}       		
		else {
			PageReference p = new PageReference('/001/o');	// Standard Account tab
			p.getParameters().put('nooverride', '1');
			p.setRedirect(true); 
			return p;
		}
	}
	
	public AcctListLimitedController () {
		ID cuid = UserInfo.getUserId();
		Set<ID> aid = new Set<Id>();
		Map<ID, User> ownermap = new Map<Id, User>();
		User urec;
		List<AuditorAssignment__c> aalist = new List<AuditorAssignment__c>([SELECT Auditor__c, Account__c from AuditorAssignment__c
		 WHERE Auditor__c = :cuid]);
		for (AuditorAssignment__c aa: aalist) {
			aid.add(aa.Account__c);
		}        
		myAccountList = new List<mylist>();
		List<Account> acclist = new List<Account>([Select Id, Name, Type, OwnerId, Audit_Client__c,
		 Facility_Street__c, Facility_City__c, Facility_State__c, Facility_Zip__c FROM Account 
		 WHERE Id IN :aid ORDER BY Name]);
		for (Account acc: acclist) {
			if (!ownermap.containsKey(acc.OwnerId)) {				     
        		urec = new User();
        		urec = [SELECT Id, Name from User WHERE Id = :acc.OwnerId];
        		ownermap.Put(acc.OwnerID, urec);
        	}
			m = new mylist();
			m.fname = acc.Name;
			m.flink = new PageReference('/apex/AccountAuditView?id=' + acc.Id);
			m.ftype = acc.Type;
			m.isClient = acc.Audit_Client__c;
			m.oname = ownermap.Get(acc.OwnerID).Name; 
			m.olink = new ApexPages.StandardController(ownermap.Get(acc.OwnerID)).view();
			m.street = acc.Facility_Street__c;
			m.city = acc.Facility_City__c;
			m.state = acc.Facility_State__c;
			m.zip = acc.Facility_Zip__c;
			m.myPending = [SELECT count() from Audit__c WHERE Account__c = :acc.Id AND Assigned_Auditor__c = :cuid AND Audit_Stage__c = 'Pending'];
			m.myScheduled = [SELECT count() from Audit__c WHERE Account__c = :acc.Id AND Assigned_Auditor__c = :cuid AND Audit_Stage__c = 'Scheduled'];
			m.myExited = [SELECT count() from Audit__c WHERE Account__c = :acc.Id AND Assigned_Auditor__c = :cuid AND Audit_Stage__c = 'Exit Completed'];			
			myAccountList.add(m);
		}		
	}
}