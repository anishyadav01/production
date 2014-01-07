public with sharing class CollectionTaskInfo {
	public Id currentCaseId { get; set; }	
	public String stepType { get; set; }
	public String stepCommunicationType { get; set; }			
	public String stepName { get; set; }	
	public String pathName { get; set; }	
	public date dueDate { get; set; }	
	public integer instalmentNumber { get; set; } 

	public CollectionTaskInfo ( Id currentCaseId, String stepType, String stepName, String pathName, date dueDate ) {
		this.currentCaseId = currentCaseId;
		this.stepType = stepType;
		this.stepName = stepName;
		this.pathName = pathName;
		this.dueDate = dueDate;
	}
	
	public CollectionTaskInfo (  Id currentCaseId, String stepType, String stepName, String pathName, date dueDate, integer instNumber ){
		this.currentCaseId = currentCaseId;
		this.stepType = stepType;
		this.stepName = stepName;
		this.pathName = pathName;
		this.dueDate = dueDate;
		this.instalmentNumber = instNumber; 
	}


}


//CollectionTaskCloseReason_Payment