@isTest
private class Test_AuditUtilities {


	@isTest static void testUpdateAccountAuditTotals() {
		Account acct = new Account();
		Decimal oldAmount = 1;
		Decimal newAmount = 2;
		acct.Audits_NumPending__c = 0;
		acct.Audits_AmtPending__c = 0;
		acct.Audits_NumScheduled__c = 0;
		acct.Audits_AmtScheduled__c = 0;
		acct.Audits_NumExited__c = 0;
		acct.Audits_AmtExited__c = 0;
		acct.Audits_NumDisputed__c = 0;
		acct.Audits_AmtDisputed__c = 0;
		acct.Audits_NumAppealed__c = 0;
		acct.Audits_AmtAppealed__c = 0;
		acct.Audits_NumClosed__c = 0;
		acct.Audits_AmtClosed__c = 0;
		acct.Audits_NumCanceled__c = 0;
		acct.Audits_AmtCanceled__c = 0;
		String[] stages = new String[] {'Pending'
		                                , 'Scheduled'
		                                , 'Exit Completed'
		                                , 'In Dispute'
		                                , 'Appealed'
		                                , 'Closed'
		                                , 'Canceled'
		                               };
		for (String oldStage : stages) {
			for (String newStage : stages) {
				AuditUtilities.updateAccountAuditTotals(acct, oldStage, newStage, oldAmount++, newAmount++);
			}
		}
	}

}