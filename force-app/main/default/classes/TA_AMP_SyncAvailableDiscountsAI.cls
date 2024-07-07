public with sharing class TA_AMP_SyncAvailableDiscountsAI implements TriggerAction.AfterInsert {

    private static final String RT_NAME_INITIATION_FEE_DISCOUNT = 'Initiation_Fee_Discount';

    private List<Assigned_Membership_Promotion__c> newList;
    private Map<Id, Membership_Promotion__c> mapPromotions;

    public void afterInsert(
        List<Assigned_Membership_Promotion__c> newList
    ) {
        this.newList = newList;
        if (hasPromosWithDiscountBenefits()) {
            createAvailableDiscounts( filterToAmpsWithDiscountBenefits() );
        }
    }

    private Boolean hasPromosWithDiscountBenefits() {
        return !getPromosWithDiscountBenefits().isEmpty();
    }

    private List<Assigned_Membership_Promotion__c> filterToAmpsWithDiscountBenefits() {
        List<Assigned_Membership_Promotion__c> filteredAmps = new List<Assigned_Membership_Promotion__c>();
        for (Membership_Promotion__c promo : getPromosWithDiscountBenefits().values()) {
            filteredAmps.addAll(promo.Assigned_Membership_Promotions__r);
        }
        return filteredAmps;
    }

    private Map<Id, Membership_Promotion__c> getPromosWithDiscountBenefits() {
        if (this.mapPromotions == null) {
            this.mapPromotions = queryForPromosWithDiscountBenefits();
        }
        return this.mapPromotions;
    }

    private void createAvailableDiscounts(
        List<Assigned_Membership_Promotion__c> amps
    ) {
        List<TREX1__Available_Discounts__c> availableDiscounts = new List<TREX1__Available_Discounts__c>();
        for (Assigned_Membership_Promotion__c amp : amps) {
            availableDiscounts.addAll( getAvailableDiscountsFromAmp(amp) );
        }
        insertAvailableDiscounts(availableDiscounts);
    }

    private List<TREX1__Available_Discounts__c> getAvailableDiscountsFromAmp(
        Assigned_Membership_Promotion__c amp
    ) {
        List<TREX1__Available_Discounts__c> availableDiscounts = new List<TREX1__Available_Discounts__c>();
        Membership_Promotion__c promo = mapPromotions.get(amp.Membership_Promotion__c);
        for (Promotion_Benefit__c pb : promo.Promotion_Benefits__r) {
            availableDiscounts.add(
                createAvailableDiscount(amp, promo, pb.Discount_Product__c)
            );
        }
        return availableDiscounts;
    }

    private TREX1__Available_Discounts__c createAvailableDiscount(
        Assigned_Membership_Promotion__c amp,
        Membership_Promotion__c promo,
        Id productId
    ) {
        return new TREX1__Available_Discounts__c(
            Assigned_Membership_Promotion__c = amp.Id,
            TREX1__Automatically_Assign__c = true,
            TREX1__Discount__c = productId,
            TREX1__Membership_Type__c = amp.Membership_Type__c,
            TREX1__Internally_Available_Date__c = promo.Start_Date__c,
            TREX1__Internally_Available_Expiry_Date__c = promo.End_Date__c,
            TREX1__Externally_Available_Date__c = promo.Start_Date__c,
            TREX1__Externally_Available_Expiry_Date__c = promo.End_Date__c,
            Name = String.valueOf(promo.Name + ' - ' + amp.Membership_Type__r.Name).left(80)
        );
    }

    private void insertAvailableDiscounts(List<TREX1__Available_Discounts__c> availableDiscounts) {
        Database.insert(availableDiscounts, AccessLevel.USER_MODE);
    }

    private Map<Id, Membership_Promotion__c> queryForPromosWithDiscountBenefits() {
        return new Map<Id, Membership_Promotion__c>([
            SELECT Id, Name, Start_Date__c, End_Date__c,
                   (SELECT Id, Discount_Product__c
                      FROM Promotion_Benefits__r
                     WHERE RecordType.DeveloperName = :RT_NAME_INITIATION_FEE_DISCOUNT),
                   (SELECT Id, Membership_Type__c, Membership_Promotion__c, Membership_Type__r.Name
                      FROM Assigned_Membership_Promotions__r
                     WHERE Id IN :this.newList)
              FROM Membership_Promotion__c
             WHERE Id IN (SELECT Membership_Promotion__c
                            FROM Assigned_Membership_Promotion__c
                           WHERE Id IN :this.newList)
               AND Id IN (SELECT Membership_Promotion__c
                            FROM Promotion_Benefit__c
                           WHERE RecordType.DeveloperName = :RT_NAME_INITIATION_FEE_DISCOUNT)
              WITH USER_MODE
        ]);
    }
    
}