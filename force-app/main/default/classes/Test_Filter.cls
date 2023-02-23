@isTest
private class Test_Filter {

	private static final AuditReportSettings__c AUDIT_REPORT_SETTINGS = AuditReportSettings__c.getOrgDefaults();
	private static final String NO_FILTER = 'no_filter';
	private static final String[] AUDIT_FIELDS = new String[] {'Id', 'NAME', 'Audit_Stage__c',
	        'Patient_Account__c', 'Account__r.Name', 'Audit_Type__c', 'Audit_Amount__c', 'Patient_Name__c',
	        'Patient_MR__c', 'Account__r.Shortname__c', 'IsUploaded__c'/*,
                                          'AUDIT_TYPE__C', 'BILL_ANALYSIS_COMPLETE__C', 'BILL_UPLOADED__C', 'CLIENT_AUDIT_ACCOUNT__C', 'DATE_ACTUAL_EXIT__C',
                                          'DATE_AUDIT_COMPLETED__C', 'DATE_BILL_RECEIVED__C', 'DATE_BILL_REQUESTED__C', 'DATE_CHART_PULL_REQUESTED__C', 'DATE_LOI__C',
                                          'DATE_PROPOSED_EXIT__C', 'EVENTGUID__C', 'EXIT_DURATION__C', 'EXIT_MODE__C', 'FACILITY_BILLING_CONTACT__C', 'FACILITY_IS_CLIENT__C',
                                          'FACILITY_MR_CONTACT__C', 'OPPOSING_AUDIT_ACCOUNT__C', 'OPPOSING_AUDITOR__C', 'OPPOSING_SCHEDULER__C', 'PATIENT_ACCOUNT__C', 'PATIENT_DOB__C',
                                          'PATIENT_DOBEDIT__C', 'PATIENT_FIRST_NAME__C', 'PATIENT_LAST_NAME__C', 'PATIENT_MR__C', 'PATIENT_NAME__C', 'PAYER_TYPE__C', 'PAYER__C',
                                          'SERVICE_END_DATE__C', 'SERVICE_START_DATE__C', 'SKIPEVENTUPDATE__C', 'TAMT_ADJ__C', 'TAMT_REVISED__C', 'TAMT_SUMOVER__C', 'TAMT_SUMUNDER__C',
                                          'TOTAL_SERVICE_DAYS__C',
                                          'XFLAG__C', 'XN1__C', 'XN2__C', 'XN3__C', 'XN4__C', 'XPA__C', 'XPD__C', 'XPM__C', 'XPN__C',
                                          'FLAGGED_ITEMS__C', 'TAMT_BILLED__C', 'TAMT_DISALLOWED__C', 'TAMT_DISPUTED__C', 'TAMT_OTHER__C', 'TAMT_OVER__C', 'TAMT_UNBILL__C', 'TAMT_UNDER__C', 'TAMT_NOMD__C', 'TOT_ITEMS__C', 'AUDIT_CONTRACTOR_EXPENSE__C', 'AUDIT_GROSS_REVENUE__C', 'AUDIT_NET_REVENUE__C', 'PATIENT_AUTH_DATE__C', 'PERCENT_DISALLOWED__C', 'PERCENT_DISPUTED__C', 'PERCENT_NET_ADJ__C', 'PERCENT_OVER__C', 'PERCENT_UNDER__C', 'PRE_AUDIT_DIS__C', 'TOTAL_DISP_ADJ__C', 'DATE_AUDIT_RESULTS_DELIVERED__C', 'DATE_BILL_ANALYSIS_COMPLETE__C', 'DATE_CHART_PULL_CONFIRMED__C', 'CURRENTUSERROLES__C', 'BILL_ATTACHED_AS_IMAGE__C', 'DATE_AUDIT_CANCELED__C', 'NEED_OPPOSING__C', 'OPPOSING_AUDIT_CASE_ID__C', 'INVOICE_NUMBER__C', 'EXIT_PAST_DUE_DAYS__C', 'PERCENT_TOT_ERR__C', 'APPROVED__C', 'NOT_APPROVED__C', 'DATE_LOI_SENT__C', 'DRG_VALIDATION_OK__C', 'DRG_VALIDATION_ALTERED__C', 'COMMENTS__C', 'AUDIT_POLICY_SENT_DATE__C'
                                        */
	                                                          };
	@isTest static void testFilterWithParameters() {
		String objectName = 'Audit__c';
		Filter auditFilter = new Filter(objectName, AUDIT_FIELDS);
		String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';

		auditFilter.setCriterias((List<Filter.Criteria>)JSON.deserialize(criteriaJson, List<Filter.Criteria>.class));
		auditFilter.filterSize = null;
		String purgeQuery = auditFilter.getQuery();
	}

	@isTest static void testFiltersWithAllFields() {
		String objectName = 'Audit__c';
		Filter auditFilter = new Filter(objectName);
		String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';

		//auditFilter.setCriterias(criterias);
		auditFilter.filterSize = null;
		auditFilter.setCriterias((List<Filter.Criteria>)JSON.deserialize(criteriaJson, List<Filter.Criteria>.class));
		String purgeQuery = auditFilter.getQuery();
		System.assertNotEquals(purgeQuery, null);
	}
	@isTest static void testFiltersWithCriterias() {
		String objectName = 'Audit__c';
		Filter auditFilter = new Filter(objectName);
		//String criteriaJson = '[{"value":"10000","prefix":"AND","operator":{"value":"<=","label":null},"id":"1","field":{"isReference":false,"fieldName":"Audit_Amount__c","fieldLabel":"Audit Amount","fieldDataType":"CURRENCY","allowedOperators":[{"value":"=","label":"equals"},{"value":"!=","label":"not equals"},{"value":"<","label":"less"},{"value":"<=","label":"less or equals"},{"value":">=","label":"greater or equals"}]}}]';
		List<Filter.Criteria> criterias = new List<Filter.Criteria>();
		ObjectMetadata auditMetadata = new ObjectMetadata('Audit__c');
		Integer idx = 1;
		for (FieldMetadata field : auditMetadata.fieldMetadata) {
			Filter.Criteria criteria = new Filter.Criteria();
			criteria.prefix = 'AND';
			//criteria.id = (idx++) +'';
			criteria.field = field;
			criteria.operator = field.allowedOperators[0];
			criteria.value = '2012';
			if (FieldMetadata.TYPE_STRING.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_TEXTAREA.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_EMAIL.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PHONE.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_URL.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PICKLIST.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_ID.equalsIgnoreCase(field.fieldDataType) ||
			        //FieldMetadata.TYPE_ENCRYPTED.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_ADDRESS.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '2012';
			}

			if (FieldMetadata.TYPE_DOUBLE.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PERCENT.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_CURRENCY.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '2012';
			}

			if (FieldMetadata.TYPE_INTEGER.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '2012';
			}

			if (FieldMetadata.TYPE_DATETIME.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '2012/03/03 12:48';
			}
			if (FieldMetadata.TYPE_DATE.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '2012/03/03';
			}

			if (FieldMetadata.TYPE_REFERENCE.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = '1234421';
			}
			if (FieldMetadata.TYPE_BOOLEAN.equalsIgnoreCase(field.fieldDataType)) {
				criteria.value = 'TRUE';
			}
			criterias.add(criteria);
		}
		//auditFilter.setCriterias(criterias);
		auditFilter.filterSize = null;
		auditFilter.setCriterias(criterias);
		String purgeQuery = auditFilter.getQuery();
		System.assertNotEquals(purgeQuery, null);
	}

}