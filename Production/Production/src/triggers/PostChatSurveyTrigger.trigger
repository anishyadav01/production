trigger PostChatSurveyTrigger on Post_Chat_Survey__c (after insert) {
  System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Inside Trigger:');

  LiveChatTranscriptHandler lcth = new LiveChatTranscriptHandler();
  
   if(trigger.isAfter && trigger.isInsert)
      lcth.handlePCSAfterInsert(trigger.new); 
}