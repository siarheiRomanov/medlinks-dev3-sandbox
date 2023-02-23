@isTest
private class AcctListLimitedTest {

    static testMethod void myUnitTest() {
    	Account facility = new Account (Name = 'Test Facility');	// Facility account object
        facility.Auditable__c = true;
        facility.Audit_Client__c = true;	// force the DCalert() to return true                      
        facility.Shortname__c = 'TEST';
        facility.Type = 'Hospital';
        facility.Facility_Street__c = '123 Main Street';
        facility.Facility_City__c = 'Troy';
        facility.Facility_State__c = 'NY';
        facility.Facility_Zip__c = '12180';
        insert facility;
        system.debug('facilityID = ' + facility.Id );
        
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
       
       	user a1 = new User();
       	a1.FirstName = 'Alan';
       	a1.LastName = 'Auditor';
       	a1.Alias = 'a1';
       	a1.Email = 'alan@auditor.com';
       	a1.Username = 'alan@auditor.com';
 		a1.emailencodingkey = 'UTF-8';
 		a1.languagelocalekey = 'en_US';
 		a1.localesidkey = 'en_US';
 		a1.profileid = userinfo.getProfileID();	// Current profile? Does it matter?
 		a1.country = 'United States';
 		a1.timezonesidkey = 'America/Los_Angeles';     
       	a1.User_is_Auditor__c = true;
       	a1.User_is_Scheduler__c = true;
       	a1.Limited_License__c = true;		// ***** SET THE CONTRACTOR FLAG
       	insert a1;
       	
       	// Join object for account -> auditor
       	AuditorAssignment__c aas = new AuditorAssignment__c();
       	aas.Auditor__c = a1.Id;
       	aas.Account__c = facility.Id;
       	insert aas;
       	       	
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
        
        insert audit1;
        system.debug('audit1 inserted, ID = ' + audit1.Id);
      	
      	System.runAs(a1) {	// Set user context to test
      	
	      	PageReference pg = Page.AccountListLimited;
	        Test.setCurrentPage(pg);
	       	AcctListLimitedController lcon = new AcctListLimitedController();
       		system.assert(lcon.myAccountList.size() == 1);
       		system.assert(lcon.myAccountList.get(0).city == 'Troy');
      	} 
    }
}