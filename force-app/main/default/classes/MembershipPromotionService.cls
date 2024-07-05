public with sharing class MembershipPromotionService {

    public class MembershipPromotionServiceException extends Exception {}

    private static final String ADJUSTMENT_TYPE_CREDIT = 'Credit';
    private static final String BENEFIT_TYPE_ACCOUNT_CREDIT = 'Account_Credit';
    private static final String BENEFIT_TYPE_GUEST_PASSES = 'Guest_Passes';
    private static final String BENEFIT_TYPE_INITIATION_FEE = 'Initiation_Fee_Discount';
    private static final String ADJUSTMENT_DESCRIPTION = 'Membership Promotion Credits';
    private static final String GUEST_PASS_STATUS_ISSUED = 'Issued';
    private static final String GUEST_PASS_SOURCE = 'Membership';

    private Set<Id> membershipIds;
    private Map<Id, TREX1__Membership__c> membershipMap;
    private List<TRecManualAdjustmentWrapper> accountCreditWrappers = new List<TRecManualAdjustmentWrapper>();
    private List<Guest_Pass__c> guestPassesToInsert = new List<Guest_Pass__c>();

    public MembershipPromotionService(Set<Id> membershipIds) {
        this.membershipIds = membershipIds;
    }
    
    public void handlePromotions() {
        for (TREX1__Membership__c mem : getMembershipMap().values()) {
            generatePromotionBenefits(mem);
        }
        insertPromotionBenefits();
    }

    private void generatePromotionBenefits(TREX1__Membership__c membership) {
        if (MembershipPromotionSelector.getActivePromotion(membership.TREX1__memb_Type__c) == null) return;
        
        Membership_Promotion__c promo = MembershipPromotionSelector.getActivePromotion(membership.TREX1__memb_Type__c);
        for (Promotion_Benefit__c pb : promo.Promotion_Benefits__r) {
            String recordTypeName = pb.RecordType.DeveloperName;
            if (recordTypeName == BENEFIT_TYPE_ACCOUNT_CREDIT) {
                accountCreditWrappers.add( createAdjustmentWrapper(membership, pb) );
            } else if (recordTypeName == BENEFIT_TYPE_GUEST_PASSES) {
                guestPassesToInsert.addAll( generateGuestPasses(membership, pb) );
            } else if (recordTypeName == BENEFIT_TYPE_INITIATION_FEE) {
                // Nothing happens here, since this is handled during the membership sale with an auto-discount
            } else {
                throw new MembershipPromotionServiceException(
                    'Unknown Promotion Benefit Type: ' + pb.RecordType.DeveloperName + ' (' + pb.Id + ')'
                );
            }
        }
    }

    /**
     * Create a single adjustment wrapper for an account credit
     */
    private static TRecManualAdjustmentWrapper createAdjustmentWrapper(
        TREX1__Membership__c membership,
        Promotion_Benefit__c promotionBenefit
    ) {
        TRecManualAdjustmentWrapper wrap = new TRecManualAdjustmentWrapper();
        wrap.accountId = membership.TREX1__Account__c;
        wrap.contactId = membership.TREX1__Contact__c;
        wrap.amount = promotionBenefit.Credit_Amount__c;
        wrap.type = ADJUSTMENT_TYPE_CREDIT;
        wrap.glCode = promotionBenefit.Expense_GL_Account__r.TREX1__GL_Account_Number__c ?? membership.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c;
        wrap.sourceMembershipId = membership.Id;
        wrap.membershipPromotionId = promotionBenefit.Membership_Promotion__c;
        return wrap;
    }

    private List<Guest_Pass__c> generateGuestPasses(
        TREX1__Membership__c membership, 
        Promotion_Benefit__c promotionBenefit
    ) {
        return GuestPassService.createGuestPassesForMembership(
            membership, 
            Integer.valueOf( promotionBenefit.Number_of_Guest_Passes__c )
        );
    }

    private void insertPromotionBenefits() {
        if (!this.accountCreditWrappers.isEmpty()) {
            TRecManualAdjustmentService service = new TRecManualAdjustmentService(this.accountCreditWrappers);
            service.description = ADJUSTMENT_DESCRIPTION;
            service.createAdjustments();
        }
        if (!this.guestPassesToInsert.isEmpty()) {
            Database.insert(this.guestPassesToInsert, AccessLevel.SYSTEM_MODE);
        }
    }

    private Map<Id, TREX1__Membership__c> getMembershipMap() {
        if (this.membershipMap == null) {
            this.membershipMap = new Map<Id, TREX1__Membership__c>([
                SELECT Id, 
                       Ineligible_for_Promotions__c, 
                       TREX1__Status__c, 
                       TREX1__Group__c, 
                       Location_ID__c, 
                       TREX1__memb_Type__c, 
                       TREX1__memb_Type__r.Revenue_GL_Account__c, 
                       TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c, 
                       TREX1__Account__c, 
                       TREX1__Contact__c, 
                       TREX1__Purchasing_Transaction__r.TREX1__Contact__c
                  FROM TREX1__Membership__c
                 WHERE Id IN :this.membershipIds
            ]);
        }
        return this.membershipMap;
    }

}
