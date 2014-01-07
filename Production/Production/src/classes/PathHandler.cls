public with sharing class PathHandler {
	
	static List<Billing_Account__c> accountsToUpsert = new List<Billing_Account__c>(); 
	static List<Case> casesToUpsert = new List<Case>(); 
	static List<Task> tasksToUpsert = new List<Task>(); 
    static Map<String, String> caseRecordTypeMapping = new Map<String, String>(); 

	public static Id getRecordTypeIdForName( string recordTypeName ){
		if ( caseRecordTypeMapping.size() == 0 ) {
		    //Get Case Record Types
		    List<RecordType> caseRecordTypes = [select Id, Name from RecordType where SObjectType = 'Case'];
		    for (RecordType rt : caseRecordTypes) {
		        caseRecordTypeMapping.put(rt.Name, rt.Id);   
		    }
		}
		//at this point the record types should be loaded in 
		return caseRecordTypeMapping.get ( recordTypeName );
	}
   
/**
	assignPath used to assign path to incoming account in collection
*/
	public static void assignPath ( CollectionAccountInfo colAccount ){
		assignPathsInBulk (new List<CollectionAccountInfo> {colAccount}  );
	}
 

/**
	This method is used to assign path to incoming account in collection in bulk
*/
	public static void assignPathsInBulk ( List<CollectionAccountInfo> colAccounts){
		if (colAccounts != null && colAccounts.size() > 0){
			// loop thru the collection 
			for (CollectionAccountInfo colAccount : colAccounts){
				System.debug (Logginglevel.ERROR, '----------------------- assignPathsInBulk --------------1-' + colAccount);
				assignCollectionPath(  colAccount );
			} 

			// save all the records 
			upsert accountsToUpsert; 
			
			upsert casesToUpsert;

		}else{
			// throw error
		}
	}
		
/**
	This method is the core method which assigns path to incoming account
*/		
	private static void assignCollectionPath( CollectionAccountInfo colAccountInfo ){
		System.debug (Logginglevel.ERROR, '----------------------- assignCollectionPath --------------1-' + colAccountInfo.billingAccount.Current_Treatment_Path__c);
		
		if ( colAccountInfo.billingAccount.Current_Treatment_Path__c == null){
		System.debug (Logginglevel.ERROR, '----------------------- assignCollectionPath -------colAccountInfo.pathId-------2-' + colAccountInfo.pathId);

			// just entering in collection 		
			// if the path is already specified assign to path
			if ( colAccountInfo.pathId != null ){
		System.debug (Logginglevel.ERROR, '----------------------- assignCollectionPath --------------3-');
				
					colAccountInfo.billingAccount.Current_Treatment_Path__c = colAccountInfo.pathId; 
			}else{
		System.debug (Logginglevel.ERROR, '----------------------- assignCollectionPath --------------4-');
				
				// find the path to assign 
				colAccountInfo.billingAccount.Current_Treatment_Path__c = discoverPathToAssign( colAccountInfo ); 
			}
			
			StepHandler.moveStep( colAccountInfo );
			
			// find the step to assign 
//			colAccountInfo.billingAccount.Current_Treatment_Step__c =  CollectionHelper.getFirstStepIdForPath( colAccountInfo.billingAccount.Current_Treatment_Path__c ) ;
//			colAccountInfo.billingAccount.Next_Treatment_Step__c =  CollectionHelper.getDeafultNextStepId( colAccountInfo.billingAccount.Current_Treatment_Path__c, colAccountInfo.billingAccount.Current_Treatment_Step__c ) ;
			
//			accountsToUpsert.add(colAccountInfo.billingAccount); // billing account to update
			
			//Create a case
			createCollectionCase ( colAccountInfo );			
		} else {
			// moving path
			StepHandler.moveStep( colAccountInfo );
		} 
	}

/**
	This method is used to exit collection path.
	If the exitCollection flag is set on CollectionAccountInfo the account exits collection
*/	
	public static void exitPath ( CollectionAccountInfo colAccount ){
		exitPathsInBulk (new List<CollectionAccountInfo> {colAccount}  );
	}

/**
	This method is used to exit collection path in bulk.
	If the exitCollection flag is set on CollectionAccountInfo the account exits collection
*/	
	public static void exitPathsInBulk ( List<CollectionAccountInfo> colAccounts){
		Map<Id,Case> accountToCaseMap = new Map<Id,Case>();
		Map<Id,Task> caseToTaskMap = new Map<Id,Task>();
		
		Set<Id> accountIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		
		accountsToUpsert = new List<Billing_Account__c>();
		casesToUpsert = new List<Case>(); 
		
		for (CollectionAccountInfo colAccount : colAccounts){
				accountIds.add(colAccount.billingAccount.id);
		}
		
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
							From Case c 
							where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and c.IsClosed = false and c.Billing_Account__c in :accountIds];
		
		for (Case openCase :cases){
			accountToCaseMap.put(openCase.Billing_Account__c, openCase);
			caseIds.add(openCase.id);
		}
		
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, t.Description, t.Date_exited__c, 
									t.Date_entered__c, t.Cost__c, t.ActivityDate 
							From Task t 
							where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and t.WhatId in :caseIds];
		
		for (Task openTask :tasks){
				caseToTaskMap.put(openTask.WhatId,openTask);
		}
		
		if (colAccounts != null && colAccounts.size() > 0){
			// loop thru the collection 
			for (CollectionAccountInfo colAccount : colAccounts){
				Case currentCase = accountToCaseMap.get(colAccount.billingAccount.id);
				Task currentTask = caseToTaskMap.get(currentCase.Id);
				if (currentTask != null){
					currentTask.Status = Constants.CollectionTaskType_Completed;
					currentTask.Status__c  = Constants.CollectionTaskType_Completed;
				}
				exitCollectionPath( colAccount,  currentCase, currentTask );
			} 

			// save all the records 
				
			upsert accountsToUpsert;
			
			upsert tasksToUpsert;
			
			upsert casesToUpsert;

		}else{
			// throw error
		}
	}
			
