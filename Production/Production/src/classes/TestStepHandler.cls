/**

	This is a class to test functionality under StepHandler

*/

@isTest
private class TestStepHandler {
/*
    static testMethod void createStepTest() {
		

        // create customer account 
        Account customer = new Account (name = 'testCustomer');
        insert customer;
        
        // create BillingAccount  
        List<Billing_Account__c> accounts = new List<Billing_Account__c>();
        Billing_Account__c billingAccount = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true 
        		//, Treatment_Path__c = 'High', current_step__c ='Comm1'
        		, 
        		Action_Date__c = system.today(),
				Next_Step__c = 'Comm2'
        		);
        accounts.add(billingAccount);

        Billing_Account__c billingAccount2 = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true 
        		//, Treatment_Path__c = 'High', current_step__c ='Comm1'
        		, 
        		Action_Date__c = system.today()
        		);
        accounts.add(billingAccount2);	
        
        Billing_Account__c billingAccount3 = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true 
        		//, Treatment_Path__c = 'High', current_step__c ='Comm1'
        		, 
        		Action_Date__c = system.today(), Next_Step__c = 'Comm2'
        		);
        accounts.add(billingAccount3);	


        Billing_Account__c billingAccount4 = new Billing_Account__c (
        		name = 'test', Account_Id__c = customer.id, In_Collections__c = true 
        		//, Treatment_Path__c = 'High', current_step__c ='Comm1'
        		, 
        		Action_Date__c = system.today(), Next_Step__c = 'Comm2'
        		);
        accounts.add(billingAccount4);	
        
                	
        insert accounts;
        
        // create a case
        //Case cs = new Case (Account = customer.id,)
        
        
        //verify default step move
        StepHandler.moveStep(billingAccount, null, null, null);
        StepHandler.moveStep(billingAccount2, null, null, null);
         StepHandler.moveStep(billingAccount3, null, 'customStep', null);
         StepHandler.moveStep(billingAccount4, null, null, 'customStepByAction');
        
        List<Billing_Account__c> billacts1 = [SELECT current_step__c from Billing_Account__c where Id = :billingAccount.id Limit 1 ];
		system.assertEquals(billacts1.size() , 1);
		system.assertEquals(billacts1[0].current_step__c , 'Comm2');


        //verify step move to first step		
        List<Billing_Account__c> billacts2 = [SELECT current_step__c from Billing_Account__c where Id = :billingAccount2.id LIMIT 1];
		system.assertEquals(billacts2.size() , 1);
		system.assertEquals(billacts2[0].current_step__c , 'firstStep');


        //verify step move to manual step		
        List<Billing_Account__c> billacts3 = [SELECT current_step__c from Billing_Account__c where Id = :billingAccount3.id LIMIT 1];
		system.assertEquals(billacts3.size() , 1);
		system.assertEquals(billacts3[0].current_step__c , 'customStep');

        //verify step move to manual step		
        List<Billing_Account__c> billacts4 = [SELECT current_step__c from Billing_Account__c where Id = :billingAccount4.id LIMIT 1];
		system.assertEquals(billacts4.size() , 1);
		system.assertEquals(billacts4[0].current_step__c , 'customStepByAction');


        /*
        
                StepHandler.moveStep(billingAccount, null, null);
        StepHandler.moveStep(billingAccount2, null, null);
        
        List<Billing_Account__c> billacts = [SELECT current_step__c, Id from Billing_Account__c where Account_Id__c = :customer.id ];
		system.assertEquals(billacts.size() , 2);
		
		//TODO is there any better way of doing this?
		for (Billing_Account__c billAct : billacts){
			if (billAct.id == billingAccount.id){
				//verify default step move
				system.assertEquals(billacts[0].current_step__c , 'Comm2');
			}else if (billAct.id == billingAccount2.id){
			    //verify step move manual
				system.assertEquals(billacts[0].current_step__c , 'firstStep');
			}

		}
		
		*/
        
    //}
}