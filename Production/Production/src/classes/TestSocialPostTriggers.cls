@IsTest
private class TestSocialPostTriggers {
	
	/* static testMethod void testNewSocialPostWhenPersonaHasNoCases() {
	 	
	 	// New Case should be created and associated to Social Persona. RecordType:Social Media, Status:New, Origin:Radian6, Suborigin: Tags
    	// New Post should be associated to new Case and Social Persona
    	
    	Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
    	//Create new Social Persona
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		//Create new Social Post		
		SocialPost p = new SocialPost (Name = 'Test Post', Headline='some description', PersonaId = per.Id, R6Service__IsOutbound__c = false,
		Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags');
		insert p;
		
		
		// Retrieve and assert
		List<Case> newCases = [select Id, Record_Type_Name__c, Status, Origin, Case_Sub_Origin__c from Case where R6Service__SocialPersona__c = :per.Id];
		
		system.assertEquals(1, newCases.size());
		system.assertEquals(Constants.CaseRecordType_SocialMedia, newCases[0].Record_Type_Name__c);
		system.assertEquals(Constants.CaseStatus_New, newCases[0].Status);
		system.assertEquals('Social Media', newCases[0].Origin);
		system.assertEquals(p.R6Service__PostTags__c, newCases[0].Case_Sub_Origin__c);
		
		SocialPost savedPost = [select Id, ParentId, PersonaId from SocialPost where Id = :p.Id];
		
		system.assertEquals(newCases[0].Id, savedPost.ParentId);
		system.assertEquals(per.Id, savedPost.PersonaId);
	 }
	 
	 static testMethod void testNewInboundSocialPostWherePersonaHasResolvedCase() {
	 	
	 	//- Receive new Inbound Post where Social Persona has cases with Case Status is 'Resolved'
    	//=> existing Case Status should be 'Customer Responded'
    	//=> New Post should be associated to the Case

    	
    	Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
    	//Create new Social Persona
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		//Create a Case with Status 'Resolved'
		RecordType socialMediaRecordType = [select Id from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_SocialMedia LIMIT 1];
		Case c = new Case (RecordTypeId = socialMediaRecordType.Id, Status = Constants.CaseStatus_Resolved, R6Service__SocialPersona__c = per.Id);
		insert c;
		
		// Now create a new inbound Social Post
		SocialPost p = new SocialPost (Name = 'Test Post', Headline='some description', PersonaId = per.Id, R6Service__IsOutbound__c = false,
						Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags');
		insert p;
				
		// Retrieve and Assert
		Case savedCase = [select Id, Record_Type_Name__c, Status, Origin, Case_Sub_Origin__c from Case where Id = :c.Id];
		SocialPost savedPost = [select ParentId, PersonaId from SocialPost where Id = :p.Id];
		
		system.assertEquals(Constants.CaseStatus_CustomerResponded, savedCase.Status);
		system.assertEquals(c.Id, savedPost.ParentId);
	 }
	 
	 static testMethod void testNewOutboundSocialPostWherePersonaHasCustomerRespondedCase() {
	 	 // - Receive new Outbound Post where Social Persona has cases, with Status 'Assigned' or 'Customer Responded'
    	 // => existing Case Status should be 'Resolved', First Response field should be assigned
    	 // => New Post should be associated to the Case
    	 
    	Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
    	//Create new Social Persona
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		//Create a Case with Status 'Customer Responded'
		RecordType socialMediaRecordType = [select Id from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_SocialMedia];
		Case c = new Case (RecordTypeId = socialMediaRecordType.Id, Status = Constants.CaseStatus_CustomerResponded, R6Service__SocialPersona__c = per.Id);
		insert c;
		
		// Now create a new Outbound Social Post
		SocialPost p = new SocialPost (Name = 'Test Post', Headline='some description', PersonaId = per.Id, R6Service__IsOutbound__c = true,
						Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags');
		insert p;
				
		// Retrieve and Assert
		Case savedCase = [select Id, Record_Type_Name__c, Status, First_Response__c, Origin, Case_Sub_Origin__c from Case where Id = :c.Id];
		SocialPost savedPost = [select ParentId, PersonaId from SocialPost where Id = :p.Id];
		
		system.assertEquals(Constants.CaseStatus_Resolved, savedCase.Status);
		system.assert(savedCase.First_Response__c != null);
		system.assertEquals(c.Id, savedPost.ParentId);
	 }
	 
	 static testMethod void testNewSocialPostWherePersonaHasClosedCasesOnly() {
	 	
	 	//- Receive new Inbound Post where Social Persona has many cases, all of them with Status ‘Closed’. 
    	//=> New Case should be created and associated to Social Persona. RecordType:Social Media, Status:New, Origin:Radian6, Suborigin: Tags
    	//=> New Post should be associated to new Case and Social Persona
    	
    	Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
    	//Create new Social Persona
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		//Create a Case with Status 'Closed'
		RecordType socialMediaRecordType = [select Id from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_SocialMedia];
		Case c = new Case (RecordTypeId = socialMediaRecordType.Id, Status = Constants.CaseStatus_Closed, R6Service__SocialPersona__c = per.Id);
		insert c;
		
		// Now create a new Inbound Social Post
		SocialPost p = new SocialPost (Name = 'Test Post', Headline='some description', PersonaId = per.Id, R6Service__IsOutbound__c = false,
						Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags');
		insert p;
				
		// Retrieve and Assert
		Case newCase = [select Id, Record_Type_Name__c, Status, R6Service__SocialPersona__c, Origin, Case_Sub_Origin__c 
						from Case where R6Service__SocialPersona__c = :per.Id and Status != :Constants.CaseStatus_Closed];
						
		SocialPost savedPost = [select ParentId, PersonaId from SocialPost where Id = :p.Id];
		
		system.assertEquals(Constants.CaseStatus_New, newCase.Status);
		system.assertEquals('Social Media', newCase.Origin);
		system.assertEquals(p.R6Service__PostTags__c, newCase.Case_Sub_Origin__c);
		system.assertEquals(Constants.CaseRecordType_SocialMedia, newCase.Record_Type_Name__c);
				
		system.assertEquals(newCase.Id, savedPost.ParentId);
		system.assertEquals(per.Id, savedPost.PersonaId);
	 	
	 	
	 }
	 
	 static testMethod void testNewSocialPostWhenPersonaHasNoCases_bulk() {
	 	
	 	// New Case should be created and associated to Social Persona. RecordType:Social Media, Status:New, Origin:Radian6, Suborigin: Tags
    	// New Post should be associated to new Case and Social Persona
    	
    	Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		List<Contact> contactsToInsert = new List<Contact>();
		for (Integer i=0; i<200; i++) {
			contactsToInsert.add(new Contact (AccountId = acc.Id, LastName = 'Testius ' + i));
		}
		insert contactsToInsert;
		
    	//Create new Social Personas
    	List<SocialPersona> personas = new List<SocialPersona>();
    	for (Integer i=0; i<200; i++) {
			personas.add(new SocialPersona(Name = 'Test Persona 1', ParentId = contactsToInsert[i].Id, Provider = 'Facebook'));
    	}
		insert personas;
		
		
		Test.startTest();
		
		//Create new Social Posts
		List<SocialPost> posts = new List<SocialPost>();
		for (Integer i=0; i<200; i++) {
			posts.add(new SocialPost (Name = 'Test Post ' + i, Headline='some description', PersonaId = personas[i].Id, R6Service__IsOutbound__c = false,
		Content  = 'my new Test Post 1' , R6Service__PostTags__c = 'some post tags'));
		}
		insert posts;
		
		Test.stopTest();
		
		
		// Retrieve and assert
		Set<Id> personaIds = new Set<Id>();
		for (SocialPersona sper : personas)
			personaIds.add(sper.Id);
		
		List<Case> newCases = [select Id, Record_Type_Name__c, Status, Origin, Case_Sub_Origin__c from Case where R6Service__SocialPersona__c in :personaIds];
		
		system.assertEquals(200, newCases.size());
		
		for (Case c : newCases) {
			system.assertEquals(Constants.CaseStatus_New, c.Status);
			system.assertEquals(Constants.CaseRecordType_SocialMedia, c.Record_Type_Name__c);
			system.assertEquals('Social Media', c.Origin);
			system.assert(c.Case_Sub_Origin__c != null);
		}
		
		Set<Id> postIds = new Set<Id>();
		for (SocialPost spost : posts) 
			postIds.add(spost.Id);
			
		List<SocialPost> savedPosts = [select Id, ParentId, PersonaId from SocialPost where Id in :postIds];
		
		for (SocialPost sp : savedPosts) {
			system.assert(sp.ParentId != null);
			system.assert(sp.PersonaId != null);
		}
	 }*/

}