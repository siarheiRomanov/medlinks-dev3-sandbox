public class Audit {
	public String id {get; set;}
	public String auditNumber {get; set;}
	public String stage {get; set;}
	public String patientName {get; set;}
	public String patientAccount {get; set;}
	public String facility {get; set;}
	public String auditType {get; set;}
	public String auditAmount {get; set;}

	public Audit(Audit__c srcAudit) {
		this.id = srcAudit.id;
		this.auditNumber = srcAudit.Name;
		this.stage = srcAudit.Audit_Stage__c;
		this.patientName = srcAudit.Patient_Name__c;
		this.patientAccount = srcAudit.Patient_Account__c;
		this.facility = srcAudit.Account__r.Name;
		this.auditType = srcAudit.Audit_Type__c;
		this.auditAmount = srcAudit.Audit_Amount__c + '';
	}
}