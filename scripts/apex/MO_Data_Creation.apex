List<String> cataloguesRecordTypes = new List<String>{
    'Pay Element',
    'Job Level',
    'Sub Level'
};
Map<String, MO_Rate_Attribute_Catalogue__c> cataloguesByRecordTypeNames = new Map<String, MO_Rate_Attribute_Catalogue__c>();
for (String recordTypeName : cataloguesRecordTypes) {
    cataloguesByRecordTypeNames.put(recordTypeName, null);
}

for (String recordTypeName : cataloguesByRecordTypeNames.keySet()) {
    Id catalogueRecordTypeId = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'bullhorn__MO_Rate_Attribute_Catalogue__c' AND Name = :recordTypeName].Id;
    MO_Rate_Attribute_Catalogue__c catalogue = new MO_Rate_Attribute_Catalogue__c(
        Name = recordTypeName + ' Catalogue',
        RecordTypeId = catalogueRecordTypeId
    );
    cataloguesByRecordTypeNames.put(recordTypeName, catalogue);
}
insert cataloguesByRecordTypeNames.values();

Map<Id,MO_Rate_Attribute_Catalogue_Scope__c> RACScopesByRACId = new Map<Id,MO_Rate_Attribute_Catalogue_Scope__c>();

for (MO_Rate_Attribute_Catalogue__c catalogue : cataloguesByRecordTypeNames.values()) {
    RACScopesByRACId.put(
        catalogue.Id,
        new MO_Rate_Attribute_Catalogue_Scope__c(
            Name = catalogue.Name + ' Scope',
            Catalogue__c = catalogue.Id
        )
    );
}
insert RACScopesByRACId.values();

List<String> RACENameAdditions = new List<String>{
    '01', '02', '03', '04', '05', '06', '07', '08', '09', '10'
};

List<MO_Rate_Attribute_Catalogue_Entry__c> entries = new List<MO_Rate_Attribute_Catalogue_Entry__c>();
for (String recordTypeName : cataloguesByRecordTypeNames.keySet()) {
    Id entryRecordTypeId = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'bullhorn__MO_Rate_Attribute_Catalogue_Entry__c' AND Name = :recordTypeName].Id;
    for (String raceNameAddition : RACENameAdditions) {
        entries.add(new MO_Rate_Attribute_Catalogue_Entry__c(
            Name = recordTypeName + ' ' + raceNameAddition,
            RecordTypeId = entryRecordTypeId,
            Catalogue__c = cataloguesByRecordTypeNames.get(recordTypeName).Id
        ));
    }
    entries.add(new MO_Rate_Attribute_Catalogue_Entry__c(
        Name = recordTypeName + ' Scope',
        RecordTypeId = entryRecordTypeId,
        Rate_Attribute_Catalogue_Scope__c = RACScopesByRACId.get(cataloguesByRecordTypeNames.get(recordTypeName).Id).Id,
        Catalogue__c = cataloguesByRecordTypeNames.get(recordTypeName).Id
    ));
}
insert entries;

//создание контактов
Contact approver = new Contact(FirstName = 'Appo', LastName = 'Approver');
List<Contact> contacts = new List<Contact>{
    new Contact(FirstName = 'Alicia', LastName = 'Silverstone'),
    new Contact(FirstName = 'Drew', LastName = 'Barrymore'),
    new Contact(FirstName = 'Julia', LastName = 'Roberts'),
    new Contact(FirstName = 'Leonardo', LastName = 'DiCaprio'),
    new Contact(FirstName = 'Will', LastName = 'Smith'),
    new Contact(FirstName = 'Meg', LastName = 'Ryan'),
    new Contact(FirstName = 'Tom', LastName = 'Cruise'),
    new Contact(FirstName = 'Winona', LastName = 'Ryder'),
    new Contact(FirstName = 'Arnold', LastName = 'Schwarzenegger'),
    new Contact(FirstName = 'Brad', LastName = 'Pitt'),
    new Contact(FirstName = 'Jim', LastName = 'Carrey'),
    new Contact(FirstName = 'Nicolas', LastName = 'Cage'),
    new Contact(FirstName = 'Robin', LastName = 'Williams'),
    new Contact(FirstName = 'Sandra', LastName = 'Bullock'),
    new Contact(FirstName = 'Tom', LastName = 'Hanks'),
    new Contact(FirstName = 'Cameron', LastName = 'Diaz'),
    new Contact(FirstName = 'Demi', LastName = 'Moore'),
    new Contact(FirstName = 'Antonio', LastName = 'Banderas'),
    new Contact(FirstName = 'John', LastName = 'Travolta'),
    new Contact(FirstName = 'Jodie', LastName = 'Foster'),
    approver
};
insert contacts;

