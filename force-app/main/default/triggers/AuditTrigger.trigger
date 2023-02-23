trigger AuditTrigger on Audit__c (before insert, before update) {

	List<Event> evUpList = new List<Event>();
	List<Task> stUpList = new List<Task>();
	Map<Id,Contact> conMap = new Map<Id,Contact>();
	
	Set<Id> acctIDs = new Set<Id>();
	for (Audit__c audit : Trigger.new) {
		acctIDs.add(audit.Account__c);		// Fetch ALL Account IDs related to this audit and read into a map
		if (audit.Client_Audit_Account__c != Null) {
			acctIDs.add(audit.Client_Audit_Account__c);
		}
		if (audit.Opposing_Audit_Account__c != Null) {
			acctIDs.add(audit.Opposing_Audit_Account__c);
		}
		if (trigger.isUpdate) { // Unfortunately, we even have to add any accounts that might have been referenced previously			
			Id oldclient = trigger.oldMap.get(audit.Id).Client_Audit_Account__c;
			Id oldopp = trigger.oldMap.get(audit.Id).Opposing_Audit_Account__c;
			if (oldclient != Null && oldclient != audit.Client_Audit_Account__c) {
				acctIDs.add(oldclient);
			}
			if (oldopp != Null && oldopp != audit.Opposing_Audit_Account__c) {
				acctIDs.add(oldopp);
			}
		}
	}
	Map<Id, Account> acctMap = new Map<Id, Account> ([Select Id, Name,
	 Audits_NumAppealed__c, Audits_NumExited__c, Audits_NumDisputed__c, Audits_NumPending__c,
	 Audits_NumScheduled__c, Audits_NumClosed__c, Audits_NumCanceled__c,
	 Audits_AmtAppealed__c, Audits_AmtExited__c, Audits_AmtDisputed__c, Audits_AmtPending__c,
	 Audits_AmtScheduled__c, Audits_AmtClosed__c, Audits_AmtCanceled__c 	 
	 FROM Account WHERE Id in :acctIDs]);
	
    for (Audit__c audit : Trigger.new) {
        
        // First process the Facility-Audit Client state based on Facility Is Client checkbox:
        
        if (audit.Facility_Is_Client__c) {
            // Thanks to validators, all we have to do is to ensure the Client Audit Account is set
            if (audit.Client_Audit_Account__c == NULL) {
                audit.Client_Audit_Account__c = audit.Account__c;    // Copy the id
            }
        }
        else {
            // If not set, it is still possible that the Facility and the Client have been set to the same account
            if (audit.Client_Audit_Account__c == audit.Account__c) {
                audit.Facility_Is_Client__c = True;    // Set the checkbox
            }    
        }
        // Resolve opposing scheduler/auditor fields
        
        Contact scon = null;
        Contact acon = null;
        ID oppconID = null;
        String oppaname = null;
        
        //if (audit.Audit_Type__c == 'Concurrent' ||			// TODO: Types should be defined in file 
        //	audit.Audit_Type__c == 'Focused Department' ||
        //	audit.Audit_Type__c == '(DNFB) Done Not Final Billed' ||
        //	audit.Audit_Type__c == 'Private Patient' ||
        //	audit.Audit_Type__c == 'Focused Timeframe') {
        // Redefined 12/8/11: Defense requires opposing; all other types it is optional (no errors)
        if (audit.Audit_Type__c != 'Defense') {				
        	audit.Need_Opposing__c = false;	// No opposing auditor/scheduler for this audit case
        	//String em = 'No Opposing Auditor/Scheduler should be defined for this audit type';
        	//if (audit.Opposing_Scheduler__c != null)
        	//	audit.Opposing_Scheduler__c.addError(em);
        	//if (audit.Opposing_Auditor__c != null)
        	//	audit.Opposing_Auditor__c.addError(em);
        	//if (audit.Opposing_Audit_Account__c != null)
        	//	audit.Opposing_Audit_Account__c.addError(em);        		        	
        }
        else {
        	audit.Need_Opposing__c = true; // Default is opposing required
        	        	
	        if (audit.Opposing_Scheduler__c != null) {        	
	        	scon = conMap.get(audit.Opposing_Scheduler__c);
	        	if (scon == null) {
	        		scon = [SELECT Id, Name, Contact.Account.Name, isScheduler__c, Omit_Invite_Task__c from Contact where ID = :audit.Opposing_Scheduler__c];
	        		conMap.put(scon.Id, scon);
	        	}
	        }
	        if (audit.Opposing_Auditor__c != null) {
	        	acon = conMap.get(audit.Opposing_Auditor__c);
	        	if (acon == null) {
	        		acon = [SELECT Id, Name, Contact.Account.Name, isScheduler__c, Omit_Invite_Task__c from Contact where ID = :audit.Opposing_Auditor__c];
	        		conMap.put(acon.Id, acon);
	        	}
	        }	       
	        if (scon == null && acon != null && acon.IsScheduler__c) {
	        	audit.Opposing_Scheduler__c = audit.Opposing_Auditor__c;	// If auditor is also scheduler, copy it
	        	scon = acon;
	        }
	        if (scon != null && scon.Account.Name != null) {
	        	oppaname = scon.Account.Name;
	        } 
	        if (scon != null && scon.Omit_Invite_Task__c) {
	        	if (acon != null) {
	        		oppconID = acon.Id;	// Auditor is primary event contact
	        	}
	        }
	        else if (scon != null) {
	        	oppconID = scon.Id;	// Scheduler is primary event contact
	        }
        }        
        // See if we have a field change on Date Proposed Exit and create/update Event if so
        // Note that validation routines prevent this unless all required states are satisfied 
        
        if (!audit.SkipEventUpdate__c) {		// Skip update if anti-recursion semaphore set
        	
        	Boolean canceled = Trigger.isInsert? False : (Trigger.oldMap.get(audit.Id).Audit_Stage__c != audit.Audit_Stage__c && audit.Audit_Stage__c == 'Canceled');
        	Boolean closed = Trigger.isInsert? False : (Trigger.oldMap.get(audit.Id).Audit_Stage__c != audit.Audit_Stage__c && audit.Audit_Stage__c == 'Closed');
        	Boolean exited = Trigger.isInsert? False : (Trigger.oldMap.get(audit.Id).Audit_Stage__c != audit.Audit_Stage__c && audit.Audit_Stage__c == 'Exit Completed');        	
        	Datetime priorexit = Trigger.isInsert? Null : Trigger.oldMap.get(audit.Id).Date_Proposed_Exit__c;
	        String priorduration = Trigger.isInsert? Null : Trigger.oldMap.get(audit.Id).Exit_Duration__c;
	        String priormode = Trigger.isInsert? Null : Trigger.oldMap.get(audit.Id).Exit_Mode__c;	        
	        Integer duration = 0;
	        Boolean skipevent = False;
	        Boolean newauditor = Trigger.isInsert? False : Trigger.oldMap.get(audit.Id).Assigned_Auditor__c != audit.Assigned_Auditor__c;
        	Boolean newoppsched = Trigger.isInsert? False : Trigger.oldMap.get(audit.Id).Opposing_Scheduler__c != audit.Opposing_Scheduler__c;        		
        	Boolean newoppaud = Trigger.isInsert? False : Trigger.oldMap.get(audit.Id).Opposing_Auditor__c != audit.Opposing_Auditor__c;        	
        	
        	if (audit.EventGUID__c != Null) {        
        		// Existing exit event - first check if we must delete/cancel
        		Boolean killdate = audit.Date_Proposed_Exit__c == Null;        	
        		if (newauditor || newoppsched || newoppaud || killdate || canceled) {
        			try {	// Yep - fetch the event and set flags to delete (cancel) it
        				Event ev = [Select ID, SkipAuditUpdate__c, DeleteAfterUpdate__c, AuditGUID__c from Event WHERE AuditGUID__c = :audit.EventGUID__c ];
        				ev.AuditGUID__c = Null;
        				ev.SkipAuditUpdate__c = True;
        				ev.DeleteAfterUpdate__c = True; // Force event to kill itself after it clears the GUID
        				evUpList.add(ev);
        			} catch (Exception e){ // Fail gracefully in case the Event rec is missing	        			
	        		}
	        		audit.EventGUID__c = Null;	// No prior event, so no update 
	        		priorexit = Null;
	        		if (audit.Audit_Stage__c == 'Scheduled') {
	        			audit.Audit_Stage__c = 'Pending';		// Reset stage
	        		}	        		 
        		}
        	}
        	if (canceled || audit.Date_Proposed_Exit__c == Null || audit.Assigned_Auditor__c == Null || audit.Assigned_Scheduler__c == Null
        	   || (audit.Need_Opposing__c && oppconID == Null)) {
	        	skipevent = True;		// Can't create new event since one or more required fields are missing
        		if (audit.Audit_Stage__c == 'Scheduled') {
        			audit.Audit_Stage__c = 'Pending';		// Reset stage
        		}	        		         		        	
	        }
	        if (!skipevent && (priorexit != audit.Date_Proposed_Exit__c || priorduration != audit.Exit_Duration__c
	         || priormode != audit.Exit_Mode__c || newauditor || newoppsched || newoppaud)) {
	        	
	        	// There has been an update to the exit event's schedule/mode/participants
	        	Datetime start;
	        	Boolean allday = false;
	        	String sub;
	        	String loc;
	        	
	        	if (audit.Exit_Duration__c.startsWith('All')) {
	        		duration = 0;	// All day
	        	}
	        	else if (audit.Exit_Duration__c.contains('Minutes')) {
	        		duration = Integer.ValueOf(audit.Exit_Duration__c.substring(0,2));        		
	        	}
	        	else if (audit.Exit_Duration__c.contains('Hour')){
	        		duration = Integer.ValueOf(audit.Exit_Duration__c.substring(0,1)) * 60;        		
	        	}
	        	if (duration == 0) {
	        		allday = True;
	        		start = datetime.newInstance(audit.Date_Proposed_Exit__c.date(),time.newinstance(0,0,0,0));
	        	}
	        	else {
	        		start = audit.Date_Proposed_Exit__c;	// Timed event
	        	}
	        	if (audit.Exit_Mode__c.contains('In Person')) {		// Meeting
	        		sub = 'Audit Exit Meeting';        			
	        		if (audit.Exit_Mode__c.contains('Facility')) {
	        			loc = 'At facility';
	        		}
	        		else {
	        			loc = 'TBD';
	        		}   				
	    		}
	    		else {
	        		sub = 'Audit Exit Call';					// Call or video
	        		loc = audit.Exit_Mode__c;
	    		}	        	
	        	if (audit.EventGUID__c != null) {
	        		try {							// Got an event already - update it
	        			Event ev = [SELECT Id, IsAllDayEvent, StartDateTime, DurationInMinutes from Event WHERE AuditGUID__c = : audit.EventGUID__c ];
						ev.StartDateTime = start;
						ev.IsAllDayEvent = allday;						
						if (duration > 0) {
	        				ev.DurationInMinutes = duration;
	        			}
	        			if (priormode != audit.Exit_Mode__c) { // Update mode if changed
	        				ev.Subject = sub + ': ' + 'Case ' + audit.Name + ' ' + acctMap.get(audit.Account__c).Name;
	        				ev.Location = loc;	        				
	        			}
	        			ev.SkipAuditUpdate__c = True;	// Flag to prevent trigger recursion	        		
	        			evUpList.add(ev);
	        		} catch (Exception e){
	        			priorexit = Null;	// Whoops - force create of new Event
	        			audit.EventGUID__c = Null;
	        		}
	        	}        	
	        	if (audit.EventGUID__c == Null) {
	        		Event ev = new Event();		// Create the new event object
	        		ev.StartDateTime = start;
					ev.IsAllDayEvent = allday;						
					if (duration > 0) {
	        			ev.DurationInMinutes = duration;
	        		}	        			        		
	        		// Fill in the details, including case number, facility name, patient acct and obfuscated name
	        		// Note that audit.Name will be null if this is a new audit with exit date entered
	        		// The null in Event Subject and Description will be updated in the future method bindExitEvents
	        		ev.Subject = sub + ': ' + 'Case ' + audit.Name + ' ' + acctMap.get(audit.Account__c).Name;
	        		ev.Location = loc;
	        		integer ol = (audit.Patient_Name__c == Null? audit.Patient_Last_Name__c.trim().length() : audit.Patient_Name__c.length());
	        		ol = (ol < 4? 1: 3);
	        		String obsname = (audit.Patient_Name__c == Null? audit.Patient_Last_Name__c.trim().substring(0,ol) + '*': audit.Patient_Name__c.substring(0,ol) + '*');        		
	        		ev.Description = 'Audit Exit for Medlinks case ' + audit.Name + ': ' + audit.Patient_Account__c + ' ' + obsname;
	        		if (acon != null) {
	        			ev.Description += '; External Auditor: ' + acon.Name;
	        			if (oppaname != null) {	        		
	        				ev.Description += ' (' + oppaname + ')';
	        			}
	        		}
	        		if (audit.Opposing_Audit_Case_ID__c != null && audit.Opposing_Audit_Case_ID__c != '') {
	        			ev.Description += '; External Audit Case #:' + audit.Opposing_Audit_Case_ID__c;
	        		}
	        		ev.OwnerId = audit.Assigned_Auditor__c;
	        		ev.WhatId = audit.Id;		// Bind it to this audit IF UPDATE. New requires post insert fixup
	        		if (audit.Need_Opposing__c) {
	        			ev.WhoId = oppconID;		// And to the opposing contact (scheduler OR auditor)
	        		}
	        		// Just to make sure we can identify this task as the one we created, create a GUID and stow in both recs
	        		String GUID = EncodingUtil.base64Encode(Crypto.GenerateAESKey(128));
	        		ev.AuditGUID__c = GUID;
	        		ev.SkipAuditUpdate__c = True;	// Flag to prevent trigger recursion
	        		EvUpList.add(ev);				// Stow Event in insert list
	        		audit.EventGUID__c = GUID;      // Save GUID in Audit rec
	        		if (audit.Need_Opposing__c && !scon.Name.contains('To Be Determined')) {
		        		// Ok, so now we create a task for the Scheduler to update the event and add the opposing scheduler
		        		// as an invitee. Necessary thanks to sfdc disabling access to the invitee API...
		        		Task st = new Task();
		        		datetime dt;
		        		if (date.today().daysBetween(start.date()) > 120) {
		        			date acd = start.date().addDays(-120);	// ** Don't invite until 120 days before
		        			st.ActivityDate = acd;
		        			dt = datetime.newInstance(acd, time.newinstance(12,0,0,0));        		
		        			st.ReminderDateTime = dt;	// pop up reminder at noon   		        		        				        		
		        		}
		        		else {
		        			st.ActivityDate = Date.Today(); // Invite TODAY!
		        			dt = datetime.now();        		
		        			st.ReminderDateTime = dt.addhours(1);	// pop up an hour from now if they haven't done it..   		        		        				        	
		        		}
		        		st.Description = 'A new Audit Exit event has been scheduled for ' + acctMap.get(audit.Account__c).Name; 
		  				st.Description += '\r\nPlease make sure the Opposing Scheduler/Auditor is added as an invitee to the event.';      		
		        		st.Description += '\r\nEdit the event, and click the \'Add to Invitees\' link next to the Opposing Scheduler/Auditor name.';
						st.IsReminderSet = True;
						st.OwnerId = audit.Assigned_Scheduler__c;	// Assign to our scheduler
						st.Priority = 'High';
						st.Status = 'In Progress';
		        		st.Subject = 'Audit Exit scheduled: Invite Opposing Scheduler/Auditor';
		        		st.WhatId = audit.Id;		// Bind to Audit. If null, will be set in bindExitTasks future method
		        		st.WhoId = oppconID;		// Primary contact - scheduler OR auditor
		        		st.AuditGUID__c = GUID;		// Save GUID as link to audit AND event
		        		StUpList.add(st);
	        		}        		        	
	        	}
   	       		if (audit.Audit_Stage__c == 'Pending') {
        			audit.Audit_Stage__c = 'Scheduled';		// ** TODO - Should be done via EventAttendee triggers
        		}	        		              	
	        }
	        if (canceled) {
	        	audit.Date_Audit_Canceled__c = datetime.now();
	        }
			if (closed) {
				audit.Date_Audit_Completed__c = date.today();
			}
			if (exited) {
				// Update from AuditDetailGridExt upon Exit Complete post - create followup tasks for auditor and scheduler
				Task st = new Task();
        		datetime dt;
    			st.ActivityDate = Date.Today(); // Task starts today
    			dt = datetime.now();        		
    			st.ReminderDateTime = dt.addDays(3);	// Reminder 3 days from now   		        		        				        	
        		st.Description = 'Exit Completed: Audit Case ' + audit.Name + ' for ' + acctMap.get(audit.Account__c).Name;
        		st.Description += '\r\n\r\nThe assigned auditor must deliver the following within 10 days:';
  				st.Description += '\r\n\r\n- Sign-off documents, both Medlinks and opposing firm.';
  				st.Description += '\r\n- Supporting documentation for all items placed in dispute. Documentation may reference either medical records or payer/provider policies.';
  				st.Description += '\r\n- Copy of check (if applicable), or explanation if check is not required.';
  				st.Description += '\r\n- Handwritten notes and all other materials used to formulate the audit findings, including those from the opposing auditor.';  
  				st.Description += '\r\n\r\nOnce you receive the materials, scan and save all documents, and send the audit results to the facility.';
  				st.Description += '\r\n\r\nWhen this task\'s status is set to "Completed", the audit case will be closed and the Medlinks billing process will be initiated.';
				st.IsReminderSet = True;
				st.OwnerId = audit.Assigned_Scheduler__c;	// Assign to our scheduler
				st.Priority = 'High';
				st.Status = 'In Progress';
        		st.Subject = 'Exit Completed: Acquire documents from auditor';
        		st.WhatId = audit.Id;	// Bind to Audit
        		// st.WhoId = audit.Assigned_Auditor__c;
        		st.CloseAudit__c = true;	// Flag for workflow rule to update audit status upon task completion	
        		StUpList.add(st);

				Task at = new Task();
        		at.ActivityDate = Date.Today(); // Task starts today
    			dt = datetime.now();        		
    			at.ReminderDateTime = dt.addDays(3);	// Reminder 3 days from now   		        		        				        	
        		at.Description = 'Exit Completed: Audit Case ' + audit.Name + ' for ' + acctMap.get(audit.Account__c).Name;
        		at.Description += '\r\n\r\nPlease deliver the following to the Medlinks office manager within 10 days:';
  				at.Description += '\r\n\r\n- Sign-off documents, both Medlinks and opposing firm.';
  				at.Description += '\r\n- Supporting documentation for all items placed in dispute. Documentation may reference either medical records or payer/provider policies.';
  				at.Description += '\r\n- Copy of check (if applicable), or explanation if check is not required.';
  				at.Description += '\r\n- Handwritten notes and all other materials used to formulate the audit findings, including those from the opposing auditor.';  
  				at.Description += '\r\n\r\nDocuments should be scanned separately and saved as a PDF with clearly identifiable file name (e.g., "Audit_Fee_Smith,Jane_123.pdf").';
  				at.IsReminderSet = True;
				at.OwnerId = audit.Assigned_Auditor__c;	// Assign to auditor
				at.Priority = 'High';
				at.Status = 'In Progress';
        		at.Subject = 'Exit Completed: Send Documentation to Medlinks';
        		at.WhatId = audit.Id;	// Bind to Audit
        		// at.WhoId = audit.Assigned_Scheduler__c;	// Reference the scheduler	
        		StUpList.add(at);
			}    
	    }
        audit.SkipEventUpdate__c = False;	// Clear the audit rec anti-recursion semaphore
        
        // Next we process the encrypted fields to ensure HIPAA/HITECH compliance, but ONLY if this is a full page edit
        
        if (audit.XFlag__c == 1) {		// Full page edit TODO: Mask bit 1
        
	        String dset = 'Active';
        	String pdate = NULL;
        	if (audit.Patient_DOBedit__c != NULL) {		// DOB is optional
	        	Date pd = audit.Patient_DOBedit__c;
        		pdate = String.valueOf(pd);				
        	}
        	String pname = audit.Patient_Last_Name__c.trim() + ', ' + audit.Patient_First_Name__c.trim();
        	String pacct = audit.Patient_Account__c;
        	String pmr = audit.Patient_MR__c;
        	List<String> xname = new String[4];
	        
        	audit.Patient_Name__c = pname;	// Set the encrypted database fields
        	audit.Patient_DOB__c = pdate;
        	audit.Patient_Last_Name__c = NULL;	// Clear the edit fields
        	audit.Patient_First_Name__c = NULL;
        	audit.Patient_DOBedit__c = NULL;
        	audit.XFlag__c = 0;					// TODO: And it to clear
        
	        audit.XPN__c = ePHIclass.encrypt(pname, dset);	// Full name
        	ePHIclass.genxs(pname, xname, dset);			// HMAC prefix segments
        	audit.XN1__c = xname[0];						// 1 letter
        	audit.XN2__c = xname[1];						// 2 letters
        	audit.XN3__c = xname[2];						// 3 letters
        	audit.XN4__c = xname[3];						// 4 letters
	        
    	    audit.XPA__c = ePHIclass.encrypt(pacct, dset);	// Account #
	      
        	// DOB and MR are optional
        	audit.XPD__c = (pdate != NULL && pdate.length() > 0) ? ePHIclass.encrypt(pdate, dset): NULL;	// DOB
        	audit.XPM__c = (pmr != NULL && pmr.length() > 0 ) ? ePHIclass.encrypt(pmr, dset): NULL;	// Medical Record #
        }        
        // If XFlag is not set, must be an inline edit from a view page, which may include encrypted fields. Thus
        // it is possible the user mucked with patient info fields. The best thing is to just let them
        // be updated via the record update...        
                
        // If payer type or dates of service change when bill is loaded we really need to re-scan and update the items
      	// TODO: For now, just use validation rule to prevent
        
		// Now update the count and dollar totals on account(s) related to this Audit rec
		
		String oldstage = null;
		String newstage = null;
		Decimal oldamt = 0;
		Decimal newamt = 0;
		Boolean newclient = false;
		Boolean newopp = false;
		if (trigger.isUpdate) {
			oldstage = trigger.oldMap.get(audit.Id).Audit_Stage__c;
			oldamt = trigger.oldMap.get(audit.Id).Audit_Amount__c;
			id oldclient = trigger.oldMap.get(audit.Id).Client_Audit_Account__c;
			id oldopp = trigger.oldMap.get(audit.Id).Opposing_Audit_Account__c;
			if (oldclient != Null && oldclient != audit.Client_Audit_Account__c) {
				// Change of client - update prior
				AuditUtilities.updateAccountAuditTotals(acctMap.get(oldclient), oldstage, newstage, oldamt, newamt);
				newclient = true;
			}			
			if (oldopp != Null && oldopp != audit.Opposing_Audit_Account__c) {
				// Change of opposing - update prior
				AuditUtilities.updateAccountAuditTotals(acctMap.get(oldopp), oldstage, newstage, oldamt, newamt);
				newopp = true;								
			}
			newstage = audit.Audit_Stage__c;
			newamt = audit.Audit_Amount__c;
			// Update facility account totals
			AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Account__c), oldstage, newstage, oldamt, newamt);
			
			// Update client and opp account totals
			if (audit.Client_Audit_Account__c != Null && audit.Client_Audit_Account__c != audit.Account__c) {
				String os = (newclient? Null: oldstage);	// if new one, no old update
				AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Client_Audit_Account__c), os, newstage, oldamt, newamt);
			}
			if (audit.Opposing_Audit_Account__c != Null) {
				String os = (newopp? Null: oldstage);	// if new one, no old update
				AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Opposing_Audit_Account__c), os, newstage, oldamt, newamt);
			}																			
		}
		else {
			// Insert - no prior values to update
			oldstage = null;
			newstage = audit.Audit_Stage__c;
			newamt = audit.Audit_Amount__c;
			// Update facility account
			AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Account__c), oldstage, newstage, oldamt, newamt);
			// Update client and opp account totals
			if (audit.Client_Audit_Account__c != Null && audit.Client_Audit_Account__c != audit.Account__c) {
				AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Client_Audit_Account__c), oldstage, newstage, oldamt, newamt);
			}
			if (audit.Opposing_Audit_Account__c != Null) {
				AuditUtilities.updateAccountAuditTotals(acctMap.get(audit.Opposing_Audit_Account__c), oldstage, newstage, oldamt, newamt);
			}
		}			
    } // Iterate all Audit recs
    // Audit Trigger completed
    
    if (!evUpList.isEmpty()) {
    	upsert evUpList;			// Add/update events	
    }
    if (!stUpList.isEmpty()) {
    	upsert stUpList;			// Add any tasks
    }
    update acctMap.Values();		// Update accounts    
}