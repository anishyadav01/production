@isTest
private class TestPaymentPlanLineItemTriggers {
	
	static testmethod void afterUpdate_AmountPaidInPart_processPaymentReceived() {
		
		TestHelper.createCollectionSettings(6);
		
		Billing_Account__c ba = TestHelper.createBillingAccount();
		
		Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, 
							Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email,
							Number_of_Installments__c = 3);
		insert pp;
		
		List<Payment_Plan_Line_Item__c> pplis = new List<Payment_Plan_Line_Item__c>();
		
		pplis.add(new Payment_Plan_Line_Item__c(Payment_Plan__c = pp.Id, Name = 'Payment 1', Amount__c = 120, Due_Date__c = Date.today(), Next_Payment_Due_Date__c = Date.today().addDays(15)));
		pplis.add(new Payment_Plan_Line_Item__c(Payment_Plan__c = pp.Id, Name = 'Payment 2', Amount__c = 120, Due_Date__c = Date.today().addDays(15), Next_Payment_Due_Date__c = Date.today().addDays(30)));
		pplis.add(new Payment_Plan_Line_Item__c(Payment_Plan__c = pp.Id, Name = 'Payment 3', Amount__c = 120, Due_Date__c = Date.today().addDays(30), Next_Payment_Due_Date__c = null));
		
		insert pplis;
		
		//pplis[0].Amount_Paid__c = pplis[0].Amount__c * 0.1;
		//pplis[0].Payment_Date__c = Date.today();
		//pplis[0].Next_Payment_Due_Date__c = Date.today().addDays(15);
		
		Test.startTest();
		Payment__c payment = new Payment__c();
		payment.Billing_Account__c = ba.id;
		payment.Payment_Source_Code__c = 6;
		payment.Payment_ID__c = '124124124';
		payment.Amount__c = pplis[0].Amount__c * 0.1;
		
		Payment__c payment1 = new Payment__c();
		payment1.Billing_Account__c = ba.id;
		payment1.Payment_Source_Code__c = 6;
		payment1.Payment_ID__c = '1241241242';
		payment1.Amount__c = pplis[1].Amount__c * 0.1;
		
		List<Payment__c> payments = new List<Payment__c>{payment, payment1};
		
		insert payments;
		//update pplis[0];
		
		//DataBase.executeBatch(new PaymentAllocationBatch());
		CollectionBatchStartContoller con = new CollectionBatchStartContoller();
		con.startJob();
		
		Test.stopTest();
		
	}

}