public with sharing class CaseGetNextController 
{
    private ApexPages.StandardSetController standardSetController;
    
    public PageReference result {get; set;}
    
    public Boolean authorisedProfile { get; set; }
    
    private id caseId;
    
    public CaseGetNextController(ApexPages.StandardSetController standardSetController) 
    { 
        this.standardSetController = standardSetController;
    }
    
     public CaseGetNextController(ApexPages.StandardController controller) {
        caseId = ApexPages.CurrentPage().getParameters().get('id');
    }

    
    public PageReference onLoad()
    {
        authorisedProfile = checkProfileAuthorisation();
        Case case0;
        Id ownerId;
        
        if(authorisedProfile){
        
            result = null;
            //invoked from List View Button
            if (standardSetController != null && standardSetController.getRecords() != null && !standardSetController.getRecords().isEmpty()){
                case0 = (Case)standardSetController.getRecords()[0];
                case0 = [Select Id, OwnerId from Case where Id = :case0.Id];
                ownerId = case0.ownerId;
             } //invoked from Detail Button
             else if(caseId != null){
                 case0 = [Select Id, Previous_OwnerId__c from Case where Id = :caseId];
                 ownerId = case0.Previous_OwnerId__c;
             }
            
            Case nextCase;
            if (ownerId != null && ownerId.getSObjectType() != User.sObjectType){
            try{
                    nextCase = fetchNextCase(ownerId);
                
            
                    result = new PageReference('/' + nextCase.Id); 
                
                }
                catch(System.DMLException dmlEx){ // If you attempt to update a record currently locked by another client
                    System.debug(LoggingLevel.ERROR, 'DMLException ' + dmlEx);
                    try{
                        nextCase = fetchNextCase(ownerId);
                    }catch(Exception ex){System.debug(LoggingLevel.ERROR, 'Exception Inner ' + ex);
                        nextCase = null;
                    }
                    result = null;
                    
                }
                catch(System.QueryException qEx){ //If you attempt to lock a record currently locked by another client
                     System.debug(LoggingLevel.ERROR, 'QueryException ' + qEx);
                     try{
                        nextCase = fetchNextCase(ownerId);
                    }catch(Exception ex){System.debug(LoggingLevel.ERROR, 'Exception Inner ' + ex);
                        nextCase = null;
                    }
                    result = null;
                }
             }
        }
        
        
        return result;
            
    }
    
    private Case fetchNextCase(String ownerId){
        
        Case oldestCase = [Select Id from Case where OwnerId = :ownerId And IsClosed = FALSE Order By CreatedDate ASC LIMIT 1];
                
        oldestCase = [Select Id, OwnerId from Case where Id = :oldestCase.Id FOR UPDATE];
                
        if(oldestCase.OwnerId != UserInfo.getUserId()){
        //Only Set Previous Owner if it is a Queue
            if(oldestCase.OwnerId.getSObjectType() != User.sObjectType)
                oldestCase.Previous_OwnerId__c = oldestCase.OwnerId;
                    
                oldestCase.OwnerId = UserInfo.getUserId();
                    
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = false;
                oldestCase.setOptions(dmo);
                    
                update oldestCase;
         }
         
         return oldestCase;
    
    }
    
    private Boolean checkProfileAuthorisation(){
    
        Id profileId = [Select Id, ProfileId from User where Id = :UserInfo.getUserId()].ProfileId;
        
        Set<String> authorisedProfiles = new Set<String>();
        
        authorisedProfiles.addAll(parseCustomSetting(Radian6_Case_Config__c.getInstance().Radian_6_Profiles__c));
        
        return authorisedProfiles.contains(profileId);
    }
    
    private List<String> parseCustomSetting(String values){
        List<String> tokens;
        System.debug('*** parseCustomSetting ' + values);
        if(values != null && values.indexOf(',') > 0)
            tokens = values.split(',');
        else
            tokens = new List<String>{values};
        
        return tokens;
    }
}