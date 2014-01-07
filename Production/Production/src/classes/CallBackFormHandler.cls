public class CallBackFormHandler{
    public set<String> CallBackSet;
    public List<Case> CallBackCaseList;
    public Map<String,Case> CaseNumberCaseMap;
    
    //constructor 
    public CallBackFormHandler(){
        CallBackSet = new Set<String>();
        CaseNumberCaseMap =  new map<String,Case>();
    }
    
    public void handleCBFBeforeInsert(List<CallBack_Form__c> triggerNew){       
        // Prepare Set of Case Numbers to retrieve Cases
        for (CallBack_Form__c cf : triggerNew){
            CallBackSet.add(cf.Case_Number__c);    
        }
        
        //Retrieve Cases linked with the submitted Call Back Form
        CallBackCaseList = [select CaseNumber,id,Status from Case where CaseNumber in :CallBackSet ];
        
        for(Case c : CallBackCaseList){
            //Update Case Status to Customer Responded if Case status is not Closed.
            if(c.Status!=Constants.CaseStatus_Closed)
                c.Status = Constants.CaseStatus_CustomerResponded;
            
            //Prepare Map of Case Number and Case
            CaseNumberCaseMap.put(c.CaseNumber, c);
            
        }
            
        for(CallBack_Form__c cf : triggerNew){
            //Get Case based on the Case Number
            if(CaseNumberCaseMap.containsKey(cf.Case_Number__c)){
                 Case c = CaseNumberCaseMap.get(cf.Case_Number__c);
                 
                 //Update Case Id on Call Back Form
                 cf.Case__c = c.id; 
                 
                 //Validate if Case status is Closed then throw error.
                 if(c.Status ==  Constants.CaseStatus_Closed)
                     cf.addError('Case already closed, can\'t request for Call Back.');   
            }
            else 
                cf.addError('Invalid Case Number');     //If Case number not found then throw error.
        
        } 
        // Apply updates to Cases. 
        update CallBackCaseList; 

    }
    

}