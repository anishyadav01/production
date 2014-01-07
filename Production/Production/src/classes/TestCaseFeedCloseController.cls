@isTest
public class TestCaseFeedCloseController {
	
	static testMethod void test() {
		
		Case c = new Case (Status = Constants.CaseStatus_CustomerResponded);
		insert c;
		
		ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(c);
		CaseFeedCloseController customCtrl = new CaseFeedCloseController(strctrl);
		
		
		customCtrl.caseRec.Reason = 'Customer not responded';
		customCtrl.caseRec.Subject = 'Subject changed';
		customCtrl.caseRec.Description = 'laaarge description';
		
		customCtrl.closeCase();
		
		//Retrieve and assert
		Case updatedCase = [select Id, Subject, Description, Reason, Status from Case where Id = :c.Id];
		
		system.assertEquals(Constants.CaseStatus_Closed, updatedCase.Status);
		system.assertEquals('Subject changed', updatedCase.Subject);
		system.assertEquals('laaarge description', updatedCase.Description);
		system.assertEquals('Customer not responded', updatedCase.Reason);
		
	}

}