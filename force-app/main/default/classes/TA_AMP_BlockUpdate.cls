public with sharing class TA_AMP_BlockUpdate implements TriggerAction.BeforeUpdate {

    @TestVisible
    private static final String AMP_UPDATE_EXCEPTION = 'Assigned Membership Promotion records should not be updated. Use the Manage Assignments flow to delete and create new assignments.';

    private Map<Id, Assigned_Membership_Promotion__c> oldMap;

    public void beforeUpdate(
        List<Assigned_Membership_Promotion__c> newList,
        List<Assigned_Membership_Promotion__c> oldList
    ) {
        this.oldMap = new Map<Id, Assigned_Membership_Promotion__c>(oldList);
        for (Assigned_Membership_Promotion__c amp : newList) {
            if (assignmentHasChanged(amp)) {
                amp.addError(AMP_UPDATE_EXCEPTION);
            }
        }
    }

    private Boolean assignmentHasChanged(Assigned_Membership_Promotion__c amp) {
        return amp.Membership_Type__c != this.oldMap.get(amp.Id).Membership_Type__c;
    }

}