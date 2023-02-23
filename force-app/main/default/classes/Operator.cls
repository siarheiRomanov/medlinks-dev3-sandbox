/**
* Represent query operator
*/
public class Operator {

	public Operator(String value, String label) {
		this.value = value;
		this.label = label;
	}

	public String value {get; set;}
	public String label {get; set;}

	public static Operator createEquals() {
		return new Operator('=', 'equals');
	}
	public static Operator createNotEquals() {
		return new Operator('!=', 'not equals');
	}
	public static Operator createLessOrEquals() {
		return new Operator('<=', 'less or equals');
	}
	public static Operator createGreater() {
		return new Operator('>', 'greater');
	}
	public static Operator createLess() {
		return new Operator('<', 'less');
	}

	public static Operator createGreaterOrEquals() {
		return new Operator('>=', 'greater or equals');
	}
	public static Operator createStartsWith() {
		return new Operator('startswith', 'starts with');
	}
	public static Operator createContains() {
		return new Operator('contains', 'contains');
	}
	public static Operator createNotContains() {
		return new Operator('notcontains', 'not contains');
	}
}