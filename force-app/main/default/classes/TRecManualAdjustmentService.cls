/****************************************************************************
 * @description Use this service class to create manual adjustments in Traction Rec
 * @date 2024
 ****************************************************************************/
public with sharing class TRecManualAdjustmentService {

    private static final String DEFAULT_DESCRIPTION     = 'Manual Adjustment';
    private static final String TYPE_MANUAL_ADJUSTMENT  = 'Manual Adjustment';
    private static final String TRANSACTION_PARENT_FLOW = 'Manual Adjustment Service';
    private static final String STATUS_DRAFT            = 'Draft';
    private static final String STATUS_FIRMED           = 'Firmed';
    private static final String GBG_NAME                = 'Asphalt Green';
    private static final String DATETIME_FORMAT         = 'yyyy-MM-dd\'T\'HH:mm:ss:SSS';
    private static final String TYPE_CREDIT             = 'Credit';

    private static Id gbgId;
    private static String arGlCode;
    private static Map<String, String> mapGlCodeToAccount;

    private static Id hhRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
    private static Id tliRecTypeId = Schema.SObjectType.TREX1__Transaction_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Manual_Adjustment').getRecordTypeId();

    /*******************************************
     * Description is set to the default description in the constructor
     * Override the default by setting a description value
     *******************************************/
    public String description {
        get { return description; }
        set { description = value; }
    }

    /*******************************************
     * Map of wrappers to create manual adjustments for
     *******************************************/
    private Map<String, TRecManualAdjustmentWrapper> mapWrappers;

    /*******************************************
     * Constructor
     *  Set default description and create a map of wrapper ids to passed wrappers
     *******************************************/
    public TRecManualAdjustmentService(List<TRecManualAdjustmentWrapper> lstWrappers) {
        this.mapWrappers = new Map<String, TRecManualAdjustmentWrapper>();
        for (TRecManualAdjustmentWrapper wrap : lstWrappers) {
            this.mapWrappers.put(wrap.id, wrap);
        }
        this.description = DEFAULT_DESCRIPTION;
    }

    /*******************************************
     * @description Create adjustments for wrappers passed to constructor
     *******************************************/
    public List<Id> createAdjustments() {
        // Create one transaction for each wrapper
        List<TREX1__Transaction__c> lstTransactions = new List<TREX1__Transaction__c>();
        for (TRecManualAdjustmentWrapper maw : mapWrappers.values()) {
            lstTransactions.add( 
                getTransaction(maw)
            );
        }
        insert lstTransactions;

        // Create one transaction line item for each transaction
        List<TREX1__Transaction_Line_Item__c> lstTlis = new List<TREX1__Transaction_Line_Item__c>();
        for (TREX1__Transaction__c trans : lstTransactions) {
            lstTlis.add( 
                getTli(trans, mapWrappers.get(trans.TREX1__Legacy_Id__c).amount) 
            );
        }
        insert lstTlis;

        // Create one accounting event for each transaction line item
        List<TREX1__Accounting_Event__c> lstAccountingEvents = new List<TREX1__Accounting_Event__c>();
        for (TREX1__Transaction_Line_Item__c tli : lstTlis) {
            lstAccountingEvents.add(
                getAccountingEvent(tli)
            );
        }
        insert lstAccountingEvents;

        // Create two journal entries for each accounting event
        List<TREX1__Journal_Entry__c> lstJes = new List<TREX1__Journal_Entry__c>();
        for (TREX1__Accounting_Event__c ae : lstAccountingEvents) {
            lstJEs.addAll(
                getJournalEntries(ae)
            );
        }
        insert lstJes;

        // Set the transaction status to close
        // A Rec trigger will update the tli statuses, generate receipt pdfs, and recalculate account rollups
        for (TREX1__Transaction__c t : lstTransactions) {
            t.TREX1__Status__c = STATUS_FIRMED;
        }
        update lstTransactions;

        // Return transaction ids
        List<Id> lstTransactionIds = new List<Id>();
        for (TREX1__Transaction__c t : lstTransactions) {
            lstTransactionIds.add(t.Id);
        }
        return lstTransactionIds;
    }


    /***************************************************
     * Get a transaction for a manual adjustment wrapper
     * @param TRecManualAdjustmentWrapper manual adjustment wrapper with transaction details
     * @return TREX1__Transaction__c transaction to be inserted
     ***************************************************/

    private TREX1__Transaction__c getTransaction(
        TRecManualAdjustmentWrapper maw
    ) {
        return new TREX1__Transaction__c(
            TREX1__Account__c = maw.AccountId, 
            TREX1__Contact__c = maw.ContactId, 
            TREX1__Created_Online__c = false, 
            TREX1__Status__c = STATUS_DRAFT, 
            TREX1__Exclude_From_Automatic_Cleanup__c = false, 
            TREX1__Parent_Flow__c = TRANSACTION_PARENT_FLOW,
            TREX1__Legacy_Id__c = maw.id
        );
    }


    /***************************************************
     * Get a transaction line item for a manual adjustment transaction
     * @param TREX1__Transaction__c manual adjustment transaction
     * @return TREX1__Transaction_Line_Item__c tli to be inserted
     ***************************************************/

    private TREX1__Transaction_Line_Item__c getTli(
        TREX1__Transaction__c trans, 
        Decimal amount
    ) {
        TRecManualAdjustmentWrapper wrap = mapWrappers.get(trans.TREX1__Legacy_Id__c);
        if (wrap.type == TYPE_CREDIT) {
            amount = (amount * -1);
        }
        return new TREX1__Transaction_Line_Item__c(
            RecordTypeId = tliRecTypeId,                                // Record Type (manual adjustment)
            TREX1__Account__c = trans.TREX1__Account__c,                // Account
            TREX1__Effective_Date__c = Date.today(),                    // Effective Date
            TREX1__Contact__c = trans.TREX1__Contact__c,                // Contact
            TREX1__Transaction__c = trans.Id,                           // Transaction
            TREX1__Transaction_Contact__c = trans.TREX1__Contact__c,    // Transaction Contact
            TREX1__Description__c = description,                        // Description
            TREX1__Status__c = STATUS_DRAFT,                            // Status
            TREX1__Type__c = 'Item Event',                              // Type
            TREX1__Event_Type__c = TYPE_MANUAL_ADJUSTMENT,              // Event Type
            TREX1__Prorated_Recurring_Fee_Percentage__c = 0.00,         // Prorated_Recurring_Fee_Percentage
            TREX1__Prorated_Recurring_Fee_Amount__c = 0.00,             // Prorated Recurring Fee Amount
            TREX1__Charge_Purchase_Billing_Immediately__c = false,      // Charge Purchase Billing Immediately
            TREX1__Net_Price__c = amount,                               // Net Price
            TREX1__Initial_Fee_Amount__c = amount,                      // Initial Fee Amount
            TREX1__Is_Edited__c = false,                                // Is Edited
            TREX1__Override_Price__c = false,                           // Override Price
            TREX1__tli_Global_Billing_Group__c = getGbgId(),            // Global Billing Group
            TREX1__Override_Prerequisites__c = false,                   // Override Prerequisites
            TREX1__Deferred_Revenue_Recognition_Finished__c = true,     // Deferred Revenue Recognition Finished
            TREX1__Total_Deferred_Revenue__c = 0.00,                    // Total Deferred Revenue
            TREX1__Legacy_Id__c = trans.TREX1__Legacy_Id__c             // Wrapper id
        );
    }


    /***************************************************
     * Get an accounting event for a manual adjustment transaction line item
     * @param TREX1__Transaction_Line_Item__c manual adjustment tli
     * @return TREX1__Accounting_Event__c accounting event to be inserted
     ***************************************************/

    private TREX1__Accounting_Event__c getAccountingEvent(
        TREX1__Transaction_Line_Item__c tli
    ) {
        return new TREX1__Accounting_Event__c(
            TREX1__System_Generated__c = false,                                          // System Generated
            TREX1__Type__c = TYPE_MANUAL_ADJUSTMENT,                                     // Type
            TREX1__Transaction__c = tli.TREX1__Transaction__c,                           // Transaction
            TREX1__Effective_Date_Time__c = Datetime.now(),                              // Effective Date Time
            TREX1__Transaction_Line_Item__c = tli.Id,                                    // Transaction Line Item
            TREX1__Total__c = tli.TREX1__Initial_Fee_Amount__c,                          // Total
            TREX1__Annotation__c = description,                                          // Annotation
            TREX1__Account__c = tli.TREX1__Account__c,                                   // Account
            TREX1__Contact__c = tli.TREX1__Contact__c,                                   // Contact
            TREX1__Legacy_Id__c = tli.TREX1__Legacy_Id__c                                // Wrapper id
        );
    }


    /***************************************************
     * Get a pair of journal entries for each manual adjustment accounting event
     * @param TREX1__Accounting_Event__c manual adjustment accounting event
     * @return List<TREX1__Journal_Entry__c> list of journal entries to insert
     ***************************************************/

    private List<TREX1__Journal_Entry__c> getJournalEntries(
        TREX1__Accounting_Event__c ae
    ) {
        List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();
        TRecManualAdjustmentWrapper wrap = mapWrappers.get(ae.TREX1__Legacy_Id__c);

        TREX1__Journal_Entry__c debitJe = new TREX1__Journal_Entry__c(
            TREX1__Effective_Date_Time__c = Datetime.now(),                              // Effective Date Time
            TREX1__Account__c = ae.TREX1__Account__c,                                    // Account
            TREX1__Contact__c = ae.TREX1__Contact__c,                                    // Contact
            TREX1__Type__c = TYPE_MANUAL_ADJUSTMENT,                                     // Type
            TREX1__Accounting_Event__c = ae.Id,                                          // Accounting Event
            TREX1__GL_Code__c = wrap.type == TYPE_CREDIT ? wrap.glCode : getArGlCode(),  // GL Code
            TREX1__Annotation__c = description,                                          // Annotation
            TREX1__Debit__c = wrap.amount,                                                // Debit
            TREX1__Credit__c = 0.00,                                                     // Credit
            TREX1__Is_Tax__c = false,                                                    // Is Tax
            TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
            TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c,        // Transaction Line Item
            TREX1__Transaction__c = ae.TREX1__Transaction__c,                            // Transaction
            TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
            TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
            TREX1__Has_Been_Summarized__c = false,                                       // Has Been Summarized
            TREX1__Legacy_Id__c = ae.TREX1__Legacy_Id__c,                                // Wrapper id
            Manual_Adjustment_ID__c = wrap.id,                                           // Manual Adjustment id
            Membership_Promotion__c = wrap.membershipPromotionId != null                 // Membership promotion id
                ? wrap.membershipPromotionId 
                : null
        );
        lstJEs.add(debitJe);

        TREX1__Journal_Entry__c creditJe = new TREX1__Journal_Entry__c(
            TREX1__Effective_Date_Time__c = Datetime.now(),                              // Effective Date Time
            TREX1__Account__c = ae.TREX1__Account__c,                                    // Account
            TREX1__Contact__c = ae.TREX1__Contact__c,                                    // Contact
            TREX1__Type__c = TYPE_MANUAL_ADJUSTMENT,                                     // Type
            TREX1__Accounting_Event__c = ae.Id,                                          // Accounting Event
            TREX1__GL_Code__c = wrap.type == TYPE_CREDIT ? getArGlCode() : wrap.glCode,  // GL Code
            TREX1__Annotation__c = description,                                          // Annotation
            TREX1__Debit__c = 0.00,                                                      // Debit
            TREX1__Credit__c = wrap.amount,                                              // Credit
            TREX1__Is_Tax__c = false,                                                    // Is Tax
            TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
            TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c,        // Transaction Line Item
            TREX1__Transaction__c = ae.TREX1__Transaction__c,                            // Transaction
            TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
            TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
            TREX1__Has_Been_Summarized__c = false,                                       // Has Been Summarized
            TREX1__Legacy_Id__c = wrap.id,                                               // Wrapper id
            Manual_Adjustment_ID__c = wrap.id,                                           // Manual Adjustment id
            Membership_Promotion__c = wrap.membershipPromotionId != null                 // Membership promotion id
                ? wrap.membershipPromotionId 
                : null,
            Promo_Credits_Source_Membership__c = wrap.type == TYPE_CREDIT && wrap.sourceMembershipId != null 
                ? wrap.sourceMembershipId 
                : null                                                                   // Source membership for issued credits
        );
        lstJEs.add(creditJe);

        return lstJEs;
    }

    /*******************************************
     * Caches and returns the gl code for accounts receivable 
     *  from Rec's Global Gl Accounts custom setting
     *******************************************/
    private static String getArGlCode() {
        if (arGlCode == null) {
            // mapGlCodeToAccount = TRecGLAccountUtility.getInstance().mapGlCodeToName;
            TREX1__Global_GL_Accounts__c globalGls = TREX1__Global_GL_Accounts__c.getOrgDefaults();
            arGlCode = globalGls.TREX1__Accounts_Receivable__c;
        }
        return arGlCode;
    }

    /***************************************************
     * Asphalt Green only has one global billing group, so this makes the record id available
     * @return Id record id of the default global billing group
     ***************************************************/

     private static Id getGbgId() {
        if (gbgId == null) {
            gbgId = [SELECT Id FROM TREX1__Global_Billing_Group__c WHERE Name = :GBG_NAME LIMIT 1].Id;
        }
        return gbgId;
    }

}