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
    public String id {get; private set;}

    public TRecManualAdjustmentWrapper() {
        this.id = UUID.randomUUID().toString();
    }

    /*******************************************
     * Account Id
     *******************************************/
    public Id accountId {get; set;}

    /*******************************************
     * Primary Contact Id
     *******************************************/
    public Id contactId {get; set;}

    /*******************************************
     * Amount of the transaction
     *******************************************/
    public Decimal amount {get; set;}

    /*******************************************
     * GL code to offset
     * Accounts Receivable will be on the other side
     *******************************************/
    public String glCode {get; set;}

    /*******************************************
     * Whether a credit or balance should be created
     * Valid types: 'Credit' and 'Balance'
     *******************************************/
    public String type {get; set;}

    /*******************************************
     * Source membership id
     *******************************************/
    public String sourceMembershipId {get; set;}

}