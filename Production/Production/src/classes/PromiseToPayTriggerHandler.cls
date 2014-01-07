public with sharing class PromiseToPayTriggerHandler {
    static boolean isFirstTime = true; 
	
	public static void handleBeforeInsert (List<Promise_to_Pay__c> newP2Ps) {
	
		// If aged debt is between 61-90 days, then Approval is required. Status will be 'Saved'. Otherwise, 'Open'
		// Also populate the Name by getting the applicable Collection Path from Custom Settings
		// EP removed 27/09: (A Promise to Pay cannot be setup if the customer had a pre-existing Promise to Pay that was active within the last 6 months)
		// Only 1 non Closed P2P can exist per Billing Account
		// It is not possible to have a P2P if a Payment Plan is active/open
		
		//Get Collection Settings for the two P2P Collection Paths
		CustomSettingsUtility.PaymentArrangementCollectionPathSettings paPathSettings = CustomSettingsUtility.getPaymentArrangementCollectionPathSettings();
		
		
        //Collections_Settings__c collSettings = Collections_Settings__c.getInstance(UserInfo.getUserId());
        Id p2pLessThan30DaysDebt = paPathSettings.p2pLessThan30PathId; //collSettings.P2P_Path_for_Less_than_30d_Debt__c;
        Id p2pBetween30And60DaysDebt = paPathSettings.p2p30To60PathId; //collSettings.P2P_Path_for_30_60d_Debt__c;
        
		Map<Id, Collection_Path__c> p2pPaths = new Map<Id, Collection_Path__c> ([select Id, Name from Collection_Path__c 
																					where Id = :p2pLessThan30DaysDebt or Id = :p2pBetween30And60DaysDebt]);
																					
		// Retrieve recent PromisesToPay (last 6 months) for the Billing Account referenced
		Set<Id> billingAccountIds = new Set<Id>();
	 	for (Promise_to_Pay__c p2p : newP2Ps) {
	 		p2p.Proposed_Payment_Date__c = Common.getNextWorkingDay( p2p.Proposed_Payment_Date__c );
	 		billingAccountIds.add(p2p.Billing_Account__c);
	 	}
	 	
	 	List<Asset> assetsList = [Select a.Status__c, a.Billing_Account__c From Asset a where status__c =:'ACTIVE' and a.Billing_Account__c in : billingAccountIds];
	 	Map<Id,Asset> billingAccountWithAssets = new Map<Id,Asset>();
	 	for(Asset asset :  assetsList){
	 		billingAccountWithAssets.put(asset.Billing_Account__c,asset);
	 	}
	 	
		List<Promise_to_Pay__c> p2pForBillingAccount = database.query('select ' + 
                                                            SObjectHelper.getFieldListForSOQL('Promise_to_Pay__c') + 
                                                        ' from Promise_to_Pay__c where Billing_Account__c IN :billingAccountIds');
                                                        
        List<Payment_Plan__c> existingPPsForBillingAccounts = database.query('select ' + 
                                                            SObjectHelper.getFieldListForSOQL('Payment_Plan__c') + 
                                                        ' from Payment_Plan__c where Billing_Account__c IN :billingAccountIds and ' +
                                                        ' Status__c != ' + '\'' +  Constants.PaymentPlanStatus_Closed + '\'');
															 	
		Map<Id, List<Promise_to_Pay__c>> notClosedP2PsPerBillingAccount = new Map<Id, List<Promise_to_Pay__c>>();
		Map<Id, List<Payment_Plan__c>> notClosedPPsPerBillingAccount = new Map<Id, List<Payment_Plan__c>>();
		
		Map<Id, List<Promise_to_Pay__c>> recentP2PsPerBillingAccount = new Map<Id, List<Promise_to_Pay__c>>();		
		
		//Populate map of Billing Account to existing not Closed Payment Plans
		for (Payment_Plan__c existingPP : existingPPsForBillingAccounts) {
        	if (!(notClosedPPsPerBillingAccount.containsKey(existingPP.Billing_Account__c))) {
        		notClosedPPsPerBillingAccount.put(existingPP.Billing_Account__c, new List<Payment_Plan__c> {existingPP});
        	}
        	else {
        		notClosedPPsPerBillingAccount.get(existingPP.Billing_Account__c).add(existingPP);
        	}
    	}
		
		//Populate maps of Billing Account to Open P2Ps and Billing Account to recent (6months) Promises To Pay
		for (Promise_to_Pay__c existingP2P : p2pForBillingAccount) {
			if (existingP2P.Status__c != Constants.PaymentPlanStatus_Closed) {
        		//add to 'Not Closed P2Ps' map
	        	if (!(notClosedP2PsPerBillingAccount.containsKey(existingP2P.Billing_Account__c))) {
	        		notClosedP2PsPerBillingAccount.put(existingP2P.Billing_Account__c, new List<Promise_to_Pay__c> {existingP2P});
	        	}
	        	else {
	        		notClosedP2PsPerBillingAccount.get(existingP2P.Billing_Account__c).add(existingP2P);
	        	}
        	}
        	
        	/* 27/09: EP commented out as requested during UAT
        	//The 'else' assumes that a finished plan will be set to 'Closed' by some process
        	else if (existingP2P.Proposed_Payment_Date__c > Date.today().addMonths(-6) && existingP2P.Proposed_Payment_Date__c < Date.today()){
        		//add to 'recent P2Ps' map
	        	if (!(recentP2PsPerBillingAccount.containsKey(existingP2P.Billing_Account__c))) {
	        		recentP2PsPerBillingAccount.put(existingP2P.Billing_Account__c, new List<Promise_to_Pay__c> {existingP2P});
				}
				else {
					recentP2PsPerBillingAccount.get(existingP2P.Billing_Account__c).add(existingP2P);
				}
        	}
        	*/
		}		
		
		// ---------- Now loop through the new items, validate, and populate values  ---------------
		
		// A P2P cannot be setup if another P2P was active in the last 6 months (based on last Due Date field)
		for (Promise_to_Pay__c newP2P : newP2Ps) {
			// Validations
			if (notClosedP2PsPerBillingAccount.containsKey(newP2P.Billing_Account__c)) {
        		newP2P.addError('Only 1 Active Promise To Pay can exist for a Billing Account');
        	}
        	else if (notClosedPPsPerBillingAccount.containsKey(newP2P.Billing_Account__c)) {
        		newP2P.addError('It is not possible to have a P2P if a Payment Plan is active/open');
        	}
        	
        	/* 27/09: EP commented out as requested during UAT
        	else if (recentP2PsPerBillingAccount.containsKey(newP2P.Billing_Account__c)) { 
        		newP2P.addError('A Promise To Pay was setup in the last 6 months');
        	}
        	*/
        	
        	//Record has passed Validations and will be inserted. Assign correct Name and Status
        	else {
        		
        		Decimal debt_60_Plus_day = newP2P.DAYS_61_90__c + newP2P.DAYS_91_120__c + newP2P.DAYS_121_150__c + newP2P.DAYS_151_180__c + 	
        								   newP2P.DAYS_181_210__c + newP2P.DAYS_211_240__c + newP2P.DAYS_241_270__c + newP2P.DAYS_271_300__c + 	
        								   newP2P.DAYS_301_330__c + newP2P.DAYS_331_360__c;
        		
	    		if(billingAccountWithAssets.get(newP2P.Billing_Account__c) == null){
	    			Decimal min_Upfront_Payment = Math.round(newP2P.Total_Over_Due__c * 0.10);
	    			if(newP2P.One_off_Payment__c == null || newP2P.One_off_Payment__c < min_Upfront_Payment){
			        	newP2P.addError('Please ensure the minimum upfront payment of £'+min_Upfront_Payment +' is made as the account is disconnected');
			        }
	    			newP2P.Collection_Path__c =  p2pPaths.get(p2pBetween30And60DaysDebt).Id;
					newP2P.Promise_To_Pay_Name__c = p2pPaths.get(p2pBetween30And60DaysDebt).Name;
					newP2P.Status__c = Constants.PaymentPlanStatus_Open;
	    			
	    		}else if (debt_60_Plus_day!= null && debt_60_Plus_day > decimal.valueof(0)) {
	    			Decimal min_Upfront_Payment = Math.round(newP2P.Total_Over_Due__c * 0.20);
	    			if(newP2P.One_off_Payment__c != null && newP2P.One_off_Payment__c < min_Upfront_Payment){
			        	 newP2P.addError('Please ensure the minimum upfront payment of £'+min_Upfront_Payment +' is made as the debt is >60 days');
			        }
	    			newP2P.Collection_Path__c =  p2pPaths.get(p2pBetween30And60DaysDebt).Id;
					newP2P.Promise_To_Pay_Name__c = p2pPaths.get(p2pBetween30And60DaysDebt).Name;
					newP2P.Status__c = Constants.PaymentPlanStatus_Saved;
				}
				else {
					newP2P.Collection_Path__c = p2pPaths.get(p2pLessThan30DaysDebt).Id;
					if(newP2P.DAYS_31_60__c > 0){
						newP2P.Promise_To_Pay_Name__c = p2pPaths.get(p2pBetween30And60DaysDebt).Name;
					}else{
						newP2P.Promise_To_Pay_Name__c = p2pPaths.get(p2pLessThan30DaysDebt).Name;
					}
					newP2P.Status__c = Constants.PaymentPlanStatus_Open;
				}
			}	
        }
	}
	
	public static void handleAfterInsert(Map<Id, Promise_to_Pay__c> newP2PMap, No_Triggers__c notriggers) { 
	
		// If a P2P is saved with Status 'Open', then a Case of type 'Collection' should be created and an Email Comm sent.
	 	//Get Collection Setting
	 	Map<Id, CollectionAccountInfo> billingAccountToPaymentPathMap = new Map<Id, CollectionAccountInfo>();
	    //Map<Id, Id> billingAccountToP2PMap = new Map<Id, Id>();
	    Map<Id, Id> billingAccountToP2PMapForEmail = new Map<Id, Id>(); //for sending comms
	 
	 	for (Promise_to_Pay__c newP2P : newP2PMap.values()) {
	 		
	 		if (newP2P.Status__c == Constants.PaymentPlanStatus_Open) {
	        	CollectionAccountInfo colInfo = new CollectionAccountInfo(null);
	 			colInfo.nextPaymentDueDate = newP2P.Proposed_Payment_Date__c;
	 			colInfo.pathId = newP2P.Collection_Path__c;
	 			
	 			billingAccountToPaymentPathMap.put ( newP2P.Billing_Account__c, colInfo );
	 		    //billingAccountToP2PMap.put(newP2P.Billing_Account__c, newP2P.Id);
	 		    
	 		    if (newP2P.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Email) {
	 		    	billingAccountToP2PMapForEmail.put(newP2P.Billing_Account__c, newP2P.Id);
	 		    }
	 		}
	 	}
	 	
	 	Set<Id> billingAccountIds = billingAccountToPaymentPathMap.keyset();
	 	List<Billing_Account__c> billingAccountsForPPs = database.query('select Primary_Contact__r.Email, ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billingAccountIds');
                                                        
        List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
        List<CommunicationInfo> commInfos = new List<CommunicationInfo>();
        
        for (Billing_Account__c ba : billingAccountsForPPs) {
        	CollectionAccountInfo colInfo = billingAccountToPaymentPathMap.get(ba.Id);
        	colInfo.billingAccount = ba;
        	collInfos.add(  colInfo  );
        	
        	//collInfos.add(new CollectionAccountInfo(ba, billingAccountToPaymentPathMap.get(ba.Id)));
        	
        	// ------- If Preferred Comm Method is Email, create commInfo --------- 
        	if (billingAccountToP2PMapForEmail.containsKey(ba.Id) && ba.Primary_Contact__r.Email != null) {
        		commInfos.add(new CommunicationInfo(ba, Enums.PA_Type.P2P, billingAccountToP2PMapForEmail.get(ba.Id)));
        	}
        }
        
        PathHandler.assignPathsInBulk(collInfos);
        
        if (notriggers == null || !notriggers.Skip_P2P_Setup_Communication__c) {
 			try {
 				CommunicationHelper.sendEmail( commInfos, Constants.DefaultEmailFromAddress_CollectionsPPandP2PConfirmation );
 				system.debug('***** sending Communication');
        	}
        	catch (Exception e) {
        		system.debug('***** error in Communication');
        		newP2PMap.values()[0].addError(e.getMessage());
        	}  
 			
    	}
	 	
	}
	
	public static void handleBeforeUpdate(Map<Id, Promise_to_Pay__c> oldP2PMap, Map<Id, Promise_to_Pay__c> newP2PMap)  {
		if ( !isFirstTime ) { return; }
		
		//Once a P2P has Status 'Open/Closed', it cannot be modified unless the payment is made. Had to be done in a trigger as the 'Close' btn updates the Status to 'Closed'
	 	for (Promise_to_Pay__c newP2P : newP2PMap.values()) {
            Promise_to_Pay__c oldP2P = oldP2PMap.get(newP2P.Id);
            newP2P.Proposed_Payment_Date__c = Common.getNextWorkingDay( newP2P.Proposed_Payment_Date__c );
            system.debug('******* Flag is ' + SystemUpdateFlags.NoCheckForPaymentPlanModification + '----isFirstTime----'+isFirstTime);
            
	 		if ( !SystemUpdateFlags.NoCheckForPaymentPlanModification && 
	 				( oldP2P.Status__c == Constants.PaymentPlanStatus_Open || oldP2P.Status__c == Constants.PaymentPlanStatus_Closed ) && 
	 				( newP2P.Amount_Paid__c == oldP2P.Amount_Paid__c ) && (newP2P.One_off_Payment_Received__c == oldP2P.One_off_Payment_Received__c) ) {
	 					
	 				system.debug('******* old status is ' + oldP2P.Status__c + ' condition true');
        			newP2PMap.values()[0].addError('You don\'t have the permission to edit Open or Closed Promises to Pay.');
        	}
	 	}
	 }
	
	public static void handleAfterUpdate(Map<Id, Promise_to_Pay__c> oldP2PMap, Map<Id, Promise_to_Pay__c> newP2PMap, No_Triggers__c notriggers)  {
		if ( !isFirstTime ) { return; }
	
		// If a PP Status has been updated to 'Open' (via Approval Process), then a Case of type 'Collection' should be created.
	 	Id paymentPathId; 	
        
  	 	Map<Id, CollectionAccountInfo> billingAccountToPaymentPathMap = new Map<Id, CollectionAccountInfo>();
	    Map<Id, Id> billingAccountToP2PMapForEmail = new Map<Id, Id>();
        List<Id> p2pToCloseList = new List<Id>();
	 
	 	for (Promise_to_Pay__c newP2P : newP2PMap.values()) {
	 		//if Status has changed to Open
	 		if (newP2P.Status__c == Constants.PaymentPlanStatus_Open && oldP2PMap.get(newP2P.Id).Status__c != Constants.PaymentPlanStatus_Open) {
	 			
	 			system.debug('***** P2P Status changed to Open');
	        	CollectionAccountInfo colInfo = new CollectionAccountInfo(null);
	 			colInfo.nextPaymentDueDate = newP2P.Proposed_Payment_Date__c;
	 			colInfo.pathId = newP2P.Collection_Path__c;
	 			
	 			billingAccountToPaymentPathMap.put( newP2P.Billing_Account__c, colInfo );	 			
	 			
	 			//billingAccountToPaymentPathMap.put(newP2P.Billing_Account__c, newP2P.Collection_Path__c);
	 			
	 			// EP commented out on 13/09 as business not ready re Letter notification functionality. Will stick to Email for now
	 			if (newP2P.Preferred_Communication_Method__c == Constants.PreferredCommMethod_Email) {
	 				billingAccountToP2PMapForEmail.put(newP2P.Billing_Account__c, newP2P.Id);
	 			}
	 			
	 		} else if ( newP2P.Amount_Paid__c != oldP2PMap.get(newP2P.Id).Amount_Paid__c  && newP2P.Payment_Date__c != null ) {
	 			if ( newP2P.Amount_Paid__c >= Collections_Settings__c.getInstance(UserInfo.getUserId()).Payment_Acceptable_Tolerance__c * newP2P.Amount_Due__c ){
	 				// the payment is received close the P2P note
	 				p2pToCloseList.add ( newP2P.Id );
	 			}
	 		}
	 	}
	 	
	 	Set<Id> billingAccountIds = billingAccountToPaymentPathMap.keyset();
	 	List<Billing_Account__c> billingAccountsForPPs = database.query('select Primary_Contact__r.Email, ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billingAccountIds');
                                                        
        List<CollectionAccountInfo> collInfos = new List<CollectionAccountInfo>();
        List<CommunicationInfo> commInfos = new List<CommunicationInfo>();        
        
        for (Billing_Account__c ba : billingAccountsForPPs) {
        	CollectionAccountInfo colInfo = billingAccountToPaymentPathMap.get(ba.Id);
        	colInfo.billingAccount = ba;
        	collInfos.add(  colInfo  );        	
        	
        	//collInfos.add(new CollectionAccountInfo(ba, billingAccountToPaymentPathMap.get(ba.Id)));
        	
        	// ------- EP included on 10/10/2013: If Preferred Comm Method is Email, create commInfo --------- 
        	if (billingAccountToP2PMapForEmail.containsKey(ba.Id) && ba.Primary_Contact__r.Email != null) {
        		commInfos.add(new CommunicationInfo(ba, Enums.PA_Type.P2P, billingAccountToP2PMapForEmail.get(ba.Id)));
        	}
        }
 
        system.debug ( '££££££££££££££££££££ 1' );
        system.debug ( '££££££££££££££££££££ p2pToCloseList.size() -'+ p2pToCloseList.size() );
        
        if( p2pToCloseList != null && p2pToCloseList.size() > 0 ){
        	isFirstTime = false;
        	system.debug ( '££££££££££££££££££££ 2' );
        	PaymentPlanPromise2PayHelper.closePromiseToPaysInBulk( p2pToCloseList );
        	
        	//CollectionsEventHandler.processPaymentReceivedInBulk( collInfos );
        }
        system.debug ( '££££££££££££££££££££ collInfos.size () -'+ collInfos.size () );

        if( collInfos.size () > 0 ) {
	        system.debug ( '££££££££££££££££££££ 10.1' );
	        PathHandler.assignPathsInBulk(collInfos);

	        system.debug ( '££££££££££££££££££££ 10.2' );	        
	        if (notriggers == null || !notriggers.Skip_P2P_Setup_Communication__c) {
	 			try {
	 				CommunicationHelper.sendEmail( commInfos, Constants.DefaultEmailFromAddress_CollectionsPPandP2PConfirmation );
	 				system.debug('***** sending Communication');
	        	}
	        	catch (Exception e) {
	        		system.debug('***** error in Communication');
	        		newP2PMap.values()[0].addError(e.getMessage());
	        	}
	    	}
        } 	
	}
	

}