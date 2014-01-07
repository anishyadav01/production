trigger AllSocialPostTriggers on SocialPost (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    
    //for social hub cases, set the sub origin to the social post's post tags value
	if (trigger.isAfter && (trigger.isUpdate || trigger.isUpdate)) {
		SocialPostTriggerHandler.handleAfterInsertOrUpdate(trigger.new);
	}
    // Do not execute for any user that has the No validation flag set to true
    //No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    //if (notriggers == null || !notriggers.Flag__c) {
        
        if (trigger.isBefore && trigger.isInsert) {
        } 
        
        if (trigger.isBefore && trigger.isUpdate) {
        }    
        
        if (trigger.isAfter && trigger.isInsert) {
           SocialPostTriggerHandler.handleAfterInsert(trigger.newMap);
        }  
        
        
        if (trigger.isAfter && trigger.isUpdate) {
        }  
        
        if (trigger.isBefore && trigger.isDelete) {
        }
   // }

}