public with sharing class PaymentPlanLineItemsOrderedController {
	
	public String ppId {
		get {return ppId;} 
		set {ppId = value; retrieveItems();}
	}
	
	public List<ppliWrapper> lineItems {get; set;}

	public void retrieveItems() {
		
		//String planId = ppId;
		List<Payment_Plan_Line_Item__c> pplis = new List<Payment_Plan_Line_Item__c>();
		
		pplis = [select Due_Date__c, Amount__c 
				from Payment_Plan_Line_Item__c 
				where Payment_Plan__c = :ppId 
			    order by Due_Date__c asc];
		
		system.debug(' ***** Payment Plan Id is: ' + ppId);

		lineItems = new List<ppliWrapper>();

		if (pplis != null && pplis.size() > 0) {
			Integer i=1;
			for (Payment_Plan_Line_Item__c li : pplis) {
				lineItems.add(new ppliWrapper(li.Due_Date__c, li.Amount__c, i));
				i++;
			}
		}
	}	

	
	public class ppliWrapper {
		public Date dueDate {get; set;}
		public Decimal amount {get; set;}
		public String sequence {get; set;}
		
		public ppliWrapper(Date aDate, Decimal anAmount, Integer seq) {
			dueDate = aDate;
			amount = anAmount;
			sequence = 'Payment ' + seq;
		}
	}

}