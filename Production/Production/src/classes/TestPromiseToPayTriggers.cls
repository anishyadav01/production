@isTest
private class TestPromiseToPayTriggers {
	
	static testmethod void testBeforeUpdate_WithOpenOrClosedStatus_CannotBeModified() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Billing_Day_in_Month__c = Date.today().day(), Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
						Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, 	One_off_Payment__c = 100);
		insert p2p;
		
		// ------ EP testing 08/10/2013
		Billing_Account__c testBA = [select Id, Current_Treatment_path__c from Billing_Account__c where Id = :ba.Id];
		system.assert(testBA.Current_Treatment_path__c != null);
		///////////////
		
		
		
		Payment__c payment = new Payment__c();
		payment.Billing_Account__c = ba.id;
		payment.Payment_Source_Code__c = 6;
		payment.Payment_ID__c = '124124124';
		payment.Amount__c = 500;
		
		Payment__c payment1 = new Payment__c();
		payment1.Billing_Account__c = ba.id;
		payment1.Payment_Source_Code__c = 6;
		payment1.Payment_ID__c = '1241241242';
		payment1.Amount__c = 500;
		
		List<Payment__c> payments = new List<Payment__c>{payment, payment1};
		
		insert payments;
		
		
		p2p.Proposed_Payment_Date__c = Date.today().addDays(1);
		
		Test.startTest();
		try {
			update p2p;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('You don\'t have the permission to edit Open or Closed Promises to Pay.') > 0);
		}
		Test.stopTest();
	}
	
	/* 
	 * Mimicks approval process of Promise To Pay
	 */
	static testmethod void testAfterUpdate_ToOpenStatus_CollectionsCaseCreatedAndEmailSent() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		TestHelper.createCollectionSettings(6);
		
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', Billing_Day_in_Month__c = Date.today().day(), CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, 
			Exposure_Value__c = 120, DAYS_61_90__c = 100);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		insert p2p; //should be saved as 'Saved'
		
		p2p.Status__c = Constants.PaymentPlanStatus_Open;
		
		Test.startTest();
		update p2p;
		Test.stopTest();
		
		//Assert
		
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		system.assertEquals(1, cases.size());
		system.assertEquals(Constants.CaseRecordType_Collection, cases[0].Record_Type_Name__c);
	}

	static testmethod void testBeforeInsert_WithNoAgedDebt_StatusSetToOpenAndCaseCreated() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', Billing_Day_in_Month__c = Date.today().day(), CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			 Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		insert p2p;
		
		//Retrieve and assert
		Promise_to_Pay__c savedP2P = [select Id, Status__c from Promise_to_Pay__c where Billing_Account__c = :ba.Id LIMIT 1];
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		
		system.assertEquals(Constants.PaymentPlanStatus_Open, savedP2P.Status__c);
		system.assertEquals(1, cases.size());
		system.assertEquals(Constants.CaseRecordType_Collection, cases[0].Record_Type_Name__c);
	}
	
	static testmethod void testBeforeInsert_WithAgedDebt6190_StatusSetToSavedAndNoCaseCreated() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, 
						Billing_Day_in_Month__c = Date.today().day(), Exposure_Value__c = 120, DAYS_61_90__c = 100);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			 Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		insert p2p;
		
		//Retrieve and assert
		Promise_to_Pay__c savedP2P = [select Id, Status__c from Promise_to_Pay__c where Billing_Account__c = :ba.Id LIMIT 1];
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		
		system.assertEquals(Constants.PaymentPlanStatus_Saved, savedP2P.Status__c);
		system.assertEquals(0, cases.size());
	}
	
	static testmethod void testBeforeInsert_WithActiveP2PInLast6Months_ErrorThrown() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, 
						Billing_Day_in_Month__c = Date.today().day(), Exposure_Value__c = 120, DAYS_61_90__c = 100);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
        
		//Create historical P2P
		Promise_to_Pay__c p2p1 = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			 Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		insert p2p1;
		
		p2p1.Status__c = Constants.PaymentPlanStatus_Closed;
		update p2p1;
		
		// Create new P2P
		Promise_to_Pay__c p2p2 = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			Proposed_Payment_Date__c = Date.today(), Amount_Due__c = 1000, One_off_Payment__c = 100);
		
		try {
			insert p2p2;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('A Promise To Pay was setup in the last 6 months') > 0);
		}	
	}
	
	static testmethod void testBeforeInsert_WithExistingActiveP2P_ErrorThrown() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, 
						Billing_Day_in_Month__c = Date.today().day(), Exposure_Value__c = 120, DAYS_61_90__c = 100);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Promise_to_Pay__c p2p1 = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		insert p2p1;
		
		// Create new P2P
		Promise_to_Pay__c p2p2 = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000, One_off_Payment__c = 100);
		
		try {
			insert p2p2;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('Only 1 Active Promise To Pay can exist for a Billing Account') > 0);
		}	
	}
	
	static testmethod void testBeforeInsert_WithExistingActivePaymentPlan_ErrorThrown() {
		
		//Create Custom Setting
		//Collections_Settings__c cs = createCollectionSettings();
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, 
						Billing_Day_in_Month__c = Date.today().day(), Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
        
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today());
		insert pp;
		
		// Create new P2P
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
			 Proposed_Payment_Date__c = Date.today().addDays(2), Amount_Due__c = 1000);
		
		try {
			insert p2p;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('It is not possible to have a P2P if a Payment Plan is active/open') > 0);
		}	
	}
	
	static Collections_Settings__c createCollectionSettings() {
		Collection_Path__c cp = new Collection_Path__c(Name = 'P2P Path', Active__c = true);
		insert cp; 
		
		Collections_Settings__c cs = new Collections_Settings__c(Approval_Term_Threshold__c = 6, 
																	Payment_Plan_Path__c = 'Payment Plan', //doesn't matter
																	PP_Call_Limit__c = 10,
																	P2P_Path_for_30_60d_Debt__c = cp.Name, //doesn't matter
																	P2P_Path_for_Less_than_30d_Debt__c = cp.Name,
																	PTP_Confirmation_Email_Template_AOL__c = 'A Template 1' , //doesn't matter 
																	PTP_Confirmation_Email_Template_TT__c = 'A Template 2', //doesn't matter
																	PA_Confirmation_Email_Template_AOL__c = 'A Template 3', //doesn't matter
																	PA_Confirmation_Email_Template_TT__c = 'A Template 4'); //doesn't matter;
		insert cs;
		
		return cs;
	}


}