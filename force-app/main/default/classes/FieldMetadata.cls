/**
* meradata for filter
*/
public class FieldMetadata implements Comparable {
	public static final String TYPE_DATETIME = 'DATETIME';
	public static final String TYPE_DATE = 'DATE';
	public static final String TYPE_ID = 'ID';
	public static final String TYPE_REFERENCE = 'REFERENCE';
	public static final String TYPE_BOOLEAN = 'BOOLEAN';
	public static final String TYPE_STRING = 'STRING';

	public static final String TYPE_DOUBLE = 'DOUBLE';
	public static final String TYPE_CURRENCY = 'CURRENCY';
	public static final String TYPE_INTEGER = 'INTEGER';
	public static final String TYPE_PERCENT = 'PERCENT';
	public static final String TYPE_TEXTAREA = 'TEXTAREA';
	public static final String TYPE_PICKLIST = 'PICKLIST';
	public static final String TYPE_EMAIL = 'EMAIL';
	public static final String TYPE_PHONE = 'PHONE';
	public static final String TYPE_URL = 'URL';
	public static final String TYPE_ADDRESS = 'ADDRESS';
	public static final String TYPE_ENCRYPTED = Schema.DisplayType.EncryptedString.name();

	public static Map<String, List<Operator>> DATATYPE_ALLOWED_OPERATORS = new Map<String, List<Operator>> {
		TYPE_DATETIME => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createGreater(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_DATE => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_ID => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createStartsWith()},
		//TYPE_ENCRYPTED => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_REFERENCE => new List<Operator>{Operator.createEquals(), Operator.createNotEquals()},
		TYPE_BOOLEAN => new List<Operator>{Operator.createEquals(), Operator.createNotEquals()},
		TYPE_STRING => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_DOUBLE => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_CURRENCY => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_INTEGER => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_PERCENT => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createLess(), Operator.createLessOrEquals(), Operator.createGreaterOrEquals()},
		TYPE_TEXTAREA => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_PICKLIST => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_EMAIL => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_PHONE => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_URL => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()},
		TYPE_ADDRESS => new List<Operator>{Operator.createEquals(), Operator.createNotEquals(), Operator.createContains(), Operator.createNotContains(), Operator.createStartsWith()}
	};

	public String fieldName {get; set;}
	public String fieldLabel {get; set;}
	public String fieldDataType {get; set;}
	public Boolean isReference {get; set;}
	//public String referencedSObject {get; set;}
	public List<Operator> allowedOperators {get; set;}

	public FieldMetadata(Schema.DescribeFieldResult fieldMetadata) {
		fieldName = fieldMetadata.getName();
		fieldLabel = fieldMetadata.getLabel();
		fieldDataType = fieldMetadata.getType().name();

		isReference = TYPE_REFERENCE.equalsIgnoreCase(fieldDataType);

		allowedOperators = DATATYPE_ALLOWED_OPERATORS.get(fieldDataType.toUpperCase());
	}

	public Integer compareTo(Object compareTo) {
		FieldMetadata other = (FieldMetadata)compareTo;
		return this.fieldLabel.compareTo(other.fieldLabel);
	}
}