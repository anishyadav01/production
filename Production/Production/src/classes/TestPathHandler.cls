/**
  	This class contains unit tests for validating the behavior of Apex classes and triggers
 	related to Path functionality
 	
 	different ways in which the account can be pushed on a path 
 	 - New to collection
 	 - Manual move to a path and/or step
	 -
 	
 	
 */
 
@isTest
private class TestPathHandler {
	
    static testMethod void createPathAndMoveStepTest() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', 
    		Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(step1);
    	
    	steps.add( new Collection_Step__c (name = 'Step2', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step4', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo(billingAccount, path.id);
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2'); 
        
        // ensure the case is created
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, 
                            	c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
                            From Case c 
                            where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and 
                            		c.IsClosed = false and c.Billing_Account__c = :billingAccount.id];

        system.assertEquals(cases.size(), 1);

        // ensure the task is created
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, Step_name__c,Step_type__c,
                            	t.Description, t.Date_exited__c, t.Date_entered__c, t.Cost__c, t.ActivityDate 
                            From Task t 
                            where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and 
                            	t.WhatId = :cases[0].id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Step_name__c, 'Step1'); 
		system.assertEquals(tasks[0].Step_type__c, 'Communication'); 
		
		// try moving this object through a path 
        colAcc.billingAccount = accts[0];
        colAcc.pathId = null;
        colAcc.stepId = null;
        
