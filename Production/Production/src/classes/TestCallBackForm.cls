/**
* Test class created for testing the functionality of CallBack Form
* being called and inserted using SOAP calls from TT online portal.
*
*/
@isTest
public with sharing class TestCallBackForm {
	/**
	* Public test method used for testing inserting of
	* a callback form into database.
	*/
	public static testMethod void testCallbackForm() {
		Case c = new Case();
		c.Status = Constants.CaseStatus_New;
		insert c;

		c = [SELECT CaseNumber, Id, Status FROM Case WHERE Id = :c.Id];

		CallBack_Form__c form = new CallBack_Form__c();
		form.Case__c = c.Id;
		form.Case_Number__c = c.CaseNumber;
		insert form;

		CallBack_Form__c formAfterInsert = [SELECT Case_Number__c, Case__c FROM CallBack_Form__c WHERE Id = :form.Id];
		//Check that form was inserted correctly into the database
		System.assertNotEquals(formAfterInsert, null);
		System.assertEquals(formAfterInsert.Case_Number__c, c.CaseNumber);

		Case caseAfterCallback = [SELECT Status FROM Case WHERE Id = :formAfterInsert.Case__c];
		//Check if the case status changed from 'New' to 'Customer Responded'
		System.assertEquals(caseAfterCallback.Status, Constants.CaseStatus_CustomerResponded);
	}
}