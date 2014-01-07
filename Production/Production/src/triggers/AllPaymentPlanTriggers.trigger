trigger AllPaymentPlanTriggers on Payment_Plan__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// Do not execute for any user that has the No validation flag set to true
    No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    
    system.debug('Skip PP Setup Communication is: ' + notriggers.Skip_PP_Setup_Communication__c);
  
    if (notriggers == null || !notriggers.Flag__c) {
    
        if (trigger.isBefore && trigger.isInsert) {
            PaymentPlanTriggerHandler.handleBeforeInsert(trigger.new);
        } 
        
        if (trigger.isAfter && trigger.isInsert) {
            PaymentPlanTriggerHandler.handleAfterInsert(trigger.newMap);
        }  
        
        if (trigger.isBefore && trigger.isUpdate) {
            PaymentPlanTriggerHandler.handleBeforeUpdate(trigger.oldMap, trigger.newMap);
        } 
        
        if (trigger.isAfter && trigger.isUpdate) {
            PaymentPlanTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap, notriggers);           
        }  
    }
}