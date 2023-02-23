@isTest
private class CDMpopupExtTest {

    static testMethod void CDMpopupUnitTest() {
		
		Account a = new Account();
		a.Name = 'Test Account';
		a.Auditable__c = true;
		a.Audit_Client__c = true;
		a.Shortname__c = 'TEST';
		insert a;
		CDM__c cm  = new CDM__c();
		cm.Facility__c = a.Id;
		cm.Effective_Date_Start__c = date.today().addDays(-30);
		cm.Name = 'CDM Master';
		insert cm;
		        
        CDMItem__c ci = new CDMItem__c();
        ci.CDM_Master__c = cm.Id;
        system.debug('CDM id=' + ci.CDM_Master__c);
        ci.Charge_Amount__c = 1000;
        ci.Name = 'Test Item';
        insert ci;
        ci=[SELECT Id, CDM_Master__r.Effective_Date_Start__c, CDM_Master__r.Effective_Date_End__c from CDMItem__c WHERE Id = :ci.Id];
        system.debug('ci='+ci.Id);
        system.debug('date='+ci.CDM_Master__r.Effective_Date_Start__c.format());
        PageReference pg = Page.CDMpopup;
        Test.setCurrentPage(pg);       
        // Create a standard controller for CDM Items
        
        ApexPages.Standardcontroller astd = new ApexPages.Standardcontroller(ci);
         
        // Create the extension and bind it to the standard controller
        
        CDMpopupExt ex = new CDMpopupExt(astd);
        
        system.debug(ex.getdates());
        
    }
}