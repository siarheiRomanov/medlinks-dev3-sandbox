@IsTest
private class EventPostTriggerTest {

//    @IsTest
//    static void eventAfterInsertUpdateTest() {
//        Id profileId = [
//            SELECT Id, Name
//            FROM Profile
//            WHERE Name = :TestDataFactory.PROFILE_NAME_SYSTEM_ADMINISTRATOR
//            LIMIT 1
//        ].Id;
//
//        User user = new User(
//            FirstName         = 'FirstName1',
//            LastName          = 'LastName1',
//            Alias             = TestDataFactory.TEST_NAME + '1',
//            Email             = 'test1@test.com',
//            Username          = 'alias1@test.com',
//            CommunityNickname = 'NickName1',
//            ProfileId         = profileId,
//            LanguageLocaleKey = TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US,
//            EmailEncodingKey  = TestDataFactory.EMAIL_ENCODING_KEY_UTF_8,
//            TimeZoneSidKey    = TestDataFactory.LOCALE_SID_KEY_US_LA,
//            LocaleSidKey      = TestDataFactory.LANGUAGE_LOCALE_KEY_EN_US
//        );
//
//        insert user;
//
//        List<Account> accounts = new List<Account>();
//
//        accounts.add(new Account(
//            Name               = 'Test1',
//            Type               = TestDataFactory.ACCOUNT_TYPE_TEST_VALUE,
//            Shortname__c       = TestDataFactory.TEST_NAME,
//            Facility_City__c   = 'City',
//            Facility_State__c  = 'State',
//            Facility_Street__c = 'Street',
//            Facility_Zip__c    = '123456'
//        ));
//
//        accounts.add(new Account(
//            Name               = 'Test2',
//            Type               = TestDataFactory.ACCOUNT_TYPE_TEST_VALUE,
//            Audit_Client__c    = true,
//            Shortname__c       = TestDataFactory.TEST_NAME,
//            Facility_City__c   = 'City',
//            Facility_State__c  = 'State',
//            Facility_Street__c = 'Street',
//            Facility_Zip__c    = '123456'
//        ));
//
//        insert accounts;
//
//        Contact contact = new Contact(LastName = 'TestContact');
//
//        insert contact;
//
//        insert new Appeal__c(
//            Appeal_Stage__c                  = TestDataFactory.APPEAL_STAGE_TEST_VALUE,
//            Appeal_Type__c                   = 'Legal',
//            Payer__c                         = accounts[0].Id,
//            Payer_Type__c                    = 'Commercial',
//            Client_Account__c                = accounts[1].Id,
//            Facility__c                      = accounts[0].Id,
//            Facility_Contact_Primary__c      = contact.Id,
////            Appeal_Due_Date__c               = Date.today(),
//            Patient_First_Name__c            = TestDataFactory.TEST_NAME,
//            Payer_Appeal_Account__c          = accounts[0].Id,
//            Patient_Last_Name__c             = TestDataFactory.TEST_NAME,
//            Patient_DOB__c                   = Date.today().addYears(-5),
//            Patient_Account__c               = 'test123',
//            Service_Start_Date__c            = Date.today(),
//            Service_End_Date__c              = Date.today(),
//            Assigned_Appeals_Specialist__c   = user.Id,
//            Assigned_Scheduler__c            = user.Id,
//            Denial_Reason__c                 = 'Coding',
//            Time_Spent_Initial_Submission__c = 1,
//            Auditor_Appeal_Rate__c           = 12,
//            Defence_Decision__c              = 'Pursue',
//            Overread_By__c                   = contact.Id,
//            Defence_Decision_Date__c         = Date.today(),
//            Overread_Date__c                 = Date.today(),
//            Date_Proposed_Exit__c            = Datetime.now(),
//            Exit_Duration__c                 = '15 Minutes',
//            Exit_Mode__c                     = 'Other'
//        );
//
//        Audit__c audit    = new Audit__c();	// Test Audit object
//        Account  facility = new Account (Name = 'Test Facility');	// Facility account object
//
//        // Must set fields so that we pass validation
//        facility.Auditable__c    = true;
//        facility.Audit_Client__c = true;
//        facility.Shortname__c    = TestDataFactory.TEST_NAME;
//        Account client           = new Account (Name = 'Test Client');	// Client account object
//        client.Auditable__c      = false;
//        client.Audit_Client__c   = true;
//
//        insert facility;
//        insert client;
//
//        // First test the facility and client account updating
//        audit.Facility_Is_Client__c   = true;
//        audit.Account__c              = facility.Id;
//        audit.Client_Audit_Account__c = null;
//        audit.XFlag__c                = 0;				// Don't do the crypto stuff yet
//        audit.Audit_Amount__c         = 100;	// Fill in required fields
//        audit.Patient_Name__c         = 'Smith, John';
//        audit.Patient_Account__c      = '1234';
//        audit.Service_Start_Date__c   = Date.today();
//        audit.Service_End_Date__c     = Date.today();
//        Contact oppAuditor            = new Contact();
//        oppAuditor.FirstName          = 'Alice';
//        oppAuditor.LastName           = 'Jones';
//        oppAuditor.IsScheduler__c     = true;
//        oppAuditor.IsAuditor__c       = true;
//
//        insert  oppAuditor;
//
//        Date     meetingDate = Date.today().addDays(30);	// In local time zone??
//        Time     meetingTime = Time.newInstance(9, 30, 0, 0); // 9:30 AM ??
//        Datetime locTime     = Datetime.newInstance(meetingDate, meetingTime);	// In local time
//
//        audit.Date_Proposed_Exit__c = locTime;
//        audit.Opposing_Scheduler__c = oppAuditor.Id;
//        audit.Opposing_Auditor__c   = oppAuditor.Id;
//        audit.Assigned_Auditor__c   = (Id)UserInfo.getUserId();
//        audit.Assigned_Scheduler__c = (Id)UserInfo.getUserId();
//
//        insert audit;
//
//        List<Event> events = [SELECT DeleteAfterUpdate__c FROM Event];
//
//        for (Event ev : events) {
//            ev.DeleteAfterUpdate__c = true;
//        }
//
//        update events;
//
//        for (Event ev : [SELECT SkipAppealUpdate__c, Description, Subject, What.Name FROM Event WHERE SkipAppealUpdate__c != NULL OR SkipAuditUpdate__c != NULL]) {
//            if (ev.SkipAppealUpdate__c) {
//                System.assert(ev.SkipAppealUpdate__c);
//            } else {
//                System.assert(ev.SkipAuditUpdate__c);
//            }
//
//            System.assert(ev.Subject.indexOf(ev.What.Name) != -1);
//            System.assert(ev.Description.indexOf(ev.What.Name) != -1);
//        }
//    }
}