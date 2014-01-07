public with sharing class CommunicationInfo {
	
	public Billing_Account__c ba {get; set;}
	public Enums.PA_Type paType {get; set;}
	public Id paId {get; set;}
	
	public CommunicationInfo (Billing_Account__c billAcc, Enums.PA_Type theType, Id paymentArrangementId) {
		ba = billAcc;
		paType = theType;
		paId = paymentArrangementId;
	}

}