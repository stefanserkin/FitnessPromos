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

    public void beforeUpdate(
        List<TREX1__Membership__c> newList, 
        List<TREX1__Membership__c> oldList
    ) {
        Map<Id, TREX1__Membership__c> oldMap = new Map<Id, TREX1__Membership__c>(oldList);

        for (TREX1__Membership__c mem : newList) {
            if (mem.Ineligible_for_Promotions__c) continue;

            Boolean isNewlyActivated = mem.TREX1__Status__c == 'Active' && eligibleFormerStatuses.contains(oldMap.get(mem.Id).TREX1__Status__c);
            Boolean isPrimaryMembership = mem.TREX1__Group__c == null || mem.TREX1__Contact__c == mem.TREX1__Purchasing_Transaction__r.TREX1__Contact__c;
            if (isNewlyActivated && isPrimaryMembership) {
                Membership_Promotion__c promo = MembershipPromotionSelector.getActivePromotion(mem.TREX1__memb_Type__c);
                if (promo != null) {
                    mem.Membership_Promotion__c = promo.Id;
                }
            }
        }
    }
    
}