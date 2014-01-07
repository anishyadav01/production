@isTest
public with sharing class CaseGetNextController_Test {

    public static Group createTestQueue()
    {
        Group g = new Group(Type='Queue',Name='testRetrieveNextCase');
        insert g;
        
        //Make this queue assignable to leads and cases
        List<QueueSobject> qs = new List<QueueSobject>();
        qs.add(new QueueSobject(QueueId=g.Id,SObjectType='Case'));        
        insert qs;
        
        return g;
    }
    
    static User createTestUser() {
        User user = new User();
        user.Username = 'test'+System.currentTimeMillis()+'@RetrieveNextUtils.com';
        user.LastName = 'LastTestName';
        user.Email = 'test@RetrieveNextUtils.com';
        user.alias = 'testAl';
        user.TimeZoneSidKey = 'America/New_York';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.ProfileId = [select id from Profile where Name='System Administrator'].Id;
        user.LanguageLocaleKey = 'en_US';
        insert user;
        //setUser(user);
        
        return user;
     }
    
     public static testMethod void testRetrieveNextCase()
     {    
        User u = createTestUser();
       
        Group g = createTestQueue();
        
        GroupMember gm = new GroupMember(UserOrGroupId=u.Id,GroupId=g.Id);
        insert gm;
        
        Test.startTest();  
        //We have to runAs so that we don't get a MIXED_DML_EXCEPTION
        System.runAs(u) {
          Radian6_Case_Config__c con = new Radian6_Case_Config__c(
            Get_Next_Unauthorised__c = 'This button is only for the use of Radian6 Agents.',
                No_Cases_Available__c = 'No cases are available at this time.',
                    Radian_6_Profiles__c = u.ProfileId,
                        Radian_6_Queues__c = g.Id);
          insert con;
        
          Case c = new Case(Subject='Test',OwnerId=g.Id);
          insert c;
          
          
          ApexPages.StandardSetController caseStdSetCon = new ApexPages.StandardSetController(new List<Case>{c});
          CaseGetNextController caseCon = new CaseGetNextController(caseStdSetCon);
          
          PageReference result = caseCon.onLoad();
          PageReference expectedResult = new PageReference('/' + c.Id);
          System.assertEquals(expectedResult.getURL(), result.getURL());
          System.assertEquals(g.Id, [Select Id, Previous_OwnerId__c from Case where Id = :c.Id].Previous_OwnerId__c);
          
          Case ownedCase = [select OwnerId from Case where Id=:c.Id];
          System.assertEquals(ownedCase.OwnerId,u.Id);
          
          Case c2 = new Case(Subject='Test2',OwnerId=g.Id);
          insert c2;
          
          Test.setCurrentPageReference(Page.CaseGetNextDetail);
          ApexPages.CurrentPage().getParameters().put('id', c.Id);
          
          ApexPages.StandardController stdCaseCon = new ApexPages.StandardController(c);
          caseCon = new CaseGetNextController(stdCaseCon);
          
          
          result = caseCon.onLoad();
          expectedResult = new PageReference('/' + c2.Id);
          System.assertEquals(expectedResult.getURL(), result.getURL());
          System.assertEquals(g.Id, [Select Id, Previous_OwnerId__c from Case where Id = :c2.Id].Previous_OwnerId__c);
     
          
        }
    }
    
    public static testMethod void testNegativeRetrieveNextCase()
    {    
        User u = createTestUser();
               
        Group g = createTestQueue();
       
        Test.startTest();  
        
        //We have to runAs so that we don't get a MIXED_DML_EXCEPTION
        System.runAs(u) {
        
          Radian6_Case_Config__c con1 = new Radian6_Case_Config__c(
            Get_Next_Unauthorised__c = 'This button is only for the use of Radian6 Agents.',
                No_Cases_Available__c = 'No cases are available at this time.',
                    Radian_6_Profiles__c = '',
                        Radian_6_Queues__c = '');
          insert con1;
          
          //Do not insert this user in the queue -- he should not get the case
          Case c = new Case(Subject='Test',OwnerId=g.Id);
          insert c;
          
          ApexPages.StandardController caseStdCon = new ApexPages.StandardController(c);
          CaseGetNextController caseCon = new CaseGetNextController(caseStdCon);
          
          PageReference result = caseCon.onLoad();
          
          System.assertEquals(false, caseCon.authorisedProfile);
          
          Case ownedCase = [select OwnerId from Case where Id=:c.Id];
          System.assertNotEquals(ownedCase.OwnerId,u.Id);
          
        }
    }
}