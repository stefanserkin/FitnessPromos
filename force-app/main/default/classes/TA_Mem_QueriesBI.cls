public with sharing class TA_Mem_QueriesBI {
    private static TA_Mem_QueriesBI instance;

    private TA_Mem_QueriesBI() {}

    public static TA_Mem_QueriesBI getInstance() {
        if (TA_Mem_QueriesBI.instance == null) {
            TA_Mem_QueriesBI.instance = new TA_Mem_QueriesBI();
        }
        return TA_Mem_QueriesBI.instance;
    }

    public Map<Id, Id> mapTransactionContactIds { get; private set; }

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Membership
     ******************************************************/

    public class Service implements TriggerAction.BeforeInsert {
        private List<TREX1__Membership__c> newList;
        private Set<Id> transactionIds;

        public void beforeInsert(List<TREX1__Membership__c> newList) {
            this.newList = newList;
            TA_Mem_QueriesBI.getInstance().mapTransactionContactIds = getTransactionContactIdMap();
        }

        private Map<Id, Id> getTransactionContactIdMap() {
            Map<Id, Id> mapResult = new Map<Id, Id>();
            Set<Id> transactionIds = getTransactionIdsFromMemberships();
            List<TREX1__Transaction__c> transactions = queryForTransactions();
            for (TREX1__Transaction__c trans : transactions) {
                mapResult.put(trans.Id, trans.TREX1__Contact__c);
            }
            return mapResult;
        }

        private Set<Id> getTransactionIdsFromMemberships() {
            this.transactionIds = new Set<Id>();
            for (TREX1__Membership__c mem : newList) {
                if (mem.TREX1__Purchasing_Transaction__c != null) {
                    this.transactionIds.add(mem.TREX1__Purchasing_Transaction__c);
                }
            }
            return this.transactionIds;
        }

        private List<TREX1__Transaction__c> queryForTransactions() {
            return [
                SELECT Id,
                       TREX1__Contact__c
                  FROM TREX1__Transaction__c
                 WHERE Id IN :this.transactionIds
                  WITH USER_MODE
            ];
        }
    }
    
}