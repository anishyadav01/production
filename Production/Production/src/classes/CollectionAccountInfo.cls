/**
This class holds the info to pass around collection methods....


*/


public class CollectionAccountInfo {

	public Billing_Account__c billingAccount { get; set; }
	public Task currentTask { get; set; }
	public Id pathId { get; set; }
	public Id stepId { get; set; }	
	public string action { get; set; }
	public boolean exitCollection { get; set; }
	public Integer numberOfInstalments { get; set; }
	public Integer instalmentNumber { get; set; }	
	public date nextPaymentDueDate { get; set; }
	
	public CollectionAccountInfo(Billing_Account__c ba) {
		billingAccount = ba;
		stepId = null;
		pathId = null;
		exitCollection = false;
		nextPaymentDueDate = null;
		action = null; //Constants.CollectionStepAction_MoveStep;
	}

	public CollectionAccountInfo(Billing_Account__c ba, Id aPathId, boolean exitColl, Date nextPayDate) {
		billingAccount = ba;
		pathId = aPathId;
		stepId = null;
		exitCollection = exitColl;
		nextPaymentDueDate = nextPayDate;
		action = null; //Constants.CollectionStepAction_MoveStep;
	}
	
	public CollectionAccountInfo(Billing_Account__c ba, Id aPathId, boolean exitColl) {
		billingAccount = ba;
		pathId = aPathId;
		stepId = null;
		exitCollection = exitColl;
		nextPaymentDueDate = null;
		action = null; //Constants.CollectionStepAction_MoveStep;
	}
	
	public CollectionAccountInfo(Billing_Account__c ba, Id aPathId) {
		billingAccount = ba;
		pathId = aPathId;
		stepId = null;
		exitCollection = false;
		nextPaymentDueDate = null;
		action = null; //Constants.CollectionStepAction_MoveStep;
	}
	
	
	public CollectionAccountInfo(Billing_Account__c ba, String anAction, date nextPaymentDate) {
		billingAccount = ba;
		action = anAction;
		nextPaymentDueDate = nextPaymentDate;
	}
	
	
	static testMethod void testAllConstructors() {
    	// create path
    	Collection_Path__c path = new Collection_Path__c (name = 'pathOne');
    	insert path;		
		
		CollectionAccountInfo colInfo = new CollectionAccountInfo( new Billing_Account__c( name='billing Acc' ) );
		system.assertEquals(colInfo.billingAccount.name, 'billing Acc');
		
		colInfo = new CollectionAccountInfo( new Billing_Account__c( name='billing Acc' ), path.id );
		system.assertEquals(colInfo.billingAccount.name, 'billing Acc');
		system.assertEquals(colInfo.pathId, path.id);
		
		colInfo = new CollectionAccountInfo( new Billing_Account__c( name='billing Acc' ), path.id, true );
		system.assertEquals(colInfo.billingAccount.name, 'billing Acc');
		system.assertEquals(colInfo.pathId, path.id);
		system.assertEquals(colInfo.exitCollection, true);

		colInfo = new CollectionAccountInfo( new Billing_Account__c( name='billing Acc' ), 'action', system.today() );
		system.assertEquals(colInfo.billingAccount.name, 'billing Acc');
		system.assertEquals(colInfo.action, 'action');
		system.assertEquals(colInfo.nextPaymentDueDate, system.today());

		colInfo = new CollectionAccountInfo( new Billing_Account__c( name='billing Acc' ), path.id, true, system.today()  );
		system.assertEquals(colInfo.billingAccount.name, 'billing Acc');
		system.assertEquals(colInfo.pathId, path.id);
		system.assertEquals(colInfo.exitCollection, true);
		system.assertEquals(colInfo.nextPaymentDueDate, system.today());
		

    }	
	
	
}