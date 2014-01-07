public with sharing class CollectionsExportAndSendData {

		public static Map<String, String> commTypeCSVHeaderMap {get;set;}
		public static Map<String, String> commTypeCSVValueMap {get;set;}

		static {
			commTypeCSVHeaderMap = new Map<String, String>();
			commTypeCSVValueMap = new Map<String, String>();

			commTypeCSVHeaderMap.put(Constants.CollectionCommunicationType_TTS, 'Home,Work,Mobile,Additional,Name,Reference');
			commTypeCSVHeaderMap.put(Constants.CollectionCommunicationType_SMS, 'Number,Misc 1,Misc 2');
		}

		public static String createTestData(String commType, List<Id> billingAccountIds) {
			List<Billing_Account__c> listResultBillingAccounts;
			String csvLines = '';

			listResultBillingAccounts = [SELECT
										Primary_Contact__r.HomePhone, Primary_Contact__r.Phone,
										Primary_Contact__r.MobilePhone, Primary_Contact__r.OtherPhone, Primary_Contact__r.Name,
										Account_Key__c, Brand__c, CURRENT_DUE__c,
										(SELECT CLI__c, UsageEndDate FROM Assets__r)
									FROM
										Billing_Account__c
									WHERE
										Id IN :billingAccountIds];

			if(Constants.CollectionCommunicationType_TTS == commType) {
				for(Billing_Account__c acc : listResultBillingAccounts) {
					csvLines += acc.Primary_Contact__r.HomePhone + ',' + acc.Primary_Contact__r.Phone + ',' +
							   acc.Primary_Contact__r.MobilePhone + ',' + acc.Primary_Contact__r.OtherPhone + ',' +
							   acc.Primary_Contact__r.Name + ',' + acc.Account_Key__c + '\n';
				}
			} else if(Constants.CollectionCommunicationType_SMS == commType) {
				for(Billing_Account__c acc : listResultBillingAccounts) {
					csvLines += acc.Primary_Contact__r.MobilePhone + ',' + acc.Primary_Contact__r.Name +
								',' + acc.Account_Key__c + '\n';
				}
			} else if(Constants.CollectionCommunicationType_Letter == commType) {
				for(Billing_Account__c acc : listResultBillingAccounts) { //MISSING:Account_Status_Description,ZIP, Addresses,Disconnection date
					String CLI = '';
					Date disconnectionDate;
					if(acc.Assets__r != null && acc.Assets__r.size() > 0) {
						CLI = acc.Assets__r[0].CLI__c;
						disconnectionDate = acc.Assets__r[0].UsageEndDate;
					}
					csvLines += acc.Primary_Contact__r.HomePhone + ',' + acc.Brand__c + ',' + acc.Account_Key__c + ',' + acc.Primary_Contact__r.Name + ',' +
								CLI + ',' + acc.CURRENT_DUE__c + ',' + (disconnectionDate != null ? disconnectionDate + '' : '') + '\n';
				}
			}

			return csvLines;
		}

		public static Document createAndSendFile(String commType, String csvLines) {
			String fileData = commTypeCSVHeaderMap.get(commType) + '\n' + csvLines;

			Id sFolderId = [Select Id From Folder where Name = 'Extracted Data'].Id;

			Document dn = new Document();
			dn.Name = 'TestFile';
			dn.FolderId = sFolderId;
			dn.Body = Blob.valueOf(fileData);
			dn.ContentType = 'text/plain';
			dn.Type = 'csv';
			insert dn;

			Account acc = new Account();
			acc.Name = 'New Account';

            Messaging.SingleEmailMessage email = createEmail(Collections_Settings__c.getInstance(UserInfo.getUserId()).Email_Address_for_Extracted_Data__c, Blob.valueOf(fileData), 'test.csv', acc, dn.Id);
            if(email != null) {
                Messaging.SendEmailResult[] r =  Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            }

			return dn;
		}

		 public static Messaging.SingleEmailMessage createEmail(String emailAddress, Blob attachment, String attachmentName, Account acc, String docId){
	        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
	        if(attachment != null){
	            // Create the email attachment
	            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	            efa.setFileName(attachmentName);
	            efa.setBody(attachment);
	            email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
	        }
	        //email.setTemplateId(emailTemplateId);
	        email.setToAddresses(new List<String>{emailAddress});
	        //email.setTargetObjectId(contactId);
	        email.setSubject('TalkTalk extracted billing account data');
	        email.setPlainTextBody('Attached is the extracted data. Link to the file is ' + getSfInstance() + '/' + docId);
	        email.setWhatId(acc.Id);
	        // Specify the address used when the recipients reply to the email.
	        email.setReplyTo('noreply@talktalk.com');

	        // Specify the name used as the display name.
	        email.setSenderDisplayName('Talk Talk');

	        return email;

    	}

    	@future
    	public static void generateAndSendFile(String commType, List<Id> caseIds) {
    		String fileLines = createTestData(commType, caseIds);
    		createAndSendFile(commType, fileLines);
    	}

    	public static String getSfInstance()
		{
		  return URL.getSalesforceBaseUrl().toExternalForm();
		}

		public class FileElement {
			public String HomePhone{ get;set; }
            public String WorkPhone{ get;set; }
            public String MobilePhone{ get;set; }
            public String AdditionalPhone{ get;set; }
            public String seqNo{ get;set; }
            public String Name{ get;set; }
            public String Reference{ get;set; }

			public FileElement() {
			}

			public FileElement(String HomePhone, String WorkPhone) {
				this.HomePhone = HomePhone;
				this.WorkPhone = WorkPhone;
			}

			public String toCSVString() {
				return HomePhone + ',' + WorkPhone;
			}
		}
}