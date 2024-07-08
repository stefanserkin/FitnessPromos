@IsTest
private class TA_AMP_ValidateExpenseAccount_Test {

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
        // Create promo without assignments
        Membership_Promotion__c promo = TestDataFactory.createActiveMembershipPromo();
        insert promo;
    }
    
    @IsTest
    static void testBlockNewAmpWithoutExpenseAccount() {
        Membership_Promotion__c promo = [SELECT Id FROM Membership_Promotion__c LIMIT 1];
        Promotion_Benefit__c pb = new Promotion_Benefit__c(
            Membership_Promotion__c = promo.Id,
            RecordTypeId = Schema.SObjectType.Promotion_Benefit__c.getRecordTypeInfosByDeveloperName().get('Account_Credit').getRecordTypeId(),
            Credit_Amount__c = 100.00,
            Void_if_Cancelled__c = true
        );
        insert pb;

        TREX1__Membership_Type__c memType = [SELECT Id, Revenue_GL_Account__c FROM TREX1__Membership_Type__c LIMIT 1];

        Test.startTest();
        Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c(
            Membership_Promotion__c = promo.Id,
            Membership_Type__c = memType.Id
        );
        
        try {
            insert amp;
            Assert.fail('Should have received an exception due to no valid expense account');
        } catch (Exception e) {
            Assert.isTrue(
                e.getMessage().contains(TA_AMP_ValidateExpenseAccount.INVALID_EXPENSE_ACCOUNT_EXCEPTION),
                'Should have received an error message for not having a valid expense account'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testAllowNewAmpWithMemTypeRevenueAccount() {
        Membership_Promotion__c promo = [SELECT Id FROM Membership_Promotion__c LIMIT 1];

        Promotion_Benefit__c pb = new Promotion_Benefit__c(
            Membership_Promotion__c = promo.Id,
            RecordTypeId = Schema.SObjectType.Promotion_Benefit__c.getRecordTypeInfosByDeveloperName().get('Account_Credit').getRecordTypeId(),
            Credit_Amount__c = 100.00,
            Void_if_Cancelled__c = true
        );
        insert pb;

        TREX1__GL_Account__c glAccount = [SELECT Id FROM TREX1__GL_Account__c LIMIT 1];

        TREX1__Membership_Type__c memType = [SELECT Id, Revenue_GL_Account__c FROM TREX1__Membership_Type__c LIMIT 1];
        memType.Revenue_GL_Account__c = glAccount.Id;
        update memType;

        Test.startTest();
        Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c(
            Membership_Promotion__c = promo.Id,
            Membership_Type__c = memType.Id
        );
        Database.SaveResult saveResult = Database.insert(amp, false);
        Test.stopTest();

        Assert.isTrue(saveResult.isSuccess(), 'Should have successfully inserted the assignment');
    }

    @IsTest
    static void testAllowNewAmpWithBenefitExpenseAccount() {
        Membership_Promotion__c promo = [SELECT Id FROM Membership_Promotion__c LIMIT 1];
        TREX1__GL_Account__c glAccount = [SELECT Id FROM TREX1__GL_Account__c LIMIT 1];

        Promotion_Benefit__c pb = new Promotion_Benefit__c(
            Membership_Promotion__c = promo.Id,
            RecordTypeId = Schema.SObjectType.Promotion_Benefit__c.getRecordTypeInfosByDeveloperName().get('Account_Credit').getRecordTypeId(),
            Credit_Amount__c = 100.00,
            Void_if_Cancelled__c = true,
            Expense_GL_Account__c = glAccount.Id
        );
        insert pb;

        TREX1__Membership_Type__c memType = [SELECT Id, Revenue_GL_Account__c FROM TREX1__Membership_Type__c LIMIT 1];

        Test.startTest();
        Assigned_Membership_Promotion__c amp = new Assigned_Membership_Promotion__c(
            Membership_Promotion__c = promo.Id,
            Membership_Type__c = memType.Id
        );
        Database.SaveResult saveResult = Database.insert(amp, false);
        Test.stopTest();

        Assert.isTrue(saveResult.isSuccess(), 'Should have successfully inserted the assignment');
    }

}