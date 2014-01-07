public class Constants {
	
	/**
     *  Text to identify the Case Record Type 
     */
    public static final String CaseRecordType_Lithium = 'TalkTalk Community';
    public static final String CaseRecordType_SocialMedia = 'Social Media';
    public static final String CaseRecordType_LiveAgent = 'Live Agent';
    public static final String CaseRecordType_Collection = 'Collection';
    
    /**
     *  Text to identify the Case Status 
     */
    public static final String CaseStatus_New = 'New';
    public static final String CaseStatus_Resolved = 'Resolved';
    public static final String CaseStatus_CustomerResponded = 'Customer Responded';
    public static final String CaseStatus_Assigned = 'Assigned';
    public static final String CaseStatus_Closed = 'Closed';
    
    /**
     *  Text to identify the Payment Plan Status 
     */
    public static final String PaymentPlanStatus_Saved = 'Saved';
    public static final String PaymentPlanStatus_PendingApproval = 'Pending Approval';
    public static final String PaymentPlanStatus_Open = 'Open';
    public static final String PaymentPlanStatus_Closed = 'Closed';
    
    /**
    * Constants to identify collection step types
    */
    public static final String CollectionStepType_Communication = 'Communication';
    public static final String CollectionStepType_BAR = 'BAR';
    public static final String CollectionStepType_Disconnect = 'Disconnect';
    public static final String CollectionStepType_DCA = 'DCA';
    public static final String CollectionStepType_Wait = 'Wait';
    public static final String CollectionStepType_Payment = 'Payment';
    public static final String CollectionStepType_CheckPayment = 'Check Payment';    
    public static final String CollectionStepType_Payment_Defaulted = 'Payment Defaulted';
    
    
    /**
    * Constants to identify collection communication types
    */
    public static final String CollectionCommunicationType_SMS = 'SMS';
    public static final String CollectionCommunicationType_TTS = 'TTS';
    public static final String CollectionCommunicationType_Letter = 'Letter';
    public static final String CollectionCommunicationType_EMail = 'EMail';
    public static final String CollectionCommunicationType_Call = 'Call';    

    /**
    * Constants to identify collection Task types
    */
    public static final String CollectionTaskType_NotStarted = 'Not Started';
    public static final String CollectionTaskType_InProgress = 'In Progress';
    public static final String CollectionTaskType_Executed = 'Executed';
    public static final String CollectionTaskType_Completed = 'Completed';
    
    /**
    * Constants to identify Billing Account Brand
    */
    public static final String BillingAccountBrand_TalkTalk = 'TalkTalk';
    public static final String BillingAccountBrand_AOL = 'AOL Broadband';
    
    /**
    * Constants to identify Preferred Communication Method
    */
    public static final String PreferredCommMethod_Email = 'Email';
    public static final String PreferredCommMethod_Letter = 'Letter';
    


    /**
    * Constants to identify actions passed for moving steps
    */
    public static final String CollectionStepAction_Payment = 'Payment';
    public static final String CollectionStepAction_PartPayment = 'Part Payment';
    public static final String CollectionStepAction_MoveStep = 'MoveStep';


	/**
    * Constants to identify criteria actions passed 
    */
    public static final String CollectionStepCriteriaAction_GotoStep = 'GoTo Step';
    
    /**
    * Constants to identify Task Subject for letter notification that a PP has been setup
    */
    public static final String TaskSubject_PaymentPlanSetup = 'Payment Plan Setup Notification';
    
    public static final String CollectionTaskCloseReason_Payment = 'Payment received';
    public static final String CollectionTaskCloseReason_Automatic = 'Automatic step change';
    public static final String CollectionTaskCloseReason_Manual = 'Manual step change';
    
    /**
    * Constants to identify Completion Step for PP and P2P
    */
    public static final String CompletionStepName_PaymentPlan = 'PP Completed';
    public static final String CompletionStepName_PromiseToPay = 'P2P Completed';


    /**
    * Constants to identify Default email address for communications
    */
    public static final String DefaultEmailFromAddress_CollectionsPPandP2PConfirmation = 'Talk Talk Billing Department';


	
}