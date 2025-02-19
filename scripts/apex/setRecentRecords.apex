List<String> employmentConditionNames = new List<String>{
    'Button Universe Inc. Condts'
};
List<String> contactNames = new List<String>{
    'Alicia Silverstone',
    'Drew Barrymore',
    'Julia Roberts'
};
List<String> accountNames = new List<String>{
    'Button Universe Inc.'
};
List<String> jobNames = new List<String>{
    'Button Universe Inc. - Button Counting'
};
List<String> RACNames = new List<String>{
    'Pay Element Catalogue',
    'Job Level Catalogue',
    'Sub Level Catalogue'
};


List<Object>
objects = [SELECT Id FROM bullhorn__MO_Employment_Conditions__c WHERE Name IN :employmentConditionNames FOR VIEW];
objects = [SELECT Id FROM Contact WHERE Name IN :contactNames FOR VIEW];
objects = [SELECT Id FROM account WHERE Name IN :accountNames FOR VIEW];
objects = [SELECT Id FROM TR1__Job__c WHERE Name IN :jobNames FOR VIEW];
objects = [SELECT Id FROM bullhorn__MO_Rate_Attribute_Catalogue__c WHERE Name IN :RACNames FOR VIEW];
objects = [SELECT Id FROM TR1__Closing_Report__c WHERE TR1__Job__r.Name IN :jobNames FOR VIEW];