/**
 * This class contains unit tests for validating the behavior of AuditEditExtension.cls
 */
@isTest
private class AuditExtensionTest {

    static testMethod void AuditExtensionUnitTest() {
        
        Audit__c audit = new Audit__c();	// Test Audit object
        
        // Initial test is for new, null Audit
        
        // Create a standard controller for Audit__c
        
        ApexPages.Standardcontroller astd = new ApexPages.Standardcontroller(audit);
         
        // Create the extension and bind it to the standard controller
        
        AuditEditExtension aext1 = new AuditEditExtension(astd);
        
        // Confirm 'new account' state
        
        //system.assert(aext1.getPageMode().equals('Creating New Record'));
        system.assert(aext1.getFacility().equals('No Faciltiy Specified'));
        system.assert(aext1.getFCalert().equals('false'));
        system.assert(aext1.getIsNew() == true);
        
        // Now update Audit object to represent an edit
        
        audit.Audit_Amount__c = 100;	// Fill in required fields (not needed?)
        audit.Patient_Name__c = 'Smith, John';
        audit.Patient_Account__c = '1234';
        audit.Patient_DOB__c = '1984-02-14';	// Not required, but set it to test code
        audit.Service_Start_Date__c = date.today();
        audit.Service_End_Date__c = date.today();        
        audit.XFlag__c = 0;				
        
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
               
        
        audit.Facility_Is_Client__c = false;
        audit.Account__c = facility.Id;				// Set both facility and client, to satify the audit validaters        
        audit.Client_Audit_Account__c = client.Id;
       
        insert audit;
        system.debug('audit inserted, ID = ' + audit.Id);
      
       	// Now create a new extension object to process the new data in the audit rec
       	 
		AuditEditExtension aext2 = new AuditEditExtension(astd);

        // Confirm 'edit account' state
        
        //system.assert(aext2.getPageMode().contains('1234'));	// Patient account in text string
        system.assert(aext2.getFacility().equals('Test Facility'));
        system.assert(aext2.getFCalert().equals('true'));
        		        
        
        // End of unit test
    }
}