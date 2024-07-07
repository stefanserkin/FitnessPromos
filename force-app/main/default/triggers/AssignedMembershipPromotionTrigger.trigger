trigger AssignedMembershipPromotionTrigger on Assigned_Membership_Promotion__c (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
    new MetadataTriggerHandler().run();
}