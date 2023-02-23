public with sharing class AccountAuditViewExt {

    private final Account acct;
    private PageReference StdAcctPage;
    private PageReference evPage;
    private PageReference fcConPage;
    private PageReference mrConPage;
	private Boolean isFCPage;
	private Boolean isMRPage;
    private String nextEvent;
    private String nextTime;
    private String qs;
    private String AuditFields;
    private String AccType;
    private String SelectedAuditor;
	private Set <Id> ourguys;
    private Set <Id> theirguys;
	private List<User> assignedAuditors;
	private List<Contact> opposingAuditors;
    private transient List<Audit__c> AuditorList;
    private List<Audit__c> NullAuditList = new List<Audit__c>();
    private Boolean isFacility = FALSE;
    private String fcName;
    private String fcTel;
    private String fcEmail;
    private String mrLabel;
    private String mrName;
    private String mrTel;
    private String mrEmail;
	private Double	NumPending;
	private Decimal AmtPending;        		
	private Double	NumScheduled;
	private Decimal AmtScheduled;
	private Double	NumExited;
	private Decimal AmtExited;
	private Double	NumDisputed;
	private Decimal AmtDisputed;
	private Double	NumAppealed;
	private Decimal AmtAppealed;
	private Double	NumTotal;
	private Decimal AmtTotal;
	private Boolean AllTabRenderFlag;
	private Boolean PendingTabRenderFlag;	
	private Boolean ScheduledTabRenderFlag;
	private Boolean ExitedTabRenderFlag;
	private Boolean DisputedTabRenderFlag;
	private Boolean AppealedTabRenderFlag;
	private Boolean ClosedTabRenderFlag;
	private Boolean CanceledTabRenderFlag;
	private Boolean SearchTabRenderFlag;
	private Boolean MyAuditsOnly = false;
	
	public PageReference testAuditable() {	// Action test upon page load
		ID acid = ApexPages.currentPage().getParameters().get('Id');
		Account a = [SELECT Id, Auditable__c, Audit_Client__c, Opposing_Audit_Account__c from Account WHERE Id = :acid];
		if (a.Auditable__c || a.Audit_Client__c || a.Opposing_Audit_Account__c) {
			return null;
		}
		else {
			PageReference p = new PageReference('/apex/AccountDetail?id=' + acid);
			p.setRedirect(true); 
			return p;
		}
	}
	        
    public AccountAuditViewExt(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
        // Determine account type and set the appropriate audit query filter
        if (acct.Auditable__c == TRUE) {
            qs = 'Account__c';
            AccType = 'Auditable Facility';
            isFacility = TRUE;
            if (acct.Audit_Client__c == FALSE) {
            	AccType += ' (non-client)';
            }           
        }
        else if (acct.Audit_Client__c == TRUE) {
            qs = 'Client_Audit_Account__c';
            AccType = 'Audit Client';
        }
        else if (acct.Opposing_Audit_Account__c == TRUE) {
            qs = 'Opposing_Audit_Account__c';
            AccType = 'Opposing Firm';
        }
        else {
        	qs = Null;
        	AccType = 'Non-client Account';
        }
        String evquery;
        ID cuid = UserInfo.getUserId();
        User curu = [Select Id, Limited_License__c, User_is_Auditor__c from User WHERE id = : cuid];     
        List<Audit__c> AuditList = new List<Audit__c>();
        ID acid = acct.Id; 	       	              	
        if (qs != Null) {	// Account has (or may have) audits
        	AuditFields = 'SELECT Id, Name, Patient_Name__c, Patient_Account__c, Audit_Stage__c, Audit_Type__c, Audit_Role__c, Date_LOI__c, Date_Proposed_Exit__c,';
        	AuditFields += 'Date_Actual_Exit__c, Assigned_Auditor__c, Assigned_Auditor__r.Name, Opposing_Auditor__c, Opposing_Auditor__r.Name, Audit_Amount__c';
        	String audquery = AuditFields + ', Account__c, Client_Audit_Account__c, Opposing_Audit_Account__c from Audit__c WHERE ' + qs + ' = :acid';
        	
        	if (curu.Limited_License__c) {
        		audquery += ' AND Assigned_Auditor__c = :cuid';	// Limited seat license for contract auditors
        		MyAuditsOnly = true;	// flag it
        		SelectedAuditor = 'My';
        		evquery = 'SELECT Id, StartDateTime, Subject from Event WHERE whatID IN :AuditList ORDER BY StartDateTime';
        	}
        	else {
        		SelectedAuditor = 'ALL';
        		evquery = 'SELECT Id, StartDateTime, Subject from Event WHERE (whatID = :acid) OR (whatID IN :AuditList) ORDER BY StartDateTime';        		
        	}        	        	
        	audquery += ' AND Audit_Stage__c != \'Canceled\' AND Audit_Stage__c != \'Closed\' ORDER BY Name';
        	system.debug ('query = ' + audquery);
        	AuditList = (Audit__c[])Database.query(audquery);         	
        	AuditorList = AuditList.deepClone(true,true,true);	// Init the ALL auditor list of Active Audits
        	setAllTabRenderFlag();		// Set active tab to All Active          	        	        
        	AccumStats();	// Add up the numbers for the selected set of audits       	
        }
       	         
        // Now find all events related to this account (but not if limited license), or to any of its audit recs
        
        List <Event> ev = new List<Event>();
        if (evquery != null) {
        	ev = (Event[])Database.query(evquery);
        }
        if (!ev.isEmpty()) {
            nextEvent = ev[0].Subject + ': ';
            nextTime = ev[0].StartDateTime.format('MM-dd-yyyy h:mm a');
            evPage = new ApexPages.Standardcontroller(ev[0]).view();            
        }
        else {
            nextEvent = 'No events are currently scheduled';
            nextTime = '';
        }
        // Get contact roles for this account
        List <Contact> con = new List <Contact>();
        if (isFacility){
    		con = [SELECT Name, Phone, Email from Contact WHERE Id IN (SELECT ContactID from AccountContactRole WHERE
    		  Role = 'Patient Billing' AND AccountID = :acct.Id) LIMIT 1];
    	}
    	else {
    		con = [SELECT Name, Phone, Email from Contact WHERE Id IN (SELECT ContactID from AccountContactRole WHERE
    		  AccountID = :acct.Id and isPrimary = True) LIMIT 1];    		
    	}
    	if (!con.isEmpty()) {
    		fcName = con[0].Name;
    		fcConPage = new ApexPages.Standardcontroller(con[0]).view();
    		isFCPage = True;    			
    		fcTel = con[0].Phone;
    		fcEmail = (String)con[0].Email;
    	}
    	else {
    		fcName = '(none specified)';
    		isFCPage = False;    			    		
    		fcTel = '';
    		fcEmail = '';
    	}
    	if (isFacility) {
    		mrLabel = 'Medical Records Contact';
    		con = [SELECT Name, Phone, Email from Contact WHERE Id IN (SELECT ContactID from AccountContactRole WHERE
    		  Role = 'Medical Records' AND AccountID = :acct.Id) LIMIT 1];
    		if (!con.isEmpty()) {
    			mrName = con[0].Name;
    			mrConPage = new ApexPages.Standardcontroller(con[0]).view();
    			isMRPage = True;
    			mrTel = con[0].Phone;
    			mrEmail = (String)con[0].Email;
    		}
    		else {
    			mrName = '(none specified)';
    			isMRPage = False;
    			mrTel = '';
    			mrEmail = '';
    		}    		
    	}
    	else {
    		mrLabel = ' ';
    		mrName = '';
    		isMRPage = False;    			
    		mrTel = '';
    		mrEmail = '';
    	}
    	// Get lists of our auditors (users) and opposing auditors (contacts)
    	ourguys = new Set<Id>();
        theirguys = new Set<Id>();
        
        for (Audit__c aud : AuditList) {
            if (aud.Assigned_Auditor__c != Null) {
                ourguys.Add(aud.Assigned_Auditor__c);	// Will only be current user if constrained license
            }
            if (aud.Opposing_Auditor__c != Null) {
                theirguys.Add(aud.Opposing_Auditor__c);
            }                   
        }
        assignedAuditors = new List<User>();
        opposingAuditors = new List<Contact>();
        
        if (!ourguys.isEmpty()) {
            assignedAuditors = new List<User>([SELECT Id, LastName, FirstName from User WHERE Id IN :ourguys ORDER BY LastName]); 
        }
        if (!theirguys.isEmpty()) {
            opposingAuditors = new List<Contact>([SELECT Id, LastName, FirstName from Contact WHERE Id IN :theirguys ORDER BY LastName]);   
        }
        // Constructor complete                                       
    }
    public List<Audit__c> getNullAuditList() {
    	return (NullAuditList);
    }
	public Boolean getMyAuditsOnly() {
		return (MyAuditsOnly);
	}
	
    public String getAccType() {
        return (AccType);
    }
    public PageReference getAcctPageRef() {
        StdAcctPage = new PageReference('/apex/AccountDetail?id=' + acct.Id);
        return (StdAcctPage);    
    }
    
    public String getNextEvent() {
        
        return(nextEvent);
    }
    public String getNextTime() {
        
        return(nextTime);
    }
	public PageReference getEventPage() {
	 	return (evPage);
	}
	public String getFacilityCSZ() {
		if (isFacility && acct.Facility_City__c != Null && acct.Facility_City__c != '') {
			return (acct.Facility_City__c + ', ' + acct.Facility_State__c + ' ' + acct.Facility_Zip__c);
		}
		else {
			return ('           ');
		}			
	}
	public String getFacilityLabel() {
		if (isFacility) {
			return ('Facility Address');
		}
		else {
			return ('          ');
		}
	}
	public String getFacilityStreet() {
		if (isFacility && acct.Facility_Street__c != Null && acct.Facility_Street__c != '') {
			return (acct.Facility_Street__c);
		}
		else if (isFacility){
			return ('(none specified)');
		}
		else {
			return (' ');
		}
	}    
    public List<SelectOption> getAuditors() {
        List<SelectOption> options = new List<SelectOption>();
        if (MyAuditsOnly) {
        	options.add(new SelectOption('My', 'My Audits'));        	
        }
        else {
        	options.add(new SelectOption('ALL', 'All Auditors'));
        	for (User c : assignedAuditors) {
            	options.add(new SelectOption(c.ID, c.FirstName + ' ' + c.LastName)); 
        	}        
        }         
        for (Contact c : opposingAuditors) {
            options.add(new SelectOption(c.ID, 'Opp:' + c.FirstName + ' ' + c.LastName)); 
        }        
        return options;
    }
    public void setSelectedAuditor(String sel) {	// Drop-down list changed
    	this.SelectedAuditor = sel;
    }
    public void changeAuditor() {    	
        if (qs == Null) {
        	return;				// Not an auditable entity - all the accums are zero
        }
        // Got auditors, possibly... reset query to All Active audits
        ID acid = acct.Id;
        String audquery = AuditFields + ' FROM Audit__c WHERE ' + qs + ' = :acid';
        audquery += ' AND Audit_Stage__c != \'Canceled\' AND Audit_Stage__c != \'Closed\' ';        		
        
        setAllTabRenderFlag();		// Set active tab to All Active          	

        if (SelectedAuditor.startsWith('ALL')) {      	
        	audquery += 'ORDER BY Name';
			AuditorList = (Audit__c[])Database.query(audquery);		// Refresh the Audit list			
        	AccumStats();
    		return;                	
        }
        else {
        	ID me = UserInfo.getUserId();        	              
        	ID guy;	// User or Contact        	
        	if (SelectedAuditor.startsWith('My')){    		
    			audquery += 'AND Assigned_Auditor__c = :me ORDER BY Name';    		
        	}
        	else {
        		guy = (ID)SelectedAuditor;	// User or Contact        	
	        	if (ourguys.contains(guy)) {
	        		// User
	        		audquery += 'AND Assigned_Auditor__c = :guy ORDER BY Name';
	        	}
	        	else {
	        		// Contact - must constrain if limited license
	        		if (MyAuditsOnly) {
	        			audquery += 'AND Assigned_Auditor__c = :me ';
	        		}
	        		audquery += 'AND Opposing_Auditor__c = :guy ORDER BY Name';
	        	}
        	}
        	AuditorList = (Audit__c[])Database.query(audquery);
        	AccumStats();        	
        	return;
        }                           
    }
    
    private void AccumStats() {
        if (SelectedAuditor.startsWith('ALL')) {      	
        	// For ALL auditors, just copy the account totals to the getters
    		NumPending = acct.Audits_NumPending__c;
    		AmtPending = acct.Audits_AmtPending__c;        		
    		NumScheduled = acct.Audits_NumScheduled__c;
    		AmtScheduled = acct.Audits_AmtScheduled__c;
    		NumExited = acct.Audits_NumExited__c;
			AmtExited = acct.Audits_AmtExited__c;
			NumDisputed = acct.Audits_NumDisputed__c;
			AmtDisputed = acct.Audits_AmtDisputed__c;
			NumAppealed = acct.Audits_NumAppealed__c;
			AmtAppealed = acct.Audits_AmtAppealed__c;
			NumTotal = acct.Audits_TotalNumActive__c;				
			AmtTotal = acct.Audits_TotalAmtActive__c;
        }
        else {
        	// Iterate through the list of Audit recs for this auditor and accumulate the numbers
    		NumPending = 0;        		    		
			AmtPending = 0;        		
    		NumScheduled = 0;
    		AmtScheduled = 0;
    		NumExited = 0;
			AmtExited = 0;
			NumDisputed = 0;
			AmtDisputed = 0;
			NumAppealed = 0;
			AmtAppealed = 0;
			NumTotal = 0;
			AmtTotal = 0;    	
        	for (Audit__c audit : AuditorList) {
	        	if (audit.Audit_Stage__c == 'Pending') {
	        		NumPending += 1;
	        		AmtPending += audit.Audit_Amount__c;        		
	        	}
	        	else if (audit.Audit_Stage__c == 'Scheduled') {
	        		NumScheduled += 1;
	        		AmtScheduled += audit.Audit_Amount__c;
	        	}	
				else if (audit.Audit_Stage__c == 'Exit Completed') {
					NumExited += 1;
					AmtExited += audit.Audit_Amount__c;
				}
				else if (audit.Audit_Stage__c == 'In Dispute') {
					NumDisputed += 1;
					AmtDisputed += audit.Audit_Amount__c;
				}
				else if (audit.Audit_Stage__c == 'Appealed') {
					NumAppealed += 1;
					AmtAppealed += audit.Audit_Amount__c;
				}
				NumTotal += 1;
				AmtTotal += audit.Audit_Amount__c;
			}        	
        }    	
    }
    
    public String getSelectedAuditor() {
        return (SelectedAuditor);       
    }
    public String getContactLabel() {
    	if (isFacility) {
    		return ('Patient Billing Contact');
    	}
    	else {
    		return ('Primary Account Contact');
    	}
    }
    public String getFirstContactName() {
    	return (fcName);
    }
    public Boolean getIsFCPage () {
    	return (isFCPage);
    }

    public PageReference getFCPage() {
	 	return (fcConPage);
	}
	
    public String getFirstContactTel() {
    	return (fcTel);
    }
	public String getFirstContactEmail() {
    	return (fcEmail);
    }
    public String getMRLabel() {
    	return (mrLabel);
    }    
    public String getMRName() {
    	return (mrName);
    }
    public Boolean getIsMRPage () {
    	return (isMRPage);
    }
    public PageReference getMRPage() {
	 	return (mrConPage);
	}

    public String getMRTel() {
    	return (mrTel);
    }
	public String getMREmail() {
    	return (mrEmail);
    }
    
    public Double getNumPending () {
    	return (NumPending);
    }    
    public Decimal getAmtPending () {
    	return (AmtPending);
    }           		     	
    public Double getNumScheduled() {
   		return (NumScheduled);
   	}
	public Decimal getAmtScheduled() {
		return(AmtScheduled);
	}
	public Double getNumExited() {
		return (NumExited);
	}
	public Decimal getAmtExited() {
		return (AmtExited);
	}
	public Double getNumDisputed() {
		return (NumDisputed);
	}
	public Decimal getAmtDisputed() {
		return (AmtDisputed);
	}
	public Double getNumAppealed () {
		return (NumAppealed);
	}
	public Decimal getAmtAppealed() {
		return (AmtAppealed);
	}
	public Double getNumTotal() {
		return (NumTotal);
	}
	public Decimal getAmtTotal() {
		return (AmtTotal);
	}
	
	public List<Audit__c> getAllAuditorList() {
		system.debug('getALL');
		return(genAuditorList('ALL'));		// return the pre-built list for current auditor(s) selected
	}
	public List<Audit__c> getPendingAuditorList() {
		system.debug('getPending');
		return(genAuditorList('Pending'));
	}
	public List<Audit__c> getScheduledAuditorList () {
		system.debug('getScheduled');
		return(genAuditorList('Scheduled'));		
	}
	public List<Audit__c> getExitedAuditorList() {
		system.debug('getExited');
		return(genAuditorList('Exit Completed'));		
	}
	public List<Audit__c> getDisputedAuditorList() {
		system.debug('getDisputed');		
		return(genAuditorList('In Dispute'));		
	}
	public List<Audit__c> getAppealedAuditorList() {
		system.debug('getAppealed');		
		return(genAuditorList('Appealed'));		
	}
	public List<Audit__c> getClosedAuditorList() {
		system.debug('getClosed');		
		return(genAuditorList('Closed'));		
	}
	public List<Audit__c> getCanceledAuditorList() {
		system.debug('getCanceled');		
		return(genAuditorList('Canceled'));
	}
	
	private  List<Audit__c> genAuditorList(String stage) {
		ID acid = acct.Id;
		ID guy;
		ID me = UserInfo.getUserId();
		List<Audit__c> results = new List<Audit__c>();
		if (qs == Null) {
			return (results); // Not an audit-related account - return empty list
		}
		String audquery = AuditFields + ' FROM Audit__c WHERE ' + qs + ' = :acid';        
		if (stage == 'ALL') {
			if (AuditorList != Null) {		
				results = AuditorList.deepClone(true,true,true);	// Just copy the ALL auditor list of Active Audits
				return (results);
			}
		}
		else {
			audquery += ' AND Audit_Stage__c = \'' + stage + '\'';
		}        	
        if (!SelectedAuditor.startsWith('ALL')) {
        	if(SelectedAuditor.startsWith('My')) {
        		audquery += ' AND Assigned_Auditor__c = :me ORDER BY Name';
        	}
        	else {
	        	// If not all auditors, add filter
	        	guy = (ID)SelectedAuditor;	// User or Contact
	        	if (ourguys.contains(guy)) {
	        		// User
	        		audquery += ' AND Assigned_Auditor__c = :guy ORDER BY Name';
	        	}
	        	else {
	        		// Contact
	        		audquery += ' AND Opposing_Auditor__c = :guy ORDER BY Name';
	        	}
        	}        	 
        }        
        else {
         	audquery += ' ORDER BY NAME';
        }
        results = (Audit__c[])Database.query(audquery);
        return (results);
	}
	
	private void setFlagsFalse() {
		AllTabRenderFlag = False;
		PendingTabRenderFlag = False;	
		ScheduledTabRenderFlag = False;
		ExitedTabRenderFlag = False;
		DisputedTabRenderFlag = False;
		AppealedTabRenderFlag = False;
		ClosedTabRenderFlag = False;
		CanceledTabRenderFlag = False;
		SearchTabRenderFlag = False;
	}
	
	
	public void setAllTabRenderFlag() {
		system.debug('set AllTab flag');
		setFlagsFalse();
		AllTabRenderFlag = True;
	}
	public Boolean getAllTabRenderFlag() {
		system.debug('get AllTab flag');
		
		return (AllTabRenderFlag);
	}
	public void setPendingTabRenderFlag() {
		system.debug('set PendingTab flag');
		
		setFlagsFalse();
		PendingTabRenderFlag = True;
	}
	public Boolean getPendingTabRenderFlag() {
		system.debug('get PendingTab flag');
		return (PendingTabRenderFlag);
	}
	public void setScheduledTabRenderFlag() {
		system.debug('set ScheduledTab flag');
		setFlagsFalse();
		ScheduledTabRenderFlag = True;
	}
	public Boolean getScheduledTabRenderFlag() {
		system.debug('set ScheduledTab flag');
		return (ScheduledTabRenderFlag);
	}
	public void setExitedTabRenderFlag() {
		system.debug('set ExitedTab flag');	
		setFlagsFalse();
		ExitedTabRenderFlag = True;
	}
	public Boolean getExitedTabRenderFlag() {
		system.debug('get ExitedTab flag');	
		return (ExitedTabRenderFlag);
	}
	public void setDisputedTabRenderFlag() {
		system.debug('set DisputedTab flag');	
		setFlagsFalse();
		DisputedTabRenderFlag = True;
	}
	public Boolean getDisputedTabRenderFlag() {
		system.debug('get DisputedTab flag');	
		return (DisputedTabRenderFlag);
	}
	public void setAppealedTabRenderFlag() {
		system.debug('set AppealedTab flag');	
		setFlagsFalse();
		AppealedTabRenderFlag = True;
	}
	public Boolean getAppealedTabRenderFlag() {
		system.debug('get AppealedTab flag');	
		return (AppealedTabRenderFlag);
	}
	public void setClosedTabRenderFlag() {
		system.debug('set ClosedTab flag');	
		setFlagsFalse();
		ClosedTabRenderFlag = True;
	}
	public Boolean getClosedTabRenderFlag() {
		system.debug('get ClosedTab flag');	
		return (ClosedTabRenderFlag);
	}
	public void setCanceledTabRenderFlag() {
		system.debug('set CanceledTab flag');	
		setFlagsFalse();
		CanceledTabRenderFlag = True;
	}
	public Boolean getCanceledTabRenderFlag() {
		system.debug('get CanceledTab flag');	
		return (CanceledTabRenderFlag);
	}
	public void setSearchTabRenderFlag() {
		system.debug('set SearchTab flag');	
		setFlagsFalse();
		SearchTabRenderFlag = True;
	}
	public Boolean getSearchTabRenderFlag() {
		system.debug('get SearchTab flag');	
		return (SearchTabRenderFlag);
	}

		
}