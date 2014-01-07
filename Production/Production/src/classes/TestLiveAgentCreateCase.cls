/**
* Test class created for testing the functionality of
* creation of a new case associated with the started
* chat session. The Case needs to be connected to
* customer data (if possible and if data propagated from
* online portal) and the LiveChatTranscript record.
*/
@isTest
private class TestLiveAgentCreateCase {

	/**
	* Public test method used for testing the creation of
	* the live chat case.
	*/
    static testmethod void test_LiveAgentCreateCase() {
        string sCaseId;
        Case c  = new Case();

        String chatKey = 'k12345';
        Apexpages.currentPage().getParameters().put('chatKey', 'k12345');

        ApexPages.Standardcontroller caseCtrl = new ApexPages.Standardcontroller(c);
        LiveAgentCreateCase customCtrl = new LiveAgentCreateCase(caseCtrl);
        customCtrl.chatKey = 'k12345';

        customCtrl.pageInfo = 'blabla&chatId=' + chatKey;

        customCtrl.createCase();

        //Assert Case has been created
        system.assert(customCtrl.caseId != null);
        sCaseId = customCtrl.caseId;

        Case savedCase = [select Id, RecordTypeId, Record_Type_Name__c, chatKey__c, Origin from Case where Id = :customCtrl.caseId ];

        system.assert(savedCase != null);
        system.assertEquals(Constants.CaseRecordType_LiveAgent, savedCase.Record_Type_Name__c);
        system.assertEquals(chatKey, savedCase.chatKey__c);
        system.assertEquals('Live Chat', savedCase.Origin);

        customCtrl.createCase();
        system.assertEquals(sCaseId, customCtrl.caseId);

    }

	/*
	* The test method used for testing the creation of the
	* create case controller. The controller uses the CLI
	* depicted on the asset, sent from the online portal,
	* to connect the case to the customer information. It will
	* propagate the CLI number to the page as a parameter in the
	* URL.
	*/
    static testmethod void testLiveChatCreateCaseController() {
    	Account account = new Account();
    	account.Name = 'Name';
    	insert account;

    	Asset asset = new Asset();
    	asset.CLI__c = '01238470891';
    	asset.Name = 'Test Name';
    	asset.AccountId = account.Id;
    	insert asset;

    	LiveChatCreateCaseController controller = new LiveChatCreateCaseController(new ApexPages.StandardController(asset));
    	controller.NavigateToCreateCase();
    	System.assert(controller.myTargetUrl.contains(asset.Id));
    	System.assertEquals(controller.assetCLI.Id, asset.Id);
    }

	/*
	* The test method used for testing the creation of the
	* deployment page controller. The controller uses the CLI
	* depecited on the asset, sent from the online portal,
	* to connect the case to the customer information.
	*/
	static testMethod void testLiveAgentDeploymentController() {
    	LiveAgentDeploymentController controller = new LiveAgentDeploymentController();

    }
}