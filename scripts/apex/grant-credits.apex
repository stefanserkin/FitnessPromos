Id memId = 'a2aUX000000EszpYAC';
Id promoId = 'a6oUX0000000UR7YAM';
Decimal creditAmount = 29.00;
String description = 'Membership Promotion Credits';

TREX1__Membership__c membership = [
    SELECT Id, TREX1__Contact__c, TREX1__Account__c, TREX1__memb_Type__c, 
           TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c
      FROM TREX1__Membership__c
     WHERE Id = :memId
     LIMIT 1
];

TRecManualAdjustmentWrapper wrap = new TRecManualAdjustmentWrapper();
wrap.accountId             = membership.TREX1__Account__c;
wrap.contactId             = membership.TREX1__Contact__c;
wrap.amount                = creditAmount;
wrap.type                  = 'Credit';
wrap.glCode                = membership.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c;
wrap.sourceMembershipId    = membership.Id;
wrap.membershipPromotionId = promoId;

System.debug(wrap);
TRecManualAdjustmentService serv = new TRecManualAdjustmentService(
    new List<TRecManualAdjustmentWrapper>{wrap}
);
serv.description = description;
serv.createAdjustments();
