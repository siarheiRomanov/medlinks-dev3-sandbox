@isTest
private class AuditDeleteTriggerTest {

    static testMethod void AuditDeleteTriggerUnitTest() {
    
    	List<Audit__c> da = new List<Audit__c>();
		
    	Account facility = new Account (Name = 'Test Facility');	// Facility account object
        facility.Auditable__c = true;
        facility.Audit_Client__c = true;                      
        facility.Shortname__c = 'TEST';
        insert facility;
        system.debug('facilityID = ' + facility.Id );
        
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
       	
        Contact oppauditor = new Contact();
        oppauditor.FirstName = 'Alice';
        oppauditor.LastName = 'Jones';
        oppauditor.IsScheduler__c = True;
        oppauditor.IsAuditor__c = True;
        insert oppauditor;
        
        
    	Audit__c audit1 = new Audit__c();	// First Audit object
        audit1.Audit_Amount__c = 100;	// Fill in required fields (not needed?)
        audit1.Patient_Name__c = 'Smith, John';
        audit1.Patient_Account__c = '1234';
        audit1.Patient_DOB__c = '1984-02-14';	// Not required, but set it to test code
        audit1.Service_Start_Date__c = date.today();
        audit1.Service_End_Date__c = date.today();        
        audit1.XFlag__c = 0;				
                      
        audit1.Facility_Is_Client__c = true;
        audit1.Account__c = facility.Id;				// Set both facility and client, to satify the audit validaters        
        audit1.Client_Audit_Account__c = facility.Id;
       
       	audit1.Assigned_Auditor__c = a1.Id;
        audit1.Assigned_Scheduler__c = a1.Id;
        
        audit1.Opposing_Scheduler__c = oppauditor.Id;
        audit1.Opposing_Auditor__c = oppauditor.Id;
        
        insert audit1;
        system.debug('audit1 inserted, ID = ' + audit1.Id);
      	da.add(audit1);
      	
      	AuditItem__c item1 = new AuditItem__c();
      	AuditItem__c item2 = new AuditItem__c();
      	
      	item1.Audit_Master__c = audit1.Id;
      	item2.Audit_Master__c = audit1.Id;
      	item1.Bill_Charge_Code__c = 'Item1';
      	item2.Bill_Charge_Code__c = 'Item2';
      	item1.Bill_Qty__c = 1;
      	item2.Bill_Qty__c = 2;
      	item1.Bill_Unit_Price__c = 50;
      	item2.Bill_Unit_Price__c = 25;
      	item1.Bill_Total__c = 50;
      	item2.Bill_Total__c = 50;
      	item1.Item_Description__c = 'This is item1';
      	item2.Item_Description__c = 'This is item2';
      	item1.Date_of_Service__c = date.today();
      	item2.Date_of_Service__c = date.today();
      	insert item1;
      	insert item2;
      	
      	// Now add the proposed exit via update!
      	date meetingdate = date.today().addDays(30);	// In local time zone??
        time meetingtime = time.newInstance(9, 30, 0, 0); // 9:30 AM ??
        datetime loctime = datetime.newInstance(meetingdate, meetingtime);	// In local time
        audit1.Date_Proposed_Exit__c = loctime;
        system.debug('Date set = ' + String.valueOf(loctime));
        audit1.Exit_Duration__c = '1 Hour';
        audit1.Exit_Mode__c = 'In Person - At Facility';
        audit1.Service_End_Date__c = date.today().addDays(10);
        audit1.Audit_Stage__c = 'Scheduled';
        update audit1;
      		
    	
    	Audit__c audit2 = new Audit__c();	// Second Audit object
        audit2.Audit_Amount__c = 200;	
        audit2.Patient_Name__c = 'Smith, Jill';
        audit2.Patient_Account__c = '1234';
        audit2.Patient_DOB__c = '1984-02-14';	// Not required, but set it to test code
        audit2.Service_Start_Date__c = date.today();
        audit2.Service_End_Date__c = date.today();        
        audit2.XFlag__c = 0;				
                      
        audit2.Facility_Is_Client__c = true;
        audit2.Account__c = facility.Id;			      
        audit2.Client_Audit_Account__c = facility.Id;
       
       	audit2.Assigned_Auditor__c = a1.Id;
        audit2.Assigned_Scheduler__c = a1.Id;
       	audit2.Opposing_Scheduler__c = oppauditor.Id;
        audit2.Opposing_Auditor__c = oppauditor.Id;
               
        insert audit2;
        system.debug('audit2 inserted, ID = ' + audit1.Id);
      	da.add(audit2);
      	
      	Account fa = [SELECT Id, Audits_NumPending__c, Audits_AmtPending__c, Audits_NumScheduled__c, Audits_AmtScheduled__c
      	 FROM Account WHERE Id = :facility.Id];
      	system.assert(fa.Audits_NumPending__c == 1);
      	system.assert(fa.Audits_AmtPending__c == 200);
      	system.assert(fa.Audits_NumScheduled__c == 1);
      	system.assert(fa.Audits_AmtScheduled__c == 100);
      	
      	// Kill the audit recs
      	delete da;
		
		fa = [SELECT Id, Audits_NumPending__c, Audits_AmtPending__c, Audits_NumScheduled__c, Audits_AmtScheduled__c
      	 FROM Account WHERE Id = :facility.Id];
      	system.assert(fa.Audits_NumPending__c == 0);
      	system.assert(fa.Audits_AmtPending__c == 0);
      	system.assert(fa.Audits_NumScheduled__c == 0);
      	system.assert(fa.Audits_AmtScheduled__c == 0);
      	    
    
    }
}