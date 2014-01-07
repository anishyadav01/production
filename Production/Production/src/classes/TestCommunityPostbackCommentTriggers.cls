@isTest
private class TestCommunityPostbackCommentTriggers {
	
	static Case c;
	
	static void prepareData(Integer socialPostsNumber) {
		Account acc = new Account (Name = 'Test_Acc_1');
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
		//Create a (Lithium) Case
		RecordType lithiumCaseRecordType = [select Id, Name from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_Lithium LIMIT 1];
		c = new Case (ContactId = con.Id, Status = Constants.CaseStatus_CustomerResponded, RecordTypeId = lithiumCaseRecordType.Id);
		insert c;
		
		//Create Custom Setting required by Lithium
		LithiumSettings__c sett = new LithiumSettings__c(Name='DefaultSetting', Username__c = 'ctest');
		insert sett;
		
		List<Community_Postback_Comment__c> comments = new List<Community_Postback_Comment__c>();
		for (Integer i=0; i < socialPostsNumber; i++) {
			comments.add(new Community_Postback_Comment__c(Postback_Comment__c = 'A comment', Case__c = c.Id));
		}
		
		insert comments;
	}
	
	static testMethod void testLithiumCaseResolutionAfterInsert() {
		
		prepareData(1);
		
		//Re-fetch Case and assert
		Case refCase = [select Id, Status from Case where Id = :c.Id];
		system.assertEquals(Constants.CaseStatus_Resolved, refCase.Status);
	}
	
	static testMethod void testLithiumCaseResolutionAfterInsert_Bulk() {
		
		prepareData(200);
		
		//Re-fetch Case and assert
		Case refCase = [select Id, Status from Case where Id = :c.Id];
		system.assertEquals(Constants.CaseStatus_Resolved, refCase.Status);
	}

}