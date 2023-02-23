public with sharing class DynamicWrapperClass {
    @AuraEnabled
    public Map<String, Map<String, Object>> objectFields;
    @AuraEnabled
    public List<Map<String, Map<String, Object>>> listObjectFields;
    @AuraEnabled
    public String objectName;

    static Id clientAccountId;
    static Id facilityAccountId;
    static Id payerAccountId;
    static Id thirdPartyFieldAccountId;
    static Id appealId;
    static Id overreadContactId;
    static Id facilityPrimaryContactId;
    static Id opposingSchedulerContactId;
    static Id opposingSpecialistContactId;
    static Id appealSchedulerUserId;
    static Id assignedSchedulerUserId;
    static Id appealSpecialistUserId;

    static Integer appealNotesCount;

    private static final String OBJECT_APPEAL      = Schema.SObjectType.Appeal__c.name;
    private static final String OBJECT_ACCOUNT     = Schema.SObjectType.Account.name;
    private static final String OBJECT_CONTACT     = Schema.SObjectType.Contact.name;
    private static final String OBJECT_USER        = Schema.SObjectType.User.name;
    private static final String OBJECT_NOTE        = Schema.SObjectType.Note.name;
    private static final String DATE_CURRENT_DAY   = 'Date: Current Day';
    private static final String DATE_CURRENT_MONTH = 'Date: Current Month';
    private static final String DATE_CURRENT_YEAR  = 'Date: Current Year';
    private static final String DAY                = 'day';
    private static final String MONTH              = 'month';
    private static final String YEAR               = 'year';
    private static final String MONTH_FORMAT       = 'MMMM';
    private static Map<String, Schema.SObjectField> objectFieldMap;

    public static Map<String, String> getMetadataFromObject(String objectName) {
        Map<String, String> objectLabelApiMap = new Map<String, String>();
        Schema.SObjectType  objectDescribe    = Schema.getGlobalDescribe().get(objectName);

        objectFieldMap = objectDescribe.getDescribe().fields.getMap();

        for (Schema.SObjectField field : objectFieldMap.values()) {
            objectLabelApiMap.put(field.getDescribe().getLabel(), field.getDescribe().getName());
        }

        return getSortedMap(objectLabelApiMap);
    }

    private static Map<String, String> getSortedMap(Map<String, String> objectLabelApiMap) {
        Map<String, String> resultObjectLabelApiMap = new Map<String, String>();
        List<String>        objectLabelApiKeyList   = new List<String>(objectLabelApiMap.keySet());

        objectLabelApiKeyList.sort();

        for (String objectLabelApiKey : objectLabelApiKeyList) {
            resultObjectLabelApiMap.put(objectLabelApiKey, objectLabelApiMap.get(objectLabelApiKey));
        }

        return resultObjectLabelApiMap;
    }

    public static String getFieldsQuery(Map<String, String> objectMetadata) {
        List<String> sObjectFields = new List<String>();

        for (String key: objectMetadata.keySet()) {
            sObjectFields.add(objectMetadata.get(key));
        }

        String query = 'SELECT ';

        for (Integer i = 0; i < sObjectFields.size(); i++) {
            if (i == sObjectFields.size() - 1) {
                query += sObjectFields[i];
            } else {
                query += sObjectFields[i] + ', ';
            }
        }

        return query;
    }

    public static void addValuesToMap(Map<String, String> objectMetadata, List<SObject> queryResults, DynamicWrapperClass wrapper, String sObjectName, Set<String> removedFields) {
        for (String key: objectMetadata.keySet()) {
            String apiName = objectMetadata.get(key);

            if (removedFields == null || !removedFields.contains(apiName)) {
                Object value = queryResults[0].get(apiName) != null ? queryResults[0].get(apiName) : '';

                if (objectFieldMap.get(apiName).getDescribe().getType() == Schema.DisplayType.DATE) {
                    value = value != '' ? ((Datetime)value).formatGmt('MM-dd-yyyy') : value;
                }

                Map<String, Object> apiValue = new Map<String, Object>();

                apiValue.put(sObjectName + '_' + apiName, value);
                wrapper.objectFields.put(sObjectName + ': ' + key, apiValue);
            }
        }
    }

    public static void getAppeal(Id appealId, DynamicWrapperClass wrapper) {
        Map<String, String> appealMetadata = getMetadataFromObject(OBJECT_APPEAL);

        appealMetadata.remove(String.valueOf(Appeal__c.fields.Link_To_Main_Document__c));

        String query = getFieldsQuery(appealMetadata);

        query += ' FROM ' + OBJECT_APPEAL + ' WHERE Id = :appealId';

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(query)
        );

        List<Appeal__c> appeals = (List<Appeal__c>)decision.getRecords();

        if (clientAccountId == null) {
            clientAccountId = appeals[0].Client_Account__c;
        }

        if (facilityAccountId == null) {
            facilityAccountId = appeals[0].Facility__c;
        }

        if (payerAccountId == null) {
            payerAccountId = appeals[0].Payer__c;
        }

        if (overreadContactId == null) {
            overreadContactId = appeals[0].Overread_By__c;
        }

        if (facilityPrimaryContactId == null) {
            facilityPrimaryContactId = appeals[0].Facility_Contact_Primary__c;
        }

        if (thirdPartyFieldAccountId == null) {
            thirdPartyFieldAccountId = appeals[0].Third_Party_Firm__c;
        }

        if (opposingSchedulerContactId == null) {
            opposingSchedulerContactId = appeals[0].Opposing_Scheduler__c;
        }

        if (opposingSpecialistContactId == null) {
            opposingSpecialistContactId = appeals[0].Opposing_Appeals_Specialist__c;
        }

        if (appealSchedulerUserId == null) {
            appealSchedulerUserId = appeals[0].Appeal_Scheduler__c;
        }

        if (assignedSchedulerUserId == null) {
            assignedSchedulerUserId = appeals[0].Assigned_Scheduler__c;
        }

        if (appealSpecialistUserId == null) {
            appealSpecialistUserId = appeals[0].Assigned_Appeals_Specialist__c;
        }

        appealNotesCount = getAppealNotesCount(appealId);

        addValuesToMap(appealMetadata, appeals, wrapper, OBJECT_APPEAL, decision.getRemovedFields().get(OBJECT_APPEAL));
    }

    private static Integer getAppealNotesCount(Id parentId) {
        // CRUD FLS security check is bypassed due to standard object without this sort of security setting
        return [SELECT COUNT() FROM Note WHERE ParentId = :parentId];
    }

    public static void getNotes(Id parentId, DynamicWrapperClass wrapper) {
        if (appealNotesCount > 0) {
            Map<String, String> notesMetadata = getMetadataFromObject(OBJECT_NOTE);
            String              query         = getFieldsQuery(notesMetadata);

            query += ' FROM ' + OBJECT_NOTE + ' WHERE ParentId = :parentId';

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            List<Note> notes = (List<Note>)Database.query(query);

            for (Note note : notes) {
                Map<String, Map<String, Object>> oneNoteItem = new Map<String, Map<String, Object>>();

                for (String key: notesMetadata.keySet()) {
                    String              apiName  = notesMetadata.get(key);
                    Object              value    = note.get(apiName) != null ? note.get(apiName) : '';
                    Map<String, Object> apiValue = new Map<String, Object>();

                    apiValue.put(OBJECT_NOTE + '_' + apiName, value);
                    oneNoteItem.put(OBJECT_NOTE + ': ' + key, apiValue);
                }

                wrapper.listObjectFields.add(oneNoteItem);
            }
        }
    }

    public static SObjectAccessDecision getSobjectAccessDecision(String sobjectName, Set<Id> recordIds) {
        Map<String, String> sobjectMetadata = getMetadataFromObject(sobjectName);
        String              query           = getFieldsQuery(sobjectMetadata);

        query += ' FROM ' + sobjectName + ' WHERE Id IN :recordIds';

        return Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(query)
        );
    }

    public static void getSobject(List<SObject> sobjects, DynamicWrapperClass wrapper, String fieldName, Set<String> deletedFields, String sobjectName) {
        if (!sobjects.isEmpty()) {
            addValuesToMap(getMetadataFromObject(sobjectName), sobjects, wrapper, fieldName, deletedFields);
        }
    }

    public static DynamicWrapperClass getAppealWrapper(Id recordId, DynamicWrapperClass wrapper) {
        appealId = recordId;

        getAppeal(appealId, wrapper);

        Set<Id> accountIds = new Set<Id>{
            facilityAccountId,
            clientAccountId,
            payerAccountId,
            thirdPartyFieldAccountId
        };

        SObjectAccessDecision accountAccessDecision = getSobjectAccessDecision(OBJECT_ACCOUNT, accountIds);
        Map<Id, SObject>      accountsMap           = new Map<Id, SObject>(accountAccessDecision.getRecords());

        getSobject(
            accountsMap.get(facilityAccountId) == null ? new List<SObject>() : new List<SObject>{accountsMap.get(facilityAccountId)},
            wrapper,
            'Facility',
            accountAccessDecision.getRemovedFields().get(OBJECT_ACCOUNT),
            OBJECT_ACCOUNT
        );
        getSobject(
            accountsMap.get(clientAccountId) == null ? new List<SObject>() : new List<SObject>{accountsMap.get(clientAccountId)},
            wrapper,
            'ClientAccount',
            accountAccessDecision.getRemovedFields().get(OBJECT_ACCOUNT),
            OBJECT_ACCOUNT
        );
        getSobject(
            accountsMap.get(payerAccountId) == null ? new List<SObject>() : new List<SObject>{accountsMap.get(payerAccountId)},
            wrapper,
            'Payer',
            accountAccessDecision.getRemovedFields().get(OBJECT_ACCOUNT),
            OBJECT_ACCOUNT
        );
        getSobject(
            accountsMap.get(thirdPartyFieldAccountId) == null ? new List<SObject>() : new List<SObject>{accountsMap.get(thirdPartyFieldAccountId)},
            wrapper,
            'ThirdPartyFirm',
            accountAccessDecision.getRemovedFields().get(OBJECT_ACCOUNT),
            OBJECT_ACCOUNT
        );

        Set<Id> contactIds = new Set<Id>{
            overreadContactId,
            facilityPrimaryContactId,
            opposingSchedulerContactId,
            opposingSpecialistContactId
        };

        SObjectAccessDecision contactAccessDecision = getSobjectAccessDecision(OBJECT_CONTACT, contactIds);
        Map<Id, SObject>      contactsMap           = new Map<Id, SObject>(contactAccessDecision.getRecords());

        getSobject(
            contactsMap.get(overreadContactId) == null ? new List<SObject>() : new List<SObject>{contactsMap.get(overreadContactId)},
            wrapper,
            'OverreadSpecialist',
            contactAccessDecision.getRemovedFields().get(OBJECT_CONTACT),
            OBJECT_CONTACT
        );
        getSobject(
            contactsMap.get(facilityPrimaryContactId) == null ? new List<SObject>() :new List<SObject>{contactsMap.get(facilityPrimaryContactId)},
            wrapper,
            'FacilityPrimary',
            contactAccessDecision.getRemovedFields().get(OBJECT_CONTACT),
            OBJECT_CONTACT
        );
        getSobject(
            contactsMap.get(opposingSchedulerContactId) == null ? new List<SObject>() : new List<SObject>{contactsMap.get(opposingSchedulerContactId)},
            wrapper,
            'PeerToPeerScheduler',
            contactAccessDecision.getRemovedFields().get(OBJECT_CONTACT),
            OBJECT_CONTACT
        );
        getSobject(
            contactsMap.get(opposingSpecialistContactId) == null ? new List<SObject>() : new List<SObject>{contactsMap.get(opposingSpecialistContactId)},
            wrapper,
            'PeerToPeerSpecialist',
            contactAccessDecision.getRemovedFields().get(OBJECT_CONTACT),
            OBJECT_CONTACT
        );

        Set<Id> userIds = new Set<Id>{
            appealSchedulerUserId,
            assignedSchedulerUserId,
            appealSpecialistUserId
        };

        SObjectAccessDecision userAccessDecision = getSobjectAccessDecision(OBJECT_USER, userIds);
        Map<Id, SObject>      usersMap           = new Map<Id, SObject>(userAccessDecision.getRecords());

        getSobject(
            usersMap.get(appealSchedulerUserId) == null ? new List<SObject>() : new List<SObject>{usersMap.get(appealSchedulerUserId)},
            wrapper,
            'AppealScheduler',
            userAccessDecision.getRemovedFields().get(OBJECT_USER),
            OBJECT_USER
        );
        getSobject(
            usersMap.get(assignedSchedulerUserId) == null ? new List<SObject>() : new List<SObject>{usersMap.get(assignedSchedulerUserId)},
            wrapper,
            'AssignedPM',
            userAccessDecision.getRemovedFields().get(OBJECT_USER),
            OBJECT_USER
        );
        getSobject(
            usersMap.get(appealSpecialistUserId) == null ? new List<SObject>() : new List<SObject>{usersMap.get(appealSpecialistUserId)},
            wrapper,
            'AppealSpecialist',
            userAccessDecision.getRemovedFields().get(OBJECT_USER),
            OBJECT_USER
        );

        getNotes(appealId,  wrapper);

        return wrapper;
    }

    public static void getOther(DynamicWrapperClass wrapper) {
        wrapper.objectFields.put(DATE_CURRENT_DAY,   new Map<String, Object>{DAY   => Date.today().day()});
        wrapper.objectFields.put(DATE_CURRENT_MONTH, new Map<String, Object>{MONTH => Datetime.now().format(MONTH_FORMAT)});
        wrapper.objectFields.put(DATE_CURRENT_YEAR,  new Map<String, Object>{YEAR  => Date.today().year()});
    }

    @AuraEnabled(Cacheable=false)
    public static DynamicWrapperClass getWrapper(Id recordId) {
        DynamicWrapperClass wrapper = new DynamicWrapperClass();

        if ((String.valueOf(recordId.getSobjectType().getDescribe().getName()) == String.valueOf(Appeal__c.getSObjectType().getDescribe().name))) {
            wrapper.objectFields = new Map<String, Map<String, Object>>();
            wrapper.listObjectFields = new List<Map<String, Map<String, Object>>>();

            String objectName = recordId.getSobjectType().getDescribe().getName();

            wrapper.objectName = objectName;

            if (objectName == OBJECT_APPEAL) {
                wrapper = getAppealWrapper(recordId, wrapper);
            }

            getOther(wrapper);
        }

        return wrapper;
    }
}