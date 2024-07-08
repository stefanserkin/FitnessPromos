@IsTest
private class GuestPassService_Test {
    
    @IsTest
    static void testGetGuestPassesForAccount() {
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;

        List<Contact> lstCtsWithAccId = [SELECT Id, AccountId FROM Contact WHERE Id = :ct.Id LIMIT 1];
        List<Guest_Pass__c> lstRecords = TestDataFactory.createHostGuestPasses(lstCtsWithAccId, 3);
        lstRecords.get(0).Expiration_Date__c = Date.today().addDays(-1);
        lstRecords.get(0).Status__c = GuestPassService.STATUS_EXPIRED;
        insert lstRecords;

        List<GuestPass> lstGuestPasses;
        Test.startTest();
        lstGuestPasses = GuestPassService.getGuestPassesForHostAccount(
            String.valueOf( lstCtsWithAccId[0].AccountId )
        );
        Test.stopTest();

        Assert.areEqual(
            lstRecords.size(), 
            lstGuestPasses.size(), 
            'Should have received a guest pass object for each sobject record'
        );
    }

    @IsTest
    static void testShareGuestPass() {
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        List<Contact> lstCtsWithAccId = [SELECT Id, AccountId FROM Contact WHERE Id = :ct.Id LIMIT 1];
        
        Guest_Pass__c record = TestDataFactory.createHostGuestPasses(lstCtsWithAccId, 1).get(0);
        insert record;

        String firstName = 'Testerooni';
        String lastName = 'Testeroodle';
        String email = 'testemail@testeroodledoodle.com';

        GuestPass pass = new GuestPass();
        pass.id = record.Id;
        pass.guestFirstName = firstName;
        pass.guestLastName = lastName;
        pass.guestEmail = email;

        Test.startTest();
        GuestPassService.shareGuestPass(pass);
        Test.stopTest();

        Guest_Pass__c passToVerify = [
            SELECT Id, Guest_First_Name__c, Guest_Last_Name__c, Guest_Email__c 
              FROM Guest_Pass__c 
             WHERE Id = :record.Id
             LIMIT 1
        ];

        Assert.areEqual(firstName, passToVerify.Guest_First_Name__c, 'Should have received the provided first name');
        Assert.areEqual(lastName, passToVerify.Guest_Last_Name__c, 'Should have received the provided last name');
        Assert.areEqual(email, passToVerify.Guest_Email__c, 'Should have received the provided email');
    }

    @IsTest
    static void testGetSharedGuestPasses() {
        List<TREX1__Location__c> lstLocations = TestDataFactory.createGuestPassLocations(1);
        insert lstLocations;

        insert TestDataFactory.createContacts(2);
        List<Contact> lstContacts = [SELECT Id, AccountId FROM Contact LIMIT 2];
        Contact hostContact = lstContacts[0];
        Contact guestContact = lstContacts[1];

        Guest_Pass__c guestPass = TestDataFactory.createHostGuestPasses(
            new List<Contact>{ hostContact }, 
            1
        ).get(0);
        guestPass.Contact__c = guestContact.Id;
        guestPass.Date_Shared__c = Date.today();
        guestPass.Location__c = lstLocations[0].Id;
        insert guestPass;

        List<GuestPass> lstGuestPasses;
        Test.startTest();
        lstGuestPasses = GuestPassService.getGuestPassesForHostAccount(
            String.valueOf( hostContact.AccountId )
        );
        Test.stopTest();

        Assert.isNotNull(lstGuestPasses[0].guestFirstName, 'Shared passes should have a guest first name');
    }

    @IsTest
    static void testShareGuestPassWithExistingContact() {
        insert TestDataFactory.createContacts(2);
        List<Contact> lstContacts = [SELECT Id, AccountId, FirstName, LastName, Email FROM Contact LIMIT 2];
        Contact hostContact = lstContacts[0];
        Contact guestContact = lstContacts[1];

        Guest_Pass__c guestPass = TestDataFactory.createHostGuestPasses(
            new List<Contact>{ hostContact }, 
            1
        ).get(0);
        insert guestPass;

        GuestPass pass = new GuestPass();
        pass.id = guestPass.Id;
        pass.guestFirstName = guestContact.FirstName;
        pass.guestLastName = guestContact.LastName;
        pass.guestEmail = guestContact.Email;

        Test.startTest();
        GuestPassService.shareGuestPass(pass);
        Test.stopTest();

        Guest_Pass__c passToVerify = [
            SELECT Contact__c
              FROM Guest_Pass__c 
             WHERE Id = :guestPass.Id
             LIMIT 1
        ];

        Assert.areEqual(guestContact.Id, passToVerify.Contact__c, 'Should have linked the guest pass to the guest contact');
    }

