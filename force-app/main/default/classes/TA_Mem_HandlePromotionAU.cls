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
        System.debug('::::: entered handle promo after update');
        oldMap = new Map<Id, TREX1__Membership__c>(oldList);

        Set<Id> eligibleMembershipIds = getEligibleNewlyActivatedMembershipIds(newList);
        System.debug('::::: eligible membership ids --> ' + eligibleMembershipIds);
        if (!eligibleMembershipIds.isEmpty()) {
            MembershipPromotionService serv = new MembershipPromotionService(eligibleMembershipIds);
            serv.handlePromotions();
        }
    }

    private Set<Id> getEligibleNewlyActivatedMembershipIds(
        List<TREX1__Membership__c> lstMemberships
    ) {
        Set<Id> membershipIds = new Set<Id>();
        for (TREX1__Membership__c mem : lstMemberships) {
            if (isEligibleForPromotion(mem)) {
                membershipIds.add(mem.Id);
            }
        }
        return membershipIds;
    }

    private Boolean isEligibleForPromotion(TREX1__Membership__c mem) {
        Boolean isEligible = false;
        Boolean isNewlyActivated = mem.TREX1__Status__c == 'Active' && eligibleFormerStatuses.contains(oldMap.get(mem.Id).TREX1__Status__c);
        if (
            mem.Membership_Promotion__c != null && 
            isNewlyActivated &&
            !mem.Ineligible_for_Promotions__c 
        ) {
            isEligible = true;
        }
        System.debug('::::::: mem --> ' + mem);
        System.debug('::::::: is eligible --> ' + isEligible);
        return isEligible;
    }
    
}