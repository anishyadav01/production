public class SocialMediaVerificationFormHandler {

	/**
     *  After insert trigger handler.
     */
    public static void handleAfterInsert(map<id, Social_Media_Verification_Form__c> newForms) {
    	
    	Set<Id> keys = newForms.keySet();
    	List<Social_Media_Verification_Form__c> newFormsExtended = database.query('select SF_Case__r.ContactId, SF_Case__r.R6Service__SocialPersona__r.ParentId, ' + 
    																					SObjectHelper.getFieldListForSOQL('Social_Media_Verification_Form__c') + 
    													' from Social_Media_Verification_Form__c where id IN :keys');  
    													
    	linkSocialPersonasAndCasesToExistingContact(newFormsExtended);
    }
    
    /*
     * Based on the SMVF's Account No, link Case and Social Persona to existing Contact (if exists)
     */
    public static void linkSocialPersonasAndCasesToExistingContact(List<Social_Media_Verification_Form__c> newFormsExtended) {
    	
    	// Get existing SF Contact based on Acc No. if exists, link Case and Social Persona to it.
    	List<SObject> objectsToLink = new List<SObject>();
    	
    	Set<String> spAccountNos = new Set<String>();
    	
    	for (Social_Media_Verification_Form__c f : newFormsExtended) {
    		if (f.Account_Number__c != null) {
    			spAccountNos.add(String.valueof(f.Account_Number__c));
    		}
    	}
    	
    	List<Contact> existingContacts = [select Id, Email, Account.AccountNumber from Contact where Account.AccountNumber in :spAccountNos];
    	
    	//Construct a map of potentially relevant Contacts by Account No
    	Map<String, List<Contact>> contactsByAccountNoMap = new Map<String, List<Contact>>();
    	for (Contact c : existingContacts) {
    		if (!contactsByAccountNoMap.containsKey(c.Account.AccountNumber)) {
    			contactsByAccountNoMap.put(c.Account.AccountNumber, new List<Contact> {c});
    		}
    		else {
    			//Currently Account-Contact is 1-1, but just to handle 1 to many in the future..
    			contactsByAccountNoMap.get(c.Account.AccountNumber).add(c);
    		}
    	} 
    	
    	//Get existing Contact if exists    	
    	for (Social_Media_Verification_Form__c f : newFormsExtended) {
    		if (f.Account_Number__c != null && contactsByAccountNoMap.containsKey(String.valueof(f.Account_Number__c)) && 
    				contactsByAccountNoMap.get(String.valueof(f.Account_Number__c)) != null && contactsByAccountNoMap.get(String.valueof(f.Account_Number__c)).size() > 0) {
    					
				Contact contactFound = contactsByAccountNoMap.get(String.valueof(f.Account_Number__c)).get(0);
				f.SF_Case__r.ContactId = contactFound.Id;
				f.SF_Case__r.R6Service__SocialPersona__r.ParentId = contactFound.Id;
				
				objectsToLink.add(f.SF_Case__r);
				objectsToLink.add(f.SF_Case__r.R6Service__SocialPersona__r);	
    		}
    	}
    	
    	if (objectsToLink.size() > 0) {
    		update objectsToLink;
    	}
    }
    
    
}