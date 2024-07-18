/*****************************************************
 * @description When a membership is newly activated, check for active promotions assigned to 
 *  its membership type
 * 
 * Called by metadata trigger handler
 * Manage from sObject Trigger Settings mdt: Membership
******************************************************/
public with sharing class TA_Mem_HandlePromotionBU implements TriggerAction.BeforeUpdate {

    private static Set<String> eligibleFormerStatuses = new Set<String>{
        'Draft', 
        'Pending Active'
    };

    private Map<Id, TREX1__Membership__c> oldMap;
    private Map<Id, TREX1__Transaction__c> mapTransactions;

    public void beforeUpdate(
        List<TREX1__Membership__c> newList, 
        List<TREX1__Membership__c> oldList
    ) {
        this.oldMap = new Map<Id, TREX1__Membership__c>(oldList);
        this.mapTransactions = TA_Mem_QueriesBU.getInstance().mapTransactions;

        for (TREX1__Membership__c mem : newList) {
            if (isEligibleForPromotions(mem)) {
                Membership_Promotion__c promo = getPromotionForMembership(mem);
                if (promo != null) {
                    mem.Membership_Promotion__c = promo.Id;
                }
            }
        }
    }

    private Boolean isEligibleForPromotions(TREX1__Membership__c mem) {
        Boolean isEligible = false;
        Boolean isNewlyActivated = mem.TREX1__Status__c == 'Active' && eligibleFormerStatuses.contains(this.oldMap.get(mem.Id).TREX1__Status__c);
        Boolean isPrimaryMembership = mem.TREX1__Group__c == null || mem.TREX1__Contact__c == this.mapTransactions.get(mem.TREX1__Purchasing_Transaction__c).TREX1__Contact__c;
        if (!mem.Ineligible_for_Promotions__c && isNewlyActivated && isPrimaryMembership) {
            isEligible = true;
        }
        return isEligible;
    }

    private Membership_Promotion__c getPromotionForMembership(TREX1__Membership__c mem) {
        return MembershipPromotionSelector.getActivePromotion(mem.TREX1__memb_Type__c);
    }
    
}