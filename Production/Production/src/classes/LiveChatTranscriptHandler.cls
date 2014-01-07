public with sharing class LiveChatTranscriptHandler{
  public Map<String,Case> caseLiveChatMap;
  public void handleLCTBeforeInsert(List <LiveChatTranscript> triggerNew){

    Set<string> chatKeySet = new Set<String>();
    caseLiveChatMap = new Map<String,Case>();

    for(LiveChatTranscript lct : triggerNew)
        chatKeySet.add(lct.chatKey);

    list<Case> liveChatCases = [select id, chatKey__c, Live_Chat_Current_Site__c from Case where chatKey__c in :chatKeySet];

    for(Case c : liveChatCases){
        caseLiveChatMap.put(c.chatKey__c, c);
    }

    for(LiveChatTranscript lct : triggerNew){

      Datetime reqTime;
      Datetime strTime;

      if(lct.Case==null){
          System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>Case is null');
          Case laCase = getCaseId(lct.chatKey);
	      if(laCase!=null) {
	          lct.Caseid = laCase.id;
	          lct.Current_Site__c = laCase.Live_Chat_Current_Site__c;
	      }
  	  }

      if(lct.RequestTime != null)
        reqTime = Datetime.newInstance(lct.RequestTime.Year(),lct.RequestTime.Month(),lct.RequestTime.Day(),lct.RequestTime.Hour(),lct.RequestTime.Minute(),0);

        if(lct.StartTime != null)
          strTime = Datetime.newInstance(lct.startTime.Year(),lct.startTime.Month(),lct.startTime.Day(),lct.startTime.Hour(),lct.startTime.Minute(),0);

      lct.Chat_Key__c =  reqTime +  '_' + strTime;

    }
  }

  public void handleLCTAfterInsert(List <LiveChatTranscript> triggerNew){

    //createAccountsAndContacts(triggerNew);
    linkLCTPostChatSurveys(triggerNew);


  }

  public void handlePCSAfterInsert(List<Post_Chat_Survey__c> triggerNew){
    linkPCSLiveChatTranscript(triggerNew);

  }

  /* after Survey Records have been inserted, if not associated with Transcripts, find matching Transcripts */
  private void linkPCSLiveChatTranscript(List<Post_Chat_Survey__c> surveys){

    Map<String, Post_Chat_Survey__c> chatKeyMap = new Map<String, Post_Chat_Survey__c>();
    List<Post_Chat_Survey__c> pcsToUpdate = new List<Post_Chat_Survey__c>();

    for(Post_Chat_Survey__c pcs : surveys)
      if(pcs.Live_Chat_Transcript__c == null) /* if not associated with a transcript */
        chatKeyMap.put(pcs.Chat_Key__c, pcs);

    System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Keyset :'+chatKeyMap.keySet());
    for(LiveChatTranscript lct : [Select Id, Chat_Key__c from LiveChatTranscript where Chat_Key__c IN :chatKeyMap.keySet()]){

      Post_Chat_Survey__c pcs = chatKeyMap.get(lct.Chat_Key__c);
      System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Post_Chat_Survey :'+pcs);
      if(pcs != null){
        pcs.Live_Chat_Transcript__c = lct.Id;
        pcsToUpdate.add(pcs);
      }
    }

    if(!pcsToUpdate.isEmpty())
      update pcsToUpdate;
  }

  /*after transcript records are inserted, find any surveys which need parenting */
  private void linkLCTPostChatSurveys(List<LiveChatTranscript> transcripts){

    Map<String, LiveChatTranscript> chatKeys = new Map<String, LiveChatTranscript>{};
    List<Post_Chat_Survey__c> postChatSurveys = new List<Post_Chat_Survey__c>{};

    for(LiveChatTranscript lct : transcripts)
      chatKeys.put(lct.Chat_Key__c, lct);

    System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Chat_Keys:'+chatKeys.keySet());
      for(Post_Chat_Survey__c pcs : [Select Id, Chat_Key__c from Post_Chat_Survey__c where Chat_Key__c IN :chatKeys.keySet() AND Live_Chat_Transcript__c = null]){

        LiveChatTranscript matchLct = chatKeys.get(pcs.Chat_Key__c);

        if(matchLct != null){
          pcs.Live_Chat_Transcript__c = matchLct.Id;
          postChatSurveys.add(pcs);
        }
      }

      if(!postChatSurveys.isEmpty())
        update postChatSurveys;
  }

  /*
      Find a Case based on ChatKey of Live Chat Transcript.
  */
  private Case getCaseId(String chatKey){
      if(!String.isBlank(chatKey)){
          if(caseLiveChatMap.containsKey(chatKey))
                return caseLiveChatMap.get(chatKey);
          else
              return null;
      }
      else
          return null;
      /*
      if(!String.isBlank(chatKey)){
          System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Inside getCaseId: '+chatKey);
          List<Case> laCaseList = [select id, ChatKey__c from Case where ChatKey__c=:chatKey limit 1];
          if(!laCaseList.isEmpty()){
              System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Case Id Found :'+laCaseList[0].Id);
              return laCaseList[0];

          }
          else
              return null;
      }*/
      return null;
  }

/*    private void createAccountsAndContacts(List<LiveChatTranscript> transcripts){

    List<Account> accts = new List<Account>{};
    List<Contact> conts = new List<Contact>{};
    List<Id> caseIds = new List<Id>{};
    Set<String> contactEmails = new Set<String>{};
    Map<String, Contact> emailContactMap = new Map<String, Contact>{};

    for(LiveChatTranscript lct : transcripts){
        caseIds.add(lct.CaseId);

        if(lct.Email__c != null)
            contactEmails.add(lct.Email__c);
    }

    Map<Id, Case> caseMap = new Map<Id,Case>([Select Id, Account_Number__c, ContactId from Case where Id in :caseIds]);

    //assuming contacts have unique email addresses
    for(Contact con : [Select Id, Email, AccountId, Account.Account_Number__c from Contact where Email IN :contactEmails])
        emailContactMap.put(con.Email, con);

    System.debug('emailContactMap : : ' + emailContactMap);

    List<Case> casesToUpdate = new List<Case>{};

    for(LiveChatTranscript lct : transcripts){

        Case caseRec = caseMap.get(lct.CaseId);

         System.debug('For LCT  ' + lct.Email__c + ' Case : : ' + caseRec);

        //if case record exists, which hasnt been parented to a contact
        if(caseRec != null && caseRec.ContactId == null){
        System.debug('if case record exists, which hasnt been parented to a contact');

            //Account Number has been input, meaning in all probability it hasnt matched, create new acc & contact
            if(caseRec.Account_Number__c != null){

            System.debug('Account Number has been input ' + caseRec.Account_Number__c);

                Account acct = new Account(Name = caseRec.Account_Number__c, BillingPostalCode=lct.PostCode__c,
                           BillingStreet = lct.Address__c, Phone = lct.Phone__c, Account_Number__c = caseRec.Account_Number__c );

                accts.add(acct);

                Contact con = new Contact(FirstName = lct.FirstName__c, LastName = lct.LastName__c,
                MailingStreet = lct.Address__c, MailingPostalCode = lct.PostCode__c, Phone = lct.Phone__c,
                Email = lct.Email__c, Account_Number__c = caseRec.Account_Number__c);
                //connect to Account using the External Id, create new Account Instance with only Ext Id Set for Matching
                con.Account = new Account(Account_Number__c = caseRec.Account_Number__c);

                conts.add(con);

                caseRec.Account = new Account(Account_Number__c = caseRec.Account_Number__c);
                caseRec.Contact = new Contact(Account_Number__c = caseRec.Account_Number__c);
                casesToUpdate.add(caseRec);
            }
            //Account Number hasnt been input, meaning it probably matched, query by email and find contact
            else{

            System.debug('Account Number hasnt been input ' + emailContactMap.get(lct.Email__c));

                Contact con = emailContactMap.get(lct.Email__c);
                if(con != null){
                    caseRec.ContactId = con.Id;
                    caseRec.AccountId = con.AccountId;
                    casesToUpdate.add(caseRec);
                }
            }
    }

    }
    try{
      if(!accts.isEmpty())
          upsert accts Account_Number__c;

      if(!conts.isEmpty())
          upsert conts Account_Number__c;

       if(!caseMap.isEmpty())
        upsert casesToUpdate;
      }
      catch(Exception ex){
        System.debug('Exception with storing accts, conts and cases ' + ex);
      }
    }
*/

}