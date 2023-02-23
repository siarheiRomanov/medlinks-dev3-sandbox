public class CDMSearchController {
	private boolean gotCDM;
	private boolean askCurrent;
	private CDM__c cdm;
	private String edates;
	private String scode;
	private String sdesc;
	private String idate;
	public ApexPages.Standardsetcontroller con{get; set;}
	
	public List<CDMItem__c> CDMItemList {
		get {
			if (con != null)
				return(List<CDMItem__c>)con.getRecords();
			else
				return null;
		}
		set;
	}
	
	public CDMSearchController() {
		CDMItemList = new List<CDMItem__c>();
		PageReference pageRef = ApexPages.currentPage();
		ID aid = pageRef.getParameters().get('acct');
		idate = pageRef.getParameters().get('date');
		Date dt = Date.valueOf(idate + ' 12:00:00');		
		scode = pageRef.getParameters().get('code');
		sdesc = pageRef.getParameters().get('desc');
		Account a = [SELECT Id, Name, CDM_Start_Date__c from Account WHERE Id = :aid];
		try {
			cdm = [SELECT Id, Name, Effective_Date_Start__c, Effective_Date_End__c, Facility__c, Item_Count__c
				 FROM CDM__c WHERE Facility__c = :aid			 
				 AND ((Effective_Date_Start__c <= :dt
				     AND Effective_Date_End__c = NULL)
				   OR (Effective_Date_Start__c <= :dt
				     AND Effective_Date_End__c >= :dt))];
		}
		catch (Exception e){
			cdm = null;
		}			     			     			     			    			    
		if (cdm == null) {
			// No corresponding CDM
			if (a.CDM_Start_Date__c != null) {
				askCurrent = true;	// Ask if current CDM should be used instead
				cdm = [SELECT Id, Name, Effective_Date_Start__c, Effective_Date_End__c, Facility__c, Item_Count__c
			 	FROM CDM__c WHERE Facility__c = :aid AND Effective_Date_Start__c = :a.CDM_Start_Date__c];				
			}
			gotCDM = false;	// indicate to page that no matching CDM exists
		}
		else {
			gotCDM = true;
			Time t = Time.newInstance(0,0,0,0); // Stupid API
       		Datetime dts = Datetime.newInstance(cdm.Effective_Date_Start__c, t);
       		edates = dts.format('M-dd-yyyy') + ' to ';        
        	if (cdm.Effective_Date_End__c == null) {
        		edates += 'Current';        	
        	}
        	else {
        		Datetime dte = Datetime.newInstance(cdm.Effective_Date_End__c, t);           
        		edates += dte.format('M-dd-yyyy');        	
        	}
		}
	}
	
	private String sclean(String s) {
		Integer i = s.indexOf('*');
		if (i >= 0) {
			s = s.replace('*', '%');				
		}
		if (s.endsWith('%')) {
			s = s.substring(0,s.length()-1);	
		}
		return s;
	}
	
	public PageReference doSearch() {   
    	system.debug('****doSearch: code=' + scode + ' desc=' + sdesc);
    	scode = (scode == null)? '': sclean(scode);
    	sdesc = (sdesc == null)? '': sclean(sdesc);
		if (scode != '' || sdesc != '') {
        	String qry = 'SELECT Id,Name,Charge_Amount__c,Billing_Description__c,Charge_Description__c,Audit_Dept__c,Audit_Dept__r.Name,CDM_Master__c FROM CDMItem__c WHERE CDM_Master__c = \''+cdm.ID+'\' AND ';
        	if (scode != '') {
				qry += 'Name LIKE \'' + scode + '%\'';        		
        	}
        	if (sdesc != '') {
        		if (scode != '')
					qry += ' AND ';
				qry += '(Billing_Description__c LIKE \'' + sdesc + '%\' OR Charge_Description__c LIKE \'' + sdesc + '%\') '; 
        	}
        	system.debug('****Qry='+qry);        	
            con = new ApexPages.StandardSetController(Database.getQueryLocator(qry)); 
            // sets the number of records in each page set
            con.setPageSize(10);
        }
        else {
        
            con = null;
        }
        return null ;
    }
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }
 
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }
 
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

    public void previous(){
        con.previous();
    }
 
    public void next(){
        con.next();
    }
    
    
	public CDM__c getcdm() {
		return cdm;
	}
	public String getScode(){
		return scode;
	}
	public void setScode(String s){
		scode = s;
	}
	
	public String getSdesc(){
		return sdesc;
	}
	public void setSdesc(String s){
		sdesc = s;
	}
	
	public String getItemDate() {
		return idate;
	}
	public String getdates() {
		return edates;
	}
	public Boolean getGotCDM() {
		return gotCDM;
	}
	public Boolean getAskCurrent() {
		return askCurrent;
	}
			

}