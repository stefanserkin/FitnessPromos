
String description = 'SS - Adjusting incorrectly granted credits from closed February promotion';

Map<TREX1__Journal_Entry__c, TREX1__Journal_Entry__c> mapCreditJeToDebit = new Map<TREX1__Journal_Entry__c, TREX1__Journal_Entry__c>();
List<TREX1__Journal_Entry__c> lstCredits = [
    SELECT Id, TREX1__Contact__c, TREX1__Account__c, Promo_Credits_Source_Membership__c, Promo_Credits_Source_Membership__r.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c
      FROM TREX1__Journal_Entry__c
     WHERE TREX1__GL_Code__c = '10-10-000-12504'
       AND TREX1__Unapplied_Credit_Amount__c = 29
       AND CreatedDate = THIS_MONTH
];

List<TRecManualAdjustmentWrapper> lstWrappers = new List<TRecManualAdjustmentWrapper>();
for (TREX1__Journal_Entry__c je : lstCredits) {
    if (je.Promo_Credits_Source_Membership__r.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c == null) continue;
    TRecManualAdjustmentWrapper wrap = new TRecManualAdjustmentWrapper();
    wrap.accountId = je.TREX1__Account__c;
    wrap.contactId = je.TREX1__Contact__c;
    wrap.amount  = 29.00;
    wrap.type  = 'Balance';
    wrap.glCode = je.Promo_Credits_Source_Membership__r.TREX1__memb_Type__r.Revenue_GL_Account__r.TREX1__GL_Account_Number__c;
    wrap.sourceMembershipId = je.Promo_Credits_Source_Membership__c;
    lstWrappers.add(wrap);
}

TRecManualAdjustmentService serv = new TRecManualAdjustmentService(lstWrappers);
serv.description = description;
serv.createAdjustments();