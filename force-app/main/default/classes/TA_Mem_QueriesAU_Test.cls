@IsTest
private class TA_Mem_QueriesAU_Test {

    @TestSetup
    static void makeData() {
        // Create App Config custom setting
        TestDataFactory.createAppConfig();
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();

        // Create global accounts in custom settings
        TREX1__Global_GL_Accounts__c globalGlAccounts = TestDataFactory.createGlobalGLAccounts();

        // Create gl accounts in custom object
        List<TREX1__GL_Account__c> lstGlAccounts = TestDataFactory.createGlAccounts(2);
        insert lstGlAccounts;

        // Create global billing group
        TREX1__Global_Billing_Group__c gbg = TestDataFactory.createGlobalBillingGroup();

        // Membership categories
        List<TREX1__Membership_Category__c> lstCats = TestDataFactory.createStandardMembershipCategories(1);
        insert lstCats;

        // Location
        List<TREX1__Location__c> lstLocations = TestDataFactory.createLocations(1);
        insert lstLocations;

        // Membership types
        TREX1__Membership_Type__c mType = TestDataFactory.createStandardMembershipTypes(
            lstCats, 
            lstLocations.get(0), 
            1
        ).get(0);
        mType.Revenue_GL_Account__c = lstGlAccounts[0].Id;
        insert mType;

        // Contacts
        List<Contact> lstContacts = TestDataFactory.createContacts(5);
        insert lstContacts;

        // Get contact with account id
        Contact ct = [SELECT Id, AccountId FROM Contact WHERE Id IN :lstContacts LIMIT 1];
        
        // Membership
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, mType);
        insert mem;
    }
    
    @IsTest
    static void testQueries() {
        TREX1__Membership__c mem = [SELECT Id, TREX1__Contact__c, TREX1__Account__c FROM TREX1__Membership__c LIMIT 1];
        Test.startTest();
        mem.TREX1__Status__c = 'Active';
        update mem;
        Test.stopTest();
        Map<Id, TREX1__Membership__c> mapMems = TA_Mem_QueriesAU.getInstance().mapMemberships;
        Assert.isTrue(mapMems.keySet().contains(mem.Id), 'Returned map should have included the updated membership');
        Assert.areEqual(mem.TREX1__Contact__c, mapMems.get(mem.Id).TREX1__Contact__c, 'Should have received the contact from the updated membership');
        Assert.areEqual(mem.TREX1__Account__c, mapMems.get(mem.Id).TREX1__Account__c, 'Should have received the account from the updated membership');
    }
    
}