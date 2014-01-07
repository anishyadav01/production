/**
    This class acts as the step monitor.
    It looks at all the tasks that are due to be executed and move to next step
*/

public with sharing class CollectionStepUpdateBatch implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext scMain) {
        CollectionStepUpdateBatch batch = new CollectionStepUpdateBatch();
        Database.executeBatch(batch, 200);
    }

   public CollectionStepUpdateBatch(){}

   public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }


    // execute method will get the current step and based on the step selected ... 
    // it will update the account with next step 
   public void execute(Database.BatchableContext BC, List<sObject> collectionAccounts){
    
    List<CollectionAccountInfo> colAccounts = new List<CollectionAccountInfo>();    
        
    
      
        // actual processing
        for ( sObject actSObject : collectionAccounts ){
            Billing_Account__c act = ( Billing_Account__c )actSObject;
        
            if( act != null && act.Current_Treatment_Path__c != null && act.Current_Treatment_Step__c != null ){
                colAccounts.add ( new CollectionAccountInfo( act ) );
            }
        }
        
    StepHandler.moveStepsInBulk ( colAccounts );        
   }

   public void finish(Database.BatchableContext BC){
    //some logic will come here
   }
   
   
    private String query{
        get{
            return ' Select b.Step_Communication_Type__c, b.Reinstate_Flag__c, b.Promise_to_Pay__c, b.Payment_Defaulted__c, b.Payment_Defaulted_Date__c, '+
                            ' b.Collection_Paused__c, b.Next_Treatment_Step__c, b.In_Collections__c, b.Current_Treatment_Step__c, b.Current_Treatment_Path__c, b.Action_Date__c ' +
                            ' From Billing_Account__c b '+ 
                    ' Where b.Action_Date__c <= TODAY ';
        }
    }

}