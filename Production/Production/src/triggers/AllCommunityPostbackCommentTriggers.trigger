trigger AllCommunityPostbackCommentTriggers on Community_Postback_Comment__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// Do not execute for any user that has the No validation flag set to true
    //No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    //if (notriggers == null || !notriggers.Flag__c) {
    	
    	if (trigger.isBefore && trigger.isInsert) {
            //CommunityPostbackCommentTriggerHandler.handleBeforeInsert(trigger.new);
        } 
        
        if (trigger.isBefore && trigger.isUpdate) {
            //CommunityPostbackCommentTriggerHandler.handleBeforeUpdate(trigger.oldMap, trigger.newMap);
        }    
        
     	if (trigger.isAfter && trigger.isInsert) {
            CommunityPostbackCommentTriggerHandler.handleAfterInsert(trigger.newMap);
        }  
		
		
     	if (trigger.isAfter && trigger.isUpdate) {
            //CommunityPostbackCommentTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap);           
        }  
        
    	if (trigger.isBefore && trigger.isDelete) {
          // CommunityPostbackCommentTriggerHandler.handleBeforeDelete(trigger.oldMap);
        }
   // }

}