Id promoId = 'a6oUX0000001VTBYA2';
Decimal creditAmount = 50.00;
String description = 'Membership Promotion Credits';

List<TREX1__Membership__c> memberships = [
    select Id, TREX1__Account__c, TREX1__Contact__c, TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c, CreatedBy.Name, Commitment_Type__c, TREX1__Type__c, Type_of_Membership__c, Contact_Age__c
  from TREX1__Membership__c 
 where Commitment_Type__c = 'First Year Contract' 
   and TREX1__Start_Date__c >= 2024-07-01
   and TREX1__Account__c NOT IN (select TREX1__Account__c from TREX1__Journal_Entry__c where TREX1__Credit__c = 50.00)
   and Contact_Age__c >= 18
   and TREX1__Status__c = 'Active'
   and Ineligible_for_Promotions__c = false
  and Type_of_Membership__c != 'Water Polo'
  and CreatedBy.Name = 'Sean Polite'
];

List<TRecManualAdjustmentWrapper> wrappers = new List<TRecManualAdjustmentWrapper>();
for (TREX1__Membership__c membership : memberships) {
    TRecManualAdjustmentWrapper wrap = new TRecManualAdjustmentWrapper();
    wrap.accountId             = membership.TREX1__Account__c;
    wrap.contactId             = membership.TREX1__Contact__c;
    wrap.amount                = creditAmount;
    wrap.type                  = 'Credit';
    wrap.glCode                = membership.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c;
    wrap.sourceMembershipId    = membership.Id;
    wrap.membershipPromotionId = promoId;
    wrappers.add(wrap);
}


TRecManualAdjustmentService serv = new TRecManualAdjustmentService(wrappers);
serv.description = description;
serv.createAdjustments();
