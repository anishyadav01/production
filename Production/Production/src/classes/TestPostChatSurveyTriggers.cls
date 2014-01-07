@isTest
private class TestPostChatSurveyTriggers {
	
	static testMethod void testLinkedWithTranscriptsAfterInsert() {
	 
		/* after Survey Records have been inserted, if not associated with Transcripts, find matching Transcripts */
		
		/*
		DateTime reqTime = DateTime.now();
		DateTime strTime = DateTime.now().addMinutes(10);
		
		String expectedChatKey = Datetime.newInstance(reqTime.Year(),reqTime.Month(),reqTime.Day(),reqTime.Hour(),reqTime.Minute(),0) +  '_' + 
								Datetime.newInstance(strTime.Year(),strTime.Month(),strTime.Day(),strTime.Hour(),strTime.Minute(),0);
								
		// Create Case for chat key - Required
		Case laCase = new Case(ChatKey__c = '12345');
		insert laCase;
		
		// Insert Live Chat Transcript for this chatKey
		LiveChatVisitor visitor = new LiveChatVisitor();
		insert visitor;
		
		LiveChatTranscript lct = new LiveChatTranscript(RequestTime = reqTime, StartTime = strTime, Chat_Key__c = expectedChatKey, chatKey = '12345',
														LiveChatVisitorId = visitor.Id);
		insert lct;
								
		//Create a Post Chat Survey
		Post_Chat_Survey__c survey = new Post_Chat_Survey__c(Chat_Key__c = expectedChatKey);
		insert survey;
		
		//Retrieve and assert
		Post_Chat_Survey__c savedSurvey = [select Live_Chat_Transcript__c from Post_Chat_Survey__c where Id = :survey.Id];
		system.assertEquals(lct.Id, savedSurvey.Live_Chat_Transcript__c);
		*/
		
	}

}