/*
    MyUtils.clearData();
 */

public with sharing class MyUtils implements Database.Batchable<SObject>, Database.Stateful {
    private List<String> sobjectsNames;

    public MyUtils(List<String> sobjectsNames) {
        if (sobjectsNames == null) {
            List<String> fullSet = new List<String>{
                'MO_Rate__c',
                'MO_Closing_Report_Rate__c',
                'TR1__Closing_Report__c',
                'TR1__Job__c',
                'MO_Rate_Bundle__c',
                'MO_Contract_Version__c',
                'MO_Contract__c',
                'MO_Employment_Conditions__c',
                'Entitlement',
                'Account',
                'MO_Change_Request_Failure__c',
                'MO_Change_Request__c'
            };
            this.sobjectsNames = fullSet;
        } else {
            this.sobjectsNames = sobjectsNames;
        }
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        delete records;
    }

    public void finish(Database.BatchableContext context) {
        if (!sobjectsNames.isEmpty()) {
            Database.executeBatch(new MyUtils(sobjectsNames));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String sobjectName = sobjectsNames.remove(0);
        String query = 'SELECT Id FROM ' + sobjectName;
        return Database.getQueryLocator(query);
    }

    public static void clearData() {
        Database.executeBatch(new MyUtils(null));
    }
}