public class TestHelper {
	
	public static void createCollectionSettings(Integer approvalThreshold) {
		
		Collection_Path__c cp_PP = new Collection_Path__c(Name = 'Payment Plan Path', Active__c = true);
		Collection_Path__c cp_P2P_1 = new Collection_Path__c(Name = 'P2P 1', Active__c = true);
		Collection_Path__c cp_P2P_2 = new Collection_Path__c(Name = 'P2P 2', Active__c = true);
		insert new List<Collection_Path__c> {cp_PP, cp_P2P_1, cp_P2P_2}; 
		
		Collection_Step__c step_PP = new Collection_Step__c (name = 'Step2', Collection_Path__c = cp_PP.id, Days_on_this_step__c = 3, 
															Step_type__c = Constants.CollectionStepType_Wait, Sequence__c = 1, is_Default_Next_Step__c = true);
		insert step_PP;
				
		
		//Create Custom Setting 
			String templateName = 'PP&P2P Template'; 

			Collections_Settings__c cs = new Collections_Settings__c(Approval_Term_Threshold__c = approvalThreshold, 
																		Payment_Plan_Path__c = cp_PP.Name,
																		PP_Call_Limit__c = 10,
																		P2P_Path_for_30_60d_Debt__c = cp_P2P_1.Name, //doesn't matter
																		P2P_Path_for_Less_than_30d_Debt__c = cp_P2P_2.Name, //doesn't matter
																		PTP_Confirmation_Email_Template_AOL__c = templateName , 
																		PTP_Confirmation_Email_Template_TT__c = templateName, 
																		PA_Confirmation_Email_Template_AOL__c = templateName, 
																		PA_Confirmation_Email_Template_TT__c = templateName, 
																		Payment_Acceptable_Tolerance__c = 0.95,
																		Payment_Days_from_Now_Tolerance_Oneoff__c = 31,
																		P2P_Payment_Days_from_Now_Tolerance__c = 21,
																		Payment_Days_from_Now_Tolerance__c = 21,
																		Email_Address_for_Extracted_Data__c = 'bla@test.com');		
		try{
			insert cs;
		} catch ( System.DmlException ex){
			// try upserting again 
			try{
				insert cs;
			} catch ( System.DmlException ex1){
				// ignore 
				insert cs;
			} 		
		} 

	}
		
	
	public static Billing_Account__c createBillingAccount() {
		Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
		Contact primaryContact = new Contact (AccountId = acc.Id, LastName = 'Testius', email='test@test.com');
        insert primaryContact;
        
		Billing_Account__c ba = new Billing_Account__c(Name = 'Test', CURRENT_OVERDUE__c = 300, Account_Balance__c = 300, Unbilled_Amount__c = 20, Call_Limit__c = 25, Brand__c = 'AOL',Account_Id__c = acc.id,
														Exposure_Value__c = 120, Primary_Contact__c = primaryContact.Id, Billing_Day_in_Month__c = 2,DAYS_31_60__c  = 0, DAYS_61_90__c  = 0, 
														DAYS_91_120__c  = 0, DAYS_121_150__c  = 0, DAYS_151_180__c  = 0, DAYS_181_210__c  = 0, 
														DAYS_211_240__c  = 0, DAYS_241_270__c  = 0, DAYS_271_300__c  = 0, DAYS_301_330__c  = 0, DAYS_331_360__c = 0);
		insert ba;
		
		ba = [Select  b.UNBILLED_AMOUNT__c, b.Step_Communication_Type__c, 
		b.Reinstate_Flag__c, b.Promise_to_Pay__c, b.Primary_Contact__c, b.Payment_Defaulted__c, b.Payment_Defaulted_Date__c,  
		b.Next_Treatment_Step__c, b.Next_Bill_Date__c, b.Name, b.Monthly_Recurring_Charge__c, b.MRC__c,Total_Over_Due__c,   
		b.LAST_INVOICE_DATE__c, b.In_Collections__c, Account_Id__c,
		b.Id, b.Exposure_Value__c, b.DAYS_91_120__c, b.DAYS_61_90__c, b.DAYS_331_360__c, b.DAYS_31_60__c, b.DAYS_301_330__c, b.DAYS_271_300__c, 
		b.DAYS_241_270__c, b.DAYS_211_240__c, b.DAYS_181_210__c, b.DAYS_151_180__c, b.DAYS_121_150__c, b.Customer_Status__c, b.Current_Treatment_Step__c, 
		b.Current_Treatment_Path__c, b.CreatedDate, b.CreatedById, b.Call_Limit__c, b.CURRENT_OVERDUE__c, b.Brand__c, 
		b.Billing_Day_in_Month__c, b.Billing_Address__c, b.Balance_Date__c, b.Balance_Amt__c, b.Action_Date__c, b.Account_Key__c, b.Account_Balance__c, 
		b.ACQUISITION_CHANNEL__c From Billing_Account__c b where id = :ba.id];
		
		insert new Asset(Name='TestassetName', AccountId=acc.Id, 	Billing_Account__c=ba.id , Status__c = 'ACTIVE');
		
		return ba;
	}
	
	

}