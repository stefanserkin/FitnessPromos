/*****************************************************
 * Called by metadata trigger handler
 * Manage from sObject Trigger Settings mdt: Membership
******************************************************/
public with sharing class TA_Mem_HandlePromotionAU implements TriggerAction.AfterUpdate {

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

        // Filter to memberships being activated
        List<TREX1__Membership__c> lstActivatedMems = filterMemberships(newMap.values());
        if (lstActivatedMems.isEmpty()) return;

        // Get active promotions for membership types
        Set<Id> setMemTypeIds = new Set<Id>();
        for (TREX1__Membership__c mem : lstActivatedMems) {
            setMemTypeIds.add(mem.TREX1__memb_Type__c);
        }
        Map<Id, TREX1__Membership_Type__c> mapTypesWithPromos = getActivePromotions(setMemTypeIds);

        // Filter to activated memberships with active promos
        List<TREX1__Membership__c> lstMemsWithPromos = new List<TREX1__Membership__c>();
        for (TREX1__Membership__c mem : lstActivatedMems) {
            if (mapTypesWithPromos.containsKey(mem.TREX1__memb_Type__c)) {
                lstMemsWithPromos.add(mem);
            }
        }

        // Create wrappers for each valid membership promo and membership
        List<TRecManualAdjustmentWrapper> lstWrappers = new List<TRecManualAdjustmentWrapper>();
        for (TREX1__Membership__c mem : lstMemsWithPromos) {
            TREX1__Membership_Type__c mTypeWithPromos = mapTypesWithPromos.get(mem.TREX1__memb_Type__c);

            for (Assigned_Membership_Promotion__c amp : mTypeWithPromos.Assigned_Membership_Promotions__r) {

                // Issue Credits promotion
                if (amp.Membership_Promotion__r.Type__c == PROMO_TYPE_ISSUE_CREDITS) {
                    // Guard against issue credits promos without a defined gl code
                    if (
                        amp.Membership_Promotion__r.GL_Account__c == null && 
                        mTypeWithPromos.Revenue_GL_Account__r.TREX1__GL_Account_Number__c == null
                    ) {
                        continue;
                    }
                    
                    // The gl code to offset, set from GL Code on promo
                    // If empty, use the revenue gl account from the membership type
                    String glCode = amp.Membership_Promotion__r.GL_Account__c != null
                        ? amp.Membership_Promotion__r.GL_Account__r.TREX1__GL_Account_Number__c
                        : mTypeWithPromos.Revenue_GL_Account__r.TREX1__GL_Account_Number__c;
                    lstWrappers.add( createAdjustmentWrapper(mem, amp, glCode) );
                }

            }
        }

        // Call manual adjustment service to create credit adjustments for wrappers
        if (!lstWrappers.isEmpty()) {
            TRecManualAdjustmentService service = new TRecManualAdjustmentService(lstWrappers);
            service.description = ADJUSTMENT_DESCRIPTION;
            service.createAdjustments();
        }
        
    }

    /**
     * Create a single adjustment wrapper
     */
    private static TRecManualAdjustmentWrapper createAdjustmentWrapper(
        TREX1__Membership__c membership,
        Assigned_Membership_Promotion__c promo, 
        String glCode
    ) {
        TRecManualAdjustmentWrapper wrap = new TRecManualAdjustmentWrapper();
        wrap.accountId             = membership.TREX1__Account__c;
        wrap.contactId             = membership.TREX1__Contact__c;
        wrap.amount                = promo.Membership_Promotion__r.Credit_Amount__c;
        wrap.type                  = ADJUSTMENT_TYPE_CREDIT;
        wrap.glCode                = glCode;
        wrap.sourceMembershipId    = membership.Id;
        wrap.membershipPromotionId = promo.Membership_Promotion__c;
        return wrap;
    }

    /**
     * @description Filter to newly activated memberships for individual memberships
     *  and for the primary membership in a group membership
     * 
     * Criteria:
     *  - NewStatus = 'Active'
     *  - OldStatus IN ('Draft', 'Pending Active')
     *  - Either an individual membership or the primary in a group membership
     */
    private List<TREX1__Membership__c> filterMemberships(
        List<TREX1__Membership__c> lstMemberships
    ) {
        List<TREX1__Membership__c> lstActivatedMems = new List<TREX1__Membership__c>();
        for (TREX1__Membership__c mem : lstMemberships) {
            Boolean isNewlyActivated = mem.TREX1__Status__c == 'Active' && eligibleFormerStatuses.contains(oldMap.get(mem.Id).TREX1__Status__c);
            Boolean isPrimaryMembership = mem.TREX1__Group__c == null || mem.TREX1__Contact__c == mem.TREX1__Purchasing_Transaction__r.TREX1__Contact__c;
            if (isNewlyActivated && isPrimaryMembership) {
                lstActivatedMems.add(mem);
            }
        }
        return lstActivatedMems;
    }

    /**
     * Get a map of membership types with active child membership promotions
     */
    private static Map<Id, TREX1__Membership_Type__c> getActivePromotions(
        Set<Id> setMembershipTypeIds
    ) {
        if (mapCachedTypesWithPromos == null) {
            mapCachedTypesWithPromos = new Map<Id, TREX1__Membership_Type__c>([
                SELECT Id, Revenue_GL_Account__r.TREX1__GL_Account_Number__c, 
                       (SELECT Membership_Promotion__c, 
                               Membership_Promotion__r.Type__c, 
                               Membership_Promotion__r.Credit_Amount__c, 
                               Membership_Promotion__r.Void_if_Cancelled__c, 
                               Membership_Promotion__r.GL_Account__c, 
                               Membership_Promotion__r.GL_Account__r.TREX1__GL_Account_Number__c
                          FROM Assigned_Membership_Promotions__r)
                  FROM TREX1__Membership_Type__c
                 WHERE Id IN :setMembershipTypeIds
                   AND Id IN (SELECT Membership_Type__c
                                FROM Assigned_Membership_Promotion__c
                               WHERE Membership_Promotion__r.Active__c = TRUE 
                                 AND Membership_Promotion__r.Start_Date__c <= TODAY
                                 AND Membership_Promotion__r.End_Date__c >= TODAY)
                  WITH USER_MODE
            ]);
        }
        return mapCachedTypesWithPromos;
    }
    
}