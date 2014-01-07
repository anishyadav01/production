public class CommunityPostbackCommentTriggerHandler {
    
    /**
     *  After insert trigger handler.
     */
    public static void handleAfterInsert(map<id, Community_Postback_Comment__c> newPostbackComments) {
        List<Case> casesToUpdate = new List<Case>();
        
        Set<Id> allCaseIds = new Set<Id>();
        
        //Get unique Case Ids referenced in new posts
        for (Community_Postback_Comment__c post : newPostbackComments.values()) {
            allCaseIds.add(post.Case__c);
        }
        
        //Get all Cases referenced to check if applicable for update
        List<Case> casesReferenced = [select Id, Status, Record_Type_Name__c from Case where Id in :allCaseIds];
        
        system.debug('******* Cases referenced: ' + casesReferenced.size());
        
        for (Case c : casesReferenced) {
            
            //if RecordType is Lithium & Status='New' or Status='Assigned' or 'Customer Responded' => Set Case Status to Resolved
            if (c.Record_Type_Name__c == Constants.CaseRecordType_Lithium && 
                    (c.Status == Constants.CaseStatus_CustomerResponded || c.Status == Constants.CaseStatus_Assigned ||
                         c.Status == Constants.CaseStatus_New) 
                ) {
                    
                c.Status = Constants.CaseStatus_Resolved;
                casesToUpdate.add(c);
                system.debug('******* Lithium CustResponded/Assigned Case with new outbound comment found: ' + c.Id);
            }
        }
        
        //finally update
        if (casesToUpdate.size() > 0) {
            update casesToUpdate;
        }
    }

}