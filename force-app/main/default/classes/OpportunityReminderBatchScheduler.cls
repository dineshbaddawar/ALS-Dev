global class OpportunityReminderBatchScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        OpportunityReminderBatchClass batch = new OpportunityReminderBatchClass();
        Database.executeBatch(batch);
    }
}