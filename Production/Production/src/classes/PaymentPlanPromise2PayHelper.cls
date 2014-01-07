public with sharing class PaymentPlanPromise2PayHelper {

	public static void closePaymentPlan ( Id ppId ){	
		closePaymentPlansInBulk ( new List<Id> { ppId }, false );	
	}	
	
	public static void closePaymentPlan ( Id ppId, boolean forceClose ){	
		closePaymentPlansInBulk ( new List<Id> { ppId }, forceClose );	
	}

	public static void closePaymentPlansInBulk ( List<Id> Ids ){
		closePaymentPlansInBulk ( Ids, false );	
	}

	public static void closePaymentPlansInBulk ( List<Id> Ids, boolean forceClose ){	
			List <Payment_Plan__c> plansToUpdate = new List<Payment_Plan__c>();
			List <CollectionAccountInfo> colAccounts = new List<CollectionAccountInfo> ();
			system.debug('------closePaymentPlansInBulk------Ids.size--' + Ids.size() + '---');
	        List<Payment_Plan__c> plans = database.query('select Id, Status__c, Billing_Account__c, ' + 
        												SObjectHelper.getFieldListForSOQL('Billing_Account__c', 'Billing_Account__r.') + 
        												' from Payment_Plan__c where Id = :Ids');
	
			if( plans != null && plans.size() > 0){
				for ( Payment_Plan__c plan : plans ) {	        	
		            //Close Plan
		            plan.Status__c = 'Closed';		            
		            plansToUpdate.add ( plan );
		            //Also Close the Collection Case & Clear History
		            colAccounts.add( new  CollectionAccountInfo(plan.Billing_Account__r, plan.Collection_Path__c, true) );
				}
				// update all the plans
		        
		        if (forceClose){
		            SystemUpdateFlags.NoCheckForPaymentPlanModification = true;
			        update plansToUpdate;
		            SystemUpdateFlags.NoCheckForPaymentPlanModification = false;

		        	PathHandler.exitPathsInBulk( colAccounts );
		        }else {
		        	StepHandler.moveStepsInBulk( colAccounts );
		        }
			}
	}
	


	public static void closePromiseToPay ( Id ppId ){	
		closePromiseToPaysInBulk ( new List<Id> { ppId }, false );	
	}	
	
	public static void closePromiseToPay ( Id ppId, boolean forceClose ){	
		closePromiseToPaysInBulk ( new List<Id> { ppId }, forceClose );	
	}

	public static void closePromiseToPaysInBulk ( List<Id> Ids ){
		system.debug ( '££££££££££££££££££££ 3' );
		closePromiseToPaysInBulk ( Ids, false );	
	}
	
	public static void closePromiseToPaysInBulk ( List<Id> Ids, boolean forceClose ){	
			List <Promise_to_Pay__c> promisesToUpdate = new List<Promise_to_Pay__c>();
			List <CollectionAccountInfo> colAccounts = new List<CollectionAccountInfo> ();
			system.debug ( '££££££££££££££££££££ 4' );
        List<Promise_to_Pay__c> promises = database.query('select Id, Status__c, Billing_Account__c, ' + 
        												SObjectHelper.getFieldListForSOQL('Billing_Account__c', 'Billing_Account__r.') + 
        												' from Promise_to_Pay__c where Id = :Ids');
	
			if( promises != null && promises.size() > 0){
				for ( Promise_to_Pay__c promise : promises ) {	        	
		            //Close Plan
system.debug ( '££££££££££££££££££££ 5' );
		            promise.Status__c = 'Closed';
		            promisesToUpdate.add ( promise );
		            
		            //Also Close the Collection Case & Clear History
		            CollectionAccountInfo colInfo = new  CollectionAccountInfo(promise.Billing_Account__r, promise.Collection_Path__c, true);
		            colInfo.action = Constants.CollectionStepAction_Payment; 
		            colAccounts.add( colInfo );
				}

		        if (forceClose){
		        	system.debug ( '££££££££££££££££££££ 6.1' );
					// update all the plans
		            SystemUpdateFlags.NoCheckForPaymentPlanModification = true;	
			        update promisesToUpdate;
		            SystemUpdateFlags.NoCheckForPaymentPlanModification = false;
		        	
		        	PathHandler.exitPathsInBulk( colAccounts );
		        }else {
		        	system.debug ( '££££££££££££££££££££ 6.2' );
		        	
		        	StepHandler.moveStepsInBulk( colAccounts );
		        }
		        
			}
	}	

}