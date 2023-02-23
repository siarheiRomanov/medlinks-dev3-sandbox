public with sharing class AppealUtilities {

//    /**
//    * Moved to sync mode because of batch
//    */
//    public static void deleteExitEventsSync(Set<Id> events) {
//        List<Event> eventList = [SELECT Id FROM Event WHERE Id IN :events];
//
//        Database.delete(eventList, false);
//    }
//
//    @Future
//    public static void deleteExitEvents(Set<Id> events) {
//        deleteExitEventsSync(events);
//    }
//
//    /**
//    * Moved to sync mode because of batch
//    */
//    public static void bindExitEventsSync(Set<Id> events) {
//        Set<String>     GUIDs         = new Set<String>();
//        Map<String, Id> guidMap       = new Map<String, Id>();
//        Map<Id, String> appealNameMap = new Map<Id, String>();
//        List<Event>     eventList     = [
//            SELECT Id, WhatId, AppealGUID__c, SkipAppealUpdate__c, Subject, Description
//            FROM Event
//            WHERE Id IN :events AND WhatId = NULL AND AppealGUID__c != NULL
//        ];
//
//        for (Event ev : eventList) {
//            GUIDs.add(ev.AppealGUID__c); // Get batch of GUIDs for the accounts
//        }
//
//        if (!GUIDs.isEmpty()) {
//            for (Appeal__c appeal : [SELECT Id, Name, EventGUID__c FROM Appeal__c WHERE EventGUID__c IN :GUIDs]) {
//                guidMap.put(appeal.EventGUID__c, appeal.Id);
//                appealNameMap.put(appeal.Id, appeal.Name);
//            }
//
//            for (Event ev : eventList) {
//                ev.WhatId = guidMap.get(ev.AppealGUID__c); // Fix the Appeal Id for this event
//                String appealName = appealNameMap.get(ev.WhatId);
//
//                if (appealName != null && ev.Subject != null && ev.Description != null) { // Fix the Appeal Name (case number) for this event
//                    ev.Subject             = ev.Subject.replace('null', appealName);
//                    ev.Description         = ev.Description.replace('null', appealName);
//                    ev.SkipAppealUpdate__c = true;
//                }
//            }
//
//            update eventList;
//        }
//    }
//
//    @Future
//    public static void bindExitEvents(Set<Id> events) {
//        bindExitEventsSync(events);
//    }
//
//    @Future
//    public static void bindExitTasks(Set<Id> tasks) {
//        bindExitTasksSync(tasks);
//    }
//
//    /**
//    * Moved to sync mode because of batch
//    */
//    public static void bindExitTasksSync(Set<Id> tasks) {
//        Set<String>     GUIDs    = new Set<String>();
//        Map<String, Id> guidMap  = new Map<String, Id>();
//        List<Task>      taskList = [
//            SELECT Id, WhatId, AppealGUID__c
//            FROM Task
//            WHERE Id IN :tasks AND WhatId = NULL AND AppealGUID__c != NULL
//        ];
//
//        for (Task st : taskList) {
//            GUIDs.add(st.AppealGUID__c); // Get batch of GUIDs for the accounts
//        }
//
//        if (!GUIDs.isEmpty()) {	// Get associated appeals
//            for (Appeal__c appeal : [SELECT Id, EventGUID__c FROM Appeal__c WHERE EventGUID__c IN :GUIDs]) {
//                guidMap.put(appeal.EventGUID__c, appeal.Id);
//            }
//
//            for (Task st : taskList) {
//                st.WhatId = guidMap.get(st.AppealGUID__c);	// Fix the Appeal Id for this event
//            }
//
//            update taskList;
//        }
//
//    }

//    public static void updateAccountAuditTotals(Account acct, String oldstage, String newstage, Decimal oldamt, Decimal newamt) {
//        if (oldstage == newstage && oldamt == newamt) {
//            return;
//        }
//        if (oldstage != Null) {
//            if (oldstage == 'Pending') {
//                acct.Audits_NumPending__c -= 1;
//                acct.Audits_AmtPending__c -= oldamt;
//            } else if (oldstage == 'Scheduled') {
//                acct.Audits_NumScheduled__c -= 1;
//                acct.Audits_AmtScheduled__c -= oldamt;
//            } else if (oldstage == 'Exit Completed') {
//                acct.Audits_NumExited__c -= 1;
//                acct.Audits_AmtExited__c -= oldamt;
//            } else if (oldstage == 'In Dispute') {
//                acct.Audits_NumDisputed__c -= 1;
//                acct.Audits_AmtDisputed__c -= oldamt;
//            } else if (oldstage == 'Appealed') {
//                acct.Audits_NumAppealed__c -= 1;
//                acct.Audits_AmtAppealed__c -= oldamt;
//            } else if (oldstage == 'Closed') {
//                acct.Audits_NumClosed__c -= 1;
//                acct.Audits_NumClosed__c -= oldamt;
//            } else if (oldstage == 'Canceled') {
//                acct.Audits_NumCanceled__c -= 1;
//                acct.Audits_AmtCanceled__c -= oldamt;
//            }
//        }
//        if (newstage != Null) {
//            if (newstage == 'Pending') {
//                acct.Audits_NumPending__c += 1;
//                acct.Audits_AmtPending__c += newamt;
//            } else if (newstage == 'Scheduled') {
//                acct.Audits_NumScheduled__c += 1;
//                acct.Audits_AmtScheduled__c += newamt;
//            } else if (newstage == 'Exit Completed') {
//                acct.Audits_NumExited__c += 1;
//                acct.Audits_AmtExited__c += newamt;
//            } else if (newstage == 'In Dispute') {
//                acct.Audits_NumDisputed__c += 1;
//                acct.Audits_AmtDisputed__c += newamt;
//            } else if (newstage == 'Appealed') {
//                acct.Audits_NumAppealed__c += 1;
//                acct.Audits_AmtAppealed__c += newamt;
//            } else if (newstage == 'Closed') {
//                acct.Audits_NumClosed__c += 1;
//                acct.Audits_AmtClosed__c += newamt;
//            } else if (newstage == 'Canceled') {
//                acct.Audits_NumCanceled__c += 1;
//                acct.Audits_AmtCanceled__c += newamt;
//            }
//        }
//    }
}