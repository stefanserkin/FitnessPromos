/************************************************
 * @description A staged manual adjustment for use in the TRecManualAdjustmentService
 *  All properties are read/write
 * 
 * @date 2024
 ************************************************/
public with sharing class TRecManualAdjustmentWrapper {

    /*******************************************
     * Set in constructor using UUID class
     *******************************************/
    @AuraEnabled
    public String id {get; private set;}

    public TRecManualAdjustmentWrapper() {
        this.id = UUID.randomUUID().toString();
    }

    /*******************************************
     * Account Id
     *******************************************/
    @AuraEnabled
    public Id accountId {get; set;}

    /*******************************************
     * Primary Contact Id
     *******************************************/
    @AuraEnabled
    public Id contactId {get; set;}

    /*******************************************
     * Amount of the transaction
     *******************************************/
    @AuraEnabled
    public Decimal amount {get; set;}

    /*******************************************
     * GL code to offset
     * Accounts Receivable will be on the other side
     *******************************************/
    @AuraEnabled
    public String glCode {get; set;}

    /*******************************************
     * Whether a credit or balance should be created
     * Valid types: 'Credit' and 'Balance'
     *******************************************/
    @AuraEnabled
    public String type {get; set;}

    /*******************************************
     * Source membership id
     *******************************************/
    @AuraEnabled
    public String sourceMembershipId {get; set;}

    /*******************************************
     * Source membership promotion
     *******************************************/
    @AuraEnabled
    public String membershipPromotionId {get; set;}

}