Map<String, String> jobTitleByCompanyName = new Map<String, String>{
    'Button Universe Inc.' => 'Button Counting',
    'Socks & Co.' => 'Sock Matching Specialist',
    'Cloud Visionaries LLC' => 'Cloud Shape Consultant',
    'PopPop Industries' => 'Bubble Wrap Popping Technician',
    'Pillow Perfectionists Ltd.' => 'Pillow Fluffing Engineer',
    'Sprinkle Science Labs' => 'Cupcake Sprinkle Strategist',
    'Snooze Solutions Inc.' => 'Nap Time Coordinator',
    'Ice Dream Innovations' => 'Ice Cream Flavor Tester',
    'Sky Flyers Corp.' => 'Paper Airplane Pilot',
    'ChocoLuxe Enterprises' => 'Chocolate Tasting Executive',
    'SandCastle Kingdoms LLC' => 'Sandcastle Architect',
    'Sharp Point Partners' => 'Pencil Sharpening Officer',
    'Splashy Ventures' => 'Puddle Splashing Expert',
    'Puzzle Detectives Agency' => 'Puzzle Piece Detective',
    'Toybox Treasures Inc.' => 'Toy Unboxing Specialist',
    'Sticker Sticklers Ltd.' => 'Sticker Placement Advisor',
    'Cocoa Stirring Systems' => 'Hot Cocoa Stirrer',
    'Lego Legends Corp.' => 'Lego Tower Supervisor',
    'Wrap It Up LLC' => 'Gift Wrapping Ninja',
    'Kernel Counting Collective' => 'Popcorn Kernel Counter'
};


Map<String, MO_Employment_Conditions__c> employmentConditionsByName = new Map<String, MO_Employment_Conditions__c>();
Map<String, Account> accountsByNames = new Map<String, Account>();
for (String companyName : jobTitleByCompanyName.keySet()) {
    accountsByNames.put(companyName, new Account(Name = companyName, MO_Default_Week_Ending_Day__c = 'Sunday'));
}
insert accountsByNames.values();

List<String> orgDefaults = new List<String>{
    'Button Universe Inc.',
    'Cloud Visionaries LLC'
};

List<MO_Employment_Conditions__c> employmentConditions = new List<MO_Employment_Conditions__c>();
for (Account account : accountsByNames.values()) {
    employmentConditions.add(new MO_Employment_Conditions__c(
        Name = account.Name + ' Condts',
        Account__c = orgDefaults.contains(account.Name) ? null : account.Id,
        Job_Level_Catalogue__c = cataloguesByRecordTypeNames.get('Job Level')?.Id,
        Pay_Element_Catalogue__c = cataloguesByRecordTypeNames.get('Pay Element')?.Id,
        Sub_Level_Catalogue__c = cataloguesByRecordTypeNames.get('Sub Level')?.Id,
        Divisor_Catalogue__c = cataloguesByRecordTypeNames.get('Divisor')?.Id,
        Rate_Integrity_Configuration__c = 'bullhorn__MO_Job_Levels_Pay_Elements_Sub_Levels' 
    ));
}
insert employmentConditions;

for (MO_Employment_Conditions__c ec : employmentConditions) {
    employmentConditionsByName.put(ec.Name, ec);
}

Id consultingJobRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'TR1__Job__c' AND Name = 'Consulting'][0].Id;
List<TR1__Job__c> jobs = new List<TR1__Job__c>();
for (String eCName : employmentConditionsByName.keySet()) {
    String accountName = eCName.remove(' Condts');
    jobs.add(new TR1__Job__c(
        RecordTypeId = consultingJobRecordTypeId,
        MO_Employment_Conditions__c = orgDefaults.contains(accountName) ? null :employmentConditionsByName.get(eCName).Id,
        TR1__Account__c = accountsByNames.get(accountName).Id,
        Name = jobTitleByCompanyName.get(accountName),
        TR1__Contact__c = approver.Id,
        TR1__Hiring_Manager__c = approver.Id,
        TR1__Number_of_Openings__c = 3,
        TR1__Maximum_Pay_Rate__c = 30,
        TR1__Maximum_Bill_Rate__c = 20000,
        TR1__Level__c = 'Staff',
        TR1__Primary_Matching_Requirement__c = 'xx',
        TR1__Estimated_Start_Date__c = Date.today().addDays(-150),
        TR1__Estimated_End_Date__c = Date.today().addDays(150),
        TR1__State__c = 'Illinois',
        TR1__State_Area__c = 'Alabama',
        TR1__Regional_Area__c = 'Anniston-Oxford Metro Area',
        TR1__City__c = 'Chicago'
    ));

}
insert jobs;



