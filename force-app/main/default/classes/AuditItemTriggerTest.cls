/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AuditItemTriggerTest {

	Static Final Integer ERR_NO_CDM = (1<<0);	// Bit number
	Static Final Integer ERR_PRICE = (1<<1);
	Static Final Integer ERR_DATE = (1<<2);
  
    static testMethod void AuditItemTriggerUnitTest() {
    	    	  
        Account facility = new Account(name = 'Test Facility');
         // Must set fields so that we pass validation
        facility.Auditable__c = true;
        facility.Audit_Client__c = true;
        facility.Shortname__c = 'TEST';        
        insert facility;		// Create test account
        CDM__c cdmcurrent = new CDM__c();	// Create 2 CDM masters, one for 2010, one for 2011
    	CDM__c cdmold = new CDM__c();
    	cdmcurrent.Facility__c = facility.Id;
    	cdmcurrent.Effective_Date_Start__c = Date.valueOf('2011-01-01');
    	cdmcurrent.Effective_Date_End__c = Null;
    	cdmold.Facility__c = facility.Id;
    	cdmold.Effective_Date_Start__c = Date.valueOf('2010-01-01');
    	cdmold.Effective_Date_End__c = Date.valueOf('2010-12-31');
    	insert cdmold;
    	insert cdmcurrent;
        
        Audit__c auditMCR = new Audit__c();		// Create a couple audits
        Audit__c auditCOM = new Audit__c();
        
        auditMCR.Payer_Type__c = 'MCR';	// Payer is Medicare                
        auditMCR.Facility_Is_Client__c = true;
        auditMCR.Account__c = facility.Id;
        auditMCR.Client_Audit_Account__c = null;
        auditMCR.XFlag__c = 0;			// Don't do the crypto stuff
        auditMCR.Audit_Amount__c = 100;	// Fill in required fields
        auditMCR.Patient_Name__c = 'Smith, John';
        auditMCR.Patient_Account__c = '1234';
        auditMCR.Service_Start_Date__c = date.valueOf('2010-12-15');
        auditMCR.Service_End_Date__c = date.valueOf('2011-01-15');		// Span two CDMs
        insert auditMCR;
        
        auditCOM.Payer_Type__c = 'COM'; // Payer is Commercial
      	auditCOM.Facility_Is_Client__c = true;
        auditCOM.Account__c = facility.Id;
        auditCOM.Client_Audit_Account__c = null;
        auditCOM.XFlag__c = 0;			// Don't do the crypto stuff
        auditCOM.Audit_Amount__c = 100;	// Fill in required fields
        auditCOM.Patient_Name__c = 'Smith, John';
        auditCOM.Patient_Account__c = '1234';
        auditCOM.Service_Start_Date__c = date.valueOf('2011-02-14');        
        auditCOM.Service_End_Date__c = date.valueOf('2011-06-06');
        insert auditCOM;
        
        // Create 10 CDM Item and Audit Item recs for each Audit by using random CDMItems as templates
        
        Audit__c[] master = new Audit__c[] {auditMCR, auditCOM};
        String[] payer = new String [] {'MCR', 'COM'};
        
        List <CDMItem__c> testcdms1 = new List <CDMItem__c>();
        List <CDMItem__c> testcdms2 = new List <CDMItem__c>();
        
        // Revised 8/5/11 to NOT use existing CDM data...
        for (Integer n = 0; n<10; n++) {
        	CDMItem__c cc1 = new CDMItem__c();
        	CDMItem__c cc2 = new CDMItem__c();
        	cc1.Name = 'TestCDMItem' + String.valueof(n);	// Name the items
        	cc1.CDM_Master__c = cdmold.Id; 					// And point it to the test parent
			cc2.Name = 'TestCDMItem' + String.valueof(n);	// Name the items
        	cc2.CDM_Master__c = cdmcurrent.Id;
        	cc1.Charge_Amount__c = (n+1)*100;
        	cc2.Charge_Amount__c = (n+1)*100;
        	cc1.MCR_HCPCS_Code__c = 'mcrhcpcs' + String.valueof(n);
			cc2.MCR_HCPCS_Code__c = cc1.MCR_HCPCS_Code__c;
			cc1.COM_HCPCS_Code__c = 'comhcpcs' + String.valueof(n);
			cc2.COM_HCPCS_Code__c = cc1.COM_HCPCS_Code__c;
			cc1.MCR_Rev_Code__c = null;	// Skip the rev codes...
			cc2.MCR_Rev_Code__c = null;
			cc1.COM_Rev_Code__c = null;
			cc2.COM_Rev_Code__c = null;
			testcdms1.add(cc1);
			testcdms2.add(cc2);			        	
        }                
        insert testcdms1;                
        insert testcdms2;
        
		// Must re-fetch the inserted CDM items        
        Set<Id> s1 = new Set<Id>();
        Set<Id> s2 = new Set<Id>();
        for (CDMItem__c tcdm: testcdms1) {
        	s1.add(tcdm.Id);
        }
        for (CDMItem__c tcdm: testcdms2) {
        	s2.add(tcdm.Id);
        }
        
        for (integer i = 0; i<10; i++) {
        	system.debug('Name1 = ' + testcdms1[i].Name + 'Name2 = ' + testcdms2[i].Name);
        }
        
        testcdms1 = new List <CDMItem__C>([Select Id, Name, CDM_Master__c, Charge_Amount__c, MCR_HCPCS_Code__c, MCR_Rev_Code__c, COM_HCPCS_Code__c, COM_Rev_Code__c from CDMItem__c WHERE Id IN :s1]);
        testcdms2 = new List <CDMItem__C>([Select Id, Name, CDM_Master__c, Charge_Amount__c, MCR_HCPCS_Code__c, MCR_Rev_Code__c, COM_HCPCS_Code__c, COM_Rev_Code__c from CDMItem__c WHERE Id IN :s2]);
        
        List <AuditItem__c> items = new List <AuditItem__c>();
        
        for (integer i = 0; i < 2; i++) {
        	Audit__c audit = master[i];
        	for (integer j = 0; j < 10 ; j++) {
        		// Create the test item
        		AuditItem__c item = new AuditItem__c();
        		if (i == 0){
        			date d = date.valueOf('2010-12-27').addDays(j);	// Generate service date that spans both CDMs
        			item.Date_of_Service__c = d;
        			if (d.year() == 2010) {
        				item.Bill_Charge_Code__c = testcdms1[j].Name;		// Use older CDM
        				item.Bill_Unit_Price__c = testcdms1[j].Charge_Amount__c;
        			}
        			else {
        				item.Bill_Charge_Code__c = testcdms2[j].Name;		// Use newer CDM
        				item.Bill_Unit_Price__c = testcdms2[j].Charge_Amount__c;        				
        			}
        		}
        		else {
        			item.Bill_Charge_Code__c = testcdms2[j].Name;		// Second set uses only newer CDM
        			item.Bill_Unit_Price__c = testcdms2[j].Charge_Amount__c;
        			item.Date_of_Service__c = date.valueOf('2011-05-01').addDays(j);	
        		}
        		item.Bill_Qty__c = j+1;		// Qty goes from 1 to 10
        		item.Bill_Total__c = item.Bill_Unit_Price__c * item.Bill_Qty__c;	// Generate good numbers
        		item.Audit_Master__c = audit.iD;	// Parent master
        		// Add to list
        		items.add(item); 
        	}        	
        }
      	
      	insert items;	// Add all 20 and fire off the trigger
      	
      	// First, confirm the add of 10 recs to each master
      	
      	List <AuditItem__c> MCRitems = new List <AuditItem__c>(
      	[SELECT Id, Date_Of_Service__c, Bill_Charge_Code__c, CDM_Charge_Code__c, CDM_HCPCS_Code__c, CDM_Rev_Code__c, Err_Code__c, Flagged__c from AuditItem__c
      	WHERE Audit_Master__c = :AuditMCR.Id ORDER BY Bill_Charge_Code__c]);
        List <AuditItem__c> COMitems = new List <AuditItem__c>(
        [SELECT Id, Date_Of_Service__c, Bill_Charge_Code__c, CDM_Charge_Code__c, CDM_HCPCS_Code__c, CDM_Rev_Code__c, Err_Code__c, Flagged__c from AuditItem__c
        WHERE Audit_Master__c = :AuditCOM.Id ORDER BY Bill_Charge_Code__c]);
        
        system.assertequals(MCRitems.size(), 10);
        system.assertequals(COMitems.size(), 10);
        
        // Examine the items and confirm that values were set according to payer code
        
        for (integer i = 0; i < 10; i++) {
        	Integer y = MCRitems[i].Date_Of_Service__c.year();
        	if (y == 2010) {        	
	        	system.assertequals(MCRitems[i].CDM_Charge_Code__c, testcdms1[i].Id);	// Older CDM
	        	system.assertequals(MCRitems[i].CDM_HCPCS_Code__c, testcdms1[i].MCR_HCPCS_Code__c);
	        	//system.assertequals(MCRitems[i].CDM_Rev_Code__c, testcdms1[i].MCR_Rev_Code__c);
        	}
        	else {
	        	system.assertequals(MCRitems[i].CDM_Charge_Code__c, testcdms2[i].Id);	// Newer CDM
	        	system.assertequals(MCRitems[i].CDM_HCPCS_Code__c, testcdms2[i].MCR_HCPCS_Code__c);
	        	//system.assertequals(MCRitems[i].CDM_Rev_Code__c, testcdms2[i].MCR_Rev_Code__c);
        	}
        	
        	system.assertequals(COMitems[i].CDM_Charge_Code__c, testcdms2[i].Id);
        	system.assertequals(COMitems[i].CDM_HCPCS_Code__c, testcdms2[i].COM_HCPCS_Code__c);
        	//system.assertequals(COMitems[i].CDM_Rev_Code__c, testcdms2[i].COM_Rev_Code__c);        	
        	
        	// Confirm no errors
        	system.assertequals(MCRitems[i].Err_Code__c, 0);
        	system.assertequals(COMitems[i].Err_Code__c, 0);
        	system.assertequals(MCRitems[i].Flagged__c, False);
        	system.assertequals(COMitems[i].Flagged__c, False);        	
        }
        // Now create some error conditions
        
        AuditItem__c item1 = new AuditItem__c();
        item1.Bill_Charge_Code__c = 'foo';				// Bad charge code
        item1.Bill_Unit_Price__c = testcdms2[0].Charge_Amount__c;
        item1.Bill_Qty__c = 1;
        item1.Bill_Total__c = testcdms2[0].Charge_Amount__c;	
        item1.Audit_Master__c = auditCOM.iD;			// Parent master
        item1.Date_of_Service__c = date.today();
        insert item1;
        item1 = [SELECT Err_Code__c, Flagged__c FROM AuditItem__c WHERE Id = :item1.Id];
        Integer f = item1.Err_Code__c.intValue(); 
		System.assert((f & ERR_NO_CDM) != 0);
		System.assert(item1.Flagged__c == True);			
        
        item1.clear();
        item1.Bill_Charge_Code__c = testcdms2[0].Name;	// Fix the CDM code
		item1.Bill_Unit_Price__c = .39;				// Change the price - this will cause multiple errors
		item1.Bill_Qty__c = 1;
        item1.Bill_Total__c = testcdms2[0].Charge_Amount__c;	
        item1.Audit_Master__c = auditCOM.iD;			// Parent master
        item1.Date_of_Service__c = date.today();        
		insert item1;
        item1 = [SELECT Err_Code__c, Flagged__c, Bill_Unit_Price__c, Bill_UP_Override__c FROM AuditItem__c WHERE Id = :item1.Id];
        f = item1.Err_Code__c.intValue(); 
		System.assert((f & ERR_PRICE) != 0);
		System.assert(item1.Flagged__c == True);			
        System.assertequals(item1.Bill_Unit_Price__c, testcdms2[0].Charge_Amount__c);
        System.assert(item1.Bill_UP_Override__c == True);
		
		item1.clear();
        item1.Bill_Charge_Code__c = testcdms2[0].Name;	
		item1.Bill_Unit_Price__c = testcdms2[0].Charge_Amount__c;
        item1.Bill_Qty__c = 1;
        item1.Bill_Total__c = testcdms2[0].Charge_Amount__c;	// Generate good numbers
        item1.Audit_Master__c = auditCOM.iD;			// Parent master        				       
        item1.Date_of_Service__c = date.today()- 7;		// Bad date
        insert item1;
        item1 = [SELECT Err_Code__c, Flagged__c FROM AuditItem__c WHERE Id = :item1.Id];
        f = item1.Err_Code__c.intValue(); 
		System.assert((f & ERR_DATE) != 0);
		System.assert(item1.Flagged__c == True);			       
                        
    }
}