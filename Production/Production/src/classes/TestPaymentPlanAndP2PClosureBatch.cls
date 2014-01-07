@isTest
private class TestPaymentPlanAndP2PClosureBatch {
	
	public static testmethod void testBatch_WithAccountWithPaymentPlanInFinalStep_PPClosed(){
		
		TestHelper.createCollectionSettings(6);
		
		//One BA with an open PP
		Billing_Account__c ba = TestHelper.createBillingAccount();
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Date_of_First_Installment__c = Date.today(), Use_New_Call_Limit__c = false, 
			Proposed_Term__c = '1', Proposed_Frequency__c = 'Monthly', Status__c = Constants.PaymentPlanStatus_Open);
		insert pp;
		
		//Createb PP's final Step
		Collection_Path__c ppPath = [select Id from Collection_Path__c where Name = 'Payment Plan Path'];
		Collection_Step__c finalStep_PP = new Collection_Step__c (name = Constants.CompletionStepName_PaymentPlan, Collection_Path__c = ppPath.id, Days_on_this_step__c = 3, 
															Step_type__c = Constants.CollectionStepType_Wait, Sequence__c = 2, is_Default_Next_Step__c = false);
		insert finalStep_PP;
		
		system.debug(finalStep_PP.Collection_Path__c + ' - ' + ba.Current_Treatment_Path__c);
		
		ba.Current_Treatment_Path__c = ppPath.Id;
		ba.Action_Date__c = Date.today();
		ba.Current_Treatment_Step__c = finalStep_PP.Id;
		update ba;
		
		//Now run batch
		
		Test.startTest();
		
		PaymentPlanAndP2PClosureBatch testBatch = new PaymentPlanAndP2PClosureBatch();
		ID testBatchPID = Database.executeBatch(testBatch); 	
		
		Test.stopTest();
		
		//Retrieve and check PP closed
		Payment_Plan__c retrievedPP = [select Status__c from Payment_Plan__c where Id = :pp.Id];
		system.assertEquals(Constants.PaymentPlanStatus_Closed, retrievedPP.Status__c);
	}
		
	public static testmethod void testBatch_WithAccountWithP2PInFinalStep_P2PClosed(){
		
		TestHelper.createCollectionSettings(6);
		
		// Another BA with an open P2P
		Billing_Account__c ba2 = TestHelper.createBillingAccount();
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba2.Id, Status__c = Constants.PaymentPlanStatus_Open, 
						Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000);
		insert p2p;
		
		//Createb P2P's final Step
		Collection_Path__c p2pPath = [select Id from Collection_Path__c where Name = 'P2P 1'];
		Collection_Step__c finalStep_P2P = new Collection_Step__c (name = Constants.CompletionStepName_PromiseToPay, Collection_Path__c = p2pPath.id, Days_on_this_step__c = 3, 
															Step_type__c = Constants.CollectionStepType_Wait, Sequence__c = 2, is_Default_Next_Step__c = false);
		insert finalStep_P2P;
		
		ba2.Current_Treatment_Path__c = p2pPath.Id;
		ba2.Action_Date__c = Date.today();
		ba2.Current_Treatment_Step__c = finalStep_P2P.Id;
		update ba2;
		
		//Now run batch
		
		Test.startTest();
		
		PaymentPlanAndP2PClosureBatch testBatch = new PaymentPlanAndP2PClosureBatch();
		ID testBatchPID = Database.executeBatch(testBatch); 	
		
		Test.stopTest();
		
		//Retrieve and check P2P closed
		Promise_to_Pay__c retrievedP2P = [select Status__c from Promise_to_Pay__c where Id = :p2p.Id];
		system.assertEquals(Constants.PaymentPlanStatus_Closed, retrievedP2P.Status__c);
	}

}