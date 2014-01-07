@isTest
private class TestPaymentPlanTriggers {
	
	static testmethod void testAfterInsert_WithOpenStatus_CollectionsCaseCreated() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp;
		
		//Assert
		
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		system.assertEquals(1, cases.size());
		system.assertEquals(Constants.CaseRecordType_Collection, cases[0].Record_Type_Name__c);
	}
	
	static testmethod void testAfterInsert_WithSavedStatus_NoCollectionsCaseCreated() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Saved, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp;
		
		//Assert
		
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		system.assertEquals(0, cases.size());
	}
	
	/* 
	 * Mimicks approval process of Payment Plan
	 */
	static testmethod void testAfterUpdate_ToOpenStatus_CollectionsCaseCreatedAndEmailSent() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Saved, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp;
		
		pp.Status__c = Constants.PaymentPlanStatus_Open;
		
		Test.startTest();
		update pp;
		Test.stopTest();
		
		//Assert
		
		List<Case> cases = [select Id, Record_Type_Name__c from Case where Billing_Account__c = :ba.Id];
		system.assertEquals(1, cases.size());
		system.assertEquals(Constants.CaseRecordType_Collection, cases[0].Record_Type_Name__c);
	}
	
	static testmethod void testBeforeUpdate_WithOpenOrClosedStatus_CannotBeModified() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp;
		
		pp.Date_of_First_Installment__c = Date.today().addDays(1);
		
		Test.startTest();
		try {
			update pp;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('You don\'t have the permission to edit Open or Closed Payment Plans') > 0);
		}
		Test.stopTest();
	}
	
	static testmethod void testBeforeInsert_WithExistingActivePP_ErrorThrown() {
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		//By 'Active' status we mean anything but 'Closed'
		Payment_Plan__c pp1 = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp1;
		
		Payment_Plan__c pp2 = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		try {
			insert pp2;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('Only 1 Open, Saved or Pending Approval Payment Plan can exist for a Billing Account') > 0);
		}	
	}
	
	static testmethod void testBeforeInsert_WithActivePPInLast6Months_ErrorThrown() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		//By 'Active' status we mean anything but 'Closed'
		Payment_Plan__c pp1 = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Closed, 
							Date_of_First_Installment__c = Date.today(), Last_Due_Date__c = Date.today().addDays(-30), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		insert pp1;
		
		Payment_Plan__c pp2 = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		try {
			insert pp2;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('A Payment Plan was setup in the last 6 months.') > 0);
		}	
	}
	
	static testmethod void testBeforeInsert_WithExistingActivePromiseToPay_ErrorThrown() {
		
		//Create Custom Setting
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', Brand__c='AOL', CURRENT_OVERDUE__c = 300, Billing_Day_in_Month__c = Date.today().day(), Unbilled_Amount__c = 20, Call_Limit__c = 25, Exposure_Value__c = 120);
		insert ba;
		
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		//Create an active P2P
		Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, Proposed_Payment_Date__c = Date.today(), Amount_Due__c = 1000);
		insert p2p;
		
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email);
		try {
			insert pp;
		}
		catch (Exception ex) {
			 System.assert(ex.getMessage().indexOf('It is not possible to have a Payment Plan if a Promise to Pay is active/open') > 0);
		}	
	}

}