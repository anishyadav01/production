@isTest
private class TestContactSocialActivitiesController {
    
    static Account acc;
    static Contact con;
    
    static void prepareData(Integer socialPostsNumber) {
        acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        con = new Contact (AccountId = acc.Id, LastName = 'Testius');
        insert con;
        
        //Create a (Lithium) Case and Postback Comments
        Case c = new Case (ContactId = con.Id);
        insert c;
        
        //Create Custom Setting required by Lithium
        LithiumSettings__c sett = new LithiumSettings__c(Name='DefaultSetting', Username__c = 'ctest');
        insert sett;
        
        List<Community_Postback_Comment__c> comments = new List<Community_Postback_Comment__c>();
        for (Integer i=0; i < socialPostsNumber; i++) {
            comments.add(new Community_Postback_Comment__c(Postback_Comment__c = 'A comment', Case__c = c.Id));
        }
        
        insert comments;
        
        //Create a Live Agent Transcript
         LiveChatVisitor lv = new LiveChatVisitor();
	    insert lv;
	    
	    LiveChatTranscript lct = new LiveChatTranscript(ContactId = con.Id, Chat_key__c = 'test1' +'_'+ 'test2', LiveChatVisitorId = lv.id, EndTime = Datetime.now());
	    insert lct;
	    
	    //Create a Social Persona and a Social Post 
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		SocialPost p = new SocialPost (Name = 'Test Post', Headline='some description', PersonaId = per.Id, R6Service__IsOutbound__c = false,
		Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags');
		insert p;
    }
    
    /*
     * This mocks the inline mode where the VF page appears in a section on the Contact's Detail Page Layout
     * Only a few records should be shown
     */
    static testMethod void test_WithContact_InInlineMode() {
        
        prepareData(10);
        
        //Test Sync Action 
        Apexpages.currentPage().getParameters().put('id', con.Id);
        
        ApexPages.Standardcontroller sdtctrl = New ApexPages.StandardController(con);
        ContactSocialActivitiesController customCtrl = new ContactSocialActivitiesController(sdtctrl);
        
        system.assertEquals(customCtrl.inlineModeOffset, customCtrl.allSocialActivities.size());
        
        system.assert(!customCtrl.getIsFullPageMode());
        
        PageReference s = new PageReference('/'+ con.Id);
        PageReference p = customCtrl.back();        
        System.assertEquals(s.getURL(), p.getURL());

        customCtrl.showAll();
        
        customCtrl.getController();
    }
    
    /*
     * This mocks the full view of the VF Page
     */
    static testMethod void test_WithAccount_InFullMode() {
        
        Integer postsNo = 10;
        prepareData(postsNo);
        
        //Test Sync Action 
        Apexpages.currentPage().getParameters().put('id', acc.Id);
        Apexpages.currentPage().getParameters().put('mode', ContactSocialActivitiesController.fullPageMode);
        
        ApexPages.Standardcontroller sdtctrl = New ApexPages.StandardController(acc);
        ContactSocialActivitiesController customCtrl = new ContactSocialActivitiesController(sdtctrl);
        
        system.assertEquals(postsNo + 2, customCtrl.allSocialActivities.size());
        
        system.assert(customCtrl.getIsFullPageMode());
        
        PageReference s = new PageReference('/'+ acc.Id);
        PageReference p = customCtrl.back();        
        System.assertEquals(s.getURL(), p.getURL());

        customCtrl.showAll();
    }

}