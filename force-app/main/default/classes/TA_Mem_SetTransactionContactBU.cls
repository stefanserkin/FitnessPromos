public with sharing class TA_Mem_SetTransactionContactBU implements TriggerAction.BeforeUpdate {
    
    public void beforeUpdate(
        List<TREX1__Membership__c> newList, 
        List<TREX1__Membership__c> oldList
    ) {
        Map<Id, TREX1__Membership__c> oldMap = new Map<Id, TREX1__Membership__c>(oldList);
        Map<Id, TREX1__Membership__c> mapMemberships = TA_Mem_QueriesBU.getInstance().mapMemberships;

        for (TREX1__Membership__c mem : newList) {
            if (mem.TREX1__Purchasing_Transaction__c != oldMap.get(mem.Id).TREX1__Purchasing_Transaction__c) {
                if (mem.TREX1__Purchasing_Transaction__c == null) {
                    mem.Transaction_Contact__c = null;
                } else {
                    mem.Transaction_Contact__c = mapMemberships.get(mem.Id).TREX1__Purchasing_Transaction__r.TREX1__Contact__c;
                }
            }
        }
    }

}