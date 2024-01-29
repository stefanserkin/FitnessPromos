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

        // Membership promotions
        Membership_Promotion__c promo = new Membership_Promotion__c(
            Name = 'Test promo',
            Type__c = 'Issue Credits',
            Active__c = true,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(1),
            Credit_Amount__c = 100.00, 
            GL_Account__c = lstGlAccounts[1].Id
        );
        insert promo;

        // Junction to link membership type to membership promo
        Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c(
            Membership_Promotion__c = promo.Id,
            Membership_Type__c = mType.Id
        );
        insert amp;

        // Contacts
        List<Contact> lstContacts = TestDataFactory.createContacts(5);
        insert lstContacts;
    }

    @IsTest
    static void testActivateMembershipWithMemTypeGlAccount() {
        // Clear membership promo gl account
        Membership_Promotion__c promo = [SELECT Id, GL_Account__c FROM Membership_Promotion__c LIMIT 1];
        promo.GL_Account__c = null;
        update promo;

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

        Membership_Promotion__c promo = [
            SELECT Id, GL_Account__r.TREX1__GL_Account_Number__c, 
                   (SELECT Id, TREX1__GL_Code__c
                      FROM TRec_Journal_Entries__r)
              FROM Membership_Promotion__c 
             LIMIT 1
        ];

        Set<String> setGlCodes = new Set<String>();
        for (TREX1__Journal_Entry__c je : promo.TRec_Journal_Entries__r) {
            setGlCodes.add(je.TREX1__GL_Code__c);
        }

        Assert.isTrue(
            setGlCodes.contains(promo.GL_Account__r.TREX1__GL_Account_Number__c),
            'Should have generated a je debiting the membership type revenue account'
        );
    }

}