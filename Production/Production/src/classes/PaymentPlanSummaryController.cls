public with sharing class PaymentPlanSummaryController {

	public String paymentPlanId {
		get {return paymentPlanId;} 
		set {paymentPlanId = value; retrieveData();}
	}
	
	public decimal monthlyInstallmentAmount {get; set;}
		
	public decimal finalInstallment {get; set;}
	
	public Integer noOfInstallments {get; set;}
	
	public Payment_Plan__c pp {get; set;}

	public void retrieveData() {
		
		List<Payment_Plan__c>pps = database.query('select ' + 
                                        SObjectHelper.getFieldListForSOQL('Payment_Plan__c') + 
                                    ' , (select ' +  SObjectHelper.getFieldListForSOQL('Payment_Plan_Line_Item__c') +
                                    	' from Payment_Plan_Lines__r order by Due_Date__c asc) '
                                    + 'from Payment_Plan__c where Id = :paymentPlanId ');
                                    
        
       // ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'***** paymentPlanId: ' + paymentPlanId));
        if (pps != null && pps.size() > 0) {
        	pp = pps[0];
        	
        	noOfInstallments = pp.Number_of_Installments__c.intValue();
        	
        	if (pp.Payment_Plan_Lines__r != null && pp.Payment_Plan_Lines__r.size() > 0) {
	        	monthlyInstallmentAmount = pp.Payment_Plan_Lines__r[0].Amount__c;
	        	finalInstallment = pp.Payment_Plan_Lines__r[pp.Payment_Plan_Lines__r.size()-1].Amount__c;
	        }
        }
	}		
}