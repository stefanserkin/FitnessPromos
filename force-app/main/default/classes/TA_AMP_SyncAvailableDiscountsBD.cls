public with sharing class TA_AMP_SyncAvailableDiscountsBD implements TriggerAction.BeforeDelete {

    private List<Assigned_Membership_Promotion__c> oldList;

    public void beforeDelete(List<Assigned_Membership_Promotion__c> oldList) {
        this.oldList = oldList;
        deleteAvailableDiscounts( getSyncedAvailableDiscounts() );
    }

    private void deleteAvailableDiscounts(List<TREX1__Available_Discounts__c> availableDiscounts) {
        Database.delete(availableDiscounts, AccessLevel.USER_MODE);
    }

    private List<TREX1__Available_Discounts__c> getSyncedAvailableDiscounts() {
        return [
            SELECT Id
              FROM TREX1__Available_Discounts__c
             WHERE Assigned_Membership_Promotion__c IN :this.oldList
              WITH USER_MODE
        ];
    }

}