/**
	This is the core method which exits the account out of collection.
	If the exitCollection flag is set on CollectionAccountInfo the account exits collection
*/	
	private static void exitCollectionPath( CollectionAccountInfo colAccountInfo, Case currentCase, Task currentTask ){
		if ( colAccountInfo.billingAccount == null){
			// not on the path ... so return
			return;	
		}
		
		// to Exit the path ... close the step
		//close case
		if( colAccountInfo.exitCollection ){
			// TODO - why sometimes the task is not present?
			if( currentTask != null ) {
				StepHandler.closeTask( currentTask, Constants.CollectionTaskCloseReason_Manual );
				tasksToUpsert.add( currentTask );
			}
		}
		
		
		// Update the account 
		colAccountInfo.billingAccount.Current_Treatment_Path__c = null;
		colAccountInfo.billingAccount.Current_Treatment_Step__c = null;
		colAccountInfo.billingAccount.Next_Treatment_Step__c = null;
		colAccountInfo.billingAccount.Action_Date__c = null;
		colAccountInfo.billingAccount.Payment_Defaulted__c = false;
		colAccountInfo.billingAccount.Payment_Defaulted_Date__c = null;
		colAccountInfo.billingAccount.Step_Communication_Type__c = null;
		
		
		if(colAccountInfo.exitCollection){
			
			colAccountInfo.billingAccount.In_Collections__c = false;
		}
		
		accountsToUpsert.add ( colAccountInfo.billingAccount );
				
		//close case
		if( colAccountInfo.exitCollection ){
			closeCollectionCase ( colAccountInfo, currentCase );
		}
	}
	
	
	
	/** 
		Create the collection case to model the collection journey 
	*/
	private static void createCollectionCase( CollectionAccountInfo colAccountInfo ){

		// Create case of type collection to model the path		
		Case colCase = new Case (Billing_Account__c =  colAccountInfo.billingAccount.id, RecordTypeId = getRecordTypeIdForName( Constants.CaseRecordType_Collection) ); 
		
		//TODO Set other fields
		
		casesToUpsert.add(colCase); // billing account to update
		
		// also create the task to represent the first step
		// --- This will now happen through the trigger
		
		//StepHandler.createTask(currentCase, moveToStep, path)
	}
	

	/** 
		Close the collection case to model the end of collection journey 
	*/
	private static void closeCollectionCase( CollectionAccountInfo colAccountInfo, Case colCase ){

		colCase.Status = 'Completed';
		
		casesToUpsert.add( colCase ); // billing account to update
	}

	/** 
		Discover the path the account should be assigned to 
	*/
	 //TODO in 1.5
	private static Id discoverPathToAssign( CollectionAccountInfo colAccountInfo ){
	
		return null;
	}
	

}