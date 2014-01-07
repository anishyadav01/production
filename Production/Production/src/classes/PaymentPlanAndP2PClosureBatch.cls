public with sharing class PaymentPlanAndP2PClosureBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
	
	public Integer p2psClosedNo = 0;
	public Integer ppsClosedNo = 0;
	
	public PaymentPlanAndP2PClosureBatch() {}
	
	public Billing_Account__c[] start(Database.BatchableContext BC) {
		Billing_Account__c[] bas = [select Id, Current_Treatment_Step__c, Current_Treatment_Step__r.Name, Action_Date__c, 
											(select Id from Payment_Plans__r where Status__c = :Constants.PaymentPlanStatus_Open),
											(select Id from Promise_to_Pay__r where Status__c = :Constants.PaymentPlanStatus_Open)
										from Billing_Account__c
										where 
										 (Current_Treatment_Step__r.Name = :Constants.CompletionStepName_PaymentPlan or 
										  Current_Treatment_Step__r.Name = :Constants.CompletionStepName_PromiseToPay)];
										  
		system.debug('***** BAs: ' + bas.size()); 
		return bas;
	}
	
	public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 50);
    }
	
	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		
		system.debug('***** PaymentPlanAndP2PClosureBatch now executing.. '); 
		
		Billing_Account__c[] billingAccounts = (Billing_Account__c[])scope;
		
		List<Id> ppIdsToClose = new List<Id>();
		List<Id> p2pIdsToClose = new List<Id>();
		
		for (Billing_Account__c ba : billingAccounts) {
			if (ba.Current_Treatment_Step__r.Name == Constants.CompletionStepName_PaymentPlan && ba.Payment_Plans__r != null && ba.Payment_Plans__r.size() > 0) {
				ppIdsToClose.add(ba.Payment_Plans__r[0].Id);
				ppsClosedNo += ppIdsToClose.size(); //for debugging
			}
			else if (ba.Current_Treatment_Step__r.Name == Constants.CompletionStepName_PromiseToPay && ba.Promise_to_Pay__r != null && ba.Promise_to_Pay__r.size() > 0) {
				p2pIdsToClose.add(ba.Promise_to_Pay__r[0].Id);
				p2psClosedNo += p2pIdsToClose.size(); //for debugging
			}
		}
		
		//system.debug('***** PPIds: ' + ppIdsToClose.size() + ' - first one is : ' + ppIdsToClose[0]);
		PaymentPlanPromise2PayHelper.closePaymentPlansInBulk(ppIdsToClose, true);
		
		PaymentPlanPromise2PayHelper.closePromiseToPaysInBulk(p2pIdsToClose, true);
	}
	
	public void finish(Database.BatchableContext bc) {
		
		system.debug('***** Payment Plans Closed: ' + ppsClosedNo);
		system.debug('***** Promises To Pay Closed: ' + p2psClosedNo);
		system.debug('***** PaymentPlanAndP2PClosureBatch now finished.. '); 
	}

}