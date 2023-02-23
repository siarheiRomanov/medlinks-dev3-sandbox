trigger AuditItemTrigger on AuditItem__c (before insert) {
	
	// First, iterate through the batch and build set of audit masters (can't assume that the
	// batch will all have the same master, right???)
	
	Set<Id> auditIDs = new Set<Id>();
	For (AuditItem__c item: Trigger.new ) {
		auditIDs.add(item.Audit_Master__c);		
	}
	
	// Now fetch the one (or more) Audit masters to a Map, with the fields we need
	
	Map<Id, Audit__c> auditMap = new Map<Id, Audit__c>(
		[SELECT Name, Account__c, Audit_Amount__c, Payer_Type__c, Service_Start_Date__c, Service_End_Date__c from Audit__c where ID in :auditIDs]);
		
	// Iterate through the Audit masters, creating their associated sets of CDM items, based on Payer type AND CDM MASTER DATE
		
	for (Id aid : auditIDs ) { 			// For each Audit ID in the set
		Audit__c master = auditMap.get(aid);		// Get the Audit master
		
		system.debug('Master dates = ' + String.ValueOf(master.Service_Start_Date__c) + '-' + String.ValueOf(master.Service_End_Date__c));
		CDM__c currentCDM = null;		
		List <CDM__c> matchCDMs = new List <CDM__c>(	// Get the set of CDMS from this facility, for this date range
			[SELECT Id, Effective_Date_Start__c, Effective_Date_End__c, Facility__c
			 FROM CDM__c WHERE Facility__c = :master.Account__c
			 AND (
			 ((Effective_Date_Start__c <= :master.Service_Start_Date__c
			     AND Effective_Date_End__c = NULL)
			   OR (Effective_Date_Start__c <= :master.Service_Start_Date__c
			     AND Effective_Date_End__c >= :master.Service_Start_Date__c))			 			 
			 OR ((Effective_Date_Start__c <= :master.Service_End_Date__c
			     AND Effective_Date_End__c = NULL)
			   OR (Effective_Date_Start__c <= :master.Service_End_Date__c
			     AND Effective_Date_End__c >= :master.Service_End_Date__c)) 
			 )
			 ORDER BY Effective_Date_Start__c DESC]);
		// 9/7 - Use current as default, if any	 
		if (matchCDMs.size() == 0) {
			try {
				currentCDM = [SELECT Id, Facility__c, Effective_Date_End__c FROM CDM__c
			 	WHERE Facility__c = :master.Account__c AND Effective_Date_End__c = NULL];
			}
			catch (Exception e) {
				currentCDM = null;
			}			 
		}
		// We have 0 to n CDMs which match the service dates, from newest to oldest, PLUS THE CURRENT CDM
		// Create a charge code set for each.
		
		Map<ID, Set<String>> cdmsets = new Map<ID, Set<String>>();	
		Set<String> cn = new Set<String>(); 	// Create a new set for the associated CDM items
				
		for (AuditItem__c item: Trigger.new ) {	// And then re-scan the entire trigger list
			if (item.Audit_Master__c == master.Id) {	// Only for current master!
				system.debug('Item Date = ' + String.Valueof(item.Date_of_Service__c));
				Boolean foundit=false;
				item.Err_Code__c = 0;			// Clear the error flags
				item.Flagged__c = False;																		
				for (CDM__c c : matchCDMs) {	// Find the appropriate CDM, if any
					system.debug('CDM Date = ' + string.valueof(c.Effective_Date_Start__c));
					if (item.Date_of_Service__c > = c.Effective_Date_Start__c
					&& (c.Effective_Date_End__c == Null || c.Effective_Date_End__c >= item.Date_of_Service__c)) {
						cn = cdmsets.get(c.Id);	// Found one - get the current set of charge codes
						system.debug('Found it');
						foundit=true;
						item.CDM_Master__c = c.Id;	// *Stow the CDM id in the item rec												
						if (cn == Null) {			// Create new set under this CDM Id
							cdmsets.put(c.Id, new Set<String>{item.Bill_Charge_Code__c});
						}
						else {
							cn.add(item.Bill_Charge_Code__c);
							cdmsets.put(c.Id, cn);		// Update the set under this CDM Id
						}
						break;	// Once a CDM is matched, exit the CDM iteration						
					}
				}
				// Found, or didn't find, a matching CDM item...
				if (!foundit && currentCDM != null) {
					// USE THE CURRENT CDM AS SOURCE
					cn = cdmsets.get(currentCDM.Id);
					item.CDM_Master__c = currentCDM.Id;	// *Stow the CDM id in the item rec
					item.Err_Code__c = 16;				// Preset the error code to 'Current CDM default'												
					if (cn == Null) {			// Create new set under this CDM Id
						cdmsets.put(currentCDM.Id, new Set<String>{item.Bill_Charge_Code__c});
					}
					else {
						cn.add(item.Bill_Charge_Code__c);
						cdmsets.put(currentCDM.Id, cn);		// Update the set under this CDM Id
					}
				} 				
			}
		}
				
		// We have the full, non-duplicated set(s) of CDM charge codes for this Audit Master
		// Build the query for the CDM recs based on associated CDM master and specific payer code
		// NB: Usually only 1 CDM matched to a bill; will be 2 only in very unlikely case that a 
		// bill's service dates spanned across a CDM update. However, this logic supports n CDMs.
		
		Map <Id, Map<String, Id>> ChargeItemMap = new Map <Id, Map<String, Id>>();
		Map <Id, CDMItem__c> ChargeItemSet = new Map <Id, CDMItem__c>();
		for (Id cdmid : cdmsets.KeySet()) {	// Iterate through CDM set list					
			cn = cdmsets.get(cdmid);	// Get charge code set for this CDM
			system.debug('Set size = ' + String.valueof(cn.size()));	
			String HCPCS = master.Payer_Type__c + '_HCPCS_Code__c';	// Prepend the 3 letter payer code
			String Rev = master.Payer_Type__c + '_Rev_Code__c';
			String qs = 'select ID, Name, CDM_Master__c, Audit_Dept__c, Charge_Amount__c, ' + HCPCS + ', ' + Rev;
			qs += ' from CDMItem__c WHERE Name IN :cn AND CDM_Master__c = :cdmid';
			Map <Id, CDMItem__c> cquery = new Map <Id, CDMItem__c>((CDMItem__c[])Database.query(qs));
				
			// Now go through the CDMItem list and create yet another map that links the Id to the Name (Charge Code)
			
			Map <String, Id> cmap = new Map <String, Id>();		
			for (ID cidt: cquery.keyset()) {			// Iterate on the key set of ID's
				CDMItem__c crec = cquery.get(cidt);	// Get the Item rec
				cmap.put(crec.Name, cidt);		// Map name to id
			}			
			ChargeItemMap.put(cdmid, cmap); 	// Now put this map into the master charge item map
			ChargeItemSet.putAll(cquery);		// And add the CDMItems to the master set
		} // Iterate CDMs
					
		// Finally, we iterate through the AuditItems one more time and update them
		
		for (AuditItem__c item: Trigger.new) {
			if (item.Audit_Master__c == master.Id) { // Must only look at current Audit Master detail recs!
				//item.Err_Code__c = 1;			// Init the flags to 'NO CDM ERROR'
				//item.Flagged__c = True;
				if (item.CDM_Master__c != Null) {	// Did we find a charge code CDM for this item?
					ID cItemid = ChargeItemMap.get(item.CDM_Master__c).get(item.Bill_Charge_Code__c);												
					if (cItemid != null) {
						// Got it!
						//item.Err_Code__c = 0;			// Reset the flags
						//item.Flagged__c = False;												
						CDMItem__c gotCDM = ChargeItemSet.get(cItemid);		// Fetch the CDM Item rec from the master set
						String HCPCS = master.Payer_Type__c + '_HCPCS_Code__c';	// Prepend the 3 letter payer code
						String Rev = master.Payer_Type__c + '_Rev_Code__c';
						if (item.Audit_Dept_Code__c == null)			
							item.Audit_Dept_Code__c = gotCDM.Audit_Dept__c;	// Copy Dept Code ID IFF not already set
						item.CDM_HCPCS_Code__c = (String)gotCDM.get(HCPCS);	// Copy payer's HCPCS code string 
						item.CDM_Rev_Code__c = (Id)gotCDM.get(Rev);			// Copy payer's Rev Code ID
						item.CDM_Charge_Code__c = cItemid;					// Id of the CDM Item -> Name = Code
						if (item.Bill_Unit_Price__c != gotCDM.Charge_Amount__c) {
							// Whoops - the bill price doesn't match the CDM amount - flag the error
							// Since this is an insert of new recs, just set the Error Code = 2 rather than twiddling bits
							Integer f = item.Err_Code__c.intValue(); 
							item.Err_Code__c = f |(1<<1);	// Set bit 1
							//item.Flagged__c = True;		// Set the flag
						}
					}										
				}
				if (item.CDM_Charge_Code__c == null) {
					item.Err_Code__c = 1;	// No CDM (overrides bit 4 if set)
				}
				// CDM data completed - check service date
				
				if (item.Date_of_Service__c < master.Service_Start_Date__c || item.Date_of_Service__c > master.Service_End_Date__c) {
					// Bad date - set error code (by ORing bit) and flag
					Integer f = item.Err_Code__c.intValue(); // 0,1, or 2
					item.Err_Code__c = f |(1<<2);	// Set bit 2
					//item.Flagged__c = True;										
				}
				// Check qty and total
				if (item.Bill_Qty__c == 0) {
					// Zero quantity is FATAL ERROR, unless this is an insert of an 'unbilled' item
					if (item.Not_Billed_Code__c == null || !item.Not_Billed_Code__c.startsWith('X')) {
						item.Bill_Qty__c.addError('Quantity cannot be zero');	// Error
					}
				}
				else {
					Double dd = item.Bill_Total__c/item.Bill_Qty__c;	// Calculate unit price
					if (dd != item.Bill_Unit_Price__c) {
						// Unit price entered on item is incorrect. Save it, correct it, and flag the error
						item.Bill_UP_Original__c = item.Bill_Unit_Price__c;
						item.Bill_Unit_Price__c = dd;
						item.Bill_UP_Override__c = True;
						Integer f = item.Err_Code__c.intValue();
						item.Err_Code__c = f |(1<<3);	// Set bit 3
						//item.Flagged__c = True;											
					}
					
				}
				if (item.Err_Code__c != 0)
					item.Flagged__c = True;			
				// AuditItem update completed
			} // Next AuditItem with this Audit Master					
		} // Iterate Audit Items 						
	} // Iterate Audit Masters	
	// Trigger complete
}