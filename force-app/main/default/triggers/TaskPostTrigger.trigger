trigger TaskPostTrigger on Task (after insert) {
	Set <Id> bindTasks = new Set <Id>();

	for (Task st : Trigger.new) {
//		if (st.WhatId == null && (st.AppealGUID__c != null || st.AuditGUID__c != null)) {	// Do we have a null audit id?
		if (st.WhatId == null && st.AuditGUID__c != null) {	// Do we have a null audit id?
			bindTasks.add(st.Id);
		}
	}
	if (!bindTasks.isEmpty()) {
		System.debug('Invoking bindExitTasks');
		// sync logic
		if (System.isBatch() || System.isFuture() || System.isScheduled()) {
			AuditUtilities.bindExitTasksSync(bindTasks);
//			AppealUtilities.bindExitTasksSync(bindTasks);
		} else {
		// async logic
			AuditUtilities.bindExitTasks(bindTasks);	// Also as a future
//			AppealUtilities.bindExitTasks(bindTasks);	// Also as a future
		}
	}
}