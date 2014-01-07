trigger AllPromiseToPayTriggers on Promise_to_Pay__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// Do not execute for any user that has the No validation flag set to true
       No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
       if (notriggers == null || !notriggers.Flag__c) {
        
	        if (trigger.isBefore && trigger.isInsert) {
	            PromiseToPayTriggerHandler.handleBeforeInsert(trigger.new);
	        } 
	        
	        if (trigger.isAfter && trigger.isInsert) {
	            PromiseToPayTriggerHandler.handleAfterInsert(trigger.newMap, notriggers);
	        }  
	        
	        if (trigger.isBefore && trigger.isUpdate) {
	            PromiseToPayTriggerHandler.handleBeforeUpdate(trigger.oldMap, trigger.newMap);
	        } 
	        
	        if (trigger.isAfter && trigger.isUpdate) {
	            PromiseToPayTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap, notriggers);           
	        }  
       }

}