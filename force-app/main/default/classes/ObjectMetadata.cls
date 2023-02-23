public class ObjectMetadata {
	public static Set<String> FILTER_SUPPORTED_FIELD_DATATYPES = new Set<String> {
		FieldMetadata.TYPE_DATETIME,
		FieldMetadata.TYPE_DATE,
		FieldMetadata.TYPE_ID,
		FieldMetadata.TYPE_REFERENCE,
		FieldMetadata.TYPE_BOOLEAN,
		FieldMetadata.TYPE_STRING,
		FieldMetadata.TYPE_DOUBLE,
		FieldMetadata.TYPE_CURRENCY,
		FieldMetadata.TYPE_INTEGER,
		FieldMetadata.TYPE_PERCENT,
		FieldMetadata.TYPE_TEXTAREA,
		FieldMetadata.TYPE_PICKLIST,
		FieldMetadata.TYPE_EMAIL,
		FieldMetadata.TYPE_PHONE,
		FieldMetadata.TYPE_URL,
		FieldMetadata.TYPE_ADDRESS
		//,
		//FieldMetadata.TYPE_ENCRYPTED
	};
	
	public static Set <String> UNSUPPORTED_FIELDS = new Set<String> {
		'Patient_First_Name__c',
		'Patient_Last_Name__c',
		'Patient_DOBedit__c',
		'Patient_Auth_Date__c'
	};

	public String name {get; set;}
	public List<FieldMetadata> fieldMetadata {get; set;}
	public ObjectMetadata(String sObjectName) {
		fieldMetadata = new List<FieldMetadata>();
		Schema.DescribeSObjectResult sobjectDescribe = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
		name = sobjectDescribe.getName();
		for (Schema.sObjectField field : sobjectDescribe.fields.getMap().values()) {
			Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
			if (FILTER_SUPPORTED_FIELD_DATATYPES.contains(fieldDescribe.getType().name()) && !UNSUPPORTED_FIELDS.contains(fieldDescribe.getName())) {
				fieldMetadata.add(new FieldMetadata(fieldDescribe));
			}
		}
		fieldMetadata.sort();
	}
}