public class CustomSettingsUtility {
	
	/*
	 * Class to hold all Email Communication Templates used for PP and P2P notificiations
	 */
	public class EmailCommunicationTemplatesSettings {
		
		public Id paTalkTalkTemplateId {get; set;}
		public Id paAolTemplateId {get; set;}
		public Id p2pTalkTalkTemplateId {get; set;}
		public Id p2pAolTemplateId {get; set;}
		
		public EmailCommunicationTemplatesSettings() {}
		
		public EmailCommunicationTemplatesSettings(Id paTT_Id, Id paAOL_Id, Id p2pTT_Id, Id p2pAOL_Id) {
			paTalkTalkTemplateId = paTT_Id;
			paAolTemplateId = paAOL_Id;
			p2pTalkTalkTemplateId = p2pTT_Id;
			p2pAolTemplateId = p2pAOL_Id;
		}
	}
	
	/*
	 * Class to hold all Collection Paths related to Payment Plans and P2Ps
	 */
	public class PaymentArrangementCollectionPathSettings {
		
		public Id paymentPlanPathId {get; set;}
		public Id p2pLessThan30PathId {get; set;}
		public Id p2p30To60PathId {get; set;}
		
		public PaymentArrangementCollectionPathSettings() {}
		
		public PaymentArrangementCollectionPathSettings (Id ppId, Id p2pLessThan30Id, Id p2pMoreThan30Id) {
			paymentPlanPathId = ppId;
			p2pLessThan30PathId = p2pLessThan30Id;
			p2p30To60PathId = p2pMoreThan30Id;
		}
	}
	

 	private static EmailCommunicationTemplatesSettings emailTemplateSettings;
 	private static PaymentArrangementCollectionPathSettings paPathSettings;
 	
 	
 	public static PaymentArrangementCollectionPathSettings getPaymentArrangementCollectionPathSettings() {
 		if (paPathSettings == null) {
 			
 			//Get Collection Settings
	        Collections_Settings__c cs = Collections_Settings__c.getInstance(UserInfo.getUserId());
 			Set<String> paCollectionPathNames = new Set<String> {cs.P2P_Path_for_Less_than_30d_Debt__c,
    														 	cs.P2P_Path_for_30_60d_Debt__c,
    														 	cs.Payment_Plan_Path__c};
    	
	    	List<Collection_Path__c> paPaths = [select Id, Name from Collection_Path__c where Name in :paCollectionPathNames];
	    	
	    	Id ppCollectionPathId, p2pLessThan30DaysDebtPathId, p2p30To60DaysDebtPathId;
	    	
	    	for (Collection_Path__c cp : paPaths) {
	    		if (cp.Name == cs.Payment_Plan_Path__c) {
	    			ppCollectionPathId = cp.Id;
	    		}
	    		else if (cp.Name == cs.P2P_Path_for_Less_than_30d_Debt__c) {
	    			p2pLessThan30DaysDebtPathId = cp.Id;
	    		}
	    		else if (cp.Name == cs.P2P_Path_for_30_60d_Debt__c) {
	    			p2p30To60DaysDebtPathId = cp.Id;
	    		}
	    	}
	    	
	    	paPathSettings = new PaymentArrangementCollectionPathSettings(ppCollectionPathId, p2pLessThan30DaysDebtPathId, p2p30To60DaysDebtPathId);
 		}
 		
 		return paPathSettings;
 	} 
 	
