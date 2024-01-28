@IsTest
private class TRecManualAdjustmentService_Test {

    @TestSetup
    static void makeData() {
        // Create App Config custom setting
        TestDataFactory.createAppConfig();
        TREX1__App_Config__c appConfig = TREX1__App_Config__c.getOrgDefaults();
        Integer numDaysToBackdate = Integer.valueOf(appConfig.Days_Until_Credit_Expiration__c) + 10;
        // Create global accounts in custom settings
        TREX1__Global_GL_Accounts__c globalGlAccounts = TestDataFactory.createGlobalGLAccounts();
        // Create gl accounts in custom object
        List<TREX1__GL_Account__c> lstGlAccounts = TestDataFactory.createGlAccounts(5);
        insert lstGlAccounts;
        // Create global billing group
        TREX1__Global_Billing_Group__c gbg = TestDataFactory.createGlobalBillingGroup();
        // Create 50 contacts in separate households
        List<Contact> lstContactsToInsert = TestDataFactory.createContacts(50);
        insert lstContactsToInsert;
    }

    @IsTest
    static void testCreateCreditAdjustment() {
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__GL_Account__c glAcc = [SELECT Id, TREX1__GL_Account_Number__c FROM TREX1__GL_Account__c LIMIT 1];
        Decimal amount = 100.00;

        TRecManualAdjustmentWrapper wrapper = new TRecManualAdjustmentWrapper();
        wrapper.accountId = ct.AccountId;
        wrapper.contactId = ct.Id;
        wrapper.amount    = amount;
        wrapper.glCode    = glAcc.TREX1__GL_Account_Number__c;
        wrapper.type      = 'Credit';

        Test.startTest();
        TRecManualAdjustmentService service = new TRecManualAdjustmentService(
            new List<TRecManualAdjustmentWrapper>{ wrapper }
        );
        service.createAdjustments();
        Test.stopTest();

        Account acc = [SELECT TREX1__Unapplied_Credit_Amount__c FROM Account WHERE Id = :ct.AccountId LIMIT 1];
        
        Assert.areEqual(
            amount, 
            acc.TREX1__Unapplied_Credit_Amount__c, 
            'The account should have a credit of the adjusted amount'
        );
    }

    @IsTest
    static void testCreateBalanceAdjustment() {
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__GL_Account__c glAcc = [SELECT Id, TREX1__GL_Account_Number__c FROM TREX1__GL_Account__c LIMIT 1];
        Decimal amount = 100.00;

        TRecManualAdjustmentWrapper wrapper = new TRecManualAdjustmentWrapper();
        wrapper.accountId = ct.AccountId;
        wrapper.contactId = ct.Id;
        wrapper.amount    = amount;
        wrapper.glCode    = glAcc.TREX1__GL_Account_Number__c;
        wrapper.type      = 'Balance';

        Test.startTest();
        TRecManualAdjustmentService service = new TRecManualAdjustmentService(
            new List<TRecManualAdjustmentWrapper>{ wrapper }
        );
        service.createAdjustments();
        Test.stopTest();

        Account acc = [SELECT TREX1__Outstanding_Account_Balance__c FROM Account WHERE Id = :ct.AccountId LIMIT 1];
        
        Assert.areEqual(
            amount, 
            acc.TREX1__Outstanding_Account_Balance__c, 
            'The account should have a balance of the adjusted amount'
        );
    }

}