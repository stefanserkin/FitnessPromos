public with sharing class MembershipPromotionSelector {

    private static Map<Id, List<Membership_Promotion__c>> cachedActivePromoMap;

    public static Membership_Promotion__c getActivePromotion(Id membershipTypeId) {
        return getActivePromosByMembershipType().containsKey(membershipTypeId)
            ? getActivePromosByMembershipType().get(membershipTypeId).get(0)
            : null;
    }

    private static Map<Id, List<Membership_Promotion__c>> getActivePromosByMembershipType() {
        if (cachedActivePromoMap == null) {
            cachedActivePromoMap = new Map<Id, List<Membership_Promotion__c>>();

            for (Membership_Promotion__c promo : queryForActivePromotions()) {
                for (Assigned_Membership_Promotion__c amp : promo.Assigned_Membership_Promotions__r) {
                    Id memTypeId = amp.Membership_Type__c;
                    if (!cachedActivePromoMap.containsKey(memTypeId)) {
                        cachedActivePromoMap.put(memTypeId, new List<Membership_Promotion__c>());
                    }
                    cachedActivePromoMap.get(memTypeId).add(promo);
                }
            }
        }
        return cachedActivePromoMap;
    }

    private static List<Membership_Promotion__c> queryForActivePromotions() {
        return [
            SELECT Id, 
                   Name, 
                   (SELECT Id, 
                           Membership_Type__c, 
                           Membership_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c
                      FROM Assigned_Membership_Promotions__r),
                   (SELECT Id, 
                           Membership_Promotion__c, 
                           RecordType.DeveloperName, 
                           Credit_Amount__c, 
                           Number_of_Guest_Passes__c, 
                           Void_if_Cancelled__c, 
                           Expense_GL_Account__c,
                           Expense_GL_Account__r.TREX1__GL_Account_Number__c,
                           Discount_Type__c,
                           Discount_Amount__c,
                           Discount_Percentage__c
                      FROM Promotion_Benefits__r)
              FROM Membership_Promotion__c
             WHERE Active__c = true
               AND Start_Date__c <= TODAY
               AND End_Date__c >= TODAY
              WITH SYSTEM_MODE
        ];
    }

}