trigger EventPostTrigger on Event (after insert, after update) {

	Set<Id> delEvents  = new Set<Id>();
	Set<Id> bindEvents = new Set<Id>();

	for (Event ev : Trigger.new) {
		if (ev.DeleteAfterUpdate__c) {
			delEvents.add(ev.Id);			// Flagged by Audit trigger for deletion
		} else if (ev.WhatId == null) { 		// Do we have a null audit id?
			bindEvents.add(ev.Id);
		}
	}
	if (System.isBatch() || System.isFuture() || System.isScheduled()) {
		System.debug('Invoking #sync');
		if (!delEvents.isEmpty()) {
			AuditUtilities.deleteExitEventsSync(delEvents);	// Must do it as a Future method !
//			AppealUtilities.deleteExitEventsSync(delEvents);	// Must do it as a Future method !
		}
		
		if (!bindEvents.isEmpty()) {
			AuditUtilities.bindExitEventsSync(bindEvents);	// Also as a future
//			AppealUtilities.bindExitEventsSync(bindEvents);	// Also as a future
		}
	} else {
		System.debug('Invoking #async');
		if (!delEvents.isEmpty()) {
			AuditUtilities.deleteExitEvents(delEvents);	// Must do it as a Future method !
//			AppealUtilities.deleteExitEvents(delEvents);	// Must do it as a Future method !
		}
		
		if (!bindEvents.isEmpty()) {
			System.debug('Invoking bindExitEvents');
			AuditUtilities.bindExitEvents(bindEvents);	// Also as a future
//			AppealUtilities.bindExitEvents(bindEvents);	// Also as a future
		}
	}
}