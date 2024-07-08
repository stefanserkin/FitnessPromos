public with sharing class TA_AMP_ValidateExpenseAccount implements TriggerAction.BeforeInsert {

    @TestVisible
    private static final String INVALID_EXPENSE_ACCOUNT_EXCEPTION = 'No valid expense account. There must either be a Revenue GL Account on the Membership Type or an Expense GL Account on the Promotion Benefit';
    private static final Set<String> RECORD_TYPES_REQUIRING_EXPENSE_ACCOUNTS = new Set<String>{
        'Initiation_Fee_Discount',
        'Account_Credit'
    };

    private List<Assigned_Membership_Promotion__c> newList;
    private Map<Id, List<Assigned_Membership_Promotion__c>> promoIdToAssignments;
    private Map<Id, Membership_Promotion__c> promosWithInvalidExpenseAccounts;
    private Map<Id, TREX1__Membership_Type__c> memTypesWithInvalidRevenueAccounts;
    
    public void beforeInsert(List<Assigned_Membership_Promotion__c> newList) {
        this.newList = newList;
        for (Assigned_Membership_Promotion__c amp : newList) {
            if (isInvalidExpenseAccount(amp)) {
                amp.addError(INVALID_EXPENSE_ACCOUNT_EXCEPTION);
            }
        }
    }

    private Boolean isInvalidExpenseAccount(Assigned_Membership_Promotion__c amp) {
        return getPromosWithInvalidExpenseAccounts().containsKey(amp.Membership_Promotion__c) &&
            getInvalidMembershipTypeAccounts().containsKey(amp.Membership_Type__c);
    }

    private Map<Id, List<Assigned_Membership_Promotion__c>> getPromoIdToAssignmentsMap() {
        if (this.promoIdToAssignments == null) {
            this.promoIdToAssignments = buildPromoIdToAssignmentsMap();
        }
        return this.promoIdToAssignments;
    }

    private Map<Id, Membership_Promotion__c> getPromosWithInvalidExpenseAccounts() {
        if (this.promosWithInvalidExpenseAccounts == null) {
            this.promosWithInvalidExpenseAccounts = queryForPromosWithInvalidExpenseAccounts();
        }
        return this.promosWithInvalidExpenseAccounts;
    }

    private Map<Id, TREX1__Membership_Type__c> getInvalidMembershipTypeAccounts() {
        if (this.memTypesWithInvalidRevenueAccounts == null) {
            this.memTypesWithInvalidRevenueAccounts = queryForInvalidMembershipTypeAccounts(
                getMembershipTypeIdsInTrigger()
            );
        }
        return this.memTypesWithInvalidRevenueAccounts;
    }

    private Set<Id> getMembershipTypeIdsInTrigger() {
        Set<Id> setMemTypeIds = new Set<Id>();
        for (Assigned_Membership_Promotion__c amp : this.newList) {
            setMemTypeIds.add(amp.Membership_Type__c);
        }
        return setMemTypeIds;
    }

    private Map<Id, List<Assigned_Membership_Promotion__c>> buildPromoIdToAssignmentsMap() {
        Map<Id, List<Assigned_Membership_Promotion__c>> assignmentMap = new Map<Id, List<Assigned_Membership_Promotion__c>>();
        for (Assigned_Membership_Promotion__c amp : this.newList) {
            if (!assignmentMap.containsKey(amp.Membership_Promotion__c)) {
                assignmentMap.put(amp.Membership_Promotion__c, new List<Assigned_Membership_Promotion__c>());
            }
            assignmentMap.get(amp.Membership_Promotion__c).add(amp);
        }
        return assignmentMap;
    }

    private Map<Id, Membership_Promotion__c> queryForPromosWithInvalidExpenseAccounts() {
        return new Map<Id, Membership_Promotion__c>([
            SELECT Id
              FROM Membership_Promotion__c
             WHERE Id IN :getPromoIdToAssignmentsMap().keySet()
               AND Id IN (SELECT Membership_Promotion__c
                            FROM Promotion_Benefit__c
                           WHERE RecordType.DeveloperName IN :RECORD_TYPES_REQUIRING_EXPENSE_ACCOUNTS
                             AND Expense_GL_Account__c = null)
        ]);
    }

    private Map<Id, TREX1__Membership_Type__c> queryForInvalidMembershipTypeAccounts(
        Set<Id> setMemTypeIds
    ) {
        return new Map<Id, TREX1__Membership_Type__c>([
            SELECT Id, Name
              FROM TREX1__Membership_Type__c
             WHERE Id IN :setMemTypeIds
               AND Revenue_GL_Account__c = null
        ]);
    }

}