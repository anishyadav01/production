/**
	This file will handle all the events affecting Collections

*/


public with sharing class CollectionsEventHandler {
	
	public static void processPaymentReceived ( CollectionAccountInfo colAccount ) {
		StepHandler.moveStep( colAccount ) ;
	}

	
	public static void processPaymentReceivedInBulk ( List<CollectionAccountInfo> colAccounts ){
		List<CollectionAccountInfo> moveStepsCollection = new List<CollectionAccountInfo>();
		//List<CollectionAccountInfo> accountsExitingCollection = new List<CollectionAccountInfo>();
		
		for(CollectionAccountInfo colAccount :colAccounts){
			//if(colAccount.nextPaymentDueDate == null){
			//	colAccount.exitCollection = true;
				//accountsExitingCollection.add(colAccount);
			//}else{
				
				moveStepsCollection.add(colAccount);
			//}
		}
		
		//if ( accountsExitingCollection.size() > 0 ) {
		//	PathHandler.exitPathsInBulk (  accountsExitingCollection );
		//}
		if ( moveStepsCollection.size() > 0 ) {
			StepHandler.moveStepsInBulk (  moveStepsCollection );
		}
	}
	 
	
}