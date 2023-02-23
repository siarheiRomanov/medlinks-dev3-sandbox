/**
 Adapted from AuditItemTriggerTest
 */
@isTest
private class AuditCaseRptExtTest {

    static testMethod void AuditCaseRptExtUnitTest() {
    	
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
        auditMCR.Audit_Stage__c = 'Pending';
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
        auditCOM.Audit_Stage__c = 'Pending';
        insert auditCOM;
        
        // Create a fake department master
        Department__c[] deps = new Department__c[] {};
        for (Integer n = 0; n<10; n++) {
        	Department__c dep = new Department__c();
        	dep.Name = 'Dept' + String.valueOf(n);
        	dep.Description__c = 'This is a medical department';
        	deps.add(dep);
        }
        insert deps;
        
        // Create 10 CDM Item and Audit Item recs for each Audit
        
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
        	cc1.Audit_Dept__c = deps[n].Id;					// Set the Audit Dept ref
			cc2.Name = 'TestCDMItem' + String.valueof(n);	// Name the items
        	cc2.CDM_Master__c = cdmcurrent.Id;
        	cc2.Audit_Dept__c = deps[n].Id;					// Set the Audit Dept ref
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
      	
      	// Now 'edit' half the items (in current CDM set only)
      	
      	List <AuditItem__c> COMitems = new List <AuditItem__c>(
        [Select Id, Audit_Master__c, Flagged__c, Err_Code__c, Bill_Qty__c, Qty_MR__c, Qty_MD__c,
         Qty_Disallowed__c,Qty_Disputed__c,Qty_Adj_Other__c,MR_Flag__c,Adj_Other_Code__c from AuditItem__c
         WHERE Audit_Master__c = :AuditCOM.Id ORDER BY Bill_Charge_Code__c]);
        Integer ii = 0;
        for (AuditItem__c ai: COMitems) {
		    if (ii < 2) {		    
		        ai.MR_Flag__c = true;   
                ai.Qty_MR__c = ai.Bill_Qty__c-1;
                ai.Qty_MD__c = ai.Bill_Qty__c-1-ii;
                ai.Qty_Adj_Other__c = 0;
                ai.Adj_Other_Code__c = Null;
                ai.Qty_Disputed__c = 0;
                ai.Qty_Disallowed__c = 0;
            }
            else if (ii == 2) {
                ai.MR_Flag__c = false;  // Disputed - special
                ai.Qty_MR__c = 0;
                ai.Qty_MD__c = 0;
                ai.Qty_Adj_Other__c = 0;
                ai.Adj_Other_Code__c = 'D';
                ai.Qty_Disputed__c = ai.Bill_Qty__c;    // Entire bill qty??
                ai.Qty_Disallowed__c = 0; 
            }
            else if (ii == 3) {
                ai.MR_Flag__c = false;  // Contractually disallowed - seperate field
                ai.Qty_MR__c = ai.Bill_Qty__c-1;
                ai.Qty_MD__c = ai.Qty_MR__c;    // MD=MR?
                ai.Qty_Disallowed__c = 1; // Get separate amt!
                ai.Qty_Adj_Other__c = 0;
                ai.Qty_Disputed__c = 0;
                ai.Adj_Other_Code__c = 'C';
            }
            else if (ii == 4) {
            	ai.MR_Flag__c = false; // All other adj types
                ai.Qty_MR__c = ai.Bill_Qty__c-1;
                ai.Qty_MD__c = ai.Qty_MR__c;    // ASSUME MD=MR 
                ai.Qty_Adj_Other__c = -1;  // Adj = +-delta
                ai.Adj_Other_Code__c = 'M1';
                ai.Qty_Disputed__c = 0;
                ai.Qty_Disallowed__c = 0;                       
            }
            ii++;           
        }
        update COMitems;
      	
      	PageReference pg = Page.AuditCaseReport;
        Test.setCurrentPage(pg);
        
        // Create a standard controller for Audit__c
        
        ApexPages.Standardcontroller astd = new ApexPages.Standardcontroller(auditCOM);
         
        // Create the extension and bind it to the standard controller
        
        AuditCaseRptExt arep = new AuditCaseRptExt(astd);
      
    	// The constructor does all the work, so that's all we need...
    
    }
}