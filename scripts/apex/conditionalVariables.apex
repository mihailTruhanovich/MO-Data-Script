List<String> names = new List<String>{
    'Cash Handling',
    'Continuous Shift',
    'Inconvenient Location',
    'Hazardous Substances',
    'Outdoor',
    'New Variable'
};

MO_Employment_Conditions__c ec = new MO_Employment_Conditions__c();
ec.Name = 'Conditional Variables';
insert ec;

MO_Rate_Bundle__c rateBundle = new MO_Rate_Bundle__c(
    Name = ec.Name,
    Employment_Conditions__c = ec.Id
);
insert rateBundle;

// List<bullhorn__MO_Conditional_Variable__c> conditionalVariables = [SELECT Name FROM bullhorn__MO_Conditional_Variable__c];
List<MO_Conditional_Variable__c> conditionalVariables = new List<MO_Conditional_Variable__c>();

for (String name : names) {
    conditionalVariables.add(new MO_Conditional_Variable__c(
        Name = name
    ));
}

insert conditionalVariables;

Date startDate = Date.today().addYears(-1);

Id basicRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Basic_Rate').getRecordTypeId();
Id otherRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Other_Rate').getRecordTypeId();

MO_Rate__c basicRate = new MO_Rate__c(
    bullhorn__Time_Categories__c   = 'Normal Time',
    RecordTypeId = basicRecordTypeId,
    Start_Date__c = startDate,
    Charge_Rate__c = 5,
    Pay_Rate__c = 3,
    Pay_Amount__c = 123,
    Rate_Bundle__c = rateBundle.Id
);

List<MO_Rate__c> rates = new List<MO_Rate__c>{basicRate};

for (bullhorn__MO_Conditional_Variable__c cv : conditionalVariables) {
    rates.add(
        new MO_Rate__c(
            bullhorn__Time_Categories__c   = 'Normal Time',
            RecordTypeId = otherRecordTypeId,
            Start_Date__c = startDate,
            Charge_Rate_Percent__c = 5,
            Pay_Rate__c = 3,
            Pay_Amount__c = 123,
            Rate_Bundle__c = rateBundle.Id,
            Conditional_Variable__c = cv.Id,
            Name__c = cv.Name
        )
    );
}
insert rates;




