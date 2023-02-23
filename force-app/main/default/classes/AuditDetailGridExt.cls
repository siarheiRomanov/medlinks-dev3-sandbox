global with sharing class AuditDetailGridExt {
/* 
History:
8/2012 SBower.  Added various code to manage loading, saving, and editing the Annotation field on the AuditItem.


*/

    private final Audit__c audit;
    private final Account acct;
    public ID acctId;
    public String acctName;
    public ID acctOwnerId;
    private String nextEvent;
    private String nextTime;
    private PageReference evPage;
    private PageReference StdAuditViewPage;
    private PageReference StdAuditEditPage;
    private PageReference MRConPage;
    private PageReference AcctOwnerPage;    
    private PageReference AuditorPage;
    private PageReference OppAuditorPage;
    private PageReference OppSchedulerPage;
    private PageReference OppFirmPage;
    private Boolean isAuditorPage;
    private Boolean isLimited = false;
    private Boolean isOppAuditorPage;
    private Boolean isOppSchedulerPage;
    private Boolean isOppFirmPage;
    private Boolean isMRConPage;
    private String auditorName;       
    private String opposingFirm;
    private String opposingAuditor;    
    private String opposingScheduler;
    private String acctOwnerName;
    private String MRContact;
    private String DOS;
    private String EndDate;
    private Integer serviceDays;
    private Integer serviceNights;
    
    global class BillItem {
        String AId;        
        String ErrCode;
        String DOS;
        String Dept;
        String ChgCode;
        String CDMid;
        String BillDesc;
        String RevCode;
        Decimal UCost;
        Integer QtyBill;
        Integer QtyMR;
        Integer QtyMD;
        Integer QtyRev;
        Integer QtyDis;	// Added 1/5/12 for new disputed handling
        Boolean MRFlag;
        String AdjCode;
        Decimal AmtBill;
        Decimal AmtAdj;
        Decimal AmtDis;
        String Annotation;
	}
    global class UpdateResponse {
        String Row;
        String Code;
        String Adis;
        Decimal Tbill;
        Decimal Tund;
        Decimal Tunb;
        Decimal Tsumu;
        Decimal Tsumo;
        Decimal Tadj;
        Decimal Tdisa;
        Decimal Trev;
        Decimal Tdisp;
        Integer Tflags;    
    }
    global class DeptList {
        String Id;
        String DCode;
        String DDesc;
    }
    global class AddItemResponse {
        String AId;        
        String ErrCode;
        String DOS;
        String Dept;
        String ChgCode;
        String CDMid;
        String BillDesc;
        String RevCode;
        Decimal UCost;
        Integer QtyBill;
        Integer QtyRev;
        Integer QtyDis; // Added 1/5/12 for new disputed handling
        Boolean MRFlag;
        String AdjCode;
        Integer QtyMR;
        Integer QtyMD;        
        Decimal AmtBill;
        Decimal AmtAdj;
        Decimal AmtDis;
        Decimal Tbill;
        Decimal Tund;
        Decimal Tunb;
        Decimal Tsumu;
        Decimal Tsumo;
        Decimal Tadj;
        Decimal Tdisa;
        Decimal Trev;
        Decimal Tdisp;
        Integer Tflags;    
    }
   
        
    
    public AuditDetailGridExt(ApexPages.StandardController stdController) {
        this.audit = (Audit__c)stdController.getRecord();
        StdAuditViewPage = new PageReference('/apex/AuditNewView?id=' + audit.Id + '&workaround=123');  // Salesforce Support Solution Case #43475356
        StdAuditEditPage = new PageReference('/apex/AuditNewEdit?id=' + audit.Id);
        acctId = audit.Account__c;                
        acct = [SELECT Id, Name, OwnerId, Auditable__c from Account WHERE Id = :acctid];
        acctName = acct.Name;       
        acctOwnerID = acct.OwnerId;     
        User urec;
        urec = [SELECT Id, Name from User WHERE Id = :acctOwnerId];
        acctOwnerName = urec.Name;
        acctOwnerPage = new ApexPages.StandardController(urec).view();  
        
        List <Event> ev = new List<Event>([SELECT Id, StartDateTime, Subject from Event WHERE
         (whatID = :audit.ID) ORDER BY StartDateTime]);
          
        if (!ev.isEmpty()) {
            nextEvent = ev[0].Subject + ': ';
            nextTime = ev[0].StartDateTime.format('MM-dd-yyyy h:mm a');
            evPage = new ApexPages.Standardcontroller(ev[0]).view();            
        }
        else {
            nextEvent = 'No events are currently scheduled';
            nextTime = '';
        }
        if (audit.Assigned_Auditor__c == Null){
            auditorName = 'NOT ASSIGNED';
            isAuditorPage = false;                  
        }
        else {
            urec = [SELECT Id, Name, Limited_License__c FROM User WHERE Id = :audit.Assigned_Auditor__c];
            auditorName = urec.Name;
            AuditorPage = new ApexPages.StandardController(urec).view();
            isAuditorPage = true;
            if (UserInfo.getUserId() == urec.Id && urec.Limited_License__c) {
                isLimited = true;   // Current user is limited license auditor
            } 
        }
        if (audit.Opposing_Audit_Account__c == Null) {
            opposingFirm = '(None Specified)';
            isOppFirmPage = false;  
        }
        else {
            Account opp = [SELECT Id, Name from Account WHERE Id = :audit.Opposing_Audit_Account__c];
            opposingFirm = opp.Name;
            oppFirmPage = new ApexPages.StandardController(opp).view();
            isOppFirmPage = true;   
        }
        if (audit.Opposing_Auditor__c == Null) {
            opposingAuditor = '(None Specified)';
            isOppAuditorPage = false;
        }
        else {
            Contact con = [SELECT Id, Name from Contact WHERE Id = :audit.Opposing_Auditor__c];
            opposingAuditor = con.Name;
            oppAuditorPage = new ApexPages.StandardController(con).view();
            isOppAuditorPage = true;
        }
        if (audit.Opposing_Scheduler__c == Null) {
            opposingScheduler = '(None Specified)';
            isOppSchedulerPage = false;     
        }
        else {
            Contact con = [SELECT Id, Name from Contact WHERE Id = :audit.Opposing_Scheduler__c];
            opposingScheduler = con.Name;
            oppSchedulerPage = new ApexPages.StandardController(con).view();
            isOppSchedulerPage = true;      
        }
        if (audit.Facility_MR_Contact__c == Null) {
            MRContact = '(none specified)';
            isMRConPage = False;        
        }
        else {
            Contact con = [SELECT Id, Name from Contact WHERE Id = :audit.Facility_MR_Contact__c];
            MRContact = con.Name;
            MRConPage = new ApexPages.Standardcontroller(con).view();
            isMRConPage = True;
        }
        
        
        // Get DOS
        Time t = Time.newInstance(0,0,0,0); // Stupid API
        Datetime ds = Datetime.newInstance(audit.Service_Start_Date__c, t);
        Datetime de = Datetime.newInstance(audit.Service_End_Date__c, t);           
        if (audit.Service_Start_Date__c.isSameDay(audit.Service_End_Date__c)) {
            DOS = ds.format('MM-dd-yyyy');
            EndDate = ds.format('yyyy-MM-dd');
            serviceDays = 1;
            serviceNights = 0;
        }
        else {
            EndDate = de.format('yyyy-MM-dd');
            DOS = ds.format('M-dd-yyyy') + ' to ' + de.format('M-dd-yyyy');
            serviceDays = audit.Service_Start_Date__c.daysBetween(audit.Service_End_Date__c) + 1;
            serviceNights = serviceDays-1;
            DOS += ' (' + String.valueOf(serviceDays) + '/' + String.valueOf(serviceNights) + ')';
        }    
    }
    public Integer getDOSsyear() {
    	return (audit.Service_Start_Date__c.year());
    }
    public Integer getDOSsmonth() {
    	return (audit.Service_Start_Date__c.month());
    }
    public Integer getDOSsday() {
    	return (audit.Service_Start_Date__c.day());
    }
    public Integer getServiceDays() { // 1/7/12
    	return (serviceDays);
    }    
    public String getAcctName() {
        return (acctName);
    }
    public ID getAcctId() {
        return (acctId);
    }

    public PageReference getAuditViewPageRef() {
        return (StdAuditViewPage);    
    }
    public PageReference getAuditEditPageRef() {
        return (StdAuditEditPage);    
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
    public String getOpposingFirm () {
        return (opposingFirm);
    }
    public String getOpposingAuditor () {
        return (opposingAuditor);
    }
    public String getOpposingScheduler () {
        return (opposingScheduler);
    }
    public String getAcctOwnerName () {
        return (acctOwnerName);
    }
    public PageReference getAcctOwnerPage () {
        return (AcctOwnerPage);
    }
    public String getMRContact () {
        return (MRContact);
    }
    public String getDOS () {
        return (DOS);
    }
    
    public Boolean getIsMRConPage () {
        return (isMRConPage);
    }
    public PageReference getMRConPage() {
        return (MRConPage);
    }
    public Boolean getIsOppFirmPage () {
        return (isOppFirmPage);
    }
    public PageReference getOppFirmPage() {
        return (OppFirmPage);
    }
    public Boolean getIsOppAuditorPage () {
        return (isOppAuditorPage);
    }
    public PageReference getOppAuditorPage() {
        return (OppAuditorPage);
    }   
    public Boolean getIsOppSchedulerPage () {
        return (isOppSchedulerPage);
    }
    public PageReference getOppSchedulerPage() {
        return (OppSchedulerPage);
    }
    public String getAuditorName () {
        return (auditorName);
    }
    public Boolean getIsAuditorPage () {
        return (isAuditorPage);
    }
    public Boolean getIsLimited () {
        return (isLimited);
    }
    
    public PageReference getAuditorPage () {
        return (AuditorPage);
    }
    public String getAuditCanExit () {
        if (audit.Audit_Stage__c == 'Scheduled') {
            return 'true';
        }
        else {
            return 'false';
        }
    }
    @RemoteAction
    global static BillItem[] fetchBill(String Aid, String msk) {
        List <BillItem> theBill = new List<BillItem>();
        // system.debug('*** fetchBill called with: ' + Aid + ' : ' + msk);     
        AuditItem__c[] audititems = [Select Id, Err_Code__c,Date_Of_Service__c,Audit_Dept_Code__c,Audit_Dept_Code__r.Name,CDM_Charge_Code__c,CDM_Charge_Code__r.Id,
         Bill_Charge_Code__c, Item_Description__c, CDM_Rev_Code__c, CDM_Rev_Code__r.Name, Bill_Unit_Price__c, Bill_Qty__c,Bill_Total__c,Qty_MR__c, Qty_MD__c,
         Qty_Net__c,Qty_Disallowed__c,Qty_Disputed__c,Qty_Adj_Other__c,MR_Flag__c,Not_Billed_Code__c,
         Adj_Other_Code__c,Amt_Adj__c,Amt_Disputed__c, Annotation__c from AuditItem__c WHERE Audit_Master__c = :Aid];
         for (AuditItem__c a: audititems) {
            BillItem b = new BillItem();
            b.AId = a.Id;
            b.ErrCode = String.valueOf(a.Err_Code__c);
            b.DOS = String.valueOf(a.Date_Of_Service__c);
            b.Dept = (a.Audit_Dept_Code__c != null? a.Audit_Dept_Code__r.Name: '');
            b.ChgCode = a.Bill_Charge_Code__c;
            // system.debug('***Charge code ID = ' + a.CDM_Charge_Code__c); 
            b.CDMid = (a.CDM_Charge_Code__c != null? (String)a.CDM_Charge_Code__r.Id : '');            
            b.BillDesc = a.Item_Description__c;            
            b.RevCode = (a.CDM_Rev_Code__c != null? a.CDM_Rev_Code__r.Name: '');
            b.UCost = a.Bill_Unit_Price__c;
            b.QtyBill = a.Bill_Qty__c.intValue();
            b.QtyMR = a.Qty_MR__c.intValue();
            b.QtyMD = a.Qty_MD__c.intValue();
            b.QtyRev = a.Qty_Net__c.intValue();
            b.QtyDis = a.Qty_Disputed__c.intValue();	// Added 1/5/12 for new disputed handling
            b.MRFlag = a.MR_Flag__c;
            if (a.MR_Flag__c == true) {
                b.AdjCode = (b.QtyMD > b.QtyBill? 'U': (b.QtyMR == b.QtyMD? 'O' : 'N'));                    
            }
            else {  // 'MR Flag' and 'Adj Other' are MUTUALLY EXCLUSIVE
                if (a.Adj_Other_Code__c == Null) {
                    b.AdjCode = (a.Not_Billed_Code__c != Null)? a.Not_Billed_Code__c: '';
                    // 'Adj Other' and 'Not Billed' are MUTUALLY EXCLUSIVE                    
                }
                else {                  
                    b.AdjCode = a.Adj_Other_Code__c;
                    // if (b.AdjCode == 'C') { // Net already includes disallowed??
                    //    b.QtyRev = (a.Bill_Qty__c - a.Qty_Disallowed__c).intValue();
                    //}
                }
            }
            b.AmtBill = a.Bill_Total__c;
            b.AmtAdj = a.Amt_Adj__c;
            b.AmtDis = a.Amt_Disputed__c;
            b.Annotation = a.Annotation__c;
            theBill.Add(b);
        }
        return theBill; 
    }
    @RemoteAction    
    global static String updateItemAnnotation(String aid, String Annotation) {
        AuditItem__c ai = [Select Id, Annotation__c from AuditItem__c WHERE Id = :aid];
        ai.Annotation__c = Annotation;
        update ai;
        return 'done';
    }
        
    @RemoteAction    
    global static UpdateResponse updateItem(String row, String aid, String acode, String qmr, String qrev, String aadj, String qdis, String adis, String mrf) {
        AuditItem__c ai = [Select Id, Audit_Master__c, Flagged__c, Err_Code__c, Bill_Qty__c, Qty_MR__c, Qty_MD__c,
         Qty_Disallowed__c,Qty_Disputed__c,Qty_Adj_Other__c,MR_Flag__c,Adj_Other_Code__c from AuditItem__c WHERE Id = :aid];
        // Note that Adj Other is still distinct and can be set together with MR, but it is not currently implemented               
        if (acode.startsWith('X')) {
            delete ai;  // Deleting a previously user-added item
        }
        else {
        	if (acode == '' && adis == '') { // 1/7/12 - no code OR disputed = undo
	            ai.MR_Flag__c = false;  // UNDO PRIOR EDIT
	            ai.Qty_MR__c = 0;		// Clear all adjustment fields
	            ai.Qty_MD__c = 0; 
	            ai.Qty_Disallowed__c = 0; 
	            ai.Qty_Adj_Other__c = 0;
	            ai.Qty_Disputed__c = 0;
	            ai.Adj_Other_Code__c = Null;
	            ai.Flagged__c = (ai.Err_Code__c != 0 ? true: false);                    
	        }
        	else {
	            ai.Flagged__c = true;        
	            if (acode == 'O' || acode == 'N' || acode == 'U') {
	                ai.MR_Flag__c = true;   
	                ai.Qty_MR__c = Double.valueOf(qmr);
	                ai.Qty_MD__c = Double.valueOf(qrev);
	                ai.Qty_Adj_Other__c = 0;
	                ai.Adj_Other_Code__c = Null;
	                // ai.Qty_Disputed__c = 0;	// removed 1/5/12
	                ai.Qty_Disallowed__c = 0;
	            }	            
	            else if (acode == 'C') {
	                ai.MR_Flag__c = false;  // Contractually disallowed - seperate field
	                ai.Qty_MR__c = Double.valueOf(qmr);
	                ai.Qty_MD__c = ai.Qty_MR__c;    // MD=MR?
	                ai.Qty_Disallowed__c = ai.Bill_Qty__c - Double.valueOf(qrev); // Get separate amt!
	                ai.Qty_Adj_Other__c = 0;
	                // ai.Qty_Disputed__c = 0;	/// removed 1/5/12
	                ai.Adj_Other_Code__c = 'C';
	            }            
	            else if (acode != '') {
	                ai.MR_Flag__c = false; // All other adj types
	                ai.Qty_MR__c = Double.valueOf(qmr);
	                ai.Qty_MD__c = ai.Qty_MR__c;    // ASSUME MD=MR 
	                ai.Qty_Adj_Other__c = Double.valueOf(qrev)-ai.Bill_Qty__c;  // Adj = +-delta
	                ai.Adj_Other_Code__c = acode;
	                // ai.Qty_Disputed__c = 0;	// removed 1/5/12
	                ai.Qty_Disallowed__c = 0;                       
	            }
	            // 1/5/12: New disputed handling - allow disputed adjustment IN ADDITION to all other line item adjustments
	            // A non-zero disputed quantity indicates adjustment
	            // TODO: should also support amount disputed, distinct from qty
	            if (qdis != '') {
	            	ai.Qty_Disputed__c = Double.valueOf(qdis);	
	            }                        	
        	}
        	update ai;	// UPDATE ITEM
        }        
        // Fetch the audit master rec to get the roll-up totals
        
        Audit__c am = [SELECT Id, TAmt_Billed__c,TAmt_Under__c,TAmt_Unbill__c,TAmt_SumUnder__c,TAmt_SumOver__c,TAmt_Adj__c,
            TAmt_Disallowed__c,TAmt_Revised__c,TAmt_Disputed__c, Flagged_Items__c FROM Audit__C WHERE Id = :ai.Audit_Master__c];
        
        UpdateResponse up = new UpdateResponse();
        
        up.Row = row;   // pass it back
        up.Code = acode;
        up.Adis = adis;	// 1/7/12
        up.Tbill = am.TAmt_Billed__c;
        up.Tund = am.TAmt_Under__c;
        up.Tunb = am.TAmt_Unbill__c;
        up.Tsumu = am.TAmt_SumUnder__c;
        up.Tsumo = am.TAmt_SumOver__c;
        up.Tadj = am.TAmt_Adj__c;
        up.Tdisa = am.TAmt_Disallowed__c;
        up.Trev = am.TAmt_Revised__c;       
        up.Tdisp = am.TAmt_Disputed__c;    
        up.Tflags = am.Flagged_Items__c.intValue();
        return up;
    }
    @RemoteAction    
    global static String updateBillFlags (String auditId, String Analysis, String Exited){
        Audit__c am = [SELECT Id, Bill_Analysis_Complete__c, Date_Bill_Analysis_Complete__c, Audit_Stage__c, Date_Actual_Exit__c FROM Audit__c WHERE Id = :auditId];
        if (Analysis == 'true') {
            am.Bill_Analysis_Complete__c = true;
            am.Date_Bill_Analysis_Complete__c = datetime.now();            
        }
        if (Exited == 'true') {		
            if (am.Date_Actual_Exit__c == null) {
            	am.Date_Actual_Exit__c = datetime.now(); // ONLY IF NOT PREVIOUSLY SET!
            }
            am.Audit_Stage__c = 'Exit Completed';
        }
        update am;
        return 'done';
    }
    @RemoteAction
    global static DeptList[] fetchDepts (String arg) {
        List<DeptList> deps = new List<DeptList>();
        // system.debug('fetchDepts called *********');
        Department__c[] ditems = [Select Id, Name, Description__c from Department__c ORDER BY Name];
        for (Department__c d: ditems) {
            DeptList dl = new DeptList();
            dl.Id = d.Id;
            dl.DCode = d.Name;
            dl.DDesc = d.Description__c;
            deps.Add(dl); 
        }
        return deps;
    }
    @RemoteAction    
    global static AddItemResponse addLineItem(String aid, String ccode, String bdesc, String dos, String dept, String rcode, String bqty, String uc, String btot) {
        AuditItem__C ai = new AuditItem__c();
        ai.Audit_Master__c = aid;
        ai.Bill_Charge_Code__c = ccode;
        ai.Item_Description__c = bdesc;
        dos += ' 12:00:00';
        ai.Date_of_Service__c = Date.valueOf(dos);
        ai.Audit_Dept_Code__c = dept;
        system.debug('**** add item: desc='+bdesc+' date='+dos);
        if (rcode == 'AA') {
            // Inserting new line item or adjustment line for manual bill
            ai.Bill_Qty__c = Double.valueOf(bqty);
            ai.Bill_Unit_Price__c = (Decimal.valueOf(uc))/100;
            ai.Bill_Total__c = (Decimal.valueOf(btot))/100;             
        }
        else {        
            ai.Not_Billed_Code__c = rcode; // "Xn"
            ai.Bill_Qty__c = 0;         // Primary indicator of unbilled item
            ai.Bill_Unit_Price__c = (Decimal.valueOf(uc))/100;
            ai.Bill_Total__c = 0;       // Note that Bill Tot=0 as well
            ai.Qty_notBilled__c = Double.valueOf(bqty); // Gets copied to 'Qty_Unbill__c'
        }
        insert ai;  // Add item, and read it back
        ai = [Select Id, Err_Code__c,Date_Of_Service__c,Audit_Dept_Code__c,Audit_Dept_Code__r.Name,CDM_Charge_Code__c,CDM_Charge_Code__r.Id,
         Bill_Charge_Code__c, Item_Description__c, CDM_Rev_Code__c, CDM_Rev_Code__r.Name, Bill_Unit_Price__c, Bill_Total__c, Bill_Qty__c,
         Qty_Net__c, Amt_Adj__c, Not_Billed_Code__c, Audit_Master__c from AuditItem__c WHERE Id = :ai.Id];
        // Get the Audit Master with update roll-up fields
        Audit__c am = [SELECT Id, TAmt_Billed__c,TAmt_Under__c,TAmt_Unbill__c,TAmt_SumUnder__c,TAmt_SumOver__c,TAmt_Adj__c,
            TAmt_Disallowed__c,TAmt_Revised__c,TAmt_Disputed__c, Flagged_Items__c FROM Audit__C WHERE Id = :ai.Audit_Master__c];
        // Build the response object
        AddItemResponse ar = new AddItemResponse();
        ar.AId = ai.Id;
        ar.MRFlag = false;
        ar.ErrCode = String.valueOf(ai.Err_Code__c);
        ar.DOS = String.valueOf(ai.Date_Of_Service__c);
        ar.Dept = (ai.Audit_Dept_Code__c != null? ai.Audit_Dept_Code__r.Name: '');
        ar.ChgCode = ai.Bill_Charge_Code__c;
        ar.CDMid = (ai.CDM_Charge_Code__c != null? (String)ai.CDM_Charge_Code__r.Id : '');            
        ar.BillDesc = ai.Item_Description__c;            
        ar.RevCode = (ai.CDM_Rev_Code__c != null? ai.CDM_Rev_Code__r.Name: '');
        ar.UCost = ai.Bill_Unit_Price__c;
        ar.QtyMR = 0;
        ar.QtyMD = 0;
        ar.QtyDis = 0; // 1/5/12
        ar.AmtDis = 0;
        ar.QtyRev = ai.Qty_Net__c.intValue();
            
        if (ai.Not_Billed_Code__c == null) {        
            ar.QtyBill = ai.Bill_Qty__c.intValue();     // New line item or summary item
            ar.AdjCode = '';
            ar.AmtBill = ai.Bill_Total__c;    
            ar.AmtAdj = 0;
            // Flag as 'manual bill' in master???        
        }
        else {  
            ar.QtyBill = 0;                         // Unbilled item
            ar.AdjCode = ai.Not_Billed_Code__c;
            ar.AmtBill = 0;
            ar.AmtAdj = ai.Amt_Adj__c;        
        }
        ar.Tbill = am.TAmt_Billed__c;        
        ar.Tund = am.TAmt_Under__c;
        ar.Tunb = am.TAmt_Unbill__c;
        ar.Tsumu = am.TAmt_SumUnder__c;
        ar.Tsumo = am.TAmt_SumOver__c;
        ar.Tadj = am.TAmt_Adj__c;
        ar.Tdisa = am.TAmt_Disallowed__c;
        ar.Trev = am.TAmt_Revised__c;       
        ar.Tdisp = am.TAmt_Disputed__c;    
        ar.Tflags = am.Flagged_Items__c.intValue();
        return ar;              
    }
}