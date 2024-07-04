/*****************************************************
 * Called by metadata trigger handler
 * Manage from sObject Trigger Settings mdt: Membership
******************************************************/
public without sharing class TA_Mem_HandlePromotionAU implements TriggerAction.AfterUpdate {

    private static final String PROMO_TYPE_ISSUE_CREDITS = 'Issue Credits';
    private static final String ADJUSTMENT_TYPE_CREDIT = 'Credit';
    @TestVisible
    private static final String ADJUSTMENT_DESCRIPTION = 'Membership Promotion Credits';

    private static Set<String> eligibleFormerStatuses = new Set<String>{
        'Draft', 
        'Pending Active'
    };

    private static Map<Id, TREX1__Membership_Type__c> mapCachedTypesWithPromos;
    private static Map<Id, TREX1__Membership__c> newMap;
    private static Map<Id, TREX1__Membership__c> oldMap;

    public void afterUpdate(
        List<TREX1__Membership__c> newList, 
        List<TREX1__Membership__c> oldList
    ) {
        oldMap = new Map<Id, TREX1__Membership__c>(oldList);
        newMap = TA_Mem_QueriesAU.getInstance().mapMemberships;

        Set<Id> setEligibleMembershipIds = getEligibleNewlyActivatedMembershipIds(newMap.values());
        if (!setEligibleMembershipIds.isEmpty()) {
            MembershipPromotionService serv = new MembershipPromotionService(setEligibleMembershipIds);
            serv.handlePromotions();
        }
    }

    private Set<Id> getEligibleNewlyActivatedMembershipIds(
        List<TREX1__Membership__c> lstMemberships
    ) {
        Set<Id> membershipIds = new Set<Id>();
        for (TREX1__Membership__c mem : lstMemberships) {
            // Override checkbox on the membership removes records from evaluation
            if (mem.Ineligible_for_Promotions__c) continue;

            Boolean isNewlyActivated = mem.TREX1__Status__c == 'Active' && eligibleFormerStatuses.contains(oldMap.get(mem.Id).TREX1__Status__c);
            Boolean isPrimaryMembership = mem.TREX1__Group__c == null || mem.TREX1__Contact__c == mem.TREX1__Purchasing_Transaction__r.TREX1__Contact__c;
            if (isNewlyActivated && isPrimaryMembership) {
                membershipIds.add(mem.Id);
            }
        }
        return membershipIds;
    }
    
}