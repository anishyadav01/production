public without sharing class LiveAgentPostChatController {
     @TestVisible private Datetime reqTime;
     @TestVisible private Datetime startTime;
     private String liveChatStatus;
     public boolean displaySurvey{get;set;}
     public boolean displayError{get;set;}
    
    public Post_Chat_Survey__c postChatSurvey { get; set; }
    
    
    public LiveAgentPostChatController(){
        postChatSurvey = new Post_Chat_Survey__c();
        displaySurvey = true;
        displayError = true;
       
        
        
        if(!ApexPages.currentPage().getParameters().isEmpty()){
            System.debug('*** *** ChatKey retrieved : ' + ApexPages.currentPage().getParameters().get('chatKey'));
            
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Parameters:'+ApexPages.currentPage().getParameters());
            
            if(ApexPages.currentPage().getParameters().containsKey('disconnectedBy'))
            {
                displaySurvey=(ApexPages.currentPage().getParameters().get('disconnectedBy')!='error');
            }
            if(ApexPages.currentPage().getParameters().containsKey('requestTime'))
            {
                reqTime = Datetime.newInstance(Long.valueOf(ApexPages.currentPage().getParameters().get('requestTime')));
                System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>RequestTime: '+ApexPages.currentPage().getParameters().get('requestTime'));
            }
            
            
            
            if(ApexPages.currentPage().getParameters().containsKey('startTime'))
            {
                if (!String.isBlank(ApexPages.currentPage().getParameters().get('startTime'))){
                    System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>StartTime: '+ApexPages.currentPage().getParameters().get('startTime'));
                    startTime = Datetime.newInstance(Long.valueOf(ApexPages.currentPage().getParameters().get('startTime')));

                }
            }
            
            if(reqTime!=null)
                reqTime = Datetime.newInstance(reqTime.Year(),reqTime.Month(),reqTime.Day(),reqTime.Hour(),reqTime.Minute(),0);
            
            if(startTime!=null)    
                startTime = Datetime.newInstance(startTime.Year(),startTime.Month(),startTime.Day(),startTime.Hour(),startTime.Minute(),0);
            if(ApexPages.currentPage().getParameters().containsKey('Status'))
                liveChatStatus = ApexPages.currentPage().getParameters().get('Status');
                
             System.Debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> display Survey and Error: '+displaySurvey+ ' & ' + displayError);
             
            if(!String.isBlank(liveChatStatus)){
                System.Debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> display Survey and Error: '+displaySurvey+ ' & ' + displayError);
                displaySurvey = (liveChatStatus!='missed');
                displayError = !(displaySurvey);
                System.Debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> display Survey and Error: '+displaySurvey+ ' & ' + displayError);
            }
            displayError = !(displaySurvey);
        }    
    }
    
    public List<SelectOption> getServiceSatisfactionOptions(){
        
        return getRatingOptions();
        
    }
    
    public List<SelectOption> getAdvisorKnowledgeOptions(){
        
        return getRatingOptions();
    }
    
    public List<SelectOption> getAdvisorCommunicationSkillsOptions(){
        
        return getRatingOptions();
    }
    
    public List<SelectOption> getAdvisorCommunicationSkillsSubResponseOptions(){
        
        Schema.DescribeFieldResult F = Post_Chat_Survey__c.Advisor_Communication_Skills_SubResponse__c.getDescribe();
        return convertPicklistToOptions(F.getPicklistValues());
        
    }
    
    public List<SelectOption> getIssueResolutionOnlineOptions(){
        
        Schema.DescribeFieldResult F = Post_Chat_Survey__c.Issue_Resolution_Online__c.getDescribe();
        return convertPicklistToOptions(F.getPicklistValues());
        
    }
    
    public List<SelectOption> getProactiveHandlingRatingOptions(){
    
        return getRatingOptions();
        
    }
    
    public List<SelectOption> getQueryResolvedOptions(){
        
        return getRatingOptions();
        
    }
    
    public List<SelectOption> getRecommendatingRatingOptions(){
        
        return getRatingOptions0To10();
        
    }
    
    
    
    private List<SelectOption> convertPicklistToOptions(List<Schema.PickListEntry> pickVals){
        List<SelectOption> selectOpts = new List<SelectOption>();
        
        selectOpts.add(new SelectOption('',''));
        
        for(Schema.PicklistEntry ple : pickVals)
            selectOpts.add(new SelectOption(ple.getLabel(), ple.getValue()));
    
        return selectOpts;
        
    }
    
    private List<SelectOption> getRatingOptions(){
        List<SelectOption> selectOpts = new List<SelectOption>();
        selectOpts.add(new SelectOption('',''));
        selectOpts.add(new SelectOption('5','5'));
        selectOpts.add(new SelectOption('4','4'));
        selectOpts.add(new SelectOption('3','3'));
        selectOpts.add(new SelectOption('2','2'));
        selectOpts.add(new SelectOption('1','1'));
        
        
        return selectOpts;
    }
    
    private List<SelectOption> getRatingOptions0To10(){
        List<SelectOption> selectOpts = new List<SelectOption>();
        selectOpts.add(new SelectOption('',''));
        selectOpts.add(new SelectOption('10','10'));
        selectOpts.add(new SelectOption('9','9'));
        selectOpts.add(new SelectOption('8','8'));
        selectOpts.add(new SelectOption('7','7'));
        selectOpts.add(new SelectOption('6','6'));
        selectOpts.add(new SelectOption('5','5'));
        selectOpts.add(new SelectOption('4','4'));
        selectOpts.add(new SelectOption('3','3'));
        selectOpts.add(new SelectOption('2','2'));
        selectOpts.add(new SelectOption('1','1'));
        selectOpts.add(new SelectOption('0','0'));
        return selectOpts;
    }
    
    public PageReference submit(){
      
        String chatKey = reqTime + '_' + startTime;
        
        postChatSurvey.Chat_Key__c = chatKey;
        
       LiveChatTranscript lct ;
        try{
            lct = [Select Id from LiveChatTranscript where Chat_Key__c = : chatKey LIMIT 1];
        }catch(Exception e){
            System.debug('Live Chat Transcript not yet available ' + e.getMessage());
        }
        
        if(lct != null)
            postChatSurvey.Live_Chat_Transcript__c = lct.Id;
        
        insert postChatSurvey;
        
        return null;
    }
    
    
}