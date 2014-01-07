public with sharing class CommunicationHelper {
	
	public static map<string, Id> orgWideEmailAddressMap = new map<string, Id>();
	
	public static id getOrgWideEmailId ( string emailAddress ){
		
		if ( orgWideEmailAddressMap.size() == 0 ){
			// fetch 
			OrgWideEmailAddress[] owea = [select Id,Address,DisplayName from OrgWideEmailAddress];
			for (OrgWideEmailAddress add : owea ){
				orgWideEmailAddressMap.put ( add.DisplayName, add.Id);
			}
		}		
		return orgWideEmailAddressMap.get ( emailAddress ); 
	}

	
	public static void sendEmail (List<CommunicationInfo> infos, String orgWideDefault) {
		//New instance of a single email message
		
		List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
				
		List<User> targetAdminUsers = [select Id, Email from User where Profile_Name__c = 'System Administrator'
		and Email like 'elena.pasia@cloudsense.com' ];	
		
		for (CommunicationInfo info : infos) {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			
			// Who you are sending the email to 
			mail.setTargetObjectId(info.ba.Primary_Contact__c);
			
			// The email template ID used for the email
			Id templateId = getTemplateId(info.ba.Brand__c, info.paType);
			
			system.debug('****TemplateId returned: '+ templateId);
			
			if (templateId != null) {
				mail.setTemplateId(templateId);
				
				mail.setWhatId(info.paId);
				mail.setBccSender(false);
				mail.setUseSignature(false);

				if ( orgWideDefault != null && getOrgWideEmailId( orgWideDefault ) != null) {
					mail.setOrgWideEmailAddressId( getOrgWideEmailId( orgWideDefault ) );
				} else {
					mail.setSenderDisplayName('Talk Talk Billing Department');			
				}
				
				mail.setSaveAsActivity(true);
				mails.add(mail);

			}
			else {
				//mails.add(createAdminNotificationEmail(info, targetAdminUsers));
				throw new CommunicationException('No Communication Template has been found. Please check the Billing Account has a valid Brand (' +
					Constants.BillingAccountBrand_TalkTalk + '/' + Constants.BillingAccountBrand_AOL +')');
			}
		}
		
		if (!Test.isRunningTest()) {
			Messaging.sendEmail(mails);
		}
	}

	
	
	
	
	
	/*
	private static Messaging.SingleEmailMessage createAdminNotificationEmail(CommunicationInfo info, List<User> adminUsers) {
		
		string billingAccountUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + info.ba.Id;
		
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		
		email.setPlainTextBody('An error has occured when attempting to email Customer notifying them of a new ' + 
								((info.paType == Enums.PA_Type.PP) ? 'Payment Plan ' : 'Promise To Pay ') + ' as Template was not found. ' +
								' The Billing Account is the following: ' + info.ba.Name +' (' + billingAccountUrl + ')');
		
		email.setHtmlBody('An error has occured when attempting to email Customer notifying them of a new ' + 
								((info.paType == Enums.PA_Type.PP) ? 'Payment Plan ' : 'Promise To Pay ') + ' as Template was not found. ' +
								' The Billing Account is the following: <a href="' + billingAccountUrl + '">' + htmlEncode(info.ba.Name) + '</a>');
							
		email.setToAddresses(new string[] { adminUsers[0].Email });
		
		return email;
	}
	*/
	
	public static void createLetterTasks(Map<Id, Id> billAccountToCollectionCaseMap) {
		
		List<Task> tasksToInsert = new List<Task>();
        
        for (Id baId : billAccountToCollectionCaseMap.keySet()) {
        	Task newTask = new Task();
        	
        	//get the Case of the Billing Account of the PP
        	newTask.WhatId = billAccountToCollectionCaseMap.get(baId);
			newTask.Date_entered__c = system.now();
			//newTask.Step_type__c = 'Communication'; 
			newTask.ActivityDate = Date.today(); 
			// newTask.Step_name__c = stepName;  // ?
			newTask.subject = Constants.TaskSubject_PaymentPlanSetup;
			//newTask.Path_Name__c = pathName;
			newTask.Status = Constants.CollectionTaskType_NotStarted;
			newTask.Status__c  = Constants.CollectionTaskType_NotStarted;
			
        	
        	tasksToInsert.add(newTask);
        }
        
        insert tasksToInsert;
	}
	
	public class CommunicationException extends Exception {}
	

	
	private static string htmlEncode(string text) {
		if (text != null) {
			text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;');
		}
		return text;
	}
	
	public static Id getTemplateId (String baBrand, Enums.PA_Type paType) { 
		
		 if (Test.isRunningTest()) {
			return 'a0Fg0000000mTr3'; //doesn't matter
		} 
        
		CustomSettingsUtility.EmailCommunicationTemplatesSettings templateSettings = CustomSettingsUtility.getEmailCommunicationTemplatesSettings();
		
		if (baBrand == Constants.BillingAccountBrand_AOL && paType == Enums.PA_Type.PP) {
			return templateSettings.paAolTemplateId;
		}
		else if (baBrand == Constants.BillingAccountBrand_TalkTalk && paType == Enums.PA_Type.PP) {
			return templateSettings.paTalkTalkTemplateId;
		}
		else if (baBrand == Constants.BillingAccountBrand_AOL && paType == Enums.PA_Type.P2P) {
			return templateSettings.p2pAolTemplateId;
		}
		else if (baBrand == Constants.BillingAccountBrand_TalkTalk && paType == Enums.PA_Type.P2P) {
			return templateSettings.p2pTalkTalkTemplateId;
		} 
		
		return null;
	}

}