 	public static EmailCommunicationTemplatesSettings getEmailCommunicationTemplatesSettings() {
 		 
 		 if (emailTemplateSettings == null) {
 		 	
 		 	//Get Collection Settings
	        Collections_Settings__c cs = Collections_Settings__c.getInstance(UserInfo.getUserId());
	        Set<String> ppTemplateNames = new Set<String> {cs.PA_Confirmation_Email_Template_AOL__c, 
	        												cs.PA_Confirmation_Email_Template_TT__c, 
	        												cs.PTP_Confirmation_Email_Template_AOL__c,
	        												cs.PTP_Confirmation_Email_Template_TT__c};
	        												
	        //Retrieve the 4 Email Templates
	        List<EmailTemplate> templates = [Select Id, Name From EmailTemplate where Name in :ppTemplateNames];
			Id paTT, paAol, p2pTT, p2pAol;
			
		
	        for (EmailTemplate et : templates) {
	        	if (et.Name == cs.PA_Confirmation_Email_Template_TT__c) {
	        		paTT = et.Id;
	        	}
	        	else if (et.Name == cs.PA_Confirmation_Email_Template_AOL__c) {
	        		paAol = et.Id;
	        	}
	        	if (et.Name == cs.PTP_Confirmation_Email_Template_AOL__c) {
	        		p2pAol = et.Id;
	        	}
	        	if (et.Name == cs.PTP_Confirmation_Email_Template_TT__c) {
	        		p2pTT = et.Id;
	        	}
	        }
	        
	        emailTemplateSettings = new EmailCommunicationTemplatesSettings(paTT, paAol, p2pTT, p2pAol);
 		 }
 		 
 		 return emailTemplateSettings;
 	}
 	
 	
 	/*
 	 * Populate map of Email Communication Templates used when a PP or P2P is setup
 	 */
 	 /*
 	private static map<String, Id> getEmailCommTemplateMap() {
 		if (emailCommTemplateMap == null) {
 			
			//Get Collection Settings
	        Collections_Settings__c cs = Collections_Settings__c.getInstance(UserInfo.getUserId());
	        Set<String> ppTemplateNames = new Set<String> {cs.PA_Confirmation_Email_Template_AOL__c, 
	        												cs.PA_Confirmation_Email_Template_TT__c, 
	        												cs.PTP_Confirmation_Email_Template_AOL__c,
	        												cs.PTP_Confirmation_Email_Template_TT__c};
	        												
	        List<EmailTemplate> templates = [Select Id, Name From EmailTemplate where Name in :ppTemplateNames];
		
	        for (EmailTemplate et : templates) {
	        	emailCommTemplateMap.put(et.Name, et.Id);
	        }
 		}
 		return emailCommTemplateMap;
 	}
 	*/
 	
 /*
 	public static Id getPaymentPlanCollectionPathId() {
 		if (ppCollectionPathId == null) {
 			populatePaymentArrangementCollectionPaths();
 		}
 		return ppCollectionPathId;
 	}
 	
 	
 	public static Id get30To60DaysDebtCollectionPathId() {
 		if (p2p30To60DaysDebtPathId == null) {
 			populatePaymentArrangementCollectionPaths();
 		}
 		return p2p30To60DaysDebtPathId;
 	}
 	
 	
 	public static Id getP2PLessThan30DaysDebtCollectionPathId() {
 		if (p2pLessThan30DaysDebtPathId == null) {
 			populatePaymentArrangementCollectionPaths();
 		}
 		return p2pLessThan30DaysDebtPathId;
 	}
 	
 	
 	private static void populatePaymentArrangementCollectionPaths() {
 		
 		//Get Collection Setting
        Collections_Settings__c cs = Collections_Settings__c.getInstance(UserInfo.getUserId());
        Set<String> paCollectionPathNames = new Set<String> {cs.P2P_Path_for_Less_than_30d_Debt__c,
    														 cs.P2P_Path_for_30_60d_Debt__c,
    														 cs.Payment_Plan_Path__c};
    	
    	List<Collection_Path__c> paPaths = [select Id, Name from Collection_Path__c where Name in :paCollectionPathNames];
    	
    	for (Collection_Path__c cp : paPaths) {
    		if (cp.Name == cs.Payment_Plan_Path__c) {
    			ppCollectionPathId = cp.Id;
    		}
    		else if (cp.Name == cs.P2P_Path_for_Less_than_30d_Debt__c) {
    			p2pLessThan30DaysDebtPathId = cp.Id;
    		}
    		else if (cp.Name == cs.P2P_Path_for_30_60d_Debt__c) {
    			p2p30To60DaysDebtPathId = cp.Id;
    		}
    	}
 	}
 	*/

}