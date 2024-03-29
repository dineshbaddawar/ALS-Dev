public class Scheduler_Insight_MonthYear_handler {
    
    @AuraEnabled
    public static MBPandApproverWrapper getMonthBeatPlan(String month,string year){
        String ApproverName;
         System.debug('month ==>'+month +' && year == >'+year);
        Monthly_Beat_Plan__c getAllMBPList = [Select Id,Name,Sales_User__c,Sales_User__r.Name,Sales_User__r.Manager.Name,CreatedDate,Month__c,Month_Name__c,Year__c,Status__c From Monthly_Beat_Plan__c Where Sales_User__c =: userInfo.getUserId() AND Year__c=:year AND Month_Name__c=:month LIMIT 1];
         System.debug('getAllMBPList ==>'+getAllMBPList);
        if(getAllMBPList.Status__c == 'Approved'){
         //   ProcessInstanceStep piStep = [SELECT Actor.Name FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId =: getAllMBPList.Id ORDER BY CreatedDate DESC LIMIT 1];
         //   ApproverName = piStep.Actor.Name;
          //  System.debug('inside Approved Block and Approver Name ==>'+ApproverName);
        }
        System.debug('getAllMBPList ==>'+getAllMBPList.Sales_User__r.Name);
        System.debug('getAllMBPList ==>'+getAllMBPList);
        System.debug('ApproverName ==>'+ApproverName);
        MBPandApproverWrapper wrapper = new MBPandApproverWrapper();
        wrapper.approverName = ApproverName;
        wrapper.MBPrec = getAllMBPList;
        System.debug('wrapper==> ' + wrapper);
        return wrapper;
    }
    
    @AuraEnabled
    Public static List<Day_Visit_Plan__c> getMonthlyRecord(String month,string year){
        System.debug('month-->'+month);
        System.debug('year-->'+year);
        List<Day_Visit_Plan__c> getAllDayVisitPlanRecList = [Select Id,Start_Date__c,End_Date__c,Total_Distance__c, Total_Covered_Distance__c,CreatedDate From Day_Visit_Plan__c where Service_Executive__c =: userInfo.getUserId() AND Year__c=:year AND Month__c=:month ORDER BY Start_Date__c DESC];
        //List<Day_Visit_Plan__c> getAllDayVisitPlanRecList = [Select Id,Start_Date__c,End_Date__c,Total_Distance__c, Total_Covered_Distance__c,CreatedDate From Day_Visit_Plan__c where Service_Executive__c =: userInfo.getUserId()];
        System.debug('getAllDayVisitPlanRecList-->'+getAllDayVisitPlanRecList);
        return getAllDayVisitPlanRecList;
    }
    
    @AuraEnabled
    Public static Id saveFilesUnderMTE(String month,string year){
        Id currentUserId = UserInfo.getUserId();
        Integer yearNumber = system.today().Year();
        System.debug('yearNumber before ==> ' + yearNumber);
        if(year!= null && year != ''){
            yearNumber = Integer.valueOf(year);
        }
        System.debug('yearNumber after ==> ' + yearNumber);
        List<Monthly_Travel_Expense__c> mteRec = new List<Monthly_Travel_Expense__c>();
           mteRec = [SELECT Id, Name FROM Monthly_Travel_Expense__c WHERE Month_Name__c =: month AND CALENDAR_YEAR(Start_Date__c)=:yearNumber AND Sales_User__c =: currentUserId LIMIT 1];
        System.debug('Monthly_Travel_Expense__c records ==> '+mteRec);
        if(!mteRec.isEmpty()){
            return mteRec[0].id;
        }
        return null;
    }
    
    public class MBPandApproverWrapper {
        @AuraEnabled
        public String approverName;
        @AuraEnabled
        public Monthly_Beat_Plan__c MBPrec;
        
    }
    
}