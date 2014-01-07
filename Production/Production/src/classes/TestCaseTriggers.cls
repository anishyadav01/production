@isTest
private class TestCaseTriggers {
    
    static String aCLI;
    static Case c;
    static Contact primaryContact;
    
    static void prepareData(Integer casesNumber) {
        Account acc = new Account (Name = 'Test_Acc_1');
        insert acc;
        
        primaryContact = new Contact (AccountId = acc.Id, LastName = 'Testius');
        insert primaryContact;
        
        Billing_Account__c billAcc = new Billing_Account__c(Name = 'Test Bill Acc', Account_Id__c = acc.Id, Primary_Contact__c = primaryContact.Id);
        insert billAcc;
        
        aCLI = 'Test CLI';
        Asset asset = new Asset(Name = 'Test Asset', ContactId = primaryContact.Id, Billing_Account__c = billAcc.Id, CLI__c = aCLI, Active__c = true);
        insert asset;
        
        //Create a Community User 
        Li_Community_User__c liUser = new Li_Community_User__c(Name = 'Test Li User', Phone_Number__c=aCLI);
        insert liUser;
        
        //Create a (Lithium) Case and associate with Li User
        RecordType lithiumCaseRecordType = [select Id, Name from RecordType where SObjectType = 'Case' and Name = :Constants.CaseRecordType_Lithium LIMIT 1];
        
        List<Case> casesToInsert = new List<Case>();
        for (Integer i=0; i < casesNumber; i++) {
            casesToInsert.add(new Case (Status = Constants.CaseStatus_CustomerResponded, RecordTypeId = lithiumCaseRecordType.Id, 
                        Phone_Number__c = aCLI, Li_Community_User__c = liUser.Id));
        }
        
        insert casesToInsert;
        
        c = casesToInsert[0];
    }
    
    static testMethod void testCaseAndCommunityUserAssociationWithContact() {
        
        prepareData(1);
        
        Case refCase = [select Id, ContactId, Li_Community_User__r.Contact__r.Id from Case where Id= :c.Id];
        
        system.assertEquals(primaryContact.Id, refCase.ContactId);
        system.assertEquals(primaryContact.Id, refCase.Li_Community_User__r.Contact__c);
        
    }
    
    /*
     * WHen a Lithium or SM Case is first being resolved, the First Response field should be set to now().
     */
    static testMethod void testFirstResponseSetWhenCaseResolved() {
        
        //Create a (Lithium) Case 
        List<RecordType> caseRecordTypes = [select Id, Name from RecordType where SObjectType = 'Case'];
        Map<String, Id> caseRecordTypesMap = new Map<String, Id>();
        for (RecordType rt : caseRecordTypes) {
            caseRecordTypesMap.put(rt.Name, rt.Id);
        }
        
        List<Case> casesToInsert = new List<Case>();
        casesToInsert.add(new Case (Status = Constants.CaseStatus_New, RecordTypeId = caseRecordTypesMap.get(Constants.CaseRecordType_Lithium)));
        casesToInsert.add(new Case (Status = Constants.CaseStatus_New, RecordTypeId = caseRecordTypesMap.get(Constants.CaseRecordType_SocialMedia)));
        
        insert casesToInsert;
        
        for (Case cs : casesToInsert) {
            cs.Status = Constants.CaseStatus_Resolved;
        }
        
        Test.startTest();
        update casesToInsert;
        Test.stopTest();
        
        List<Case> casesUpdated = [select Id, First_Response__c from Case where Id = :casesToInsert[0].Id or Id = :casesToInsert[1].Id];
        
        system.assert(casesUpdated[0].First_Response__c != null);
        system.assert(casesUpdated[1].First_Response__c != null);
        
        //Set back to 'Customer Responded' and the 'Resolved' again and ensure First Response has not been reset
        for (Case cs : casesUpdated) {
            cs.Status = Constants.CaseStatus_CustomerResponded;
        }
        
        update casesUpdated;
        
        for (Case cs : casesUpdated) {
            cs.Status = Constants.CaseStatus_Resolved;
        }
        
        //Retrieve and assert
        List<Case> casesUpdated2 = [select Id, First_Response__c from Case where Id = :casesToInsert[0].Id or Id = :casesToInsert[1].Id];
        
        system.assertEquals(casesUpdated[0].First_Response__c, casesUpdated2[0].First_Response__c);
        system.assertEquals(casesUpdated[1].First_Response__c, casesUpdated2[1].First_Response__c);
    }

}