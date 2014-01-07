// this is the helper class to help step monitor


public with sharing class StepHandler {
	
	static List<Billing_Account__c> accountsToUpsert = new List<Billing_Account__c>(); 
	static List<Task> taskToUpsert = new List<Task>(); 
	
	public static void moveStep ( CollectionAccountInfo colAccount ){
		moveStepsInBulk (new List<CollectionAccountInfo> {colAccount}  );
	}
	
	public static void moveStepsInBulk ( List<CollectionAccountInfo> colAccounts ){
		
		Map<Id,Case> accountToCaseMap = new Map<Id,Case>();
		Map<Id,Task> caseToTaskMap = new Map<Id,Task>();
		accountsToUpsert = new List<Billing_Account__c>(); 
		taskToUpsert = new List<Task>(); 
		Set<Id> accountIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		 
		for (CollectionAccountInfo colAccount : colAccounts){
				accountIds.add(colAccount.billingAccount.id);
		}
		
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
							From Case c 
							where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and c.IsClosed = false and c.Billing_Account__c in :accountIds];
		
		for (Case openCase :cases){
			accountToCaseMap.put( openCase.Billing_Account__c, openCase );
			caseIds.add(openCase.id);			
		}
		
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, t.Description, t.Date_exited__c, 
									t.Date_entered__c, t.Cost__c, t.ActivityDate, Step_name__c
							From Task t 
							where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and t.WhatId in :caseIds];
		
		for (Task openTask :tasks){
				caseToTaskMap.put( openTask.WhatId, openTask );
		}
		
		if (colAccounts != null && colAccounts.size() > 0){
									
			// loop thru the collection 
			for (CollectionAccountInfo colAccount : colAccounts){
				Case currentCase = accountToCaseMap.get(colAccount.billingAccount.id);
				Task currentTask = null;
				if(currentCase != null){
					currentTask = caseToTaskMap.get(currentCase.Id);
				}
				moveStep(  colAccount, currentCase, currentTask);
			} 

			// save all the records 
			system.debug('****** accountsToUpsert are ' + accountsToUpsert);
			upsert accountsToUpsert;

			system.debug('****** taskToUpsert are ' + taskToUpsert.size());			
			upsert taskToUpsert;

		}else{
			// throw error
		}

	}
	
	
	/**
		This method changes the step
		
		
		/////// get Current / moveTo and next steps
		//////  check exit criteria passes
		//////  check meets entry criteria
		
		////// check if requires immediate execution
		//////////// execute
		///////////  wait
		
		
		 
	*/

	
	public static void closeTask( Task oldTask, String reasonForClosing ){
		oldTask.Status = Constants.CollectionTaskType_Completed;
		oldTask.Status__c  = Constants.CollectionTaskType_Completed;
		
		oldTask.Reason_for_exit__c  = reasonForClosing;
		oldTask.Date_exited__c  = system.now();
	}


	public static void createTask( Case currentCase, Collection_Step__c moveToStep, Collection_Path__c path, boolean hasPathChanged, date dueDate, integer instNumber, String stepCommunicationType){
		if(hasPathChanged) {
			Task dummyTask = new Task();
			createPathChangeTask( dummyTask, currentCase.id,  moveToStep.Name, path.Name );
			taskToUpsert.add( dummyTask );
		}

		CollectionTaskInfo colTaskInfo = new CollectionTaskInfo ( currentCase.id, moveToStep.Step_type__c, moveToStep.Name, path.Name, dueDate );
		colTaskInfo.instalmentNumber = instNumber;
		colTaskInfo.stepCommunicationType = stepCommunicationType;
		
		Task newTask = new Task();		
		createTask( newTask, colTaskInfo );
		taskToUpsert.add(newTask);
	}

	public static void createTask( Task currentTask, CollectionTaskInfo colTaskInfo ){
		System.debug (Logginglevel.ERROR, '----------------------- createTask - 2 ----------dueDate----1-' + colTaskInfo.dueDate);
		
		currentTask.WhatId = colTaskInfo.currentCaseId;
		currentTask.Date_entered__c = system.now();
		
		if ( colTaskInfo.stepType != null && colTaskInfo.stepType == Constants.CollectionStepType_Communication ){
			
			currentTask.step_Communication_type__c = getBestCommunicationStep();
		}
		currentTask.Step_type__c = colTaskInfo.stepType; 
		currentTask.Step_Communication_Type__c = colTaskInfo.stepCommunicationType;
		
		if ( colTaskInfo.dueDate < system.today() ) {
			currentTask.ActivityDate = system.today();
		}else {
			currentTask.ActivityDate = colTaskInfo.dueDate;
		}
		
		currentTask.Step_name__c = colTaskInfo.stepName;
		if ((colTaskInfo.stepType == Constants.CollectionStepType_Communication || colTaskInfo.stepType == Constants.CollectionStepType_CheckPayment) && colTaskInfo.instalmentNumber > 0 ){
			currentTask.subject = colTaskInfo.stepName + ' - ' + colTaskInfo.instalmentNumber;
			currentTask.Instalment_Number__c = colTaskInfo.instalmentNumber;
		}else{
			currentTask.subject = colTaskInfo.stepName;
		}
		
		currentTask.Path_Name__c = colTaskInfo.pathName;
		currentTask.Status = Constants.CollectionTaskType_NotStarted;
		currentTask.Status__c  = Constants.CollectionTaskType_NotStarted;
	}


	public static void createPathChangeTask( Task currentTask, Id currentCaseId, String stepName, String pathName ){
		System.debug (Logginglevel.ERROR, '----------------------- createTask - 2 --------------1-');
		
		currentTask.WhatId = currentCaseId;
		currentTask.Date_entered__c = System.now();

		currentTask.Step_type__c = 'Path Change'; 
		currentTask.Date_entered__c = system.now();
		currentTask.ActivityDate = system.today();
		currentTask.Step_name__c = stepName;
		currentTask.subject = 'Path Changed to - ' + pathName;
		currentTask.Path_Name__c = pathName;
		currentTask.Status = Constants.CollectionTaskType_Completed;
		currentTask.Status__c  = Constants.CollectionTaskType_Completed;
	}



	/**
		This method looks through the entry criteria and returns true if successfully passed
	*/
	public static boolean passesEntryCriteria (){
		// TODO - verify Entry Criteria

		return true;	
	}
	
	
	/**
		This method looks through all the exit criterias and determines the next step the account should be moved on to
	*/
	public static Collection_Step__c getStepByExitCriteria ( CollectionAccountInfo colAccount, String currentStepName ){		
		if( colAccount.action == Constants.CollectionStepAction_Payment ){
			// Should be moved to the previous step for next installment
			// find the step where it should be moved
			// this will be available in the exit criteria of the step 
			
			// for payment check if this is the last installment for different action
			string additionalCriteria = null;
			if ( colAccount.nextPaymentDueDate == null ){
				additionalCriteria = 'Last';
			}
			
			Collection_Step__c currentStep = CollectionHelper.getStepByName  ( colAccount.billingAccount.Current_Treatment_path__c, currentStepName );
			if( currentStep != null ) {
				// check for exit criteria
				system.debug('-------------action--------' + colAccount.action);
				system.debug('-------------currentStep.id--------' + currentStep.id);
				system.debug('-------------action--------' + colAccount.action + '--additionalCriteria--' + additionalCriteria);
				

				Collection_Step_Criteria__c criteria = CollectionHelper.getStepExitCriteriaByAction ( currentStep.id, colAccount.action, additionalCriteria );
				
				system.debug('-------------criteria.Action__r--------' + criteria.Action__r);
				if( criteria.Action__r.Type__c  == Constants.CollectionStepCriteriaAction_GotoStep){
					return CollectionHelper.getStepByName  ( colAccount.billingAccount.Current_Treatment_path__c, criteria.Action__r.Value__c );
				}		
			}
		}
		return null;
	}
	
	/**
		This method looks through all the communication medium available for the customer and selects the best method for the current reminder type
	*/
	public static string getBestCommunicationStep (){
		// TODO - Find the best comm method for the account
		
		
		return Constants.CollectionCommunicationType_SMS;	
	}
	
	private static void moveStep ( CollectionAccountInfo colAccount, Case currentCase, Task currentTask ){
		//TODO - break down this method
		
		Collection_Step__c moveToStep = null;
		Collection_Step__c currentStep = null;
		Collection_Path__c path = null;
		boolean hasPathChanged = false;
		boolean onFirstStep = false;
		date nextTaskDueDate = system.today(); 
		integer instalmentNumber = 0;
		String reasonForExitingCurrentStep = Constants.CollectionTaskCloseReason_Automatic;

system.debug('----------colAccount-------------'+ colAccount );
		
		if( colAccount != null ){

			if( colAccount.billingAccount.Collection_Paused__c ){
				// collection task is on hold .. do nothing
				return;
			}

			// verify the actions and the steps to take 
			if( colAccount.action != null ){
system.debug('----------moveStep-------------1' );
				
				path = CollectionHelper.getPathById( colAccount.billingAccount.Current_Treatment_path__c );
				currentStep = CollectionHelper.getStepByName  ( colAccount.billingAccount.Current_Treatment_path__c, currentTask.Step_name__c );

				moveToStep = getStepByExitCriteria (colAccount, currentTask.Step_name__c );
				
				//TODO: move it to proper place increment the instalmentNumber
				if( colAccount.instalmentNumber > 0 ){
					instalmentNumber = colAccount.instalmentNumber;
				}
				
				reasonForExitingCurrentStep = Constants.CollectionTaskCloseReason_Payment;
				
			}else {
system.debug('----------moveStep-------------2');

				if( colAccount.pathId == null && colAccount.stepId != null) {  
					// set the path to the current path
					path = CollectionHelper.getPathById( colAccount.billingAccount.Current_Treatment_path__c );
					moveToStep = CollectionHelper.getStepForPath( path.id, colAccount.stepId );
	
					currentStep = CollectionHelper.getStepForPath  ( path.id, colAccount.stepId  );									
				} else if( colAccount.pathId != null && colAccount.stepId == null) {
					// move to first step
system.debug('----------moveStep-------------3' );

					onFirstStep = true;
					currentStep = CollectionHelper.getFirstStepForPath( colAccount.pathId );
					path = CollectionHelper.getPathById( colAccount.pathId );
					
					if(currentStep != null && currentStep.Step_type__c == Constants.CollectionStepType_Wait) {
						// if its a wait step the actual step is the next step so get the next step
						moveToStep = CollectionHelper.getDeafultNextStep(path.Id, currentStep.Id);
system.debug('----------moveStep-------------4');

					} else {
system.debug('----------moveStep-------------5' );

						currentStep = null;
						moveToStep = CollectionHelper.getFirstStepForPath( colAccount.pathId );					
					}

				} else if( colAccount.pathId == null && colAccount.stepId == null ) {
					// move to default next step	
					path = CollectionHelper.getPathById( colAccount.billingAccount.Current_Treatment_path__c );
					currentStep = CollectionHelper.getStepForPath  ( colAccount.billingAccount.Current_Treatment_path__c, colAccount.billingAccount.Current_Treatment_Step__c );
					moveToStep = CollectionHelper.getStepForPath( colAccount.billingAccount.Current_Treatment_path__c, colAccount.billingAccount.Next_Treatment_Step__c );
				} else {
					moveToStep = CollectionHelper.getStepForPath( colAccount.pathId, colAccount.stepId );
					path = CollectionHelper.getPathById( colAccount.pathId );
					currentStep = CollectionHelper.getStepForPath  ( colAccount.billingAccount.Current_Treatment_path__c, colAccount.billingAccount.Current_Treatment_Step__c );
					
					reasonForExitingCurrentStep = Constants.CollectionTaskCloseReason_Manual;
				}
				
				if( colAccount.pathId != null && colAccount.billingAccount.current_treatment_path__c != null &&
					colAccount.billingAccount.current_treatment_path__c != colAccount.pathId){
					hasPathChanged = true;	
				}	
			}
			
			// if the step to move to is wait .. then we should move one more step
			if ( moveToStep != null && moveToStep.Step_type__c == Constants.CollectionStepType_Wait ){
				currentStep = moveToStep;
				moveToStep = CollectionHelper.getDeafultNextStep(path.Id, currentStep.Id);
			} else if ( moveToStep != null && moveToStep.Step_type__c == Constants.CollectionStepType_Payment_Defaulted ){
				// update account flag to indicate missing payment
				colAccount.billingAccount.Payment_Defaulted__c = true;
				colAccount.billingAccount.Payment_Defaulted_Date__c = system.today();			
			}
			
			
			// validate if step passes the entry criteria
			if ( !passesEntryCriteria() ){
				// TODO - send back error message
				// ---------  set error on the account -------------
			}			
			
			// update account to indicate step change 			
			if( path != null ){						
				colAccount.billingAccount.current_treatment_path__c = path.id;
			}
system.debug('----------currentStep-------------'+ currentStep );
			if ( colAccount.nextPaymentDueDate != null ){
				if ( currentStep != null ){
					nextTaskDueDate = colAccount.nextPaymentDueDate + integer.valueOf( currentStep.Days_on_this_step__c );
				}
				// ensure this date is on weekday
				nextTaskDueDate = Common.getPreviousWorkingDay( nextTaskDueDate );
			} else {
				if ( currentStep != null && currentStep.Days_on_this_step__c != null ){
					if ( currentTask != null && currentTask.ActivityDate != null ) {
						nextTaskDueDate = currentTask.ActivityDate  + integer.valueOf( currentStep.Days_on_this_step__c );
					} else {
						nextTaskDueDate = system.today()  + integer.valueOf( currentStep.Days_on_this_step__c );
					}
				}				
			}

			if ( nextTaskDueDate < system.today() ) {
				nextTaskDueDate = system.today();
			}

			if(moveToStep != null){
				colAccount.billingAccount.current_treatment_step__c = moveToStep.id;
				// get the next default step to set on billing account			
				colAccount.billingAccount.next_treatment_step__c = CollectionHelper.getDeafultNextStepId( path.Id, moveToStep.Id ); 
				colAccount.billingAccount.Action_Date__c = nextTaskDueDate;
				colAccount.billingAccount.Step_Communication_Type__c = moveToStep.Step_Communication_Type__c; 
			}

			accountsToUpsert.add ( colAccount.billingAccount ) ;
			
			if( currentTask != null ){
				closeTask( currentTask, reasonForExitingCurrentStep );
				taskToUpsert.add( currentTask );		
			}

			if( currentCase != null && moveToStep != null && path != null){
				createTask( currentCase, moveToStep, path, hasPathChanged, nextTaskDueDate, instalmentNumber, moveToStep.Step_Communication_Type__c );
			}
		}
	}	



	public static void executeStep ( CollectionAccountInfo colAccount ){

		Collection_Path__c path = CollectionHelper.getPathById( colAccount.billingAccount.Current_Treatment_path__c );
		Collection_Step__c currentStep = CollectionHelper.getStepForPath  ( colAccount.billingAccount.Current_Treatment_path__c, colAccount.billingAccount.Current_Treatment_Step__c );

		// check if the step passes the entry criteria .... usually will have to see if the payment is made
		
		//TODO** how will we know if the payment is made?
				
		
	}

}