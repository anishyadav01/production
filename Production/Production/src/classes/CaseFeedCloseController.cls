public class CaseFeedCloseController {

    public Case caseRec {get; set;}

    public CaseFeedCloseController(ApexPages.StandardController controller) {
        Case c = (Case)controller.getRecord();

        caseRec = [select Id, Subject, Case_Outcome__c, Close_Reason__c, Reason, Description, Status from Case where Id = :c.Id];

    }

    public PageReference closeCase() {
        caseRec.Status = Constants.CaseStatus_Closed;
        update caseRec;

        return null;
    }

}