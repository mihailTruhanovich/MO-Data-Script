/*
        CreateTestDataHierarchyScript.createTestData(5,10,4,10,1);
*/

public with sharing class CreateTestDataHierarchyScript implements Database.Batchable<SObject> {

    private static final Id BASIC_RATE_RECORDTYPE_ID = Schema.SObjectType.MO_Rate__c
        .getRecordTypeInfosByDeveloperName().get('MO_Basic_Rate').getRecordTypeId();
    private static final Id OTHER_RATE_RECORDTYPE_ID = Schema.SObjectType.MO_Rate__c
        .getRecordTypeInfosByDeveloperName().get('MO_Other_Rate').getRecordTypeId();
    private static final Id CONSULTING_JOB_RECORDTYPE_ID = Schema.SObjectType.TR1__Job__c
        .getRecordTypeInfosByDeveloperName().get('Consulting').getRecordTypeId();
    private static final Id CONSULTING_CLOSING_REPORT_RECORDTYPE_ID = Schema.SObjectType.TR1__Closing_Report__c
        .getRecordTypeInfosByDeveloperName().get('Consulting').getRecordTypeId();
    private static final Date PERIOD_START = Date.newInstance(2024, 12, 15);
    private static final Date PERIOD_END = Date.newInstance(2025, 5, 15);

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT TR1__Account__c, TR1__Job__c, MO_Rate_Bundle__c, TR1__Start_Date__c, TR1__End_Date__c,
                MO_Rate_Integrity_Configuration__c, RecordTypeId, MO_Employee_Contract__c
            FROM TR1__Closing_Report__c
        ]);
    }

    public void execute(Database.BatchableContext context, List<TR1__Closing_Report__c> scope) {
        List<MO_Rate_Bundle__c> rateBundles = [
            SELECT (SELECT Id FROM Rates__r)
            FROM MO_Rate_Bundle__c
            WHERE Id
                IN (
                    SELECT MO_Rate_Bundle__c
                    FROM TR1__Closing_Report__c
                    WHERE Id IN :new Map<Id, TR1__Closing_Report__c>(scope).keySet()
                )
        ];
        Set<String> rateIds = new Set<String>();
        Set<Id> rateBundleIds = new Set<Id>();
        for (MO_Rate_Bundle__c rateBundle : rateBundles) {
            rateBundleIds.add(rateBundle.Id);
            for (MO_Rate__c rate : rateBundle.Rates__r) {
                rateIds.add(rate.Id);
            }
        }
        List<MO_Rate__c> rates = MO_RateSelector.instance.selectWithAllFieldsByIds(rateIds);
        Map<String, Map<Id, MO_Rate__c>> ratesParam = new Map<String, Map<Id, MO_Rate__c>>{
            'create' => new Map<Id, MO_Rate__c>(rates)
        };
        MO_ClosingReportRatesProcessor.instance.importRatesFromRateBundle(
            scope,
            rateBundleIds,
            new Set<Id>(),
            ratesParam
        );
    }

    public void finish(Database.BatchableContext context) {
    }

    private static void runRatesImportOnClosingReports() {
        Database.executeBatch(new CreateTestDataHierarchyScript());
    }

    /**
     * @param hierarchyDepthLevel main Employment Conditions inheritance chain length
     * @param accountsPerEC Number of accounts per each to level Employment Conditions
     * @param accountsHierarchyDepthLevel account hierarchy chain length
     * @param jobsPerAccount Number of jobs per each Account
     * @param closingReportsPerJob Number of Closing Reports per each Job
     *
     * Largest tested params values: (5, 15, 5, 10, 1) - created top-lvl ECs chain with length 5, 37835 rates and
     * 31500 closing report rates. Further increase of parameter values results in STORAGE_LIMIT_EXCEEDED error.
     * It is recommended to use a set of parameters that leads to the creation of a total number
     * of MO_Rate__c and MO_Closing_Report_Rate__c records of no more than 80k.
     */
    public static void createTestData(
        Integer hierarchyDepthLevel,
        Integer accountsPerEC,
        Integer accountsHierarchyDepthLevel,
        Integer jobsPerAccount,
        Integer closingReportsPerJob
    ) {
        System.enqueueJob(new HierarchyDataFacility(
            null, hierarchyDepthLevel, accountsPerEC, accountsHierarchyDepthLevel, jobsPerAccount, closingReportsPerJob
        ));
    }

    private class HierarchyDataFacility implements Queueable {
        private final MO_Employment_Conditions__c parentEmploymentConditions;
        private final Integer hierarchyDepthLevel;
        private final Integer accountsPerEC;
        private final Integer accountsHierarchyDepthLevel;
        private final Integer jobsPerAccount;
        private final Integer closingReportsPerJob;

        public HierarchyDataFacility(
            MO_Employment_Conditions__c parentEmploymentConditions,
            Integer hierarchyDepthLevel,
            Integer accountsPerEC,
            Integer accountsHierarchyDepthLevel,
            Integer jobsPerAccount,
            Integer closingReportsPerJob
        ) {
            this.parentEmploymentConditions = parentEmploymentConditions;
            this.hierarchyDepthLevel = hierarchyDepthLevel;
            this.accountsPerEC = accountsPerEC;
            this.accountsHierarchyDepthLevel = accountsHierarchyDepthLevel;
            this.jobsPerAccount = jobsPerAccount;
            this.closingReportsPerJob = closingReportsPerJob;
        }

        public void execute(QueueableContext context) {
            MO_Employment_Conditions__c topLevelConditions = createTopLevelConditions();

            List<Account> accounts = new List<Account>();
            List<MO_Employment_Conditions__c> employmentConditions = new List<MO_Employment_Conditions__c>();
            for (Integer i = 0; i < accountsPerEC; i++) {
                Account account = new Account(
                    Name = String.format('{0} {1}', new List<Object>{
                        topLevelConditions.Name.replace(' ch', '').replaceAll(' gr',''),
                        MO_GenericUtils.generateRandomString(5)
                    })
                );
                accounts.add(account);
            }
            insert accounts;
            for (Account account : accounts) {
                String ecName = account.Name + ' Conditions';
                MO_Employment_Conditions__c accEmploymentConditions = buildEmploymentConditions(ecName, topLevelConditions.Id);
                accEmploymentConditions.Account__c = account.Id;
                employmentConditions.add(accEmploymentConditions);
            }
            insert employmentConditions;
            employmentConditions = createAccountHierarchy(accounts, employmentConditions, accountsHierarchyDepthLevel);
            List<MO_Contract__c> contracts = new List<MO_Contract__c>();
            List<MO_Rate_Bundle__c> accountRateBundles = [
                SELECT Id
                FROM MO_Rate_Bundle__c
                WHERE Employment_Conditions__c
                    IN :new Map<Id, MO_Employment_Conditions__c>(employmentConditions).keySet()
            ];
            for (MO_Rate_Bundle__c rateBundle : accountRateBundles) {
                contracts.add(new MO_Contract__c(
                    State__c = 'Approved',
                    DateStart__c = PERIOD_START,
                    Rate_Bundle__c = rateBundle.Id
                ));
            }
            insert contracts;
            List<MO_Contract_Version__c> contractVersions = new List<MO_Contract_Version__c>();
            for (MO_Contract__c contract : contracts) {
                contractVersions.add(new MO_Contract_Version__c(
                    DateStart__c = contract.DateStart__c,
                    HR_Contract__c = contract.Id
                ));
            }
            insert contractVersions;
            Boolean isLastChainLink = hierarchyDepthLevel == 1;
            createCurrentLevelJobs(
                new Map<Id, MO_Employment_Conditions__c>(employmentConditions).keySet(),
                jobsPerAccount,
                closingReportsPerJob,
                isLastChainLink
            );

            if (hierarchyDepthLevel > 1) {
                System.enqueueJob(new HierarchyDataFacility(
                    topLevelConditions,
                    hierarchyDepthLevel - 1,
                    accountsPerEC,
                    accountsHierarchyDepthLevel,
                    jobsPerAccount,
                    closingReportsPerJob
                ));
            }
        }

        private MO_Employment_Conditions__c createTopLevelConditions() {
            MO_Employment_Conditions__c topLevelEC;
            if (parentEmploymentConditions == null) {
                topLevelEC = buildEmploymentConditions(
                    MO_GenericUtils.generateRandomString(7), null
                );
                insert topLevelEC;
                MO_Rate_Bundle__c topLevelRateBundle = new  MO_Rate_Bundle__c(
                    Name = topLevelEC.Name + ' Bundle',
                    Employment_Conditions__c = topLevelEC.Id
                );
                insert topLevelRateBundle;
                List<MO_Rate__c> rates = new List<MO_Rate__c>();
                rates.addAll(buildRatesForGivenPeriod(PERIOD_START, PERIOD_END, BASIC_RATE_RECORDTYPE_ID));
                rates.addAll(buildRatesForGivenPeriod(PERIOD_START, PERIOD_END, OTHER_RATE_RECORDTYPE_ID));
                for (MO_Rate__c rate : rates) {
                    rate.Rate_Bundle__c = topLevelRateBundle.Id;
                }
                insert rates;
            } else {
                String parentECName = parentEmploymentConditions.Name;
                String childName = parentECName.contains('ch') ? parentECName.replace('ch', 'gr ch') : parentECName + ' ch';
                topLevelEC = buildEmploymentConditions(childName, parentEmploymentConditions.Id);
                insert topLevelEC;
            }
            return topLevelEC;
        }
    }

    @Future
    private static void createCurrentLevelJobs(
        Set<Id> employmentConditionsIds, Integer jobsPerAccount, Integer closingReportsPerJob, Boolean isLastChainLink
    ) {
        List<TR1__Job__c> jobs = new List<TR1__Job__c>();
        for (Id employmentConditionsId : employmentConditionsIds) {
            for (Integer i = 0; i < jobsPerAccount; i++) {
                TR1__Job__c job = new TR1__Job__c(
                    Name = employmentConditionsId + ' Job ' + i,
                    TR1__Job_Title__c = employmentConditionsId + ' Job ' + i,
                    RecordTypeId = CONSULTING_JOB_RECORDTYPE_ID,
                    MO_Employment_Conditions__c = employmentConditionsId
                );
                jobs.add(job);
            }
        }
        insert jobs;
        System.enqueueJob(new ClosingReportDataFacility(new Map<Id, TR1__Job__c>(jobs).keySet(), closingReportsPerJob, isLastChainLink));
    }

    private class ClosingReportDataFacility implements Queueable {
        private final Set<Id> currentChunkJobIds;
        private final Integer closingReportsPerJob;
        private final Boolean isLastChainLink;

        private ClosingReportDataFacility(Set<Id> currentChunkJobIds, Integer closingReportsPerJob, Boolean isLastChainLink) {
            this.currentChunkJobIds = currentChunkJobIds;
            this.closingReportsPerJob = closingReportsPerJob;
            this.isLastChainLink = isLastChainLink;
        }

        public void execute(QueueableContext context) {
            List<TR1__Closing_Report__c> closingReports = new List<TR1__Closing_Report__c>();
            List<TR1__Job__c> jobs = [SELECT TR1__Account__c FROM TR1__Job__c WHERE Id IN :currentChunkJobIds];
            List<MO_Rate_Bundle__c> rateBundles = [
                SELECT Job__c, (SELECT Id FROM Rates__r)
                FROM MO_Rate_Bundle__c
                WHERE Job__c IN :currentChunkJobIds
            ];
            Map<Id, Id> rateBundleIdByTheirJobIds = new Map<Id, Id>();
            List<MO_Rate__c> rateBundlesRates = new List<MO_Rate__c>();
            for (MO_Rate_Bundle__c rateBundle : rateBundles) {
                rateBundleIdByTheirJobIds.put(rateBundle.Job__c, rateBundle.Id);
                rateBundlesRates.addAll(rateBundle.Rates__r);
            }
            for (TR1__Job__c job : jobs) {
                for (Integer i = 0; i < closingReportsPerJob; i++) {
                    TR1__Closing_Report__c closingReport = new TR1__Closing_Report__c(
                        TR1__Account__c = job.TR1__Account__c,
                        TR1__Job__c = job.Id,
                        MO_Rate_Bundle__c = rateBundleIdByTheirJobIds.get(job.Id),
                        TR1__Start_Date__c = PERIOD_START,
                        TR1__End_Date__c = PERIOD_END,
                        MO_Rate_Integrity_Configuration__c = 'bullhorn__MO_Job_Levels_And_Pay_Elements',
                        RecordTypeId = CONSULTING_CLOSING_REPORT_RECORDTYPE_ID
                    );
                    closingReports.add(closingReport);
                }
            }
            insert closingReports;
            if (isLastChainLink) {
                runRatesImportOnClosingReports();
            }
        }
    }

    private static MO_Employment_Conditions__c buildEmploymentConditions(String childName, Id parentECId) {
        return new MO_Employment_Conditions__c(
            Name = childName,
            Parent__c = parentECId,
            Payment_Term__c = 100
        );
    }

    private static List<MO_Rate__c> buildRatesForGivenPeriod(Date start, Date endDate, Id recordTypeId) {
        List<MO_Rate__c> rates = new List<MO_Rate__c>();
        if (recordTypeId == OTHER_RATE_RECORDTYPE_ID) {
            MO_Rate__c otherRate = makeRate(start, endDate, null, recordTypeId);
            otherRate.Pay_Rate_Percent__c = 7;
            otherRate.Name__c = 'Other rate';
            rates.add(otherRate);
        } else {
            Decimal initialPayRate = 10;
            buildAndCollectNextRate(rates, start, endDate, initialPayRate, recordTypeId);
        }
        return rates;
    }

    private static List<MO_Employment_Conditions__c> createAccountHierarchy(
        List<Account> parentAccs, List<MO_Employment_Conditions__c> employmentConditions, Integer accountsHierarchyDepthLevel
    ) {
        List<MO_Employment_Conditions__c> allEmploymentConditions = new List<MO_Employment_Conditions__c>(employmentConditions);
        for (Integer i = 0; i < accountsHierarchyDepthLevel; i++) {
            Map<Id, Id> ecIdByAccountId = new Map<Id, Id>();
            for (MO_Employment_Conditions__c ec : employmentConditions) {
                ecIdByAccountId.put(ec.Account__c, ec.Id);
            }List<Account> childAccounts = new List<Account>();
            List<MO_Employment_Conditions__c> employmentConditionsList = new List<MO_Employment_Conditions__c>();
            for (Account parentAccount : parentAccs) {
                String childName = parentAccount.Name.contains(' ch') ? parentAccount.Name.replace('ch', 'gr ch') : parentAccount.Name + ' ch';
                childAccounts.add(new Account(
                    Name = childName,
                    ParentId = parentAccount.Id
                ));
            }
            insert childAccounts;
            for (Account account : childAccounts) {
                String ecName = account.Name + ' Conditions';
                MO_Employment_Conditions__c accEmploymentConditions = buildEmploymentConditions(ecName, ecIdByAccountId.get(account.ParentId));
                accEmploymentConditions.Account__c = account.Id;
                employmentConditionsList.add(accEmploymentConditions);
            }
            insert employmentConditionsList;
            allEmploymentConditions.addAll(employmentConditionsList);
            employmentConditions = employmentConditionsList;
            parentAccs = childAccounts;
        }
        return allEmploymentConditions;
    }

    private static void buildAndCollectNextRate(
        List<MO_Rate__c> rates,
        Date start,
        Date endDate,
        Decimal payRate,
        Id recordTypeId
    ) {
        if (start > endDate) {
            return;
        }
        Date intervalEnd = start.toStartOfMonth().addMonths(1).addDays(-1);
        if (intervalEnd > endDate) {
            intervalEnd = endDate;
        }
        rates.add(makeRate(start, intervalEnd, payRate, recordTypeId));
        buildAndCollectNextRate(rates, intervalEnd.addDays(1), endDate, payRate + 5, recordTypeId);
    }

    private static MO_Rate__c makeRate(Date startDate, Date endDate, Decimal payRate, Id recordTypeId) {
        return new MO_Rate__c(
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Pay_Rate__c = payRate,
            RecordTypeId = recordTypeId
        );
    }
}