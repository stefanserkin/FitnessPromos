public with sharing class TA_Mem_QueriesBU {
    private static TA_Mem_QueriesBU instance;

    private TA_Mem_QueriesBU() {}

    public static TA_Mem_QueriesBU getInstance() {
        if (TA_Mem_QueriesBU.instance == null) {
            TA_Mem_QueriesBU.instance = new TA_Mem_QueriesBU();
        }
        return TA_Mem_QueriesBU.instance;
    }

    public Map<Id, TREX1__Membership__c> mapMemberships { get; private set; }

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Membership
     ******************************************************/

    public class Service implements TriggerAction.BeforeUpdate {
        public void beforeUpdate(
            List<TREX1__Membership__c> newList,
            List<TREX1__Membership__c> oldList
        ) {
            TA_Mem_QueriesBU.getInstance().mapMemberships = getMembershipMap(newList);
        }

        private Map<Id, TREX1__Membership__c> getMembershipMap(
            List<TREX1__Membership__c> newList
        ) {
            Map<Id, TREX1__Membership__c> mapResult = new Map<Id, TREX1__Membership__c>([
                SELECT Id, 
                       Ineligible_for_Promotions__c, 
                       TREX1__Status__c, 
                       TREX1__Group__c, 
                       TREX1__memb_Type__c, 
                       TREX1__Account__c, 
                       TREX1__Contact__c, 
                       TREX1__Purchasing_Transaction__r.TREX1__Contact__c
                  FROM TREX1__Membership__c
                 WHERE Id IN :newList
            ]);
            return mapResult;
        }

    }
}