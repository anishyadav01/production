public with sharing class CollectionHelper {

	static Map<Id, Collection_Path__c>  allPathsMap = new  Map<Id, Collection_Path__c>();	
	static Map<Id, Collection_Step_Criteria__c>  allCriteriaMap = new  Map<Id, Collection_Step_Criteria__c>();	
	
		
	public static Map<Id, Collection_Path__c> getAllPaths(){
		if ( allPathsMap.size() == 0 ){
			Map<Id, Collection_Path__c> allPaths = 
					new  Map<Id, Collection_Path__c>( [SELECT name, id, active__c, 
										( SELECT Name, Active__c, Days_on_this_step__c, Proceed_if_faliure__c, 
											Step_type__c, Cost__c, Sequence__c, Step_Communication_Type__c, is_Default_Next_Step__c 
									 		from Collection_steps__r order by Sequence__c) 
									 from Collection_Path__c]);
			allPathsMap = allPaths;	 				 
		}
		return allPathsMap; 
	} 


	public static Map<Id, Collection_Step_Criteria__c> getAllCriteriaMap(){
		if ( allCriteriaMap.size() == 0 ){
			Map<Id, Collection_Step_Criteria__c> allCriterias = 
					new  Map<Id, Collection_Step_Criteria__c>( [Select c.Type__c, c.Order_of_Execution__c, c.Name, c.Id, c.Expression__c, c.Collection_Step__c, c.Exit_Criteria_Type__c,
																c.Action__r.Collection_Step__c, c.Action__r.Value__c, c.Action__r.Type__c, c.Action__r.Name, c.Action__c 
													   From Collection_Step_Criteria__c c ] );
			allCriteriaMap = allCriterias;	 				 
		}
		return allCriteriaMap; 
	} 
	



	public static Collection_Path__c getPathById ( Id pathId ) {
		return getAllPaths().get ( pathId );
	}

/*
	public static Collection_Step__c getFirstStepForPath ( Id pathId ) {
		Collection_Path__c path = getAllPaths().get( pathId );
		
		if (path != null && path.Collection_steps__r != null && path.Collection_steps__r.size() > 0){
			// return the first default step from the Collection_steps__r
				return path.Collection_steps__r[0];	 
		}
		return null;
	}
	*/
	
	public static Collection_Step__c getFirstStepForPath ( Id pathId ) {
		return getDeafultNextStep ( pathId, null );
	}
	
	

	public static Collection_Step__c getStepForPath ( Id pathId, Id stepId ) {
		Collection_Path__c path = getAllPaths().get( pathId );
		
		if (path != null && path.Collection_steps__r != null && path.Collection_steps__r.size() > 0){
			// return the first step from the Collection_steps__r
			
			for (Collection_Step__c step : path.Collection_steps__r){
				if (step != null && step.id == stepId ){
					return step;
				}
			}
		}
		
		return null;
	}
	
	public static Collection_Step__c getDeafultNextStep ( Id pathId, Id stepId ) {
		Collection_Path__c path = getAllPaths().get( pathId );
		boolean foundStep = false;
		// move to first step
		if ( stepId == null ){
			foundStep = true;
		}
		
		if (path != null && path.Collection_steps__r != null && path.Collection_steps__r.size() > 0){
			// return the first step from the Collection_steps__r
			
			for (Collection_Step__c step : path.Collection_steps__r){
				if(foundStep){
					if ( step.is_Default_Next_Step__c ) {
						return step;
					}// if its not the default next step then will let it go on to the next one
				}
				
				if (step != null && step.id == stepId ){
					foundStep = true;
				}
			}
		}
		
		return null;
	}	
	
	public static Collection_Step__c getStepByName ( Id pathId, String stepName ) {
		Collection_Path__c path = getAllPaths().get( pathId );
		if (path != null && path.Collection_steps__r != null && path.Collection_steps__r.size() > 0){
			for (Collection_Step__c step : path.Collection_steps__r){
				if (step != null && step.Name == stepName ){
					return step;
				}
			}
		}
		
		return null;
	}	
		
	
	 /* When the Status of a PP or P2P is set to Open, a Case needs to be created.
	    This will be either at the creation of the record if it doesn't need to be submitted for Approval, or when it is Approved
	 */
	 /*
	 public static void createCollectionCaseForBillingAccounts(List<Billing_Account__c> billingAccountsForPPs, Map<Id, Id> billingAccountToPaymentPathMap) {
	 	
	 	List<CollectionAccountInfo> infos = new List<CollectionAccountInfo>();
	 	
	 	Set<Id> billingAccountIds = billingAccountToPaymentPathMap.keyset(); 
	 	
	 	List<Billing_Account__c> billingAccountsForPPs = database.query('select ' + 
                                                            SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where id IN :billingAccountIds');
                                                        
        for (Billing_Account__c ba : billingAccountsForPPs) {
        	infos.add(new CollectionAccountInfo(ba, billingAccountToPaymentPathMap.get(ba.Id)));
        	system.debug('******** Creating CollectionAccountInfo for ' + ba.Id);
        }
        
        PathHandler.assignPathsInBulk(infos);
	 }
	 */

	public static Id getFirstStepIdForPath ( Id pathId ) {
		Collection_Step__c step = getFirstStepForPath( pathId );
		if(step != null){
			return step.id;
		}
		return null;
	}


	public static Id getDeafultNextStepId ( Id pathId, Id stepId ) {
		Collection_Step__c step = getDeafultNextStep(pathId, stepId);
		if(step != null){
			return step.Id;
		}
		return null;
	}


	public static Collection_Step_Criteria__c getStepExitCriteriaByAction ( Id stepId, string action, string additionalCriteria ){	
		system.debug( 'stepId>>>>>>>>'+stepId);
		system.debug( 'action>>>>>>>>'+action);
		system.debug( 'additionalCriteria>>>>>>>>'+additionalCriteria);
		if ( additionalCriteria ==  null ) additionalCriteria = '';	
		
		for ( Collection_Step_Criteria__c criteria : getAllCriteriaMap().values() ){
			system.debug( '------criteria.Collection_Step__c-'+criteria.Collection_Step__c+'--stepId--' + stepId );
			system.debug( '------criteria.Exit_Criteria_Type__c-' + criteria.Exit_Criteria_Type__c + '-----action-----' + action );
			system.debug( '------criteria.Expression__c-----' + criteria.Expression__c + '-----additionalCriteria-----' + additionalCriteria );
			if( criteria.Collection_Step__c == stepId && criteria.Exit_Criteria_Type__c == action && Common.getBlankIfNull( criteria.Expression__c ) ==  Common.getBlankIfNull( additionalCriteria ) ){
				return criteria;
			}
		}
		return null;
	}

}