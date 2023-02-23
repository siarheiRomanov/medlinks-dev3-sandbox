/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AuditTriggerTest {

    static testMethod void AuditTriggerUnitTest() {

        Audit__c audit = new Audit__c();	// Test Audit object
        Account facility = new Account (Name = 'Test Facility');	// Facility account object
        // Must set fields so that we pass validation
        facility.Auditable__c = true;
        facility.Audit_Client__c = true;
        facility.Shortname__c = 'TEST';        
        Account client = new Account (Name = 'Test Client');	// Client account object
        client.Auditable__c = false;
        client.Audit_Client__c = true;
        
        insert facility;
        system.debug('facilityID = ' + facility.Id );       
        insert client;
        system.debug('clientID = ' + client.Id);
        system.assert(facility.ID != client.ID);
        // First test the facility and client account updating
        audit.Facility_Is_Client__c = true;
        audit.Account__c = facility.Id;
        audit.Client_Audit_Account__c = null;
        system.debug('Facility Account = ' + audit.Account__c);
        system.debug('Client Account = '+ audit.Client_Audit_Account__c);
        audit.XFlag__c = 0;				// Don't do the crypto stuff yet
        audit.Audit_Amount__c = 100;	// Fill in required fields
        audit.Patient_Name__c = 'Smith, John';
        audit.Patient_Account__c = '1234';
        audit.Service_Start_Date__c = date.today();
        audit.Service_End_Date__c = date.today();
        test.startTest();        
        insert audit;
        system.debug('audit inserted, ID = ' + audit.Id);
        
        // Fetch the inserted audit rec and confirm that facility was copied to client
        audit = [SELECT Name, Facility_Is_Client__c, Client_Audit_Account__c FROM Audit__c where ID = :audit.Id];
        system.assertEquals(audit.Client_Audit_Account__c, facility.Id);

		// Reset the checkbox, update, and confirm it was set by the trigger
		
		audit.Facility_Is_Client__c = false;        
        update audit;
        audit = [SELECT Name, Facility_Is_Client__c FROM Audit__c where ID = :audit.Id];
        system.assert(audit.Facility_Is_Client__c);
        
        // Now set flag for page edit, and test the encryption fields
        
        audit.XFlag__c = 1;				// Indicate that we are updating from a page edit
        audit.Patient_Last_Name__c = 'Johnson  '; // Last name, with some whitespace
        audit.Patient_First_Name__c = 'Joey';
        audit.Patient_DOBedit__c = date.valueOf('1962-06-06');
        audit.Patient_MR__c = '5678';
        
        // when we update, the original name 'Smith, John' will be overwritten
        
        update audit;
        audit = [SELECT Name, Patient_Name__c, Patient_DOB__c, Patient_MR__c, Patient_Account__c FROM Audit__c where ID = :audit.Id];
        
        // Save the values (unencrypted)
        String pname = audit.Patient_Name__c;
        String pdob = audit.Patient_DOB__c;
        String pmr = audit.Patient_MR__c;
        String pacct = audit.Patient_Account__c;
        
        // Confirm values
        
        system.assert(pname.equals('Johnson, Joey'));
        system.assert(pdob.equals('1962-06-06'));
        system.assert(pmr.equals('5678'));
        system.assert(pacct.equals('1234'));
        
        // Now get the HMAC fields
        audit = [SELECT Name, XN1__c, XN2__c, XN3__c, XN4__c, XPA__c, XPD__c, XPM__c, XPN__c, XFlag__c from Audit__c where ID = :audit.Id];
        
        // Confirm they all match the patient values
        String dset = 'Active';
        String xname = ePHIclass.decrypt(audit.XPN__c, dset);              
        system.assert(xname.equals(pname));	// The decrypted name from audit = original name?        
        String xdob = ePHIclass.decrypt(audit.XPD__c, dset);
        system.assert(xdob.equals(pdob));
        String xacct = ePHIclass.decrypt(audit.XPA__c, dset);
        system.assert(xacct.equals(pacct));
        String xmr = ePHIclass.decrypt(audit.XPM__c, dset);
        system.assert(xmr.equals(pmr));
        // Generate the search segments and confirm they match
        list<string> x = new string[4];
        ePHIclass.genxs(pname, x, dset);
        system.assert(x[0].equals(audit.XN1__c));
        system.assert(x[1].equals(audit.XN2__c));
        system.assert(x[2].equals(audit.XN3__c));
        system.assert(x[3].equals(audit.XN4__c));
        
        system.assert(audit.XFlag__c == 0);	// Ensure the flag is clear TODO: bit mask
        
        // Now test the Event creation and update, for both the audit and event triggers
        
        audit = [SELECT Date_Proposed_Exit__c, Exit_Mode__c, Exit_Duration__c, Assigned_Auditor__c, Assigned_Scheduler__c, Opposing_Scheduler__c FROM Audit__c WHERE Id = :audit.Id ];
        
        audit.Assigned_Auditor__c = (Id)UserInfo.getUserId();
        audit.Assigned_Scheduler__c = (Id)UserInfo.getUserId();
        Contact oppauditor = new Contact();
        oppauditor.FirstName = 'Alice';
        oppauditor.LastName = 'Jones';
        oppauditor.IsScheduler__c = True;
        oppauditor.IsAuditor__c = True;
        insert  oppauditor;
        audit.Opposing_Scheduler__c = oppauditor.Id;
        audit.Opposing_Auditor__c = oppauditor.Id;
        date meetingdate = date.today().addDays(30);	// In local time zone??
        time meetingtime = time.newInstance(9, 30, 0, 0); // 9:30 AM ??
        datetime loctime = datetime.newInstance(meetingdate, meetingtime);	// In local time
        audit.Date_Proposed_Exit__c = loctime;
        system.debug('Date set = ' + String.valueOf(loctime));
        audit.Exit_Duration__c = '1 Hour';
        audit.Exit_Mode__c = 'In Person - At Facility';
        update audit;
        audit = [SELECT Date_Proposed_Exit__c, EventGUID__c FROM Audit__c WHERE Id = :audit.Id];
        system.assert(audit.EventGUID__c != Null);	// Event created?
        system.debug('Date read back = ' + String.valueOf(audit.Date_Proposed_Exit__c));
        
        Event ev = [SELECT StartDateTime, DurationInMinutes, AuditGUID__c FROM Event WHERE AuditGUID__c = :audit.EventGUID__c];
        system.assertequals(ev.StartDateTime, audit.Date_Proposed_Exit__c);
        system.assertequals(ev.DurationInMinutes, 60);        
        datetime newday = loctime.addDays(2);		
        audit.Date_Proposed_Exit__c = newday;	// Now change the date on audit rec, forcing update of event
        update audit;
        ev = [SELECT StartDateTime, DurationInMinutes, AuditGUID__c FROM Event WHERE AuditGUID__c = :audit.EventGUID__c];
        system.assertequals(ev.StartDateTime, newday);                
	    // CHANGED 01/12: Calendar event update is now DECOUPLED from audit - the Proposed Date will not change
	    // if an auditor changes their calendar entry, although the change is logged	    
	    ev.StartDateTime = loctime.addDays(5);
	    update ev;	// Doing this for test coverage only
	    audit = [SELECT Date_Proposed_Exit__c, Exit_Duration__c FROM Audit__c WHERE Id = :audit.Id];
        system.assertequals(audit.Date_Proposed_Exit__c, newday );	// no change        
        
        audit.Date_Proposed_Exit__c = Null;		// Kill the meeting date on the audit, which will delete event
        update audit;
		audit = [SELECT Date_Proposed_Exit__c, EventGUID__c FROM Audit__c WHERE Id = :audit.Id];
		system.assertequals(audit.EventGUID__c, Null);
		try {
			ev = [SELECT Id, StartDateTime, DurationInMinutes, AuditGUID__c FROM Event WHERE Id = :ev.Id];
		} catch (System.Queryexception e) {
			system.Debug(e.getMessage());
		}
		audit.Date_Proposed_Exit__c = newday;	// Now set date again, which will create new Event rec
		update audit;
		audit = [SELECT Date_Proposed_Exit__c, EventGUID__c FROM Audit__c WHERE Id = :audit.Id];
        system.assert(audit.EventGUID__c != Null);	// Event created?
        ev = [SELECT StartDateTime, DurationInMinutes, AuditGUID__c FROM Event WHERE AuditGUID__c = :audit.EventGUID__c];
        system.assertequals(ev.StartDateTime, audit.Date_Proposed_Exit__c);
        // CHANGED 01/12: Direct deletion of calendar event is no longer permitted.
        // delete ev;	// Now kill the event directly
        // audit = [SELECT Date_Proposed_Exit__c, EventGUID__c FROM Audit__c WHERE Id = :audit.Id];
        // system.assertequals(audit.EventGUID__c, Null);	// Event deleted?
        // system.assertequals(audit.Date_Proposed_Exit__c, Null);
                
        // Finally, create a new audit and try setting the exit date during the insert (new feature a/o 8/10)
        
        Audit__c naudit = new Audit__c(); 
        
        naudit.Facility_Is_Client__c = true;
        naudit.Account__c = facility.Id;
        naudit.Client_Audit_Account__c = null;
        naudit.XFlag__c = 0;				// Don't do the crypto stuff yet
        naudit.Audit_Amount__c = 100;	// Fill in required fields
        naudit.Patient_Name__c = 'Lewis, John';
        naudit.Patient_Account__c = '1234';
        naudit.Service_Start_Date__c = date.today();
        naudit.Service_End_Date__c = date.today();  
        naudit.Assigned_Auditor__c = (Id)UserInfo.getUserId();
        naudit.Assigned_Scheduler__c = (Id)UserInfo.getUserId();
        naudit.Opposing_Scheduler__c = oppauditor.Id;
        naudit.Opposing_Auditor__c = oppauditor.Id;        
        newday = loctime.addDays(3);
        naudit.Date_Proposed_Exit__c = newday;
        naudit.Exit_Duration__c = '1 Hour';
        naudit.Exit_Mode__c = 'In Person - At Facility';
       
        insert naudit;
        test.stopTest();	// Force future methods to complete?
        naudit = [SELECT Date_Proposed_Exit__c, EventGUID__c FROM Audit__c WHERE Id = :naudit.Id];
        system.assert(naudit.EventGUID__c != Null);	// Event created?
        ev = [SELECT Id, WhatID, StartDateTime, DurationInMinutes, AuditGUID__c FROM Event WHERE AuditGUID__c = :naudit.EventGUID__c];
        system.assertequals(ev.WhatID, naudit.Id);
        system.assertequals(ev.StartDateTime, naudit.Date_Proposed_Exit__c);
        
       
    }
}