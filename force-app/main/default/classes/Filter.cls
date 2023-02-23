public with sharing class Filter {


	private List<Criteria> criterias;

	/**
	* Filter option
	*/
	public class Criteria {
		/**
		* Logical prefix
		*/
		public String prefix {get; set;}
		/**
		* Id of the criteria
		*/
		public String id {get; private set;}
		/**
		* Filed metadata
		*/
		public FieldMetadata field {get; set;}
		/**
		* Logic operator
		*/
		public Operator operator {get; set;}
		/**
		* Filter optioon value
		*/
		public String value {get; set;}

		/**
		* Check if reuired fields initialized
		*/
		public Boolean isValid() {
			return field != null
			       && String.isNotBlank(field.fieldName)
			       && operator!= null
			       && String.isNotBlank(operator.value)
			       && String.isNotBlank(value);
		}

		private String parseDateTime() {
			String[] dateAndTime = value.split('\\s');
			String[] monthDateYear = dateAndTime[0].split('[\\\\/\\.-]');

			Integer year = monthDateYear.size() > 2 ? Integer.valueOf(monthDateYear[2]) : 0;
			Integer month = monthDateYear.size() > 0 ? Integer.valueOf(monthDateYear[0]) : 0;
			Integer day = monthDateYear.size() > 1 ? Integer.valueOf(monthDateYear[1]) : 0;

			Date dateValue = Date.newInstance(year,
			                                  month,
			                                  day);
			String[] timeItems = dateAndTime[1].split(':');

			Integer hours = timeItems.size() > 0 ? Integer.valueOf(timeItems[0]) : 0;
			Integer minutes = timeItems.size() > 1 ? Integer.valueOf(timeItems[1]) : 0;
			Integer seconds = timeItems.size() > 2 ? Integer.valueOf(timeItems[2]) : 0;
			Time timeValue = Time.newInstance(hours,
			                                  minutes,
			                                  seconds,
			                                  0);

			System.debug('#$#dateValue#$# ' + dateValue.day() + '-' + dateValue.month() + '-' + dateValue.year());
			String rangeExpr = field.fieldName + ' ' + operator.value + ' ' + DateTime.newInstance(dateValue, timeValue).format('yyyy-MM-dd\'T\'hh:mm:ss') + '.000+0000';
			return rangeExpr;
		}

		private String parseDate() {
			String[] monthDateYear = value.split('[\\\\/\\.-]');
			Date dateValue = Date.newInstance(Integer.valueOf(monthDateYear[2]),
			                                  Integer.valueOf(monthDateYear[0]),
			                                  Integer.valueOf(monthDateYear[1]));
			System.debug('#$#dateValue#$# ' + dateValue.day() + '-' + dateValue.month() + '-' + dateValue.year());
			String rangeExpr = field.fieldName + ' ' + operator.value + ' ' + DateTime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
			return rangeExpr;
		}

		private String parseInteger() {
			Integer integerValue = Integer.valueOf(value);
			String rangeExpr = field.fieldName + ' ' + operator.value + ' ' + integerValue;
			return rangeExpr;
		}

		private String parseDouble() {
			Double doubleValue = Double.valueOf(value);
			String rangeExpr = field.fieldName + ' ' + operator.value + ' ' + doubleValue;
			return rangeExpr;
		}

		private String parseRef() {
			String relationFieldName = field.fieldName.replace('__c', '__r') + '.Name';
			String rangeExpr = relationFieldName + operator.value + '\'' + value + '\'';
			return rangeExpr;
		}

		private String parseString() {
			String rangeExpr;
			if ('startswith'.equalsIgnoreCase(operator.value)) {
				operator.value = 'like';
				value = value.replace('%', '\\%') + '%';
				rangeExpr = field.fieldName + ' ' + operator.value + ' ' + '\'' + value + '\'';
			} else if ('contains'.equalsIgnoreCase(operator.value)) {
				operator.value = 'like';
				value = '%' + value.replace('%', '\\%') + '%';
				rangeExpr = field.fieldName + ' ' + operator.value + ' ' + '\'' + value + '\'';
			} else if ('notcontains'.equalsIgnoreCase(operator.value)) {
				operator.value = 'like';
				value = value.replace('%', '\\%') + '%';
				rangeExpr = '(NOT ' + field.fieldName + ' ' + operator.value + ' ' + '\'' + value + '\')';
			} else {
				rangeExpr = field.fieldName + ' ' + operator.value + ' ' + '\'' + value + '\'';
			}
			return rangeExpr;
		}

		private String parseBoolean() {
			if (!'true'.equalsIgnoreCase(value)) {
				value = 'false';
			}
			String rangeExpr = field.fieldName + ' ' + operator.value + ' ' + value;
			return rangeExpr;
		}

		/**
		*Form part of SOQL WHERE clause
		*/
		public String formWhereClause() {
			system.debug(this);
			String rangeExpr = '';
			this.value = String.escapeSingleQuotes(this.value);
			if (FieldMetadata.TYPE_STRING.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_TEXTAREA.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_EMAIL.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PHONE.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_URL.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PICKLIST.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_ID.equalsIgnoreCase(field.fieldDataType) ||
			        //FieldMetadata.TYPE_ENCRYPTED.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_ADDRESS.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = this.parseString();
			}

			if (FieldMetadata.TYPE_DOUBLE.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_PERCENT.equalsIgnoreCase(field.fieldDataType) ||
			        FieldMetadata.TYPE_CURRENCY.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = parseDouble();
			}

			if (FieldMetadata.TYPE_INTEGER.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = parseInteger();
			}

			if (FieldMetadata.TYPE_DATETIME.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = this.parseDateTime();
			}
			if (FieldMetadata.TYPE_DATE.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = this.parseDate();
			}

			if (FieldMetadata.TYPE_REFERENCE.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = this.parseRef();
			}
			if (FieldMetadata.TYPE_BOOLEAN.equalsIgnoreCase(field.fieldDataType)) {
				rangeExpr = this.parseBoolean();
			}
			return rangeExpr;
		}
	}
	/**
	* Filter name
	*/
	public String name {get; set;}

	/**
	* Name of sObject
	*/
	public String objectName {get; set;}

	/**
	* Number of records to select
	*/
	public Integer filterSize {get; set;}

	/**
	* Array of fields to select
	*/
	public String[] fieldSet {get; set;}

	private String initQuery() {
		String query = 'SELECT ';
		for (Integer i = 0; i < fieldSet.size(); i++) {
			query += fieldSet[i];
			if (i != fieldSet.size() - 1) {
				query += ', ';
			} else {
				query += ' ';
			}
		}
		query += 'FROM ' + objectName;
		String whereClause = '';
		//if (criterias.size() > 0) {
		for (Integer i = 0; i < criterias.size(); i++) {
			Criteria criteria = criterias[i];
			if (criteria.isValid()) {
				if (i != 0) {
					whereClause += (String.isBlank(criteria.prefix) ? ' AND ' : ' ' + criteria.prefix + ' ');
				}

				whereClause += criteria.formWhereClause();
			}
		}
		//}
		if (String.isNotBlank(whereClause)) {
			query += (' WHERE ' + whereClause);
		}
		if (this.filterSize != null && filterSize > 0) {
			query += ' LIMIT ' + filterSize;
		}
		return query;
	}
	public Filter(String objectName) {
		this(objectName, null);
	}
	/**
	*
	* @param objectName - API name of the sObject
	* @param fieldset - array of fields to select
	*/
	public Filter(String objectName, String[] fieldSet) {
		this.objectName = objectName;
		if (fieldSet == null || fieldSet.size() == 0) {
			this.fieldSet = new List<String>();
			Schema.DescribeSObjectResult sobjectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
			for (Schema.sObjectField field : sobjectDescribe.fields.getMap().values()) {
				Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
				/*if (ObjectMetadata.FILTER_SUPPORTED_FIELD_DATATYPES.contains(fieldDescribe.getType().name())
				        && !ObjectMetadata.UNSUPPORTED_FIELDS.contains(fieldDescribe.getName())) {*/
				this.fieldSet.add(fieldDescribe.getName());
				//}
			}
			//fieldMetadata.sort();
		} else {
			this.fieldSet = new List<String>(fieldSet);
		}
		criterias = new List<Criteria>();
		this.initQuery();
	}
	/**
	* Form a SOQL query for specified sObject
	*/
	public String getQuery() {
		//this.initQuery();
		//System.debug('###SOQL### ' + query);
		return this.initQuery();
	}

	/**
	* Set array of filter options
	*/
	public void setCriterias(List<Criteria> criterias) {
		this.criterias = new List<Criteria>(criterias);
	}
	/*

		public class Criteria {
			public String objectName {get; set;}
			public String fieldName {get; set;}
			public String fieldLabel {get; set;}
			public String fieldDataType {get; set;}
			public String operation {get; set;}
			public String value {get; set;}
			public Map<String, String> allowedOperators {get; set;}

			public Criteria() {
				this.objectName = '';
				this.fieldName = '';
				this.fieldDataType = '';
				this.operation = '';
				this.value = '';
			}

			public Criteria(Schema.DescribeFieldResult fieldMetadata) {
				this.objectName = '';
				this.fieldName = '';
				this.fieldDataType = '';
				this.operation = '';
				this.value = '';
			}

			public Boolean isValid() {
				if (fieldDataType == 'DATE') {
					return checkDate(value.trim());
				} else if (fieldDataType == 'DATETIME') {
					String[] dateTime4send;
					if (value.trim().containsIgnoreCase('T') && !value.trim().containsIgnoreCase('LAST') && !value.trim().containsIgnoreCase('DAYS') && !value.trim().containsIgnoreCase('MONTH') && !value.trim().containsIgnoreCase('NEXT') && !value.trim().containsIgnoreCase('TODAY')) {
						dateTime4send = value.trim().split('T');
					} else if (value.trim().containsIgnoreCase('LAST') || value.trim().containsIgnoreCase('NEXT')) {
						dateTime4send = new String[] {value};
					} else {
						dateTime4send = value.trim().split(' ');
					}
					if (checkDate(dateTime4send[0])) {
						if (dateTime4send.size() > 1) {
							String[] time4Send = dateTime4send[1].split(':');
							if (time4Send.size() >= 2 && time4Send[0].isNumeric() && Integer.valueOf(time4Send[0]) < 24 && time4Send[1].isNumeric() && Integer.valueOf(time4Send[1]) < 60) {
								if (time4Send.size() == 3 && time4Send[2].split('\\.')[0].isNumeric() && Integer.valueOf(time4Send[2]) < 60) {
									if (time4Send[2].split('\\.').size() == 2) {
										this.value = dateTime4send[0] + 'T' + dateTime4send[1];
									} else {
										this.value = dateTime4send[0] + 'T' + dateTime4send[1] + '.000';
									}
								} else if (time4Send.size() == 2) {
									this.value = dateTime4send[0] + 'T' + dateTime4send[1] + ':00.000';
								} else {
									return false;
								}
							} else {
								return false;
							}
						} else {
							if (!value.trim().containsIgnoreCase('LAST') && !value.trim().containsIgnoreCase('MONTH') && !value.trim().containsIgnoreCase('NEXT') && !value.trim().containsIgnoreCase('TODAY')) {
								this.value = dateTime4send[0] + 'T' + String.valueOf(System.now().hour()) + ':' + String.valueOf(System.now().minute()) + ':00.000';
							}
						}
					} else {
						return false;
					}
				} else {
					try {
						if (fieldDataType == 'CURRENCY' || fieldDataType == 'PERCENT' || fieldDataType == 'DOUBLE') {
							Decimal check = Decimal.valueOf(value);
						} else if (fieldDataType == 'INTEGER') {
							Integer check = Integer.valueOf(value);
						}
					} catch (Exception e) {
						return false;
					}
				}
				return !(String.isEmpty(this.objectName) || String.isEmpty(this.fieldName) || String.isEmpty(this.fieldDataType) || String.isEmpty(this.operation) || String.isEmpty(this.value));
			}

			public Boolean checkDate(String value) {
				if (value.split('-').size() < 3 && value != 'TODAY' &&  value != 'LAST MONTH') {
					value = value.trim();
					String[] daysFormat = value.split(' ');
					if (daysFormat.size() < 3 || daysFormat[0] != 'NEXT' || !daysFormat[1].isNumeric() || Integer.valueOf(daysFormat[1]) == 0 || daysFormat[2] != 'DAYS') {
						return false;
					}
				} else if (value.split('-').size() == 3) {
					try {
						Date check = Date.valueOf(value);
						this.value = String.valueOf(check).split(' ')[0];
					} catch (Exception e) {
						return false;
					}
				}
				if (fieldDataType == 'DATE' && value.trim().contains(':')) {
					return false;
				}
				return true;
			}
		}

		public class RuleCriteriaWrapper {
			public Criteria criterion {get; set;}
			public List<SelectOption> operators {get; set;}
			public String fullFieldName {get; set;}
			public Integer num {get; set;}
			public List<SelectOption> picklistValues {get; set;}

			public RuleCriteriaWrapper(Integer num) {
				criterion = new Criteria();
				this.operators = new List<SelectOption>();
				this.fullFieldName = '';
				this.num = num;
				this.picklistValues = new List<SelectOption>();
			}

			public void selectType(String objectName, String fieldName, String fieldDataType) {
				System.debug(objectName);
				System.debug(fieldName);
				System.debug(fieldDataType);

				picklistValues = new List<SelectOption>();

				if (objectName != NULL && fieldName != NULL && (fieldDataType == 'REFERENCE' || fieldDataType == 'ID')) {

					String refObjName = '';
					if (fieldDataType == 'REFERENCE') {
						Schema.DescribeFieldResult dfr = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
						List<Schema.sObjectType> types = dfr.getReferenceTo();
						System.debug(types);
						refObjName = types[0].getDescribe().getName();
					} else {
						refObjName = objectName;
					}

				}

				if (objectName != NULL && fieldName != NULL && fieldDataType == 'PICKLIST') {
					Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
					Schema.SObjectType objType = gd.get(objectName);
					Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
					Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
					List<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
					for (Schema.PicklistEntry a : values) {
						picklistValues.add(new SelectOption(a.getLabel(), a.getValue()));
					}
				}

				criterion.value = '';

				criterion.objectName = objectName;
				criterion.fieldName = fieldName;
				criterion.fieldDataType = fieldDataType;
				operators = type2operation.get(criterion.fieldDataType);
			}

			public void setCriterion(Criteria criterion) {
				this.criterion = criterion;
				System.debug(criterion);
				this.fullFieldName = this.criterion.objectName + '.' + this.criterion.fieldName;
				operators = type2operation.get(criterion.fieldDataType);
				if (criterion.fieldDataType == 'PICKLIST') {
					Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
					Schema.SObjectType objType = gd.get(criterion.objectName);
					Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
					Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
					List<Schema.PicklistEntry> values = fieldMap.get(criterion.fieldName).getDescribe().getPickListValues();
					for (Schema.PicklistEntry a : values) {
						picklistValues.add(new SelectOption(a.getLabel(), a.getValue()));
					}
				}
				if (criterion.fieldDataType == 'REFERENCE' || criterion.fieldDataType == 'ID') {

					String refObjName = '';
					if (criterion.fieldDataType == 'REFERENCE') {
						Schema.DescribeFieldResult dfr = Schema.getGlobalDescribe().get(criterion.objectName).getDescribe().fields.getMap().get(criterion.fieldName).getDescribe();
						List<Schema.sObjectType> types = dfr.getReferenceTo();
						System.debug(types);
						refObjName = types[0].getDescribe().getName();
					} else {
						refObjName = criterion.objectName;
					}

					String q = 'SELECT Id, Name, Owner.Name FROM ' + refObjName + ' LIMIT 10';
					List<sObject> objs = Database.query(q);
					for (sObject obj : objs) {
						picklistValues.add(new SelectOption((String)obj.get('Id'), (String)obj.get('Name') + ' (' + (String)obj.get('Owner.Name') + ')'));
					}
				}
			}
		}
		*/
}