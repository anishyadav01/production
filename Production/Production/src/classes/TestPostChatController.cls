@isTest
private class TestPostChatController{
  
  static testmethod void test_PostChatControllerChatMissed() {
    
    Apexpages.currentPage().getParameters().put('disconnectedBy', 'error');
    Apexpages.currentPage().getParameters().put('Status', 'missed');
        
    LiveAgentPostChatController laPostChat = new LiveAgentPostChatController();

    system.assertEquals(false,laPostChat.displaySurvey);
    system.assertEquals(true,laPostChat.displayError);
  }
  
  static testmethod void test_PostChatControllerChatFinished() {
    
    Apexpages.currentPage().getParameters().put('requestTime', String.valueOf(12312312)); 
    Apexpages.currentPage().getParameters().put('startTime', String.valueOf(24323234));
    Apexpages.currentPage().getParameters().put('Status', 'Started');
    
    LiveAgentPostChatController laPostChat = new LiveAgentPostChatController();

    system.assertEquals(true,laPostChat.displaySurvey);
    system.assertEquals(false,laPostChat.displayError);
    
    List<SelectOption> lsSatisfactionOptions = laPostChat.getServiceSatisfactionOptions();
    system.assertEquals(6,lsSatisfactionOptions.size());
    
    List<SelectOption> lsCommunicationSkillsOptions = laPostChat.getAdvisorCommunicationSkillsOptions();
    system.assertEquals(6,lsCommunicationSkillsOptions.size());
    
    List<SelectOption> lsSubResponseOptions = laPostChat.getAdvisorCommunicationSkillsSubResponseOptions();
    system.assertEquals(8,lsSubResponseOptions.size());
    
    List<SelectOption> lsResolutionOnlineOptions = laPostChat.getIssueResolutionOnlineOptions();
    system.assertEquals(3,lsResolutionOnlineOptions.size());
    
    List<SelectOption> lsAdvisorKnowledgeOptions = laPostChat.getAdvisorKnowledgeOptions();
    system.assertEquals(6,lsAdvisorKnowledgeOptions.size());

    List<SelectOption> lsProactiveOptions = laPostChat.getProactiveHandlingRatingOptions();
    system.assertEquals(6,lsProactiveOptions.size()); 

    List<SelectOption> lsResolvedOptions = laPostChat.getQueryResolvedOptions();
    system.assertEquals(6,lsResolvedOptions.size());     
    
    List<SelectOption> lsRecommendatingOptions = laPostChat.getRecommendatingRatingOptions();
    system.assertEquals(12,lsRecommendatingOptions.size());     
    
    LiveChatVisitor lv = new LiveChatVisitor();
    insert lv;
    
    LiveChatTranscript lct = new LiveChatTranscript();
    lct.Chat_key__c = laPostChat.reqTime +'_'+ laPostChat.startTime;
    lct.LiveChatVisitorId = lv.id;
    insert lct;
    
    laPostChat.submit();
    
    system.assertNotEquals(null, laPostChat.postChatSurvey.id); 
   
      
   
  }


}