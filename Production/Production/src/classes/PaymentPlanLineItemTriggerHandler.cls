public with sharing class PaymentPlanLineItemTriggerHandler {
	
	public static void handleAfterInsert(Map<Id, Payment_Plan_Line_Item__c> newPPLImap, No_Triggers__c notriggers) { 
	
		// If Payment Plan Status is 'Open', then send an Email or Letter Communication
		//EP 10/10/2013: Only send an Email comm if Preferred Comm Method is Email and an Email has been provided on the Primary Contact.
		
		//get unique PP Ids for Open PPs
		Set<Id> ppIds = new Set<Id>();
		
		for (Payment_Plan_Line_Item__c ppli : newPPLImap.values()) { 
			ppIds.add(ppli.Payment_Plan__c);
		}
		
		List<CommunicationInfo> commInfos = new List<CommunicationInfo>();
		Set<Id> billingAccountsToGenerateLetterTaskFor = new Set<Id>();
		
		//retrieve PPs to check Status
		List<Payment_Plan__c> newPPs = database.query('select Id, Status__c, Billing_Account__c, Preferred_Communication_Method__c, Billing_Account__r.Primary_Contact__r.Email, ' + 
        												SObjectHelper.getFieldListForSOQL('Billing_Account__c', 'Billing_Account__r.') + 
        												' from Payment_Plan__c where Id in :ppIds');
		
		for (Payment_Plan__c newPP : newPPs) {
			if (newPP.Status__c == Constants.PaymentPlanStatus_Open) {
				
				//EP: only send email if Preferred Comm Method is Email and Email is provided (10/10/2013)
				if (newPP.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Email && newPP.Billing_Account__r.Primary_Contact__r.Email != null) {
					commInfos.add(new CommunicationInfo(newPP.Billing_Account__r, Enums.PA_Type.PP, newPP.Id));
				}
				else if (newPP.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Letter)  {
					//billingAccountsToGenerateLetterTaskFor.add(newPP.Billing_Account__c);
				}
				
				
				/* TEMP send emails for all until further notice re Letters: commented out 10/10/2013
				commInfos.add(new CommunicationInfo(newPP.Billing_Account__r, Enums.PA_Type.PP, newPP.Id));
				end TEMP */
				
			}
		}
		
		system.debug('>>>>>>>>>>>>>>>> notriggers = '+notriggers);
		system.debug('>>>>>>>>>>>>>>>> !notriggers.Skip_PP_Setup_Communication__c = '+!notriggers.Skip_PP_Setup_Communication__c);
		
		//Send Email comm where applicable
		if (notriggers == null || !notriggers.Skip_PP_Setup_Communication__c) {
	 		try {
 				CommunicationHelper.sendEmail( commInfos, Constants.DefaultEmailFromAddress_CollectionsPPandP2PConfirmation );
 				system.debug('***** sending Communication');
        	}
        	catch (Exception e) {
        		system.debug('***** error in Communication');
        		newPPLImap.values()[0].addError(e.getMessage());
        	}
        }
		
		/* EP commented out on 13/09 as Letter communication on hold at the moment
		
		//Retrieve Collection Cases for the above Billing Accounts, required for Task creation
        List<Case> newCollectionCases = [select Id, Billing_Account__c from Case 
        								where Billing_Account__c in :billingAccountsToGenerateLetterTaskFor]; //and RecordTypeId = 
        Map<Id, Id> billAccountToCollectionCaseMap = new Map<Id, Id>();
        
        for (Case nc : newCollectionCases) {
        	billAccountToCollectionCaseMap.put(nc.Billing_Account__c, nc.Id);
        }
        
        //Generate Letter Tasks where applicable
        CommunicationHelper.createLetterTasks(billAccountToCollectionCaseMap);
		*/
	}
	
	public static void handleBeforeInsert(List<Payment_Plan_Line_Item__c> newPPLIs) {}
	
	public static void handleBeforeUpdate(Map<Id, Payment_Plan_Line_Item__c> oldPPLImap, Map<Id, Payment_Plan_Line_Item__c> newPPLImap) {}
	
	public static void handleAfterUpdate(map<Id, Payment_Plan_Line_Item__c> oldPPLImap, map<id, Payment_Plan_Line_Item__c> newPPLImap) {
		
		 List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
		 //Get Billing Accounts of all the updated Line Items
		 Set<Id> billAccountIds = new Set<Id>();
		 	
		for (Payment_Plan_Line_Item__c newLi : newPPLImap.values()) {
			billAccountIds.add(newLi.Billing_Account__c);
		}
		
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c> ((List<Billing_Account__c>)database.query('select ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billAccountIds'));
        Map<Id, List<Payment_Plan_Line_Item__c>>  billingAccountToPPLinesMap = new Map<Id, List<Payment_Plan_Line_Item__c>>();
                                                      
        //If 95% or more of payment due has been paid, call method
		for (Payment_Plan_Line_Item__c newLi : newPPLImap.values()) {
			Payment_Plan_Line_Item__c oldLi = oldPPLImap.get(newLi.Id);
			
			if (newLi.Amount_Paid__c != oldLi.Amount_Paid__c && newLi.Amount_Paid__c >= Collections_Settings__c.getInstance(UserInfo.getUserId()).Payment_Acceptable_Tolerance__c  * newLi.Amount__c) {
				if(billingAccountToPPLinesMap.containsKey(newLi.Billing_Account__c)){
						List<Payment_Plan_Line_Item__c> paymentLines = billingAccountToPPLinesMap.get(newLi.Billing_Account__c);
						paymentLines.add(newLi);
						billingAccountToPPLinesMap.put(newLi.Billing_Account__c, paymentLines);  
						
					}else{
						List<Payment_Plan_Line_Item__c> paymentList = new List<Payment_Plan_Line_Item__c>{newLi};
						billingAccountToPPLinesMap.put(newLi.Billing_Account__c, paymentList);
					}
			}
		} 
		
		Set<Id> billingAccIds = billingAccountToPPLinesMap.keySet();
		
		for(Id billingAccId : billingAccIds){
			List<Payment_Plan_Line_Item__c> paymentLines = billingAccountToPPLinesMap.get(billingAccId);
			if(paymentLines.size() == 1){
				CollectionAccountInfo colInfo = new CollectionAccountInfo( billingAccountsMap.get( paymentLines[0].Billing_Account__c ) );
				colInfo.action = Constants.CollectionStepAction_Payment;
				colInfo.nextPaymentDueDate = paymentLines[0].Next_Payment_Due_Date__c;
				if(paymentLines[0].Next_Payment_Due_Date__c != null){
					colInfo.instalmentNumber = Integer.valueOf(paymentLines[0].Sequence__c+1);
				}
				colInfo.numberOfInstalments = 1;
				collInfos.add( colInfo );
			}else{
				Integer countLines = 0;
				Payment_Plan_Line_Item__c lastPPLine = paymentLines[0];	
				for(Payment_Plan_Line_Item__c paymentLine : paymentLines){
					countLines = countLines + 1;
					if(paymentLine.Sequence__c > lastPPLine.Sequence__c){
						lastPPLine = paymentLine;
					}
				}
				CollectionAccountInfo colInfo = new CollectionAccountInfo( billingAccountsMap.get( lastPPLine.Billing_Account__c ) );
				colInfo.action = Constants.CollectionStepAction_Payment;
				colInfo.nextPaymentDueDate = lastPPLine.Next_Payment_Due_Date__c;
				if(lastPPLine.Next_Payment_Due_Date__c != null){
					colInfo.instalmentNumber = Integer.valueOf(lastPPLine.Sequence__c+1);
				}
				colInfo.numberOfInstalments = countLines;
				collInfos.add( colInfo );
			}
		}
		                                               
        system.debug('-------PaymentPlanLineItemTriggerHandler----collInfos.size()-' + collInfos.size());
		//UNCOMMENT!!!
		if ( collInfos.size() > 0 ){
			system.debug('-------PaymentPlanLineItemTriggerHandler----collInfos.size()-' + collInfos.size());
			CollectionsEventHandler.processPaymentReceivedInBulk( collInfos );
		}
		
	}
	
	/*
	public static void handleAfterUpdate(map<Id, Payment_Plan_Line_Item__c> oldPPLImap, map<id, Payment_Plan_Line_Item__c> newPPLImap) {
		
		 List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
		 List<Id> paymentPlansToClose = new List<Id>();		 
		 
		 //Get Billing Accounts of all the updated Line Items
		 Set<Id> billAccountIds = new Set<Id>();
		 	
		for (Payment_Plan_Line_Item__c newLi : newPPLImap.values()) {
			billAccountIds.add(newLi.Billing_Account__c);
		}
		
		Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c> ((List<Billing_Account__c>)database.query('select ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billAccountIds'));
                                                        
        
        //If 95% or more of payment due has been paid, call method
		for (Payment_Plan_Line_Item__c newLi : newPPLImap.values()) {
			Payment_Plan_Line_Item__c oldLi = oldPPLImap.get(newLi.Id);
			
			if (newLi.Amount_Paid__c != oldLi.Amount_Paid__c && newLi.Amount_Paid__c >= Collections_Settings__c.getInstance(UserInfo.getUserId()).Payment_Acceptable_Tolerance__c  * newLi.Amount__c) {
				CollectionAccountInfo colInfo = new CollectionAccountInfo( billingAccountsMap.get( newLi.Billing_Account__c ) );
				//if( newLi.Next_Payment_Due_Date__c != null) {
					// still have next payment to accept
					colInfo.action = Constants.CollectionStepAction_Payment;
					colInfo.nextPaymentDueDate = newLi.Next_Payment_Due_Date__c;
					collInfos.add( colInfo );
				//} else {
					// this was the last payment, so close plan 
				//	paymentPlansToClose.add( newLi.Payment_Plan__c );
				//}				
			}
		}                                                
        system.debug('-------PaymentPlanLineItemTriggerHandler----collInfos.size()-' + collInfos.size());
		//UNCOMMENT!!!
		if ( collInfos.size() > 0 ){
			system.debug('-------PaymentPlanLineItemTriggerHandler----collInfos.size()-' + collInfos.size());
			CollectionsEventHandler.processPaymentReceivedInBulk( collInfos );
		}
		system.debug('-------PaymentPlanLineItemTriggerHandler----paymentPlansToClose.size()-' + paymentPlansToClose.size());
		if ( paymentPlansToClose.size() > 0 ){
			PaymentPlanPromise2PayHelper.closePaymentPlansInBulk( paymentPlansToClose );
		}
	
	}*/

}