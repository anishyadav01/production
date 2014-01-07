public with sharing class MoveCollectionStepController {
	private Id accId = null;

    public Billing_Account__c billingAccount {get; set;}
    private string previousPath = null;
    private string previousStep = null;    
    
    private string newPath = null;    
    private string newStep = null;
    
    public MoveCollectionStepController(ApexPages.StandardController controller) {
       this.billingAccount = (Billing_Account__c)controller.getRecord();
		//TODO check why this is not returning the whole object

		list<Billing_Account__c> accountList = new list<Billing_Account__c>();
	    accId = System.currentPageReference().getParameters().get('Id');  
	    accountList = [Select ID, Name, Current_Treatment_Path__c, Current_Treatment_Step__c, Collection_Paused__c, Next_Treatment_Step__c From Billing_Account__c Where ID = :accId LIMIT 1];
	    if(accountList.isEmpty() == false){
	      	this.billingAccount = accountList[0];
	    }else{
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'The Billing Account ID is invalid.');
			ApexPages.addMessage(msg);
	    }

       this.previousPath = this.billingAccount.Current_Treatment_Path__c;
       this.previousStep = this.billingAccount.Current_Treatment_Step__c;
    }
    
    
    // this method will compare the changes in the previous and new path and steps and update accordingly.    
    public pageReference moveStep(){
        //check if anything has changed
       this.newPath = this.billingAccount.Current_Treatment_Path__c;
       this.newStep = this.billingAccount.Current_Treatment_Step__c;
       // set back the previous values 
       this.billingAccount.Current_Treatment_Path__c =  this.previousPath;
       this.billingAccount.Current_Treatment_Step__c = this.previousStep;
       
       
        if ( this.previousPath != this.newPath || this.previousStep != this.newStep ){
            CollectionAccountInfo accInfo = new CollectionAccountInfo( billingAccount );
            accInfo.pathId = this.newPath;
            accInfo.stepId = this.newStep;
            
            if (this.previousPath == null){
                //  just moving into collections .. call assign path
                PathHandler.assignPath( accInfo );
            
            } else {
                // moving step ... call move path
                StepHandler.moveStep( accInfo );
            } 
        }else{
            // no changes ... nothing to do
        
        }
		return returnToOrigination();
    }

//-------------------- temp methods .... should be removed ----------START--------------------------------------------
    // this method will compare the changes in the previous and new path and steps and update accordingly.    
    public pageReference moveToDefaultStep(){
            CollectionAccountInfo accInfo = new CollectionAccountInfo( billingAccount );
            accInfo.pathId = null;
            accInfo.stepId = null;
            StepHandler.moveStep( accInfo );

		return returnToOrigination();
    }
    

    // this method will compare the changes in the previous and new path and steps and update accordingly.    
    public pageReference exitCollection (){
            CollectionAccountInfo accInfo = new CollectionAccountInfo( billingAccount );
            accInfo.pathId = this.newPath;
            accInfo.stepId = this.newStep;
            accInfo.exitCollection = true;
            
            //  just moving into collections .. call assign path
            PathHandler.exitPath( accInfo );
		return returnToOrigination();
    }    
    
//-------------------- temp methods .... should be removed -------------END-----------------------------------------    
    
	private pageReference returnToOrigination(){
		PageReference page = new PageReference('/' + accId);
		page.setRedirect(true);
		return page;
	}

}