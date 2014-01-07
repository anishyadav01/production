public with sharing class LiveAgentCreateCase {
    public string pageInfo{get;set;}
    public string CLI{get;set;}
    public Contact theContact;
    public String currentURL{ get;set; }

    public LiveAgentCreateCase(ApexPages.StandardController controller) {

        //chatKey = ApexPages.currentPage().getParameters().get('chatKey');
        //theContact = new Contact();
        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>> Chat Key for New Case: '+ApexPages.currentPage().getParameters());

    }

    public Case newCase;
    public string chatKey{get;set;}
    public string caseId;

    public LiveAgentCreateCase(){



    }

public string getCaseId(){
    return 'Case: '+caseId;
}

public PageReference sendContact(){
    System.debug('>>>>>>>>>>>>>>>>>> CLI : '+CLI);
   // List<contact> contactList = [select id, FirstName,LastName,Email,AccountId from contact where id=:CLI];
   // theContact = contactList[0];
    System.debug('>>>>>>>>>>>>>>>>>> theContact : '+theContact);
    return null;
}


public PageReference createCase(){
   pageReference pr;
   RecordType rt;

   integer iCaseCount = [select count() from Case where chatKey__c=:chatKey];
   if((iCaseCount==0) && (!String.isBlank(chatKey))){
       newCase = new Case(subject='Live Chat');
       rt = [select id from RecordType where Name='Live Agent' and SObjectType='Case' limit 1];
       newCase.RecordTypeId = rt.id;
       newCase.chatKey__c = chatKey;
       newCase.Origin = 'Live Chat';
       newCase.DPA_Status__c = 'DPA Not Checked';
       if(currentURL != null) {
       		newCase.Live_Chat_Current_Site__c = currentURL;
       }

		System.debug('cli is ' + cli);
		list<Asset> baList;
       if(CLI != null && !String.isBlank(CLI)){
           baList = [select id,Billing_Account__r.Primary_Contact__c,Billing_Account__c from Asset where CLI__c=:CLI];
           if(!baList.isEmpty()){

               list<contact> contactList = [select id, FirstName,LastName,Email,AccountId from contact where id =:baList[0].Billing_Account__r.Primary_Contact__c];

               if(!contactList.isEmpty())
                   theContact = contactList[0];
           }
       }

       System.debug('contact is ' + theContact);

       try
       {
       System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>> Inside createCase theContact:'+ theContact);
       if(theContact!=null) {
           System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>> AccountId:'+ theContact.AccountId);
           newCase.AccountId = theContact.AccountId;
           newCase.ContactId = theContact.id;
           newCase.DPA_Status__c = 'DPA Passed';
           newCase.CLI__c = CLI;
           newCase.Billing_Account__c = baList[0].Billing_Account__c;
       }

           insert newCase;

       }catch (Exception e){
           System.debug('ERROR:' + e);
       }
       finally{

       }
       caseId = newCase.id;
       pr = new PageReference('/'+caseId);
       pr.setRedirect(true);
       return pr;

   }
   else{
       Case laCase = [select id from Case where chatKey__c=:chatKey limit 1];
       caseId = laCase.id;
       pr = new PageReference('/'+caseId);
       pr.setRedirect(true);
       return pr;
   }
   return null;
}

}