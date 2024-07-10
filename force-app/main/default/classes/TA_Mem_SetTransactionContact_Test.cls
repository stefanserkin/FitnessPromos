@IsTest
private class TA_Mem_SetTransactionContact_Test {

    @TestSetup
    static void makeData() {
        TREX1__Location__c location = TestDataFactory.createLocations(1).get(0);
        insert location;
        List<TREX1__Membership_Category__c> categories = TestDataFactory.createStandardMembershipCategories(1);
        insert categories;
        List<TREX1__Membership_Type__c> memTypes = TestDataFactory.createStandardMembershipTypes(categories, location, 1);
        insert memTypes;
        Account acc = TestDataFactory.createHouseholdAccounts(1).get(0);
        insert acc;
        Contact ct = TestDataFactory.createContacts(new List<Account>{acc}, 1).get(0);
        insert ct;
        TestDataFactory.createDraftTransaction(ct);
    }

    @IsTest
    static void testSetTransactionContactBeforeInsert() {
        TREX1__Membership_Type__c memType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Transaction__c trans = [SELECT Id, TREX1__Contact__c FROM TREX1__Transaction__c LIMIT 1];

        Test.startTest();
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, memType);
        mem.TREX1__Purchasing_Transaction__c = trans.Id;
        insert mem;
        Test.stopTest();

        TREX1__Membership__c refreshedMem = [
            SELECT Id, Transaction_Contact__c 
              FROM TREX1__Membership__c 
             WHERE Id = :mem.Id LIMIT 1
        ];

        Assert.areEqual(
            trans.TREX1__Contact__c, 
            refreshedMem.Transaction_Contact__c, 
            'Should have set the transaction contact to the contact on the related purchasing transaction'
        );
    }

    @IsTest
    static void testSetTransactionContactBeforeUpdate() {
        TREX1__Membership_Type__c memType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Transaction__c trans = [SELECT Id, TREX1__Contact__c FROM TREX1__Transaction__c LIMIT 1];

        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, memType);
        insert mem;

        Test.startTest();
        mem.TREX1__Purchasing_Transaction__c = trans.Id;
        update mem;
        Test.stopTest();

        TREX1__Membership__c refreshedMem = [
            SELECT Id, Transaction_Contact__c 
              FROM TREX1__Membership__c 
             WHERE Id = :mem.Id 
             LIMIT 1
        ];

        Assert.areEqual(
            trans.TREX1__Contact__c, 
            refreshedMem.Transaction_Contact__c, 
            'Should have set the transaction contact to the contact on the related purchasing transaction'
        );
    }

    @IsTest
    static void testNoRelatedPurchasingTransaction() {
        TREX1__Membership_Type__c memType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Transaction__c trans = [SELECT Id, TREX1__Contact__c FROM TREX1__Transaction__c LIMIT 1];

        Test.startTest();
        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, memType);
        insert mem;
        Test.stopTest();

        TREX1__Membership__c refreshedMem = [
            SELECT Id, Transaction_Contact__c 
              FROM TREX1__Membership__c 
             WHERE Id = :mem.Id 
             LIMIT 1
        ];

        Assert.isNull(
            refreshedMem.Transaction_Contact__c, 
            'Should have successfully saved the membership without a transaction contact'
        );
    }
    
    @IsTest
    static void testClearTransactionContactBeforeUpdate() {
        TREX1__Membership_Type__c memType = [SELECT Id, TREX1__Category__c FROM TREX1__Membership_Type__c LIMIT 1];
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        TREX1__Transaction__c trans = [SELECT Id, TREX1__Contact__c FROM TREX1__Transaction__c LIMIT 1];

        TREX1__Membership__c mem = TestDataFactory.createDraftStandardMembership(ct, memType);
        mem.TREX1__Purchasing_Transaction__c = trans.Id;
        insert mem;

        Test.startTest();
        mem.TREX1__Purchasing_Transaction__c = null;
        update mem;
        Test.stopTest();

        TREX1__Membership__c refreshedMem = [
            SELECT Id, Transaction_Contact__c 
              FROM TREX1__Membership__c 
             WHERE Id = :mem.Id 
             LIMIT 1
        ];

        Assert.isNull(
            refreshedMem.Transaction_Contact__c, 
            'Should have successfully cleared the transaction contact'
        );
    }

}