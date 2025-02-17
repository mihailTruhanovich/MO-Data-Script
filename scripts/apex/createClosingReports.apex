List<TR1__Job__c> jobs = [SELECT Id, TR1__Account__c, TR1__Contact__c, TR1__Estimated_Start_Date__c FROM TR1__Job__c];
List<TR1__Closing_Report__c> closingReports = new List<TR1__Closing_Report__c>();
Id clConsultingRecordTypeId = Schema.SObjectType.TR1__Closing_Report__c.getRecordTypeInfosByDeveloperName()
                                    .get('Consulting')
                                    .getRecordTypeId();
for (TR1__Job__c job : jobs) {
    closingReports.add( new TR1__Closing_Report__c(
            TR1__Start_Date__c = job.TR1__Estimated_Start_Date__c,
            TR1__End_Date__c = job.TR1__Estimated_Start_Date__c.addDays(300),
            TR1__Job__c = job.Id,
            RecordTypeId = clConsultingRecordTypeId,
            MO_Period__c = 'Week',
            TR1__Person_Placed__c = job.TR1__Contact__c,
            TR1__Account__c = job.TR1__Account__c,
            TR1__Week_Ending__c = 'Sunday'
        )
    );
}

insert closingReports;