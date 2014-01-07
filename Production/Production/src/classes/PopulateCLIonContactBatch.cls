public with sharing class PopulateCLIonContactBatch implements Database.Batchable<sObject>, Schedulable {
	
 	public void execute(SchedulableContext sc) {
      	PopulateCLIonContactBatch populateCLIonContactBatch = new PopulateCLIonContactBatch(); 
      	database.executebatch(populateCLIonContactBatch);
   	}

	public Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
   	 }
   	 
   	public void execute(Database.BatchableContext BC, List<Asset> allAssets){
 
   	    Map<Id, Set<Asset>> contactIDToAssetMap = new Map<Id, Set<Asset>>();
   	 	Set<Id> assetIds = new Set<Id>();
   	 	
   	 	for(Asset currentAsset : allAssets){
   	 		assetIds.add(currentAsset.Id);
   	 		if(contactIDToAssetMap.get(currentAsset.Contact_Id__c)!= null){
   	 			Set<Asset> assetList = contactIDToAssetMap.get(currentAsset.Contact_Id__c);
   	 			assetList.add(currentAsset);
   	 			contactIDToAssetMap.put(currentAsset.Contact_Id__c, assetList);	
   	 		}else{
   	 			contactIDToAssetMap.put(currentAsset.Contact_Id__c, new Set<Asset>{currentAsset});	
   	 		}
   	 	}
   		//Other Assets for thsi contact which have not been modified	 	
   	 	List<Asset> otherAssets = [Select a.CLI__c, a.Contact_Id__c, a.Billing_Account__c From Asset a where a.Contact_Id__c in :contactIDToAssetMap.KeySet() and a.id not in :assetIds];
   		for(Asset currentAsset : otherAssets){
   			if(contactIDToAssetMap.get(currentAsset.Contact_Id__c)!= null){
   	 			Set<Asset> assetList = contactIDToAssetMap.get(currentAsset.Contact_Id__c);
   	 			assetList.add(currentAsset);
   	 			contactIDToAssetMap.put(currentAsset.Contact_Id__c, assetList);	
   	 		}
   		}
   	 	
   	 	List<Contact> contacts = [Select c.Id, c.Related_CLI__c From Contact c where id in :contactIDToAssetMap.KeySet()];
   	 		 	
   	 	List<Contact> updatedContacts = new List<Contact>();
   	 	for(Contact con: contacts){
   	 		con.Related_CLI__c = '';
   	 		Set<Asset> currentContactAssets = contactIDToAssetMap.get(con.id);
   	 		for(Asset currentContactAsset : currentContactAssets){
   	 			if(con.Related_CLI__c != null && con.Related_CLI__c.length() > 0){
   	 				con.Related_CLI__c = con.Related_CLI__c+' ,'+ currentContactAsset.CLI__c;
   	 			}else{
   	 				con.Related_CLI__c = currentContactAsset.CLI__c;
   	 			}
   	 		}
   	 		updatedContacts.add(con);
   	 	}
   	 	update updatedContacts;
   	 }
   	 
   	 public void finish(Database.BatchableContext BC){
      //some logic will come here
     }
     
      private String query{
        get{
        	return 'Select a.CLI__c, a.Contact_Id__c, a.Billing_Account__c From Asset a where a.Status__c = \'ACTIVE\' and (a.LastModifiedDate = TODAY or a.CreatedDate = TODAY) order by a.Contact_Id__c';//only runs for today as the DWH load will load data in the morning
        }
    }
}