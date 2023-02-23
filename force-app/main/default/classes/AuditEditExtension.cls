public class AuditEditExtension {

    private final Audit__c audit;
    private Account acct;
    private ApexPages.StandardController ac;    // save the Audit controller
    private Boolean isNew;                      // Indicates if this is a new rec rather than an edit
    private Boolean haveFacility;                // Indicates if facility has been specified
    // In the constructor get current audit record from standard controller
    public AuditEditExtension(ApexPages.StandardController stdController) {
        ac = stdController;
        this.audit = (Audit__c)ac.getRecord();
      	audit.XFlag__c = 1;		// TODO: OR Indicates to trigger that this is coming from edit page, not inline edit in view      	
        if (audit.id == null) {
            isNew = true;    
        }
        else {
        	// Doing a full edit of existing audit rec
        	list<String> n = new String[2];
            isNew = false;
            // Initialize the crypto editing fields (leave patient account and MR native, for now
            if (audit.Patient_DOB__c != NULL && audit.Patient_DOB__c.length() > 0) {
            	try {
            		audit.Patient_DOBedit__c = date.ValueOf(audit.Patient_DOB__c);
            	} catch (Exception e){
            		audit.Patient_DOBedit__c = NULL;	// If error, just clear the date (old cruft in field)
            	}
            }
            else {
            	audit.Patient_DOBedit__c = NULL;	            	
            }
            
            String en = audit.Patient_Name__c;
            if (en != null) {
                n = en.split(', ');		// Get last and first names separated
            }
            else {
                n[0] = '';
                n[1] = '';
            }
            audit.Patient_Last_Name__c = n[0];	// Set the edit fields (always unencrypted)
            audit.Patient_First_Name__c = n[1];
        }
        // See if there is an Account object pre-populated in Facility (new or edit)
        String f = (String)audit.Account__c;
        if (f != null && f.length() > 0) {
            haveFacility = True;
            acct = [SELECT ID, Name, Auditable__c, Audit_Client__c from Account where ID = :audit.Account__c]; 
        }
        else {        
            haveFacility = False;
        }
    }
    //public String getPageMode() {    
    //    return (isNew == True ? 'Creating New Record' : 'Editing Record with patient account = '+ audit.Patient_Account__c);         
    //}
    public Boolean getIsNew() {
    	return (isNew);
    }
    public String getFacility() {
        if (haveFacility) {
            return (acct.Name);
        }
        else {
            return ('No Faciltiy Specified');
        }
    }
    public String getFCalert() {       
        
            // Flag to indicate if account existed on entry and it was NOT an audit client, i.e., you can't change it!
             if (haveFacility && !acct.Audit_Client__c) {
                 return ('true');
             }
             else {
                 return ('false');
             }                 
    }
    public void setFCalert(String s) {
    }
     
}