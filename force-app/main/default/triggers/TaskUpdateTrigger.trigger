trigger TaskUpdateTrigger on Task (before update) {
    Set <Id> auditIds  = new Set <Id>();
//    Set <Id> appealIds = new Set <Id>();

    // Find all post-exit tasks that are now completed
    for (Task st : Trigger.new) {
        if (Trigger.oldMap.get(st.Id).Status != st.Status && st.Status == 'Completed' && st.WhatId != null) {
            if (st.CloseAudit__c) {
                auditIds.add(st.WhatId);
            }

//            if (st.CloseAppeal__c) {
//                appealIds.add(st.WhatId);
//            }
        }
    }

    if (!auditIds.isEmpty()) {   
        List<Task> stUpList = new List<Task>(); 
        List<Audit__c> audList = new List<Audit__c>([SELECT Id, Name, Account__r.Name, Audit_Stage__c, Date_Audit_Completed__c FROM Audit__c
         WHERE Id IN :auditIds]);
        User coo = [SELECT Id, Name FROM User WHERE User_is_Billing_Manager__c = TRUE LIMIT 1]; // TODO: MUST BE EXACTLY ONE
        for (Audit__c audit: audList) {
            if (audit.Audit_Stage__c == 'Exit Completed') { // Ensure expected stage
                audit.Audit_Stage__c = 'Closed';
                audit.Date_Audit_Completed__c = Date.today();
                // Create new task to initiate billing process
                Task st = new Task();
                Datetime dt;
                st.ActivityDate = Date.today(); // Task starts today
                dt = Datetime.now();
                st.ReminderDateTime = dt.addDays(5);    // Reminder 5 days from now                                                             
                st.Description = 'Audit Completed: Audit Case ' + audit.Name + ' for ' + audit.Account__r.Name;
                st.IsReminderSet = true;
                st.OwnerId = coo.Id;    // Assign to billing manager
                st.Priority = 'High';
                st.Status = 'In Progress';
                st.Subject = 'Audit Completed: Initiate billing process';
                st.WhatId = audit.Id;   // Bind to Audit
                stUpList.add(st);
            }
        }

        update audList;
        insert stUpList;
    }

//    if (!appealIds.isEmpty()) {
//        List<Task>      stUpList   = new List<Task>();
//        User            coo        = [
//            SELECT Id, Name
//            FROM User
//            WHERE User_is_Billing_Manager__c = TRUE
//            LIMIT 1
//        ]; // TODO: MUST BE EXACTLY ONE
//
//        List<Appeal__c> appealAnalysisCompleteList = new List<Appeal__c>();
//
//        List<Appeal__c> updatedAppeals = new List<Appeal__c>();
//
//        for (Appeal__c appeal: [
//                SELECT Id, Name, Facility__r.Name, Appeal_Stage__c, Date_Appeal_Completed__c, Analysis_Complete__c
//                FROM Appeal__c
//                WHERE Id IN :appealIds
//        ]) {
//            if (appeal.Appeal_Stage__c == 'Appeal Complete') { // Ensure expected stage
//                appeal.Appeal_Stage__c          = 'Closed';
//                appeal.Date_Appeal_Completed__c = Date.today();
//
//                if (appeal.Analysis_Complete__c) {
//                    appeal.Analysis_Complete__c = false;
//                    appealAnalysisCompleteList.add(appeal);
//                }
//                updatedAppeals.add(appeal);
//
//                // Create new task to initiate billing process
//                Task     st = new Task();
//                Datetime dt;
//
//                st.ActivityDate     = Date.today(); // Task starts today
//                dt                  = Datetime.now();
//                st.ReminderDateTime = dt.addDays(5);    // Reminder 5 days from now
//                st.Description      = 'Appeal Completed: Appeal Case ' + appeal.Name + ' for ' + appeal.Facility__r.Name;
//                st.IsReminderSet    = true;
//                st.OwnerId          = coo.Id;    // Assign to billing manager
//                st.Priority         = 'High';
//                st.Status           = 'In Progress';
//                st.Subject          = 'Appeal Completed: Initiate billing process';
//                st.WhatId           = appeal.Id;   // Bind to Audit
//                stUpList.add(st);
//            }
//        }
//
//        update updatedAppeals;
//
//        List<Appeal__c> analysisCompleteAppeals = new List<Appeal__c>();
//
//        for (Appeal__c appeal: appealAnalysisCompleteList) {
//            appeal.Analysis_Complete__c     = true;
//            analysisCompleteAppeals.add(appeal);
//        }
//
//        if (!analysisCompleteAppeals.isEmpty()) {
//            update analysisCompleteAppeals;
//        }
//
//        insert stUpList;
//    }

}