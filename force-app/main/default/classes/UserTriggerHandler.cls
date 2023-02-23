public with sharing class UserTriggerHandler {
    public static final String PERMISSION_SET_COMMUNITY_USER = 'Community_User_Permission_Set';
    public static final String USER_TYPE_CSP_LITE_PORTAL     = 'CspLitePortal';

    public static void afterInsertUser(Map<Id, User> newUsersMap) {
        Map<Id, User> communityUsers = new Map<Id, User>(getCommunityUsers(newUsersMap.values()));

        if (!communityUsers.isEmpty()) {
            List<PermissionSetAssignment> insertedPermissionSetAssignments = new List<PermissionSetAssignment>();

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            Id communityPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :PERMISSION_SET_COMMUNITY_USER LIMIT 1].Id;

            for (User user : communityUsers.values()) {
                insertedPermissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId = communityPermissionSetId, AssigneeId = user.Id));
            }

            // CRUD FLS security check is bypassed due to standard object without this sort of security setting
            insert insertedPermissionSetAssignments;
        }
    }

    private static List<User> getCommunityUsers(List<User> users) {
        List<User> communityUsers = new List<User>();

        for (User user : users) {
            if (user.UserType == USER_TYPE_CSP_LITE_PORTAL) {
                communityUsers.add(user);
            }
        }

        return communityUsers;
    }
}