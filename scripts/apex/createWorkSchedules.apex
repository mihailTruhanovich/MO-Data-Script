Id clockBasedRTId = Schema.SObjectType.MO_Work_Schedule__c.getRecordTypeInfosByDeveloperName()
                                    .get('Clock_Based')
                                    .getRecordTypeId();

MO_Work_Schedule__c monFriSchedule = new MO_Work_Schedule__c(
    RecordTypeId = clockBasedRTId,
    bullhorn__Name__c = 'Mon-Fri Schedule',
    bullhorn__Pattern_Type__c = 'Week-based',
    bullhorn__Week_Ending_Day__c = 'Sunday'
);
MO_Work_Schedule__c monWorkSchedule = new MO_Work_Schedule__c(
    RecordTypeId = clockBasedRTId,
    bullhorn__Name__c = 'Only Mon Schedule',
    bullhorn__Pattern_Type__c = 'Week-based',
    bullhorn__Week_Ending_Day__c = 'Sunday'
);
insert new List<MO_Work_Schedule__c> { monFriSchedule, monWorkSchedule };

List<MO_Work_Schedule_Item__c> wsis = new List<MO_Work_Schedule_Item__c>();

Map<Integer, String> dayByDayNumber = new Map<Integer, String>{
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday',
    7 => 'Sunday'
};

for (Integer i = 1; i < 8; i++) {
    if (i < 6) { // Monday - Friday
        wsis.add(new MO_Work_Schedule_Item__c(
            bullhorn__End_Time__c = Time.newInstance(17, 0, 0, 0),
            // bullhorn__Break_Start__c = Time.newInstance(12, 0, 0, 0),
            // bullhorn__Break_End__c = Time.newInstance(13, 0, 0, 0),
            bullhorn__Order_Number__c = i,
            bullhorn__Start_Time__c = Time.newInstance(8, 0, 0, 0),
            bullhorn__Week_Day__c = dayByDayNumber.get(i),
            bullhorn__Work_Schedule__c = monFriSchedule.Id
        ));
    } else {
        wsis.add(new MO_Work_Schedule_Item__c(
            bullhorn__Order_Number__c = i,
            bullhorn__Week_Day__c = dayByDayNumber.get(i),
            bullhorn__Work_Schedule__c = monFriSchedule.Id
        ));
    }
}

for (Integer i = 1; i < 8; i++) {
    if (i == 1) { // only Monday
        wsis.add(new MO_Work_Schedule_Item__c(
            bullhorn__End_Time__c = Time.newInstance(17, 0, 0, 0),
            // bullhorn__Break_Start__c = Time.newInstance(12, 0, 0, 0),
            // bullhorn__Break_End__c = Time.newInstance(13, 0, 0, 0),
            bullhorn__Order_Number__c = i,
            bullhorn__Start_Time__c = Time.newInstance(8, 0, 0, 0),
            bullhorn__Week_Day__c = dayByDayNumber.get(i),
            bullhorn__Work_Schedule__c = monWorkSchedule.Id
        ));
    } else {
        wsis.add(new MO_Work_Schedule_Item__c(
            bullhorn__Order_Number__c = i,
            bullhorn__Week_Day__c = dayByDayNumber.get(i),
            bullhorn__Work_Schedule__c = monWorkSchedule.Id
        ));
    }
}

insert wsis;

MO_Shift_Type__c shiftType = new MO_Shift_Type__c(
    Name = 'Standard Day',
    Description__c = 'Description',
    Start_Time__c = Time.newInstance(08, 0, 0, 0),
    End_Time__c = Time.newInstance(17, 0, 0, 0)
);
insert shiftType;

MO_Break__c br = new MO_Break__c(
    Shift_Type__c = shiftType.Id,
    Scheduled_Start_Time__c = Time.newInstance(12, 0, 0, 0),
    Start_Time__c = Time.newInstance(12, 0, 0, 0),
    Scheduled_End_Time__c = Time.newInstance(13, 0, 0, 0),
    End_Time__c = Time.newInstance(13, 0, 0, 0)
);
insert br;