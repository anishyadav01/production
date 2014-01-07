trigger AllSocialMediaVerificationFormTriggers on Social_Media_Verification_Form__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (trigger.isBefore && trigger.isInsert) {
        } 
        
        if (trigger.isBefore && trigger.isUpdate) {
        }    
        
     	if (trigger.isAfter && trigger.isInsert) {
            SocialMediaVerificationFormHandler.handleAfterInsert(trigger.newMap);
        }  
		
		
     	if (trigger.isAfter && trigger.isUpdate) {
        }  
        
    	if (trigger.isBefore && trigger.isDelete) {
        }
	

}