trigger CallBackFormTrigger on Callback_Form__c (before insert) {
  

  CallBackFormHandler cbfh = new CallBackFormHandler();
  
   if(trigger.isBefore && trigger.isInsert)
      cbfh.handleCBFBeforeInsert(trigger.new); 
}