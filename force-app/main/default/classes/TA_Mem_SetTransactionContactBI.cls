public with sharing class TA_Mem_SetTransactionContactBI implements TriggerAction.BeforeInsert {
    
    public void beforeInsert(List<TREX1__Membership__c> newList) {
        Map<Id, Id> mapTransactionContactIds = TA_Mem_QueriesBI.getInstance().mapTransactionContactIds;
        for (TREX1__Membership__c mem : newList) {
            if (mapTransactionContactIds.containsKey(mem.TREX1__Purchasing_Transaction__c)) {
                mem.Transaction_Contact__c = mapTransactionContactIds.get(mem.TREX1__Purchasing_Transaction__c);
            }
        }
    }

}