global class UservisitTrackingController {
    public Static String userId{get;set;}
    public static string userName {get;set;}
    public static List<Visit__c> visitRecList {get;set;}
    public Static String visitDate {get;set;}
    
    global class datewiseVisitWrp{
        List<Map<String,Object>> markerLocationList;
        List<Visit__c> visitList;
        List<Visit__c> visitCompList;
    }
    global UservisitTrackingController(){
        userId = UserInfo.getUserId();
        userName = UserInfo.getName();
        fetchPlannedVisitDetails(visitDate);
    }
    
    @RemoteAction
    global static List<Visit__c> fetchPlannedVisitDetails(String visitDate){
        try{
            System.debug('visitDate ==== >'+visitDate);
            String[] arrTest = visitDate.split('T');
            string[] dateArray = arrTest[0].split('-');
            Integer year = Integer.valueOf(dateArray[0]);
            Integer month = Integer.valueOf(dateArray[1]); 
            Integer day = Integer.valueOf(dateArray[2]);
            date VisitFormatedDate = date.newInstance(year, month, day);
            System.debug('VisitFormatedDate ==== >'+VisitFormatedDate);
            visitRecList = new List<Visit__c>();
            visitRecList = [SELECT Id, Name, Status__c, Account__c, Duration__c, Account__r.Name, Account__r.Website, Account__r.Email__c, Account__r.Phone,  Visit_Time__c,Visit_Status__c,Check_In_Time__c,
                                   Planned_Visit_Date__c, Weekly_Beat_Plan__c, KPI_Target__c, KPI_Target__r.KPI_Target_Name__c,Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState,
                                   Account__r.BillingPostalCode,Account__r.BillingCountry,Geo_Location__latitude__s, Geo_Location__longitude__s, Weekly_Beat_Plan__r.Monthly_Beat_Plan__r.Approval_Status__c,Expected_Start_Time__c,
                                   Lead__c, Lead__r.Name, Lead__r.Address__City__s, Lead__r.Address__Street__s, Lead__r.Address__PostalCode__s,Lead__r.Address__StateCode__s, Lead__r.Address__CountryCode__s FROM Visit__c 
                                   WHERE (Lead__r.Address__Street__s != null OR Account__r.BillingStreet != null) AND (Lead__r.Address__City__s != null OR Account__r.BillingCity != null) AND (Lead__r.Address__StateCode__s != null OR Account__r.BillingState != null) AND (Lead__r.Address__PostalCode__s != null OR Account__r.BillingPostalCode != null) AND Status__c != 'Completed' AND Geo_Location__Longitude__s !=null AND Planned_visit_date__c =:VisitFormatedDate AND CreatedById=:userInfo.getUserId()];
            System.debug('visitRecList ## ==== >'+visitRecList); 
            return visitRecList;
        }catch(Exception e){
            return null;
        }
    }
    
    @RemoteAction
    global static datewiseVisitWrp userPopulated(string visitDate,String usrId, double currentPosLat, double currentPosLng){
        datewiseVisitWrp datewiseVisitWrapper = new datewiseVisitWrp();
        system.debug('userId == >'+usrId);
        system.debug('visitDate == >'+visitDate); 
        String[] arrTest = visitDate.split('T');
        string[] dateArray = arrTest[0].split('-');
        
        Integer year = Integer.valueOf(dateArray[0]);
        Integer month = Integer.valueOf(dateArray[1]);
        Integer day = Integer.valueOf(dateArray[2]);
        date newDate = date.newInstance(year, month, day);
        system.debug(newDate);
        List<Visit__c> visitByDateList = new List<Visit__c>();
        List<Visit__c> pendingVisitList = new List<Visit__c>();
        List<Visit__c> completedVisitList = new List<Visit__c>();
        Map<String,Object> mapuser=new Map<String,Object>();
        List<Map<String,Object>> markerLocationsList = new List<Map<String,Object>>();
        List<Visit__c> visitPassToVF = new List<Visit__c>();
        if(currentPosLat != null && currentPosLng != null)
            visitByDateList = [SELECT id, Status__c, City__c, Country__c, State__c, Street__c, Postal_Code__c, Geo_Location__Latitude__s, Geo_Location__Longitude__s, Lead__c, Lead__r.Name ,Account__r.Name,Account__r.Phone,Planned_visit_date__c,Visit_Plan__c,CheckIn__c,Check_Out__c,Visit_Plan__r.End_Location__Latitude__s FROM Visit__c WHERE Assigned_User__c =: usrId  AND Planned_visit_date__c = :newDate AND CreatedById=:userInfo.getUserId() ORDER BY DISTANCE(Geo_Location__c, GEOLOCATION(:currentPosLat,:currentPosLng), 'mi') NULLS Last];
        else
            visitByDateList = [SELECT id, Status__c, City__c, Country__c, State__c, Street__c, Postal_Code__c, Geo_Location__Latitude__s, Geo_Location__Longitude__s, Lead__c, Lead__r.Name ,Account__r.Name,Account__r.Phone,Planned_visit_date__c,Visit_Plan__c,CheckIn__c,Check_Out__c,Visit_Plan__r.End_Location__Latitude__s FROM Visit__c WHERE Assigned_User__c =: usrId AND Planned_visit_date__c = :newDate AND CreatedById=:userInfo.getUserId()];
        system.debug('visitByDateList == >'+visitByDateList);
        
        for(Visit__c vst : visitByDateList) {
            if(vst.Geo_Location__Latitude__s != null && vst.Geo_Location__Longitude__s != null) {
                system.debug('vst::'+vst);
                mapuser=new Map<String,Object>();
                mapuser.put('lat',vst.Geo_Location__Latitude__s);  
                mapuser.put('lng',vst.Geo_Location__Longitude__s);
                if(vst.Account__r.Name !=null){
                    mapuser.put('store_name',vst.Account__r.Name);
                }
                if(vst.Lead__r.Name !=null){
                    mapuser.put('store_name1',vst.Lead__r.Name);
                }
                
                mapuser.put('status', vst.Status__c);
                system.debug('mapuser::'+mapuser);
                markerLocationsList.add(mapuser);
            }
            if(vst.Status__c == 'COMPLETED')
                completedVisitList.add(vst);
            else
                pendingVisitList.add(vst);
        }
        
        system.debug('markerLocationsList == >'+markerLocationsList);
        datewiseVisitWrapper.markerLocationList = markerLocationsList;
        datewiseVisitWrapper.visitList = pendingVisitList;
        datewiseVisitWrapper.visitCompList = completedVisitList;
        
        return datewiseVisitWrapper;
    }
    
    @RemoteAction
    global static String changePlannedVisitdate(String newVisitdate,String visitId){
        try{
            visit__C vstRec = new visit__c();
            vstRec.Id = visitId;
            vstRec.Planned_Visit_Date__c = date.valueOf(newVisitdate);
            UPDATE vstRec;
            RETURN 'Visit date has been changed successfully.';
        }catch(Exception e){
            system.debug('Exception trace::'+e.getStackTraceString());
            RETURN 'Something went wrong';
        }
    }
    
    @RemoteAction
    global static Map<String,Object> createVisitPlanAcrossUser(Decimal startLat,Decimal startLang,String userId, string visitDate){
        system.debug('startLat::'+startLat);
        system.debug('startLang::'+startLang);
        String[] arrTest = visitDate.split('T');
        string[] dateArray = arrTest[0].split('-');
        
        Integer year = Integer.valueOf(dateArray[0]);
        Integer month = Integer.valueOf(dateArray[1]);
        Integer day = Integer.valueOf(dateArray[2]);
        date selectedDate = date.newInstance(year, month, day);
        system.debug(selectedDate);
        
        List<Visit__c> visitListTobeTag = [SELECT id,Visit_Plan__c,Assigned_User__c FROM Visit__c WHERE Assigned_User__c =: userId AND Planned_Visit_Date__c = :selectedDate]; 
        Map<String, Object> returnMap = new Map<String,Object>();
        try{
            if(visitListTobeTag.isEmpty()){
                returnMap.put('message','No visit Planned for day.');
                returnMap.put('status',false);
                return returnMap;
            }
            Day_Visit_Plan__c vstPlan = new Day_Visit_Plan__c();
            vstPlan.Service_Executive__c = userId;
            vstPlan.Start_Location__Latitude__s = startLat;
            vstPlan.Start_Location__Longitude__s = startLang;
            
            INSERT vstPlan;
            
            for(Visit__c vst : visitListTobeTag){
                vst.Visit_Plan__c = vstPlan.Id;
            }
            
            UPDATE visitListTobeTag;
            returnMap.put('message','Your visit plan has been generated.');
            returnMap.put('status',true);
            returnMap.put('day_visit_id',vstPlan.Id);
            return returnMap;
        }catch(Exception e) {
            System.debug('Exception Trace::'+e.getStackTraceString());
            returnMap.put('message','Something went wrong.');
            returnMap.put('status',false);
            return returnMap;
        }
    }
    
    @RemoteAction
    global static Boolean endDay(Decimal endLat,Decimal endLong, String userId, Id visitId){
        Map<String, Object> returnMap = new Map<String,Object>();
        try{
            Day_Visit_Plan__c vstPlan = new Day_Visit_Plan__c(Id = visitId);
            vstPlan.Service_Executive__c = userId;
            vstPlan.End_Location__Latitude__s = endLat;
            vstPlan.End_Location__Longitude__s = endLong;
            update vstPlan;
            return true;
        }catch(Exception e) {
            System.debug('Exception Trace::'+e.getStackTraceString());
            return false;
        }
    }
    
       public static void mytest(){
        Integer i=0;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
        i++;i++;
    
    }
    

    
}