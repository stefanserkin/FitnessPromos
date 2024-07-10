public with sharing class TA_Mem_QueriesBU {
    private static TA_Mem_QueriesBU instance;

    private TA_Mem_QueriesBU() {}

    public static TA_Mem_QueriesBU getInstance() {
        if (TA_Mem_QueriesBU.instance == null) {
            TA_Mem_QueriesBU.instance = new TA_Mem_QueriesBU();
        }
        return TA_Mem_QueriesBU.instance;
    }

    public Map<Id, TREX1__Transaction__c> mapTransactions { get; private set; }

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Membership
     ******************************************************/

    public class Service implements TriggerAction.BeforeUpdate {
        public void beforeUpdate(
            List<TREX1__Membership__c> newList,
            List<TREX1__Membership__c> oldList
        ) {
            TA_Mem_QueriesBU.getInstance().mapTransactions = getTransactionMap(newList);
        }
        
        private Map<Id, TREX1__Transaction__c> getTransactionMap(
            List<TREX1__Membership__c> newList
        ) {
            Set<Id> transactionIds = new Set<Id>();
            for (TREX1__Membership__c mem : newList) {
                if (mem.TREX1__Purchasing_Transaction__c != null) {
                    transactionIds.add(mem.TREX1__Purchasing_Transaction__c);
                }
            }
            Map<Id, TREX1__Transaction__c> mapResult = new Map<Id, TREX1__Transaction__c>([
				SELECT Id, TREX1__Contact__c
                  FROM TREX1__Transaction__c
				 WHERE Id IN :transactionIds                
            ]);
            return mapResult;
        }

    }
}