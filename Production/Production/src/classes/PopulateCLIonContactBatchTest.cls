@isTest
private class PopulateCLIonContactBatchTest {

    static testMethod void testBatch() {
    	Billing_Account__c billingAccount = TestHelper.createBillingAccount();
    	
    	Asset currentAsset1 = new Asset(Name='Test Name1', AccountId=billingAccount.Account_Id__c, Billing_Account__c = billingAccount.id, Status__c='ACTIVE');
        insert currentAsset1; 
        
        Asset currentAsset = new Asset(Name='Test Name', AccountId=billingAccount.Account_Id__c, Billing_Account__c = billingAccount.id, Status__c='ACTIVE');
        insert currentAsset;
    	
    	 Test.StartTest();
    	 PopulateCLIonContactBatch populateCLIonContactBatch = new PopulateCLIonContactBatch();
    	 ID batchprocessid = Database.executeBatch(populateCLIonContactBatch);
    	 Test.StopTest();
    }
}