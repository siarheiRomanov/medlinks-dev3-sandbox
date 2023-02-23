public with sharing class AuditReportUploadLog {
	public static final String STATE_SUCCESS = 'ok';
	public static final String STATE_FAIL = 'fail';

	private Map<String, Set<Id>> auditIdStateMap = new Map<String, Set<Id>>();

	public AuditReportUploadLog() {
		auditIdStateMap.put(STATE_SUCCESS, new Set<Id>());
		auditIdStateMap.put(STATE_FAIL, new Set<Id>());
	}

	public void logSuccess(Id auditId) {
		if (auditIdStateMap.get(STATE_FAIL).contains(auditId)) {
			auditIdStateMap.get(STATE_FAIL).remove(auditId);
		}
		auditIdStateMap.get(STATE_SUCCESS).add(auditId);
	}

	public void logError(Id auditId) {
		if (auditIdStateMap.get(STATE_SUCCESS).contains(auditId)) {
			auditIdStateMap.get(STATE_SUCCESS).remove(auditId);
		}
		auditIdStateMap.get(STATE_FAIL).add(auditId);
	}

	public Set<Id> getSuccessfulyUploadedAudits() {
		return auditIdStateMap.get(STATE_SUCCESS);
	}

	public Set<Id> getFailedToUploadAudits() {
		return auditIdStateMap.get(STATE_FAIL);
	}
}