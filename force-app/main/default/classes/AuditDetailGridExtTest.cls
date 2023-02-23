@isTest
private class AuditDetailGridExtTest {
	

    static testMethod void AuditDetailGridUnitTest() {
        
        Audit__c audit = new Audit__c();	// Test Audit object
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
      	
      	AuditItem__c item1 = new AuditItem__c();
      	AuditItem__c item2 = new AuditItem__c();
      	
      	item1.Audit_Master__c = audit.Id;
      	item2.Audit_Master__c = audit.Id;
      	item1.Bill_Charge_Code__c = 'Item1';
      	item2.Bill_Charge_Code__c = 'Item2';
      	item1.Bill_Qty__c = 1;
      	item2.Bill_Qty__c = 1;
      	item1.Bill_Unit_Price__c = 50;
      	item2.Bill_Unit_Price__c = 150;
      	item1.Bill_Total__c = 50;
      	item2.Bill_Total__c = 150;
      	item1.Item_Description__c = 'This is item1';
      	item2.Item_Description__c = 'This is item2';
      	item1.Date_of_Service__c = date.today();
      	item2.Date_of_Service__c = date.today();
      	insert item1;
      	insert item2;      
        
        PageReference pg = Page.AuditDetailGrid;
        Test.setCurrentPage(pg);
        
        // Create a standard controller for Audit__c
        
        ApexPages.Standardcontroller astd = new ApexPages.Standardcontroller(audit);
         
        // Create the extension and bind it to the standard controller
        
        AuditDetailGridExt agrid = new AuditDetailGridExt(astd);
        system.debug('Account Name = ' + agrid.getAcctName());
        system.debug('Acct ID = ' + agrid.getAcctId());        
        system.assert(agrid.getAcctName().equals('Test Facility'));
        
		system.assert(agrid.getAuditViewPageRef() != null);		 
	    system.assert(agrid.getAuditEditPageRef() != null);     
	    system.assert(agrid.getNextEvent().equals('No events are currently scheduled')); 
	    system.assert(agrid.getNextTime().equals('')); 
	    system.assert(agrid.getEventPage() == null);
	     
	    system.assert(agrid.getOpposingFirm().equals('(None Specified)')); 
	    system.assert(agrid.getOpposingAuditor().equals('(None Specified)')); 
	    system.assert(agrid.getOpposingScheduler().equals('(None Specified)')); 
	    system.assert(agrid.getAcctOwnerName() != null); 
	    system.assert(agrid.getAcctOwnerPage() != null); 
	    system.assert(agrid.getMRContact().equals('(none specified)')); 
	    system.assert(agrid.getDOS().length() == 10); 
	    
	    system.assert(agrid.getIsMRConPage() == false); 
	    system.assert(agrid.getMRConPage() == null); 
	    system.assert(agrid.getIsOppFirmPage() == false); 
	    system.assert(agrid.getOppFirmPage() == null); 
	    system.assert(agrid.getIsOppAuditorPage() == false); 
	    system.assert(agrid.getOppAuditorPage() == null);
	    system.assert(agrid.getIsOppSchedulerPage() == false); 
	    system.assert(agrid.getOppSchedulerPage() == null);
	    system.assert(agrid.getAuditorName().equals('NOT ASSIGNED')); 
	    system.assert(agrid.getIsAuditorPage() == false); 
	    system.assert(agrid.getAuditorPage() == null); 
	    system.assert(agrid.getAuditCanExit() == 'false');     
       	
       	// Update audit fields
       	
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
        Contact fc = new Contact();
        fc.FirstName = 'Bob';
        fc.LastName = 'Smith';
        insert fc;
        audit.Facility_Billing_Contact__c = fc.Id;
        audit.Facility_MR_Contact__c = fc.Id;
        Account oppfirm = new Account (Name = 'The Firm');
        oppfirm.Opposing_Audit_Account__c = true;
        insert oppfirm;
        audit.Opposing_Audit_Account__c = oppfirm.Id; 
        date meetingdate = date.today().addDays(30);	// In local time zone??
        time meetingtime = time.newInstance(9, 30, 0, 0); // 9:30 AM ??
        datetime loctime = datetime.newInstance(meetingdate, meetingtime);	// In local time
        audit.Date_Proposed_Exit__c = loctime;
        system.debug('Date set = ' + String.valueOf(loctime));
        audit.Exit_Duration__c = '1 Hour';
        audit.Exit_Mode__c = 'In Person - At Facility';
        audit.Service_End_Date__c = date.today().addDays(10);
        
        update audit;
        
        AuditDetailGridExt agrid2 = new AuditDetailGridExt(astd);
		
		system.debug('Account Name = ' + agrid.getAcctName());
        system.debug('Acct ID = ' + agrid.getAcctId());        
        system.assert(agrid2.getAcctName().equals('Test Facility'));
        
		system.assert(agrid2.getAuditViewPageRef() != null);		 
	    system.assert(agrid2.getAuditEditPageRef() != null);     
	    system.assert(agrid2.getNextEvent() != 'No events are currently scheduled'); 
	    system.assert(agrid2.getNextTime() != ''); 
	    system.assert(agrid2.getEventPage() != null);
	     
	    system.assert(agrid2.getOpposingFirm().equals('The Firm')); 
	    system.assert(agrid2.getOpposingAuditor().equals('Alice Jones')); 
	    system.assert(agrid2.getOpposingScheduler().equals('Alice Jones')); 
	    system.assert(agrid2.getMRContact().equals('Bob Smith')); 
	    system.assert(agrid2.getDOS().length() > 10); 
	    
	    system.assert(agrid2.getIsMRConPage() == true); 
	    system.assert(agrid2.getMRConPage() != null); 
	    system.assert(agrid2.getIsOppFirmPage() == true); 
	    system.assert(agrid2.getOppFirmPage() != null); 
	    system.assert(agrid2.getIsOppAuditorPage() == true); 
	    system.assert(agrid2.getOppAuditorPage() != null);
	    system.assert(agrid2.getIsOppSchedulerPage() == true); 
	    system.assert(agrid2.getOppSchedulerPage() != null);
	    system.assert(agrid2.getAuditorName() != ''); 
	    
	    List <AuditDetailGridExt.BillItem> theBill = new List<AuditDetailGridExt.BillItem>();
	    theBill = AuditDetailGridExt.fetchBill(audit.Id, 'all');
	    AuditDetailGridExt.UpdateResponse up = new AuditDetailGridExt.UpdateResponse();
	    up = AuditDetailGridExt.updateItem('1', item1.Id, 'O', '0', '0', '-50', '0', '0', 'true');
	    up = AuditDetailGridExt.updateItem('1', item1.Id, '', '', '', '', '', '', 'false');
	    AuditDetailGridExt.DeptList[] dl = new List<AuditDetailGridExt.DeptList>();
	    dl = AuditDetailGridExt.fetchDepts('true');
	    String aid = audit.Id;
	    String ccode = '123456';
	    String bdesc = 'This is a medical item';
	    String dos = String.valueOf(date.today());
	    Department__c objdept = new Department__c();
	    objdept.name ='MM';
	    objdept.Description__c ='Test Dept';
	    insert objdept;
	    Department__c dep = [SELECT Id from Department__c where Name = 'MM'];
	    String dept= dep.Id;
	    String rcode = 'X1';
	    String bqty = '1';
	    String uc = '100';
	    String btot = '100';
	    AuditDetailGridExt.AddItemResponse ar = new AuditDetailGridExt.AddItemResponse();
	    ar = AuditDetailGridExt.addLineItem(aid,ccode,bdesc,dos,dept,rcode,bqty,uc,btot);
	    //system.assert(ar.AId == audit.Id);
	    
	    String uf = AuditDetailGridExt.updateBillFlags(audit.Id, 'true', 'false');
	    system.assert(uf == 'done');
	    
	                    
    }
}