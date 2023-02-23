public with sharing class CDMpopupExt {
	private final CDMItem__c cdmitem;
	private String edates;
		
	public CDMpopupExt(ApexPages.StandardController stdController) {
        this.cdmitem = (CDMItem__c)stdController.getRecord();
        system.debug('CDMpopupExt constructor');
        Time t = Time.newInstance(0,0,0,0); // Stupid API
        Datetime ds = Datetime.newInstance(cdmitem.CDM_Master__r.Effective_Date_Start__c, t);
       	edates = ds.format('M-dd-yyyy') + ' to ';
        
        if (cdmitem.CDM_Master__r.Effective_Date_End__c == null) {
        	edates += 'Current';        	
        }
        else {
        	Datetime de = Datetime.newInstance(cdmitem.CDM_Master__r.Effective_Date_End__c, t);           
        	edates += de.format('M-dd-yyyy');        	
        }
	}
	public String getdates() {
		return edates;
	}
}