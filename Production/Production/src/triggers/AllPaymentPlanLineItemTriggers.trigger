trigger AllPaymentPlanLineItemTriggers on Payment_Plan_Line_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// Do not execute for any user that has the No validation flag set to true
    No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    if (notriggers == null || !notriggers.Flag__c) {
    
        if (trigger.isBefore && trigger.isInsert) {
            PaymentPlanLineItemTriggerHandler.handleBeforeInsert(trigger.new);
        } 
        
        if (trigger.isAfter && trigger.isInsert) {
            PaymentPlanLineItemTriggerHandler.handleAfterInsert(trigger.newMap, notriggers);
        }  
        
        if (trigger.isBefore && trigger.isUpdate) {
            PaymentPlanLineItemTriggerHandler.handleBeforeUpdate(trigger.oldMap, trigger.newMap);
        } 
        
        if (trigger.isAfter && trigger.isUpdate) {
            PaymentPlanLineItemTriggerHandler.handleAfterUpdate(trigger.oldMap, trigger.newMap);           
        }  
    }

}