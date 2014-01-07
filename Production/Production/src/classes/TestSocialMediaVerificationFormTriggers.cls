@isTest
private class TestSocialMediaVerificationFormTriggers {
	
	static testMethod void testLinkPersonaAndCaseToContact_ContactExists() {
		
		Decimal accNo = 12345;
		Account acc = new Account (Name = 'Test_Acc_1', AccountNumber = String.valueOf(accNo));
		insert acc;
		
		Contact con = new Contact (AccountId = acc.Id, LastName = 'Testius');
		insert con;
		
		//Create new Social Persona
		SocialPersona per = new SocialPersona(Name = 'Test Persona 1', ParentId = con.Id, Provider = 'Facebook');
		insert per;
		
		//Create a Case
		RecordType socialMediaRecordType = [select Id from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_SocialMedia];
		Case c = new Case (RecordTypeId = socialMediaRecordType.Id, Status = Constants.CaseStatus_CustomerResponded, R6Service__SocialPersona__c = per.Id);
		insert c;
		
		Test.startTest();
		
		//Create a SMVF
		Social_Media_Verification_Form__c form = new Social_Media_Verification_Form__c(SF_Case__c = c.Id, Account_Number__c = accNo, Case_Number__c = 12);
		insert form;
		
		Test.stopTest();
		
		//Retrieve and assert
		Social_Media_Verification_Form__c savedForm = database.query('select SF_Case__r.ContactId, SF_Case__r.R6Service__SocialPersona__r.ParentId, ' + 
    																					SObjectHelper.getFieldListForSOQL('Social_Media_Verification_Form__c') + 
    													' from Social_Media_Verification_Form__c where id = \'' + form.Id + '\'');  
    													
    	system.assertEquals(con.Id, savedForm.SF_Case__r.ContactId);
    	system.assertEquals(con.Id, savedForm.SF_Case__r.R6Service__SocialPersona__r.ParentId);
	}
	
	static testMethod void testLinkPersonaAndCaseToContact_ContactNotExists() {
		
	}

}