		StepHandler.moveStep (colAcc );
		// ensure the account has the path and steps set
		
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Collection_Paused__c, Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step2'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step3'); 
    }

    static testMethod void createPathAndMoveToStepTest() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', 
    		Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add( step1 );
    	
    	Collection_Step__c step2 = new Collection_Step__c (name = 'Step2', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', 
    		Sequence__c = 2, is_Default_Next_Step__c = true); 
    	steps.add( step2 );

        steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	Collection_Step__c Step4 = new Collection_Step__c (name = 'Step4', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true); 
    	steps.add( Step4 );

        steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo(billingAccount, path.id);
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2'); 
        
        // ensure the case is created
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, 
                            	c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
                            From Case c 
                            where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and 
                            		c.IsClosed = false and c.Billing_Account__c = :billingAccount.id];

        system.assertEquals(cases.size(), 1);

        // ensure the task is created
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, Step_name__c,Step_type__c,
                            	t.Description, t.Date_exited__c, t.Date_entered__c, t.Cost__c, t.ActivityDate 
                            From Task t 
                            where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and 
                            	t.WhatId = :cases[0].id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Step_name__c, 'Step1'); 
		system.assertEquals(tasks[0].Step_type__c, 'Communication'); 
		
		// try moving this object through a path 
        colAcc = new CollectionAccountInfo(accts[0], null);
        colAcc.stepId = Step4.id;
        
		StepHandler.moveStep ( colAcc );
		// ensure the account has the path and steps set
		
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Collection_Paused__c, Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step4'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step5'); 
    }    

    static testMethod void autoDiscoverPath() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(step1);
    	
    	steps.add( new Collection_Step__c (name = 'Step2', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step4', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo( billingAccount );
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, null); 
/*        
        // ensure the case is created
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, 
                            	c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
                            From Case c 
                            where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and 
                            		c.IsClosed = false and c.Billing_Account__c = :billingAccount.id];

        system.assertEquals(cases.size(), 1);

        // ensure the task is created
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, Step_name__c,Step_type__c,
                            	t.Description, t.Date_exited__c, t.Date_entered__c, t.Cost__c, t.ActivityDate 
                            From Task t 
                            where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and 
                            	t.WhatId = :cases[0].id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Step_name__c, 'Step1'); 
		system.assertEquals(tasks[0].Step_type__c, 'Communication'); 
		
		// try moving this object through a path 
        colAcc.billingAccount = accts[0];
        colAcc.pathId = null;
        colAcc.stepId = null;
        
		StepHandler.moveStep (colAcc );
		// ensure the account has the path and steps set
		
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step2'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step3'); 
*/ 
    }    
    
    
    static testMethod void createAndExitPathTest() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(step1);
    	
    	steps.add( new Collection_Step__c (name = 'Step2', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step4', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo(billingAccount, path.id);
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2'); 
        
        

        colAcc.billingAccount = accts[0];
        colAcc.pathId = null;
        colAcc.stepId = null;        
        PathHandler.exitPath ( colAcc );
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, null); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, null); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, null); 
        
        
    }
	

    static testMethod void createAndExitCollectionTest() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(step1);
    	
    	steps.add( new Collection_Step__c (name = 'Step2', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = path.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step4', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = path.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo(billingAccount, path.id);
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2'); 
        system.assertEquals(accts[0].In_Collections__c, true);
        

        colAcc.billingAccount = accts[0];
        colAcc.pathId = null;
        colAcc.stepId = null; 
        colAcc.exitCollection = true;       
        PathHandler.exitPath ( colAcc );
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, null); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, null); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, null); 
		system.assertEquals(accts[0].In_Collections__c, false);        
    }

    static testMethod void createPathAndMovePathStepTest() {
    	// create paths
    	List<Collection_Path__c> paths = new List<Collection_Path__c>(); 
    	Collection_Path__c pathOne = new Collection_Path__c (name = 'pathOne');
    	paths.add(pathOne);
    	
    	Collection_Path__c pathTwo = new Collection_Path__c (name = 'pathTwo');
    	paths.add(pathTwo);
    	
    	insert paths;
    	//create steps 
    	List<Collection_Step__c> steps = new List<Collection_Step__c>();
    	
    	Collection_Step__c step1 = new Collection_Step__c (name = 'Step1', Collection_Path__c = pathOne.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(step1);
    	
    	steps.add( new Collection_Step__c (name = 'Step2', Collection_Path__c = pathOne.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step3', Collection_Path__c = pathOne.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step4', Collection_Path__c = pathOne.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'Step5', Collection_Path__c = pathOne.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );
    	
    	Collection_Step__c p2step1 = new Collection_Step__c (name = 'p2Step1', Collection_Path__c = pathTwo.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 1, is_Default_Next_Step__c = true); 
    	steps.add(p2step1);
    	
    	steps.add( new Collection_Step__c (name = 'p2Step2', Collection_Path__c = pathTwo.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 2, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'p2Step3', Collection_Path__c = pathTwo.id, Days_on_this_step__c = 3, Step_type__c = 'Communication', Sequence__c = 3, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'p2Step4', Collection_Path__c = pathTwo.id, Days_on_this_step__c = 5, Step_type__c = 'BAR', Sequence__c = 4, is_Default_Next_Step__c = true) );
    	steps.add( new Collection_Step__c (name = 'p2Step5', Collection_Path__c = pathTwo.id, Days_on_this_step__c = 5, Step_type__c = 'FinalDemand', Sequence__c = 5, is_Default_Next_Step__c = true) );


    	insert steps;
    	
    	
        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true );
        accounts.add(billingAccount);
        insert accounts;

		CollectionAccountInfo colAcc = new CollectionAccountInfo(billingAccount, pathOne.id);
		        
        //verify default step move 
        PathHandler.assignPath ( colAcc );		
		// ensure the account has the path and steps set
		
		List<Billing_Account__c> accts = [SELECT name, Account_Id__c, In_Collections__c, 
                                          Collection_Paused__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2'); 
        
        // ensure the case is created
		List<Case> cases = [Select c.Status, c.RecordTypeId, c.IsClosed, c.Id, 
                            	c.Description, c.CreatedDate, c.CreatedById, c.Billing_Account__c 
                            From Case c 
                            where c.Record_Type_Name__c = :Constants.CaseRecordType_Collection and 
                            		c.IsClosed = false and c.Billing_Account__c = :billingAccount.id];

        system.assertEquals(cases.size(), 1);

        // ensure the task is created
		List<Task> tasks = [Select t.WhatId, t.Status__c, t.Status, t.RecordTypeId, t.IsClosed, t.Id, Step_name__c,Step_type__c,
                            	t.Description, t.Date_exited__c, t.Date_entered__c, t.Cost__c, t.ActivityDate 
                            From Task t 
                            where t.Record_Type_Name__c = :Constants.CaseRecordType_Collection and t.IsClosed = false and 
                            	t.WhatId = :cases[0].id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Step_name__c, 'Step1'); 
		system.assertEquals(tasks[0].Step_type__c, 'Communication'); 
		
		// try moving this object through a path 
        colAcc.billingAccount = accts[0];
        colAcc.pathId = pathTwo.id;
        colAcc.stepId = null;
        
		StepHandler.moveStep (colAcc );
		// ensure the account has the path and steps set
		
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name, Collection_Paused__c 
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathTwo'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'p2Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'p2Step2'); 
        
		// try moving this object through a path 
        colAcc.billingAccount = accts[0];
        colAcc.pathId = pathOne.id;
        colAcc.stepId = null;
        
		PathHandler.assignPath(colAcc );
		// ensure the account has the path and steps set
		
		accts = [SELECT name, Account_Id__c, In_Collections__c, Current_Treatment_Step__r.name, Current_treatment_path__r.name, 
				Action_Date__c, Next_Treatment_Step__r.name , Collection_Paused__c
												FROM Billing_Account__c WHERE id = :billingAccount.id];     

		system.assertEquals(accts.size(), 1);
		system.assertEquals(accts[0].Current_Treatment_Path__r.name, 'pathOne'); 
		system.assertEquals(accts[0].current_Treatment_Step__r.name, 'Step1'); 
		system.assertEquals(accts[0].next_Treatment_Step__r.name, 'Step2');
    }   
   
   
    
}