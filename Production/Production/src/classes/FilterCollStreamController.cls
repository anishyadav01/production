public with sharing class FilterCollStreamController {

	public List<Case> pagedResults;
	private integer counter=0;  //keeps track of the offset
   	private integer listSize=2; //sets the page size or number of rows
   	public integer totalSize; //used to show user the total size of the list
	public List<Id> collOpenCaseIds;
	public List<SelectOption> codeOptions{ get;set; }
	public String selectedCommCode { get;set; }
	public String selectedCommType { get;set; }
	public static List<SelectOption> commTypeOptions { get;set; }
	public static Map<String, String> commTypeToCodeMapping { get;set; }
	public Integer numberOfResultsToFilter { get;set; }
	public String currentCommunicationFullCode { get;set; }
	public Boolean validSearchDone { get;set; }

	static{
		commTypeOptions = new List<SelectOption>();
		commTypeOptions.add(new SelectOption('--', ' '));
		commTypeOptions.add(new SelectOption(Constants.CollectionCommunicationType_SMS, Constants.CollectionCommunicationType_SMS));
		commTypeOptions.add(new SelectOption(Constants.CollectionCommunicationType_TTS, Constants.CollectionCommunicationType_TTS));
		commTypeOptions.add(new SelectOption(Constants.CollectionCommunicationType_Letter, Constants.CollectionCommunicationType_Letter));
		commTypeOptions.add(new SelectOption(Constants.CollectionCommunicationType_Call, Constants.CollectionCommunicationType_Call));
		commTypeOptions.add(new SelectOption(Constants.CollectionCommunicationType_Email, Constants.CollectionCommunicationType_EMail));

		commTypeToCodeMapping = new Map<String, String>();
		commTypeToCodeMapping.put(Constants.CollectionCommunicationType_SMS, Constants.CollectionCommunicationType_SMS + '/');
		commTypeToCodeMapping.put(Constants.CollectionCommunicationType_TTS, Constants.CollectionCommunicationType_TTS + '/');
		commTypeToCodeMapping.put(Constants.CollectionCommunicationType_Letter, 'F');
		commTypeToCodeMapping.put(Constants.CollectionCommunicationType_Call, 'CALL/');
		commTypeToCodeMapping.put(Constants.CollectionCommunicationType_Email, Constants.CollectionCommunicationType_EMail);

	}

	public FilterCollStreamController() {
		 List<Task> collOpenCaseTasks= 	[SELECT
	 										WhatId
	 									FROM
	 										Task
	 									WHERE
	 										Status = 'Not Started' AND Record_Type_Name__c = 'Collection' AND ActivityDate > TODAY AND What.Type = 'Case'
	 									];
		 collOpenCaseIds = new List<Id>();
		 for(Task task : collOpenCaseTasks) {
		 	collOpenCaseIds.add(task.WhatId);
		 }
		 totalSize = collOpenCaseIds.size();


		 //Fetch all of the communication type mappings for the filtering of data
		 List<Communication_Code_Mapping__c> codeMappings = [SELECT
		 														Communication_Code__c, Communication_Code_Explanation__c
		 													 FROM
		 													 	Communication_Code_Mapping__c
		 													 WHERE
		 													 	Is_Active__c = true];
		codeOptions = new List<SelectOption>();
		codeOptions.add(new SelectOption('--', ' '));
		for(Communication_Code_Mapping__c mapping : codeMappings) {
	 	 	codeOptions.add(new SelectOption(mapping.Communication_Code__c, mapping.Communication_Code_Explanation__c));
		}

		numberOfResultsToFilter = 56;

		getPagedResults();
		validSearchDone = false;
	}

	public Boolean getHasResults() {
		return !pagedResults.isEmpty();
	}

	public Integer getResultNumber(){
		return pagedResults.size();
	}

	public List<Case> getPagedResults() {
		system.debug('Executing fetching filtered Results...');
		pagedResults	= 	[SELECT
		 						Billing_Account__r.Name, Billing_Account__r.Primary_Contact__r.Name,
		 						Billing_Account__r.Account_Key__c, Billing_Account__r.Unbilled_Amount__c,
		 						Billing_Account__r.Account_Balance__c, Billing_Account__r.Current_Overdue__c,
		 					    Id, Billing_Account__c
		 					FROM
		 						Case
		 					WHERE
		 						Id IN :collOpenCaseIds
		 					ORDER BY
		 						Id
		 					LIMIT :listSize OFFSET :counter
		 					];
		system.debug('Paged Results fetched: ' + pagedResults);
		return pagedResults;
	}

	public void searchAccounts() {
		validSearchDone = false;
		system.debug('Selected comm code and type are ' + selectedCommCode + ' and ' + selectedCommType);
		if(selectedCommCode == '--' || selectedCommType  == '--') {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The fields have to be populated'));
			//return null;
		}
		String[] commCodeSplit = selectedCommCode.split('/');
		if(commCodeSplit.size() == 2) {
			currentCommunicationFullCode = commCodeSplit[0] + '/' + commTypeToCodeMapping.get(selectedCommType) + commCodeSplit[1];
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in filters'));
		}

		validSearchDone = true;
		List<Task> collOpenCaseTasks= 	[SELECT
	 										WhatId
	 									FROM
	 										Task
	 									WHERE
	 										Status = 'Not Started' AND Record_Type_Name__c = 'Collection' AND ActivityDate > TODAY AND What.Type = 'Case'
	 										AND Step_Communication_Code__c = :currentCommunicationFullCode
	 									];
		 collOpenCaseIds = new List<Id>();
		 for(Task task : collOpenCaseTasks) {
		 	collOpenCaseIds.add(task.WhatId);
		 }
		 totalSize = collOpenCaseIds.size();

		 //return null;
	}

	public void generateFile() {
		List<Id> billingAccountIds = new List<Id>();
		for(Case pagedResult : pagedResults) {
			billingAccountIds.add(pagedResult.Billing_Account__c);
		}

		CollectionsExportAndSendData.generateAndSendFile(selectedCommType, billingAccountIds);
	}

	/**Methods needed for pagination**/
	public PageReference Beginning() { //user clicked beginning
      counter = 0;
      return null;
   }

   public PageReference Previous() { //user clicked previous button
      counter -= listSize;
      return null;
   }

   public PageReference Next() { //user clicked next button
      counter += listSize;
      return null;
   }

   public PageReference End() { //user clicked end
      counter = totalSize - math.mod(totalSize, listSize) - 1;
      return null;
   }

   public Boolean getDisablePrevious() {
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext() { //this will disable the next and end buttons
      if (counter + listSize < totalSize) return false; else return true;
   }

   public Integer getTotalSize() {
      return totalSize;
   }

   public Integer getPageNumber() {
      return counter/listSize + 1;
   }

   public Integer getTotalNumberResultsPossible() {
   	  return collOpenCaseIds.size();
   }

   public Integer getTotalPages() {
      if (math.mod(totalSize, listSize) > 0) {
         return totalSize/listSize + 1;
      } else {
         return (totalSize/listSize);
      }
   }

}