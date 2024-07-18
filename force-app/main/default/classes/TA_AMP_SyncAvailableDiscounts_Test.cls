@IsTest
private class TA_AMP_SyncAvailableDiscounts_Test {

    private static final String RT_NAME_INITIATION_FEE_DISCOUNT = 'Initiation_Fee_Discount';

    @TestSetup
    static void makeData() {
        TREX1__GL_Account__c glAccount = TestDataFactory.createGlAccounts(1).get(0);
        insert glAccount;
        List<TREX1__Membership_Category__c> mCats = TestDataFactory.createStandardMembershipCategories(1);
        insert mCats;
        List<TREX1__Location__c> lstLocations = TestDataFactory.createLocations(1);
        insert lstLocations;
        List<TREX1__Membership_Type__c> mTypes = TestDataFactory.createStandardMembershipTypes(
            mCats, 
            lstLocations.get(0), 
            5
        );
        insert mTypes;
        // Create promo with benefits, but no assignments
        TestDataFactory.createPromoWithBenefits(new List<TREX1__Membership_Type__c>(), glAccount);
    }

    @IsTest
    static void testSyncAfterInsert() {
        Membership_Promotion__c promo = [
            SELECT Id, 
                   (SELECT Id, Discount_Product__c 
                      FROM Promotion_Benefits__r
                     WHERE RecordType.DeveloperName = :RT_NAME_INITIATION_FEE_DISCOUNT
                     LIMIT 1)
              FROM Membership_Promotion__c 
             LIMIT 1
        ];
        Id productId = promo.Promotion_Benefits__r[0].Discount_Product__c;

        List<TREX1__Membership_Type__c> memTypes = [SELECT Id FROM TREX1__Membership_Type__c];

        Test.startTest();
        List<Assigned_Membership_Promotion__c> assignments = new List<Assigned_Membership_Promotion__c>();
        for (TREX1__Membership_Type__c memType : memTypes) {
            Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c();
            amp.Membership_Promotion__c = promo.Id;
            amp.Membership_Type__c = memType.Id;
            assignments.add(amp);
        }
        insert assignments;
        Test.stopTest();

        List<TREX1__Available_Discounts__c> availableDiscounts = [
            SELECT Id, Assigned_Membership_Promotion__c, TREX1__Membership_Type__c
              FROM TREX1__Available_Discounts__c
             WHERE TREX1__Discount__c = :productId
        ];

        Assert.areEqual(
            assignments.size(), 
            availableDiscounts.size(), 
            'Should have received an available discount for each assigned membership type'
        );

        Map<Id, Assigned_Membership_Promotion__c> mapAssignments = new Map<Id, Assigned_Membership_Promotion__c>(assignments);
        for (TREX1__Available_Discounts__c ad : availableDiscounts) {
            Assert.isTrue(
                mapAssignments.containsKey(ad.Assigned_Membership_Promotion__c), 
                'Should have populated the amp lookup with a valid assignment'
            );
            Assert.areEqual(
                mapAssignments.get(ad.Assigned_Membership_Promotion__c).Membership_Type__c, 
                ad.TREX1__Membership_Type__c, 
                'Available discount should have been mapped to the assignment\'s membership type'
            );
        }
    }

    @IsTest
    static void testSyncBeforeDelete() {
        Membership_Promotion__c promo = [
            SELECT Id, 
                   (SELECT Id, Discount_Product__c 
                      FROM Promotion_Benefits__r
                     WHERE RecordType.DeveloperName = :RT_NAME_INITIATION_FEE_DISCOUNT
                     LIMIT 1)
              FROM Membership_Promotion__c 
             LIMIT 1
        ];
        Id productId = promo.Promotion_Benefits__r[0].Discount_Product__c;

        List<TREX1__Membership_Type__c> memTypes = [SELECT Id FROM TREX1__Membership_Type__c];

        List<Assigned_Membership_Promotion__c> assignments = new List<Assigned_Membership_Promotion__c>();
        for (TREX1__Membership_Type__c memType : memTypes) {
            Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c();
            amp.Membership_Promotion__c = promo.Id;
            amp.Membership_Type__c = memType.Id;
            assignments.add(amp);
        }
        insert assignments;

        List<TREX1__Available_Discounts__c> availableDiscounts = [
            SELECT Id, Assigned_Membership_Promotion__c, TREX1__Membership_Type__c
              FROM TREX1__Available_Discounts__c
             WHERE TREX1__Discount__c = :productId
        ];

        Assert.areEqual(
            assignments.size(), 
            availableDiscounts.size(), 
            'Should have received an available discount for each assigned membership type prior to running the test'
        );

        Test.startTest();
        delete assignments;
        Test.stopTest();

        List<TREX1__Available_Discounts__c> refreshedAvailableDiscounts = [
            SELECT Id, Assigned_Membership_Promotion__c, TREX1__Membership_Type__c
              FROM TREX1__Available_Discounts__c
             WHERE TREX1__Discount__c = :productId
        ];

        Assert.isTrue(
            refreshedAvailableDiscounts.isEmpty(), 
            'Should have deleted associated available discounts'
        );
    }

}