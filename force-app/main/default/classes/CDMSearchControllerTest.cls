@isTest
private class CDMSearchControllerTest {

    static testMethod void myUnitTest() {

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
        ci.Name = 'Test Code';
        ci.Billing_Description__c = 'Test Item';
        ci.Charge_Description__c = 'Test Item';       
        insert ci;
        ci=[SELECT Id, CDM_Master__r.Effective_Date_Start__c, CDM_Master__r.Effective_Date_End__c from CDMItem__c WHERE Id = :ci.Id];
        system.debug('ci='+ci.Id);
        system.debug('date='+ci.CDM_Master__r.Effective_Date_Start__c.format());
        
        PageReference pg = Page.CDMsearch;        
        Test.setCurrentPage(pg);       
        ApexPages.CurrentPage().getParameters().put('acct', a.Id);
   		ApexPages.CurrentPage().getParameters().put('date', String.valueOf(date.today()));
   		ApexPages.CurrentPage().getParameters().put('code', '');
   		ApexPages.CurrentPage().getParameters().put('desc', 'Test');   				        
        CDMSearchController scon = new CDMSearchController();
        system.assert(scon.getGotCDM() == true);
        scon.doSearch();
        List<CDMItem__c> cil = scon.CDMItemList;
        system.assert(cil.size() == 1);
        system.assert(scon.hasNext == false);
        system.assert(scon.hasPrevious == false);
        system.assert(scon.pageNumber == 1);
        system.assert(scon.getcdm().Id == cm.Id);
        scon.setScode('Code2');
        system.assert(scon.getScode() == 'Code2');
        scon.setSdesc('Desc2');
        system.assert(scon.getSdesc() == 'Desc2');
        String gid = scon.getItemDate();
        String eds = scon.getdates();
        Boolean ba = scon.getAskCurrent();               
    }
}