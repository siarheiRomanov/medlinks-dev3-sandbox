@isTest
private class AccountAuditViewExtTest {

    static testMethod void AccountAuditViewUnitTest() {
    	
    	Account facility = new Account (Name = 'Test Facility');	// Facility account object
        facility.Auditable__c = true;
        facility.Audit_Client__c = false;	// force the DCalert() to return true                      
        facility.Shortname__c = 'TEST';
        Account client = new Account (Name = 'Test Client');	// Client account object
        client.Auditable__c = false;
        client.Audit_Client__c = true;
        
        insert facility;
        system.debug('facilityID = ' + facility.Id );
        insert client;
        system.debug('clientID = ' + client.Id);
        AccountContactRole mr = new AccountContactRole();
        AccountContactRole pb = new AccountContactRole();
        mr.AccountId = facility.Id;
        pb.AccountId = facility.Id;
        mr.Role = 'Medical Records';
        pb.Role = 'Patient Billing';
        Contact fc = new Contact();
        fc.FirstName = 'Bob';
        fc.LastName = 'Smith';
        insert fc;
        mr.ContactId = fc.Id;
        pb.ContactId = fc.Id;
        insert mr;
        insert pb;
        
    	Audit__c audit1 = new Audit__c();	// First Audit object
        audit1.Audit_Amount__c = 100;	// Fill in required fields (not needed?)
        audit1.Patient_Name__c = 'Smith, John';
        audit1.Patient_Account__c = '1234';
        audit1.Patient_DOB__c = '1984-02-14';	// Not required, but set it to test code
        audit1.Service_Start_Date__c = date.today();
        audit1.Service_End_Date__c = date.today();        
        audit1.XFlag__c = 0;				
                      
        audit1.Facility_Is_Client__c = false;
        audit1.Account__c = facility.Id;				// Set both facility and client, to satify the audit validaters        
        audit1.Client_Audit_Account__c = client.Id;
       
       	user a1 = new User();
       	a1.FirstName = 'Alan';
       	a1.LastName = 'Auditor';
       	a1.Alias = 'a1';
       	a1.Email = 'alan@auditor.com';
       	a1.Username = 'alan@auditor.com';
 		a1.emailencodingkey = 'UTF-8';
 		a1.languagelocalekey = 'en_US';
 		a1.localesidkey = 'en_US';
 		a1.profileid = userinfo.getProfileID();
 		a1.country = 'United States';
 		a1.timezonesidkey = 'America/Los_Angeles';     
       	a1.User_is_Auditor__c = true;
       	a1.User_is_Scheduler__c = true;
       	insert a1;
       	audit1.Assigned_Auditor__c = a1.Id;
        audit1.Assigned_Scheduler__c = a1.Id;
        
        Contact oppauditor = new Contact();
        oppauditor.FirstName = 'Alice';
        oppauditor.LastName = 'Jones';
        oppauditor.IsScheduler__c = True;
        oppauditor.IsAuditor__c = True;
        insert  oppauditor;
        audit1.Opposing_Scheduler__c = oppauditor.Id;
        audit1.Opposing_Auditor__c = oppauditor.Id;
        audit1.Facility_Billing_Contact__c = fc.Id;
        audit1.Facility_MR_Contact__c = fc.Id;
        Account oppfirm = new Account (Name = 'The Firm');
        oppfirm.Opposing_Audit_Account__c = true;
        insert oppfirm;
        audit1.Opposing_Audit_Account__c = oppfirm.Id; 
        insert audit1;
        system.debug('audit1 inserted, ID = ' + audit1.Id);
      	// Now add the proposed exit via update!
      	date meetingdate = date.today().addDays(30);	// In local time zone??
        time meetingtime = time.newInstance(9, 30, 0, 0); // 9:30 AM ??
        datetime loctime = datetime.newInstance(meetingdate, meetingtime);	// In local time
        audit1.Date_Proposed_Exit__c = loctime;
        system.debug('Date set = ' + String.valueOf(loctime));
        audit1.Exit_Duration__c = '1 Hour';
        audit1.Exit_Mode__c = 'In Person - At Facility';
        audit1.Service_End_Date__c = date.today().addDays(10);
        update audit1;
      		
    	
    	Audit__c audit2 = new Audit__c();	// First Audit object
        audit2.Audit_Amount__c = 100;	// Fill in required fields (not needed?)
        audit2.Patient_Name__c = 'Smith, John';
        audit2.Patient_Account__c = '1234';
        audit2.Patient_DOB__c = '1984-02-14';	// Not required, but set it to test code
        audit2.Service_Start_Date__c = date.today();
        audit2.Service_End_Date__c = date.today();        
        audit2.XFlag__c = 0;				
                      
        audit2.Facility_Is_Client__c = false;
        audit2.Account__c = facility.Id;				// Set both facility and client, to satify the audit validaters        
        audit2.Client_Audit_Account__c = client.Id;
       
        user a2 = new User();
        a2.FirstName = 'Alex';
        a2.LastName = 'Auditor';
       	a2.Alias = 'a2';
       	a2.Email = 'alex@auditor.com';
       	a2.Username = 'alex@auditor.com';
 		a2.emailencodingkey = 'UTF-8';
 		a2.languagelocalekey = 'en_US';
 		a2.localesidkey = 'en_US';
 		a2.profileid = userinfo.getProfileID();
 		a2.country = 'United States';
 		a2.timezonesidkey = 'America/Los_Angeles';     
       	
       	a2.User_is_Auditor__c = true;
       	a2.User_is_Scheduler__c = true;
       	insert a2;
       	audit2.Assigned_Auditor__c = a2.Id;
        audit2.Assigned_Scheduler__c = a2.Id;
       	audit2.Opposing_Scheduler__c = oppauditor.Id;
        audit2.Opposing_Auditor__c = oppauditor.Id;
        audit2.Facility_Billing_Contact__c = fc.Id;
        audit2.Facility_MR_Contact__c = fc.Id;
        audit2.Opposing_Audit_Account__c = oppfirm.Id; 
               
        insert audit2;
        system.debug('audit2 inserted, ID = ' + audit1.Id);
      	
      	PageReference pg = Page.AccountAuditView;
        Test.setCurrentPage(pg);
        
        // Create a standard controller for Account
        
        ApexPages.Standardcontroller astd = new ApexPages.Standardcontroller(facility);
         
        // Create the extension and bind it to the standard controller
        
        AccountAuditViewExt av = new AccountAuditViewExt(astd);
       	system.debug(facility.name);
       	system.debug(facility.Id);
       	system.debug(av.getAccType());
    	system.assert(av.getAccType().equals('Auditable Facility (non-client)'));
    	system.assert(av.getAcctPageRef() != null);
    	system.assert(av.getNextEvent() != null);
    	system.assert(av.getNextTime() != null);
    	system.assert(av.getEventPage() != null);
    	system.assert(av.getFacilityCSZ() != null);
    	system.assert(av.getFacilityLabel() != null);
    	system.assert(av.getFacilityStreet() != null);
    	List<SelectOption> so = new List<SelectOption>(av.getAuditors());
    	system.assert(so.size() == 4);
    	for (integer i = 3; i>=0; i--) {	// Iterate through all the selections
    		av.setSelectedAuditor(so[i].getValue());
    		av.changeAuditor();
    		
    		List<Audit__c> l2 = av.getPendingAuditorList();
    		List<Audit__c> l3 = av.getScheduledAuditorList();
    		List<Audit__c> l4 = av.getExitedAuditorList();
    		List<Audit__c> l5 = av.getDisputedAuditorList();
    		List<Audit__c> l6 = av.getAppealedAuditorList();
    		List<Audit__c> l7 = av.getClosedAuditorList(); 
    		List<Audit__c> l8 = av.getCanceledAuditorList();
    		List<Audit__c> l1 = av.getAllAuditorList(); 		
    	}
    	
    	system.assert(av.getSelectedAuditor() != null);
    	system.assert(av.getContactLabel() != null);
		system.assert(av.getFirstContactName() != null);    	    	
    	system.assert(av.getIsFCPage() == true);
        system.assert(av.getFCPage() != null);
        system.assert(av.getFirstContactTel() == null);
        system.assert(av.getFirstContactEmail() == null);
        system.assert(av.getMRLabel() != null);
        system.assert(av.getMRName() != null);
        system.assert(av.getIsMRPage() == true);
        system.assert(av.getMRPage() != null);
        system.assert(av.getMRTel() == null);
        system.assert(av.getMREmail() == null);
        system.assert(av.getNumPending() == null);
        system.assert(av.getAmtPending() == null);        
        system.assert(av.getNumScheduled() == null);
        system.assert(av.getAmtScheduled() == null);
        system.assert(av.getNumExited() == null);
        system.assert(av.getAmtExited() == null);
        system.assert(av.getNumDisputed() == null);
        system.assert(av.getAmtDisputed() == null);
        system.assert(av.getNumAppealed() == null);
        system.assert(av.getAmtAppealed() == null);
        system.debug(av.getNumTotal());
        system.debug(av.getAmtTotal());
        
        
        av.setAllTabRenderFlag();
        system.assert(av.getAllTabRenderFlag() == true);
        av.setPendingTabRenderFlag();
        system.assert(av.getPendingTabRenderFlag() == true);
        av.setScheduledTabRenderFlag();
        system.assert(av.getScheduledTabRenderFlag() == true);
        av.setExitedTabRenderFlag();
        system.assert(av.getExitedTabRenderFlag() == true);
        av.setDisputedTabRenderFlag();
        system.assert(av.getDisputedTabRenderFlag() == true);
        av.setAppealedTabRenderFlag();
        system.assert(av.getAppealedTabRenderFlag() == true);
        av.setClosedTabRenderFlag();
        system.assert(av.getClosedTabRenderFlag() == true);
		av.setCanceledTabRenderFlag();
        system.assert(av.getCanceledTabRenderFlag() == true);
		av.setSearchTabRenderFlag();
        system.assert(av.getSearchTabRenderFlag() == true);

    }
}