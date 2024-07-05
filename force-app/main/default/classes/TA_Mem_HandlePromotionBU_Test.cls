@IsTest
private class TA_Mem_HandlePromotionBU_Test {

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

        // Promos, promo benefits, and assignments
        TestDataFactory.createPromoWithBenefits(new List<TREX1__Membership_Type__c>{mType}, lstGlAccounts[1]);

        // Contacts
        List<Contact> lstContacts = TestDataFactory.createContacts(5);
        insert lstContacts;
    }

    @IsTest
    static void unitTest1() {

    }

}