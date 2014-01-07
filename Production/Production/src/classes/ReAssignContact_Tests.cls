@istest
global class ReAssignContact_Tests {
	
	static testmethod void test1(){
		
		ContactReAssignSearchSettings__c settings = new ContactReAssignSearchSettings__c();
		settings.New_Owner_Id__c = userinfo.getUserId();
		insert settings;
		system.assertnotequals(null,settings.id);
		
		Contact c1 = new Contact();
		c1.lastName = 'TEST1';
		insert c1;
		system.assertnotequals(null,c1.id);
		Contact c2 = new Contact();
		c2.lastName = 'TEST2';
		insert c2;
		system.assertnotequals(null,c2.id);
		
		SocialPersona sp1 = new SocialPersona();
		sp1.ParentId = c2.id;
		sp1.Name = 'TESTSP1';
		sp1.Provider = 'Twitter';
		insert sp1;
		system.assertnotequals(null,sp1.id);
		
		SocialPersona sp2 = new SocialPersona();
		sp2.ParentId = c1.id;
		sp2.Name = 'TESTSP2';
		sp2.Provider = 'Twitter';
		insert sp2;
		system.assertnotequals(null,sp2.id);
		
		SocialPost pst1 = new SocialPost();
		pst1.WhoId = c1.id;
		pst1.Headline = 'TEST1';
		pst1.PersonaId = sp1.id;
		pst1.Provider = 'Twitter';
		pst1.name = 'TEST1';
		insert pst1;
		system.assertnotequals(null,pst1.id);
		
		SocialPost pst2 = new SocialPost();
		pst2.WhoId = c2.id;
		pst2.Headline = 'TEST2';
		pst2.PersonaId = sp2.id;
		pst2.Provider = 'Twitter';
		pst2.name = 'TEST2';
		insert pst2;
		system.assertnotequals(null,pst2.id);
		
		Case cs1 = new Case();
		cs1.contactId = c1.id;
		cs1.Subject = 'Test1';
		cs1.Description = 'Test1';
		insert cs1;
		system.assertnotequals(null,cs1.id);
		
		apexpages.Standardcontroller con = new apexpages.Standardcontroller(cs1);
		reassignContact rc = new ReAssignContact(con);
		rc.searchTerm = '1';
		rc.doSearch();
		rc.searchTerm = 'test*';
		rc.doSearch();
		rc.recordId = cs1.id;
		rc.selectId = c2.id;
		rc.reAssign();
		
		list<SocialPersona> spList = [select id from SocialPersona where parentid = : c2.id];
		system.assertequals(2,splist.size());
		list<SocialPost> pstList = [select id from SocialPost where whoid = : c2.id];
		system.assertequals(2,pstList.size());
		list<Case> clist = [select id from Case where contactId = : c2.id];
		system.assertequals(1,clist.size());
	}	
}