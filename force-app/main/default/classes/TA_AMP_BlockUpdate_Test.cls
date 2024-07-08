@IsTest
private class TA_AMP_BlockUpdate_Test {

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
            2
        );
        insert mTypes;
        // Create promo and assign to only one of the membership types
        TestDataFactory.createPromoWithBenefits(new List<TREX1__Membership_Type__c>{mTypes[0]}, glAccount);
    }

    @IsTest
    static void testBlockUpdateOnMembershipTypeChange() {
        Assigned_Membership_Promotion__c amp = [SELECT Id, Membership_Type__c FROM Assigned_Membership_Promotion__c LIMIT 1];
        TREX1__Membership_Type__c otherMembershipType = [SELECT Id FROM TREX1__Membership_Type__c WHERE Id != :amp.Membership_Type__c LIMIT 1];

        Test.startTest();
        try {
            amp.Membership_Type__c = otherMembershipType.Id;
            update amp;
            Assert.fail('Should have received an exception when attempting to change the membership type');
        } catch (Exception e) {
            Assert.isTrue(
                e.getMessage().contains(TA_AMP_BlockUpdate.AMP_UPDATE_EXCEPTION),
            	'Should have received the error message for attempting to update an assignment'
            );
        }
        Test.stopTest();
    }

}