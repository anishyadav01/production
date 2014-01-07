public class PaymentPlanTriggerHandler {


	 public static void handleAfterInsert(Map<Id, Payment_Plan__c> newPPMap) { 
	 
	 	// If a PP is saved with Status 'Open', then a Case of type 'Collection' should be created
	 	//Get Collection Setting
	 	
	 	//EP 02/10/2013: If a Preferred Email has been provided, override the Primary Contact's email address. This is to ensure that
	 	//the email notification will be sent to this email address. Cannot explicitly set an ad hoc email address when the email uses a template..
	 	
	 	Id paymentPathId;
	 	
        //Collections_Settings__c collSettings = Collections_Settings__c.getInstance(UserInfo.getUserId());
        
        CustomSettingsUtility.PaymentArrangementCollectionPathSettings paPathSettings = CustomSettingsUtility.getPaymentArrangementCollectionPathSettings();
        
        if (paPathSettings != null && !String.isEmpty(paPathSettings.paymentPlanPathId)) {
        	paymentPathId = paPathSettings.paymentPlanPathId;
        }
        
	 	Map<Id, Id> billingAccountToPaymentPathMap = new Map<Id, Id>();
	 	Map<Id, Payment_Plan__c> billingAccountToPPMap = new Map<Id, Payment_Plan__c>(); 
	 
	 	for (Payment_Plan__c newPP : newPPMap.values()) {
	 		if (newPP.Status__c == Constants.PaymentPlanStatus_Open) { // ------- Only if Open!!!
	 			billingAccountToPaymentPathMap.put(newPP.Billing_Account__c, paymentPathId);
	 			billingAccountToPPMap.put(newPP.Billing_Account__c, newPP);
	 		}
	 	}
	 	
	 	Set<Id> billingAccountIds = billingAccountToPaymentPathMap.keyset();
	 	List<Billing_Account__c> billingAccountsForPPs = database.query('select Primary_Contact__r.Id, Primary_Contact__r.Email, ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billingAccountIds');
                                                        
        List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
        List<CommunicationInfo> commInfos = new List<CommunicationInfo>();
        
        List<Contact> primaryContactsToUpdate = new List<Contact>(); //update Primary Contact's email if supplied
        
        for (Billing_Account__c ba : billingAccountsForPPs) { 
        	
        	// --- Construct Collection Info ---
        	system.debug('***** Payment Path Id passed: ' + billingAccountToPaymentPathMap.get(ba.Id));
        	CollectionAccountInfo colInfo = new CollectionAccountInfo(ba);
        	colInfo.pathId = billingAccountToPaymentPathMap.get(ba.Id);
        	colInfo.nextPaymentDueDate = billingAccountToPPMap.get(ba.Id).Date_of_First_Installment__c;
        	
        	collInfos.add( colInfo );
        	
        	// ---- Get Primary Contacts for email update ---   //added 03/10/2013
        	if (!String.isEmpty(newPPMap.get(billingAccountToPPMap.get(ba.Id).Id).Preferred_Email__c) && ba.Primary_Contact__r != null) {
        		ba.Primary_Contact__r.Email = newPPMap.get(billingAccountToPPMap.get(ba.Id).Id).Preferred_Email__c;
        		primaryContactsToUpdate.add(ba.Primary_Contact__r);
        	}
        }
        
        if (primaryContactsToUpdate.size() > 0) {
        	update primaryContactsToUpdate;
        }
        
        PathHandler.assignPathsInBulk(collInfos);
	 }
	 
	 
	 public static void handleBeforeInsert(List<Payment_Plan__c> newPPs) {
	 
	 	// Only 1 non Closed PP can exist per Billing Account
	 	// // EP removed 27/09: (A PP cannot be setup if another PP was concluded in the last 6 months (based on last Due Date field))
	 	// It is not possible to have a Payment Plan if a P2P is active/open
	 	
	 	Set<Id> billingAccountIds = new Set<Id>();
	 	for (Payment_Plan__c pp : newPPs) {
	 		billingAccountIds.add(pp.Billing_Account__c);
	 	}
	 	
	 	List<Payment_Plan__c> existingPPsForBillingAccounts = [select Id, Name, Status__c, Last_Due_Date__c, Billing_Account__c
	 															from Payment_Plan__c
                                                    			where Billing_Account__c in :billingAccountIds];
                                                    			
        List<Promise_to_Pay__c> notClosedP2PsForBillingAccount = [select Id, Name, Billing_Account__c
                                                                  from Promise_to_Pay__c
                                                                  where Billing_Account__c in :billingAccountIds and 
                                                                        Status__c != :Constants.PaymentPlanStatus_Closed];
                                                    				
        Map<Id, List<Payment_Plan__c>> notClosedPPsPerBillingAccount = new Map<Id, List<Payment_Plan__c>>();
        Map<Id, List<Payment_Plan__c>> recentPPsPerBillingAccount = new Map<Id, List<Payment_Plan__c>>();
        Map<Id, List<Promise_to_Pay__c>> notClosedP2PsPerBillingAccountMap = new Map<Id, List<Promise_to_Pay__c>>();
        
        //Populate map of Billing Account to existing not Closed P2P
		for (Promise_to_Pay__c existingP2P : notClosedP2PsForBillingAccount) {
        	if (!(notClosedP2PsPerBillingAccountMap.containsKey(existingP2P.Billing_Account__c))) {
        		notClosedP2PsPerBillingAccountMap.put(existingP2P.Billing_Account__c, new List<Promise_to_Pay__c> {existingP2P});
        	}
        	else {
        		notClosedP2PsPerBillingAccountMap.get(existingP2P.Billing_Account__c).add(existingP2P);
        	}
    	}
        
        //Populate maps of Billing Account to Open PPs and Billing Account to recent (6months) PPs
        for (Payment_Plan__c existingPP : existingPPsForBillingAccounts) {
        	if (existingPP.Status__c != Constants.PaymentPlanStatus_Closed) {
        		//add to 'Not Closed PPs' map
	        	if (!(notClosedPPsPerBillingAccount.containsKey(existingPP.Billing_Account__c))) {
	        		notClosedPPsPerBillingAccount.put(existingPP.Billing_Account__c, new List<Payment_Plan__c> {existingPP});
	        		system.debug('****** existing PP found for ' + existingPP.Billing_Account__c);
	        	}
	        	else {
	        		notClosedPPsPerBillingAccount.get(existingPP.Billing_Account__c).add(existingPP);
	        		system.debug('****** existing PP found for ' + existingPP.Billing_Account__c);
	        	}
        	}
        	
        	/* 27/09: EP commented out as requested during UAT
        	//The 'else' assumes that a finished plan will be set to 'Closed' by some process
        	else if (existingPP.Last_Due_Date__c > Date.today().addMonths(-6) && existingPP.Last_Due_Date__c < Date.today()){
        		//add to 'recent PPs' map
	        	if (!(recentPPsPerBillingAccount.containsKey(existingPP.Billing_Account__c))) {
	        		recentPPsPerBillingAccount.put(existingPP.Billing_Account__c, new List<Payment_Plan__c> {existingPP});
	        		system.debug('****** existing PP found for ' + existingPP.Billing_Account__c);
	        	}
	        	else {
	        		recentPPsPerBillingAccount.get(existingPP.Billing_Account__c).add(existingPP);
	        		system.debug('****** existing PP found for ' + existingPP.Billing_Account__c);
	        	}
        	}
        	*/
        }
        
        //For every inserted PP, check if its Billing Account already has either not-closed PPs or recent(6 months) PPs
        for (Payment_Plan__c newPP : newPPs) {
        	if (notClosedPPsPerBillingAccount.containsKey(newPP.Billing_Account__c)) {
        		newPP.addError('Only 1 Open, Saved or Pending Approval Payment Plan can exist for a Billing Account');
        	}
        	else if (notClosedP2PsPerBillingAccountMap.containsKey(newPP.Billing_Account__c)) {
        		newPP.addError('It is not possible to have a Payment Plan if a Promise to Pay is active/open');
        	}
        	
        	/* 27/09: EP commented out as requested during UAT
        	else if (recentPPsPerBillingAccount.containsKey(newPP.Billing_Account__c)) {
        		newPP.addError('A Payment Plan was setup in the last 6 months.');
        	}
        	*/
        }
	 }
	 
	 public static void handleBeforeUpdate(Map<Id, Payment_Plan__c> oldPPMap, Map<Id, Payment_Plan__c> newPPMap) {
	 	List<ID> ppIds = new List<ID>();
	 	for (Payment_Plan__c newPP : newPPMap.values()) {
	 		ppIds.add(newPP.id);
	 	}
	 	
	 	List<Payment_Plan_Line_Item__c> pplines = [Select p.Payment_Plan__c, p.Amount_Paid__c From Payment_Plan_Line_Item__c p where p.More_than_95_paid__c = true and p.Payment_Plan__c in :ppIds];
	 	Map<Id,Boolean> modifiedLineMap = new Map<Id,Boolean>();
	 	
	 	for(Payment_Plan_Line_Item__c ppline: pplines){
	 		modifiedLineMap.put(ppline.Payment_Plan__c, true);
	 	}
	 	
	 	//Once a Payment Plan has Status 'Open/Closed', it cannot be modified. Had to be done in a trigger as the 'Close' btn updates the Status to 'Closed'
	 	for (Payment_Plan__c newPP : newPPMap.values()) {
            Payment_Plan__c oldPP = oldPPMap.get(newPP.Id);
            
            system.debug('******* Flag is ' + SystemUpdateFlags.NoCheckForPaymentPlanModification);
            
            if(!SystemUpdateFlags.NoCheckForPaymentPlanModification && oldPP.Total_Paid__c == newPP.Total_Paid__c && modifiedLineMap.containsKey(oldPP.id) && modifiedLineMap.get(oldPP.id)){
            	newPPMap.values()[0].addError('You cant\'t modify a Payment Plan where payment has been collected.');
            }
            
	 	//	if ( !SystemUpdateFlags.NoCheckForPaymentPlanModification && 
	 		//		(oldPP.Status__c == Constants.PaymentPlanStatus_Open || oldPP.Status__c == Constants.PaymentPlanStatus_Closed)) {
	 			if ( !SystemUpdateFlags.NoCheckForPaymentPlanModification && oldPP.Status__c == Constants.PaymentPlanStatus_Closed) {
	 					
	 					system.debug('******* old status is ' + oldPP.Status__c + ' condition true');
        			newPPMap.values()[0].addError('You can\'t modify closed Payment Plans.');
        	}
	 	}
	 }
	 
	 public static void handleAfterUpdate(map<Id, Payment_Plan__c> oldPPMap, map<id, Payment_Plan__c> newPPMap, No_Triggers__c notriggers) {
	 
	 	 // If a PP Status has been updated to 'Open' (via Approval Process), then a Case of type 'Collection' should be created
	 	 // and an email/letter communication sent
	 	 
	 	 //EP 02/10/2013: If a Preferred Email has been provided, override the Primary Contact's email address. This is to ensure that
	 	//the email notification will be sent to this email address. Cannot explicitly set an ad hoc email address when the email uses a template..
	 	
	 	//EP 10/10/2013: Only send an Email comm if Preferred Comm Method is Email and an Email has been provided on the Primary Contact.
	 	
	 	Id paymentPathId;
	 	
        //Collections_Settings__c collSettings = Collections_Settings__c.getInstance(UserInfo.getUserId());
        
        CustomSettingsUtility.PaymentArrangementCollectionPathSettings paPathSettings = CustomSettingsUtility.getPaymentArrangementCollectionPathSettings();
        
        if (paPathSettings != null && !String.isEmpty(paPathSettings.paymentPlanPathId)) {
        	paymentPathId = paPathSettings.paymentPlanPathId;
        }
        
        Set<Id> billingAccountIds = new Set<Id>();
        Set<Id> billingAccountIdsForApprovedPPs = new Set<Id>();
	 	Map<Id, Id> billingAccountToPaymentPathMap = new Map<Id, Id>(); // for assigning Paths
	 	Map<Id, Payment_Plan__c> billingAccountToPPMap = new Map<Id, Payment_Plan__c>(); 
	    Map<Id, Id> billingAccountToPaymentPlanMapForEmail = new Map<Id, Id>(); //for sending comms
	    
	    Set<Id> billingAccountsToGenerateLetterTaskFor = new Set<Id>();
	 
	 	for (Payment_Plan__c newPP : newPPMap.values()) {
	 		
	 		billingAccountIds.add(newPP.Billing_Account__c);
	 		billingAccountToPPMap.put(newPP.Billing_Account__c, newPP);
	 		
	 		//if Status has changed to Open (just been approved)
	 		if (newPP.Status__c == Constants.PaymentPlanStatus_Open && oldPPMap.get(newPP.Id).Status__c != Constants.PaymentPlanStatus_Open) {
	 			
	 			system.debug('***** PP Status changed to Open');
	 			
	 			billingAccountIdsForApprovedPPs.add(newPP.Billing_Account__c); // required as only these will trigger CollInfo & CommInfo	
	 			billingAccountToPaymentPathMap.put(newPP.Billing_Account__c, paymentPathId);
	 			
	 			// EP commented out on 13/09 as business not ready re Letter notification functionality. Will stick to Email for now
	 			if (newPP.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Email) {
	 				billingAccountToPaymentPlanMapForEmail.put(newPP.Billing_Account__c, newPP.Id);
	 			}
	 			else if (newPP.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Letter) {
	 				//billingAccountsToGenerateLetterTaskFor.add(newPP.Billing_Account__c);
	 			}
	 			
	 			/* The below is the old temp implementation where an Email Comm was being sent in all cases
	 			billingAccountToPaymentPlanMapForEmail.put(newPP.Billing_Account__c, newPP.Id);
	 			end comment */
	 			
	 		}
	 	}
	 	
	 	List<Contact> primaryContactsToUpdate = new List<Contact>(); //update Primary Contact's email if supplied
	 	
	 	//Set<Id> billingAccountIds = billingAccountToPaymentPathMap.keyset();
	 	List<Billing_Account__c> billingAccountsForUpdatedPPs = database.query('select Primary_Contact__r.Id, Primary_Contact__r.Email, ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billingAccountIds');
                                                        
        List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
        List<CommunicationInfo> commInfos = new List<CommunicationInfo>();
        
        for (Billing_Account__c ba : billingAccountsForUpdatedPPs) {
        	
        	//For all Billing Accounts of updated PPs
        	if (!String.isEmpty(newPPMap.get(billingAccountToPPMap.get(ba.Id).Id).Preferred_Email__c) && ba.Primary_Contact__r != null) {
        		ba.Primary_Contact__r.Email = newPPMap.get(billingAccountToPPMap.get(ba.Id).Id).Preferred_Email__c;
        		primaryContactsToUpdate.add(ba.Primary_Contact__r);
        	}
        	
        	//Only for newly approved ones
        	if (billingAccountIdsForApprovedPPs.contains(ba.Id)) {
	        	
	        	// ----- Generate Case and move path (= create collInfo) for all newly approved PPs --------
	        	CollectionAccountInfo colInfo = new CollectionAccountInfo(ba);
	        	colInfo.pathId = billingAccountToPaymentPathMap.get(ba.Id);
	        	colInfo.nextPaymentDueDate = billingAccountToPPMap.get(ba.Id).Date_of_First_Installment__c;
	
	        	collInfos.add( colInfo );        	
	
	        	// ------- EP included on 10/10/2013: If Preferred Comm Method is Email, create commInfo --------- 
	        	if (billingAccountToPaymentPlanMapForEmail.containsKey(ba.Id) && ba.Primary_Contact__r.Email != null) {
	        		commInfos.add(new CommunicationInfo(ba, Enums.PA_Type.PP, billingAccountToPaymentPlanMapForEmail.get(ba.Id)));
	        	}
        	}
        }
        
        //---- EP 03/10/2013: First update Contacts so that the right email is updated before sending the email comm!
        if (primaryContactsToUpdate.size() > 0) {
        	update primaryContactsToUpdate;
        }
        
        //The following 2 operations only occur for Billing Accounts where the PP has been approved
        if (billingAccountIdsForApprovedPPs.size() > 0) {
        	PathHandler.assignPathsInBulk(collInfos);
        	
        	system.debug('Skip PP Setup Communication is: ' + notriggers.Skip_PP_Setup_Communication__c);
        	
        	if (notriggers == null || !notriggers.Skip_PP_Setup_Communication__c) {
	 			try {
	 				CommunicationHelper.sendEmail( commInfos, Constants.DefaultEmailFromAddress_CollectionsPPandP2PConfirmation );
	 				system.debug('***** sending Communication');
	        	}
	        	catch (Exception e) {
	        		system.debug('***** error in Communication');
	        		newPPMap.values()[0].addError(e.getMessage());
	        	}
        	}
        }
        
        //Retrieve Collection Cases for the above Billing Accounts, required for Task creation
        
        /* EP commented out on 13/09 as Letter communication on hold at the moment
        List<Case> newCollectionCases = [select Id, Billing_Account__c from Case where Billing_Account__c in :billingAccountsToGenerateLetterTaskFor]; //and RecordTypeId = 
        Map<Id, Id> billAccountToCollectionCaseMap = new Map<Id, Id>();
        
        for (Case nc : newCollectionCases) {
        	billAccountToCollectionCaseMap.put(nc.Billing_Account__c, nc.Id);
        }
        
        //Generate Letter Tasks
        CommunicationHelper.createLetterTasks(billAccountToCollectionCaseMap);
        */
	 	
	 } 
	 
}