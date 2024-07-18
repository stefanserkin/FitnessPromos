@IsTest
private class TA_Mem_HandlePromotionAU_Test {

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
    static void testActivateMembershipWithMemTypeGlAccount() {
        // Clear promo benefit gl account
        Promotion_Benefit__c pb = [SELECT Id, Expense_GL_Account__c FROM Promotion_Benefit__c WHERE RecordType.DeveloperName = 'Account_Credit' LIMIT 1];
        pb.Expense_GL_Account__c = null;
        update pb;

        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Membership_Type__c mType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];

        // Create draft membership
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, mType);
        insert mem;

        Test.startTest();
        mem.TREX1__Status__c = 'Active';
        update mem;
        Test.stopTest();

        List<TREX1__Journal_Entry__c> lstJEs = [
            SELECT Id, TREX1__Annotation__c
              FROM TREX1__Journal_Entry__c
             WHERE Promo_Credits_Source_Membership__c = :mem.Id
        ];

        Assert.isFalse(
            lstJEs.isEmpty(), 
            'Should have received promo credit jes related to the source membership'
        );

        Assert.areEqual(
            TA_Mem_HandlePromotionAU.ADJUSTMENT_DESCRIPTION, 
            lstJEs[0].TREX1__Annotation__c, 
            'Annotation should be set to the default adjustment description'
        );
    }

    @IsTest
    static void testActivateMembershipWithPromoGlAccount() {
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Membership_Type__c mType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];

        // Create draft membership
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, mType);
        insert mem;

        Test.startTest();
        mem.TREX1__Status__c = 'Active';
        update mem;
        Test.stopTest();

        Promotion_Benefit__c benefit = [
            SELECT Id, Expense_GL_Account__c, Expense_GL_Account__r.TREX1__GL_Account_Number__c
              FROM Promotion_Benefit__c
             WHERE RecordType.DeveloperName = 'Account_Credit'
             LIMIT 1
        ];

        List<TREX1__Journal_Entry__c> lstJEs = [
            SELECT Id, TREX1__Annotation__c, TREX1__GL_Code__c
              FROM TREX1__Journal_Entry__c
             WHERE TREX1__Debit__c > 0
        ];

        Assert.areEqual(
            benefit.Expense_GL_Account__r.TREX1__GL_Account_Number__c, 
            lstJEs[0].TREX1__GL_Code__c,
            'Should have generated a je debiting the expense gl account'
        );
    }

    @IsTest
    static void testActivateIneligibleMembership() {
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Membership_Type__c mType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];

        // Create draft membership
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, mType);
        insert mem;

        Test.startTest();
        mem.Ineligible_for_Promotions__c = true;
        mem.TREX1__Status__c = 'Active';
        update mem;
        Test.stopTest();

        Membership_Promotion__c promo = [
            SELECT Id, GL_Account__r.TREX1__GL_Account_Number__c, 
                   (SELECT Id, TREX1__GL_Code__c
                      FROM TRec_Journal_Entries__r)
              FROM Membership_Promotion__c 
             LIMIT 1
        ];

        Assert.isTrue(
            promo.TRec_Journal_Entries__r.isEmpty(),
            'Should not have generated any promotional credits for ineligible membership'
        );
    }

}