    @IsTest
    static void testShareGuestPassWithExistingLead() {
        Contact ct = TestDataFactory.createContacts(1).get(0);
        insert ct;
        List<Contact> lstCtsWithAccId = [SELECT Id, AccountId FROM Contact WHERE Id = :ct.Id LIMIT 1];
        
        Guest_Pass__c record = TestDataFactory.createHostGuestPasses(lstCtsWithAccId, 1).get(0);
        insert record;

        Lead ld = new Lead();
        ld.RecordTypeId = GuestPassService.getMembershipLeadRecordTypeId();
        ld.FirstName = 'Testrey';
        ld.LastName = 'Testordonez';
        ld.Email = 'testrey@mets.com';
        ld.Company = GuestPassService.LEAD_COMPANY_DEFAULT;
        ld.Status = GuestPassService.LEAD_STATUS_DEFAULT;
        insert ld;

        GuestPass pass = new GuestPass();
        pass.id = record.Id;
        pass.guestFirstName = ld.FirstName;
        pass.guestLastName = ld.LastName;
        pass.guestEmail = ld.Email;

        Test.startTest();
        GuestPassService.shareGuestPass(pass);
        Test.stopTest();

        Guest_Pass__c passToVerify = [
            SELECT Lead__c
              FROM Guest_Pass__c 
             WHERE Id = :record.Id
             LIMIT 1
        ];

        Assert.areEqual(ld.Id, passToVerify.Lead__c, 'Should have linked the guest pass to the guest lead');
    }

    @IsTest
    static void testCreateGuestPassFromMembership() {
        Integer numberOfGuestPasses = 4;

        TREX1__Membership__c mem = getStandardMembership();
        Test.startTest();
        List<Guest_Pass__c> guestPasses = GuestPassService.createGuestPassesForMembership(mem, numberOfGuestPasses);
        Test.stopTest();

        Assert.areEqual(numberOfGuestPasses, guestPasses.size(), 'Should have created ' + numberOfGuestPasses + ' guest passes');

        for (Guest_Pass__c gp : guestPasses) {
            Assert.areEqual(mem.TREX1__Contact__c, gp.Host_Contact__c, 'Should have linked the guest pass to the correct contact');
            Assert.areEqual(mem.ID, gp.Host_Membership__c, 'Should have linked the guest pass to the correct membership');
            Assert.areEqual(GuestPassService.STATUS_ISSUED, gp.Status__c, 'Should have created passes with a status of Issued');
        }
    }

    private static TREX1__Membership__c getStandardMembership() {
        Account acc = TestDataFactory.createHouseholdAccounts(1).get(0);
        acc.Id = TestUtility.getFakeId(Account.SObjectType);
        Contact ct = TestDataFactory.createContacts(new List<Account>{acc}, 1).get(0);
        ct.Id = TestUtility.getFakeId(Contact.SObjectType);
        TREX1__Membership_Category__c category = TestDataFactory.createStandardMembershipCategories(1).get(0);
        category.Id = TestUtility.getFakeId(TREX1__Membership_Category__c.SObjectType);
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        location.Id = TestUtility.getFakeId(TREX1__Location__c.SObjectType);
        TREX1__Membership_Type__c memType = TestDataFactory.createStandardMembershipTypes(new List<TREX1__Membership_Category__c>{category}, location, 1).get(0);
        memType.Id = TestUtility.getFakeId(TREX1__Membership_Type__c.SObjectType);
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, memType);
        mem.Id = TestUtility.getFakeId(TREX1__Membership__c.SObjectType);
        return mem;
    }
    
}