List<MO_Employment_Conditions__c> ECs = [SELECT Id, Name FROM MO_Employment_Conditions__c];
List<MO_Rate_Bundle__c> rateBundles = new List<MO_Rate_Bundle__c>();
for (MO_Employment_Conditions__c ec : ECs) {
    String name = ec.Name.replace('Condts', 'Bundle');
    rateBundles.add(new MO_Rate_Bundle__c(
        Name = name,
        Employment_Conditions__c = ec.Id
    ));
}
insert rateBundles;
Integer quantityOfRatesPerBundle = 3;
Integer payRate = 10;
Integer chargeRate = 3;
List<MO_Rate__c> rates = new List<MO_Rate__c>();
Date startDate = Date.today();
Id basicRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Basic_Rate').getRecordTypeId();
Id otherRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Other_Rate').getRecordTypeId();
Id expenseRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Expense_Rate').getRecordTypeId();
Id allowanceRecordTypeId = Schema.SObjectType.MO_Rate__c.getRecordTypeInfosByDeveloperName().get('MO_Allowance_Rate').getRecordTypeId();

Map<Id,bullhorn__MO_Compensation_Type_Set__c> groupByRateBundleId = new Map<Id,bullhorn__MO_Compensation_Type_Set__c>();
for (MO_Rate_Bundle__c rateBundle : rateBundles) {
    groupByRateBundleId.put(
        rateBundle.Id,
        new bullhorn__MO_Compensation_Type_Set__c(
            Name__c = 'Group name',
            Rate_Bundle__c = rateBundle.Id
        )
    );
}
insert groupByRateBundleId.values();

for (MO_Rate_Bundle__c rateBundle : rateBundles) {
    MO_Rate__c otherRate = new MO_Rate__c(
        bullhorn__Time_Categories__c   = 'Overtime',
        RecordTypeId = otherRecordTypeId,
        Start_Date__c = startDate,
        Charge_Rate_Percent__c = 5,
        Pay_Rate__c = payRate,
        Rate_Bundle__c = rateBundle.Id,
        Name__c = 'Other rate'
    );
    MO_Rate__c otherRateGroup = new MO_Rate__c(
        bullhorn__Time_Categories__c   = 'Overtime',
        RecordTypeId = otherRecordTypeId,
        Start_Date__c = startDate,
        Charge_Rate_Percent__c = 5,
        Pay_Rate__c = payRate,
        Rate_Bundle__c = rateBundle.Id,
        Interpretation_Grouping__c = groupByRateBundleId.get(rateBundle.Id).Id,
        Name__c = 'Other rate group'
    );
    MO_Rate__c expenseRate = new MO_Rate__c(
        RecordTypeId = expenseRecordTypeId,
        Start_Date__c = startDate,
        Charge_Rate_Percent__c = 10,
        Pay_Rate__c = payRate,
        Rate_Bundle__c = rateBundle.Id,
        Name__c = 'Expense rate'
    );
    MO_Rate__c allowanceRate = new MO_Rate__c(
        RecordTypeId = allowanceRecordTypeId,
        Start_Date__c = startDate,
        End_Date__c = startDate.addDays(100),
        Charge_Rate__c = payRate + 10,
        Pay_Rate__c = payRate,
        Rate_Bundle__c = rateBundle.Id,
        Name__c = 'Allowance rate 1'
    );
    MO_Rate__c allowanceRateSecond = new MO_Rate__c(
        RecordTypeId = allowanceRecordTypeId,
        Start_Date__c = startDate,
        End_Date__c = startDate.addDays(100),
        Charge_Rate__c = payRate + 11,
        Pay_Rate__c = payRate + 1,
        Rate_Bundle__c = rateBundle.Id,
        Name__c = 'Allowance rate 2'
    );
    for (Integer i = 1; i <= quantityOfRatesPerBundle; i++) {
        MO_Rate__c rate = new MO_Rate__c(
            RecordTypeId = basicRecordTypeId,
            Start_Date__c = startDate,
            End_Date__c = startDate.addMonths(1).toStartOfMonth().addDays(-1),
            Pay_Rate__c = payRate,
            Charge_Rate__c = chargeRate,
            Rate_Bundle__c = rateBundle.Id
        );
        startDate = rate.End_Date__c.addDays(1);
        payRate += 2;
        chargeRate++;
        rates.add(rate);
    }
    otherRate.End_Date__c = startDate.addDays(-1);
    otherRateGroup.End_Date__c = startDate.addDays(-1);
    rates.add(otherRate);
    rates.add(otherRateGroup);
    rates.add(expenseRate);
    rates.add(allowanceRate);
    rates.add(allowanceRateSecond);
    payRate = 10;
}
insert rates;