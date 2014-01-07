public with sharing class PaymentAllocationBatch implements Database.Batchable<sObject>, Schedulable{
	
	  public void execute(SchedulableContext scMain) {
        PaymentAllocationBatch batch = new PaymentAllocationBatch();
        Database.executeBatch(batch, 200);
     }

   	 public PaymentAllocationBatch(){}

   	 public Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
   	 }
   	 
   	  public void execute(Database.BatchableContext BC, List<sObject> scope){
   	  	Payment__c[] payments = (Payment__c[])scope;
  
  		List<Payment__c>  paymentsToBeDeleted = new List<Payment__c>();
  		List<Payment__c>  paymentsToUpdated = new List<Payment__c>();
  			  	
   	  	Map<Id, List<Payment__c>> billingAccToPaymentMap = new Map<Id,List<Payment__c>>();
        system.debug ('*******-----payments-----******'+payments);
        for(Payment__c payment : payments){
	        if(billingAccToPaymentMap.containsKey(payment.Billing_Account__c)){
	            List<Payment__c> paymentList =billingAccToPaymentMap.get(payment.Billing_Account__c);
	            paymentList.add(payment);
	            billingAccToPaymentMap.put(payment.Billing_Account__c, paymentList);
	            
	        }else{
	            List<Payment__c> paymentList = new List<Payment__c>{payment};
	            billingAccToPaymentMap.put(payment.Billing_Account__c, paymentList);
	        }
    	}
    
    String pp = 'PP Completed';
    String p2p = 'P2P Completed';
    //Map<ID, Billing_Account__c> billingAccountsMap = new Map<ID, Billing_Account__c>([Select b.Promise_to_Pay__c, b.Id From Billing_Account__c b where b.Payment_Defaulted__c != true and (b.Promise_to_Pay__c = true or b.Current_Treatment_Path__c != null) and Current_Treatment_Step__c != :pp and Current_Treatment_Step__c != :p2p  and b.id in :billingAccToPaymentMap.keySet()]);
 
    Map<ID, Billing_Account__c> billingAccountsMap = new Map<ID, Billing_Account__c>([Select b.Promise_to_Pay__c, b.Id 
                                                                                        From Billing_Account__c b 
                                                                                        where b.Payment_Defaulted__c != true and 
                                                                                            (b.Promise_to_Pay__c = true or b.Current_Treatment_Path__c != null) 
                                                                                            and Current_Treatment_Step__r.name != :pp 
                                                                                            and Current_Treatment_Step__r.name != :p2p  
                                                                                            and b.id in :billingAccToPaymentMap.keySet()]);

    for(Payment__c payment : payments){
        if(!billingAccountsMap.containsKey(payment.Billing_Account__c)){
        	paymentsToBeDeleted.add(payment);
        }else{
        	payment.Allocated__c = true;
        	paymentsToUpdated.add(payment);
        }
    }
    
	    //Getting P2P records
	    Map<ID,Promise_to_Pay__c> billingAccountToP2PMap = new Map<ID,Promise_to_Pay__c>();
	    List<Promise_to_Pay__c> promisetoPayList = [Select  p.Payment_Date__c, p.Amount_Paid__c, p.Amount_Due__c, p.One_off_Payment__c, p.One_off_Payment_Received__c, p.One_off_Payment_Due__c, p.Billing_Account__c From Promise_to_Pay__c p where p.Status__c != 'Closed' and p.Billing_Account__c in :billingAccountsMap.keySet()];
	    for(Promise_to_Pay__c promisetoPay : promisetoPayList){
	        billingAccountToP2PMap.put(promisetoPay.Billing_Account__c,promisetoPay);
	    }
	    
	    //Getting PP records
	    Map<ID,Payment_Plan__c> billingAccountToPPMap = new Map<ID,Payment_Plan__c>();
	    Map<ID, Payment_Plan__c> paymentPlanMap = new Map<ID, Payment_Plan__c>([Select p.Status__c, p.One_off_Payment__c, p.One_off_Payment_Received__c, p.One_off_Payment_Due__c, p.Billing_Account__c From Payment_Plan__c p where p.Status__c != 'Closed' and p.Billing_Account__c in :billingAccountsMap.keySet()]);
	    List<Payment_Plan__c> paymentPlans = paymentPlanMap.values();
	    for(Payment_Plan__c paymentPlan : paymentPlans){
	        billingAccountToPPMap.put(paymentPlan.Billing_Account__c,paymentPlan);
	    }
	    
	    //Getting PP lines records
	    Map<ID,List<Payment_Plan_Line_Item__c>> p2pToLinesMap = new Map<ID,List<Payment_Plan_Line_Item__c>>();
	    List<Payment_Plan_Line_Item__c> ppLines = [Select p.Payment_Plan__c, p.Payment_Date__c, p.Sequence__c, p.Next_Payment_Due_Date__c, p.Billing_Account__c, p.Amount__c, p.Amount_Paid__c, p.Amount_Due__c From Payment_Plan_Line_Item__c p where Payment_Plan__c in :paymentPlanMap.keySet() and p.Amount_Due__c>0];
	    for(Payment_Plan_Line_Item__c ppLine : ppLines){
	        if(p2pToLinesMap.containsKey(ppLine.Payment_Plan__c)){
	            List<Payment_Plan_Line_Item__c> paymentLines = p2pToLinesMap.get(ppLine.Payment_Plan__c);
	            paymentLines.add(ppLine);
	            p2pToLinesMap.put(ppLine.Payment_Plan__c, paymentLines);  
	            
	        }else{
	            List<Payment_Plan_Line_Item__c> paymentList = new List<Payment_Plan_Line_Item__c>{ppLine};
	            p2pToLinesMap.put(ppLine.Payment_Plan__c, paymentList);
	        }
	    }
	    
	    List<Promise_to_Pay__c> updatedP2P = new List<Promise_to_Pay__c>();
	    List<Payment_Plan__c> updatedPP = new List<Payment_Plan__c>();
	    List<Payment_Plan_Line_Item__c> updatedPPLines = new List<Payment_Plan_Line_Item__c>();
	    
	    for(Billing_Account__c billingAccount :  billingAccountsMap.values()){
	        
	        List<Payment__c> currentAccountPayments  = billingAccToPaymentMap.get(billingAccount.Id);
	        Decimal totalPayments = 0.0;
	        for(Payment__c payment: currentAccountPayments){
	            totalPayments = totalPayments + payment.Amount__c;
	        }
	        
	        
	        if(billingAccountToP2PMap.containsKey(billingAccount.id)){ //Promise to pay exists
	            Promise_to_Pay__c currentP2P = billingAccountToP2PMap.get(billingAccount.id);
	           
	           if(currentP2P.One_off_Payment_Due__c > 0){
	                if(currentP2P.One_off_Payment_Received__c == null){
	                    currentP2P.One_off_Payment_Received__c = 0.00;
	                }
	                
	                if(totalPayments > currentP2P.One_off_Payment_Due__c){
	                    currentP2P.One_off_Payment_Received__c = currentP2P.One_off_Payment_Received__c + currentP2P.One_off_Payment_Due__c;
	                    totalPayments = totalPayments - currentP2P.One_off_Payment_Due__c;
	                }else{
	                    currentP2P.One_off_Payment_Received__c = currentP2P.One_off_Payment_Received__c + totalPayments;
	                    totalPayments = 0.00;
	                }
	            }
	           
	           
	            if(totalPayments > (currentP2P.Amount_Due__c - currentP2P.Amount_Paid__c)){
	                currentP2P.Amount_Paid__c = currentP2P.Amount_Due__c;
	            }else{
	                currentP2P.Amount_Paid__c = currentP2P.Amount_Paid__c + totalPayments;
	            }
	            
	            currentP2P.Payment_Date__c = System.today();
	            updatedP2P.add(currentP2P);
	        }
	        
	        if(billingAccountToPPMap.containsKey(billingAccount.id)){ //Payment Plan exists
	            Payment_Plan__c currentPP = billingAccountToPPMap.get(billingAccount.id);
	            List<Payment_Plan_Line_Item__c> currentPPLines = p2pToLinesMap.get(currentPP.Id);
	            
	            if(currentPP.One_off_Payment_Due__c > 0){
	                if(currentPP.One_off_Payment_Received__c == null){
	                    currentPP.One_off_Payment_Received__c = 0.00;
	                }
	                
	                if(totalPayments > currentPP.One_off_Payment_Due__c){
	                    currentPP.One_off_Payment_Received__c = currentPP.One_off_Payment_Received__c + currentPP.One_off_Payment_Due__c;
	                    totalPayments = totalPayments - currentPP.One_off_Payment_Due__c;
	                }else{
	                    currentPP.One_off_Payment_Received__c = currentPP.One_off_Payment_Received__c + totalPayments;
	                    totalPayments = 0.00;
	                }
	                updatedPP.add(currentPP);   
	            }
	            
	            if(totalPayments > 0){
	                List<Decimal> sequenceList = new List<Decimal>();
	                Map<Decimal,Payment_Plan_Line_Item__c> pplinesMap = new Map<Decimal,Payment_Plan_Line_Item__c>();
	                for(Payment_Plan_Line_Item__c currentPPLine : currentPPLines){
	                    sequenceList.add(currentPPLine.Sequence__c);
	                    pplinesMap.put(currentPPLine.Sequence__c, currentPPLine);
	                }
	                sequenceList.sort();
	                
	                for(Decimal sequence : sequenceList){
	                    if(totalPayments > 0){
	                        Payment_Plan_Line_Item__c currentPPLine = pplinesMap.get(sequence);
	                        if(currentPPLine.Amount_Paid__c == null){
	                            currentPPLine.Amount_Paid__c = 0.00;
	                        }
	                        
	                        if(totalPayments > currentPPLine.Amount_Due__c){
	                            currentPPLine.Amount_Paid__c = currentPPLine.Amount_Paid__c + currentPPLine.Amount_Due__c;
	                            totalPayments = totalPayments - currentPPLine.Amount_Due__c;
	                        }else{
	                            currentPPLine.Amount_Paid__c = currentPPLine.Amount_Paid__c + totalPayments;
	                            totalPayments = 0.00;
	                        }
	                        currentPPLine.Payment_Date__c = System.today();
	                        updatedPPLines.add(currentPPLine);
	                    }
	                }
	            }
	        }
	        
	    }
	    
	    
	    system.debug('P2Ps to be updated as part of PaymentBeforeTrigger: ' + updatedP2P);
        system.debug('PPs to be updated as part of PaymentBeforeTrigger: ' + updatedPP);
        system.debug('PP Lines to be updated as part of PaymentBeforeTrigger: ' + updatedPPLines);
        
        if( updatedP2P.size() > 0){
            update updatedP2P;
        }
     
        if( updatedPP.size() >0){
            update updatedPP;
        }
        if(updatedPPLines.size() >0){
        	update updatedPPLines;   
        } 
     
        update paymentsToUpdated;
        delete paymentsToBeDeleted;
   	  }
   	  
   	 
   	 public void finish(Database.BatchableContext BC){
   	 	DataBase.executeBatch(new CollectionStepUpdateBatch());
   	 }
   	 
   	 private String query{
        get{
            return ' Select p.Payment_Source_Code__c, p.Payment_ID__c, p.Payment_Date__c, p.Name, p.Id, p.Billing_Account__c, p.Amount__c '+ 
            'From Payment__c p where Allocated__c = false ';
        }
    }

}