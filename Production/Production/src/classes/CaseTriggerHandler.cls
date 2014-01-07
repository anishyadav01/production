public class CaseTriggerHandler {
    
     
     public static void handleAfterInsert(Map<Id, Case> newCasesMap) {
        
        Set<Id> newKeys = newCasesMap.keySet();
        
        List<Case> newCasesExtended = database.query('select Li_Community_User__r.Contact__r.Id, ' + 
                                                            SObjectHelper.getFieldListForSOQL('Case') + 
                                                        ' from Case where id IN :newKeys');  
        
        
        Set<String> cliList = new Set<String>();
        Map<Id, Case> billingAccountCasesMap = new Map<Id, Case>();
        
        for (Case c : newCasesExtended) {
            if (c.Record_Type_Name__c == Constants.CaseRecordType_Lithium) {
                cliList.add(c.Phone_Number__c);
            } else if  (c.Record_Type_Name__c == Constants.CaseRecordType_Collection) {
            	billingAccountCasesMap.put (c.Billing_Account__c, c);
            }
        }
        
        //Associate Lithium Case and Community User to existing Contact if applicable, by mapping the Case.CLI to Asset.CLI
        associateLithiumCaseAndCommunityUserToContact(cliList, newCasesExtended);
        
        createTasksForCases(billingAccountCasesMap);
     }
     
     public static void handleBeforeInsert(List<Case> newCases) {
       
            Set<String> communityUserSet = new Set<String>();
            Map<id,String> communityUserPhoneMap = new Map<id,String>();
            
            //Get all community users associated with the Case(s) beging inserted.
            for(Case c : newCases){
             if (c.Record_Type_Name__c == Constants.CaseRecordType_Lithium) 
               communityUserSet.add(c.Li_Community_User__c); 
            }
            
            //Create a map of Community User and Phone Number
            if(!communityUserSet.isEmpty()){ 
                for (Li_Community_User__c cu : [select id,Phone_Number__c from Li_Community_User__c where id in :communityUserSet])
                   communityUserPhoneMap.put(cu.id,cu.Phone_Number__c); 
            }
            
            //Assign value of Phone Number to CLI.
            for (Case c : newCases){
                if (c.Record_Type_Name__c == Constants.CaseRecordType_Lithium) 
                    if(communityUserPhoneMap.containsKey(c.Li_Community_User__c))
                        c.Phone_Number__c = communityUserPhoneMap.get(c.Li_Community_User__c);
                
            }    
       
        
     }
     
     public static void handleBeforeUpdate(Map<Id, Case> oldCasesMap, Map<Id, Case> newCasesMap) {
                
        //if Status set to Resolved for first time, populate the 'First Response' field for Social Media & Lithium Cases
        for (Case c: newCasesMap.values()) {
            if ((c.Record_Type_Name__c == Constants.CaseRecordType_SocialMedia || c.Record_Type_Name__c == Constants.CaseRecordType_Lithium) &&
                 c.Status == Constants.CaseStatus_Resolved && oldCasesMap.get(c.Id).Status != Constants.CaseStatus_Resolved && c.First_Response__c == null) {
                    
                c.First_Response__c = DateTime.now();
                system.debug('***** Case being resolved for the 1st time found');
            }
        }
     }
     
     /*
      * Associate Case and Community User to an Existing Contact based on Asset.CLI (-Billing Account-Primary Contact) => Case.CLI maaping
      */
     public static void associateLithiumCaseAndCommunityUserToContact(Set<String> cliList, List<Case> newCases) {
        
        List<SObject> objectsToLink = new List<SObject>();
        
        List<Asset> relatedAssets = [select Id, CLI__c, Billing_Account__r.Primary_Contact__r.Id from Asset where CLI__c in :cliList and Active__c = true];
         
        Map<String, Id> contactsByCLIMap = new Map<String, Id>();
        
        //Assumes that CLI numbers are unique per active Asset
        for (Asset a : relatedAssets) {
            if (!contactsByCLIMap.containsKey(a.CLI__c) && a.Billing_Account__c != null) {
                contactsByCLIMap.put(a.CLI__c, a.Billing_Account__r.Primary_Contact__c);
            }
        }
        
        for (Case c : newCases) {
            if (c.Phone_Number__c != null && contactsByCLIMap.containsKey(c.Phone_Number__c)) {
                //existing Contact match found
                system.debug('***** Contact match found on CLI: ' + c.Phone_Number__c);
                
                Id contactIdFound = contactsByCLIMap.get(c.Phone_Number__c);
                c.ContactId = contactIdFound;
                objectsToLink.add(c);
                
                if (c.Li_Community_User__c != null) {
                    c.Li_Community_User__r.Contact__c = contactIdFound;
                    objectsToLink.add(c.Li_Community_User__r);
                }
            }
        }
        
        if (objectsToLink.size() > 0) {
            update objectsToLink;
        }
        
     }
     
     
     public static void createTasksForCases (Map<Id, Case> billingAccountCasesMap){
     	List<Task> tasksToInsert = new List<Task>();
     	if (billingAccountCasesMap != null && billingAccountCasesMap.size() > 0){
     		// for each case create the task for the first step

			System.debug (Logginglevel.ERROR, '----------------------- createTasksForCases - 1 ----------' );
     		
     		// from billing account get the path and step details
     		List<Billing_Account__c> billingAccounts = [SELECT Id, Current_Treatment_Path__r.name, Current_Treatment_Step__r.Step_type__c, Step_Communication_Type__c,
     														Action_Date__c, Current_Treatment_Step__r.name 
     													from Billing_Account__c where id in :billingAccountCasesMap.keyset()];     		
     		for (Billing_Account__c account : billingAccounts){ 
     			if (account != null){
     				System.debug (Logginglevel.ERROR, '----------------------- createTasksForCases - 2 ----------' );
					Task newTask = new Task();
					date taskDueDate = account.Action_Date__c;
					if ( taskDueDate == null ) {
						taskDueDate = system.today();
					}
					
					CollectionTaskInfo colTaskInfo = new CollectionTaskInfo ( (billingAccountCasesMap.get(account.id)).id, account.Current_Treatment_Step__r.Step_type__c, 
										account.Current_Treatment_Step__r.Name, account.Current_Treatment_Path__r.name, taskDueDate );
					colTaskInfo.instalmentNumber = 1;
					colTaskInfo.stepCommunicationType = account.Step_Communication_Type__c;
			
					System.debug (Logginglevel.ERROR, '----------------------- createTask - 2.1 ----------caseid----' + (billingAccountCasesMap.get(account.id)).id );
					
					StepHandler.createTask(newTask, colTaskInfo );
					tasksToInsert.add(newTask);     				     				
     			}
     		} 
     		System.debug (Logginglevel.ERROR, '----------------------- createTasksForCases - 3 ------tasksToInsert.size----' + tasksToInsert.size() );
     		insert tasksToInsert;
     	}
     }
     

}