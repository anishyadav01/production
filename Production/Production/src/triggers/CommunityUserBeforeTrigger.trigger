trigger CommunityUserBeforeTrigger on Li_Community_User__c (before insert, before update) {
    Map<String, Li_Community_User__c> emailToCommunityUserMap = new Map<String, Li_Community_User__c>();
    Map<String, Contact> emailToContactMap = new Map<String, Contact>();
    List<Li_Community_User__c> listOfCommunityUsers = new List<Li_Community_User__c>();
    List<Contact> contactsToInsert = new List<Contact>();
    LithiumSettings__c liSetting = LithiumSettings__c.getValues('DefaultSetting');
    
    if(liSetting == NULL) {
        liSetting = new LithiumSettings__c();
        liSetting.Name = 'DefaultSetting';
        liSetting.Sync_With_Contact__c = true;
        liSetting.Create_New_Contact_record__c = true;
        
        Database.insert(liSetting);
    }
    
    for(Li_Community_User__c aCommunityUser : trigger.new) {
        if(aCommunityUser.Email_Address__c != NULL)
            emailToCommunityUserMap.put(aCommunityUser.Email_Address__c, aCommunityUser); // build a map of email>community user
    }
    
    for(Contact aContact : [SELECT Id, FirstName, LastName, Name, Email
                            FROM Contact
                            WHERE Email IN :emailToCommunityUserMap.keySet()]) {
        emailToContactMap.put(aContact.Email, aContact);  // build a map of email>contact (Contacts which have same email as community users)
    }
    
    for(String email : emailToCommunityUserMap.keySet()) { // loop through all community users with email address
        Contact aContact = emailToContactMap.get(email);
        Li_Community_User__c aCommunityUser = emailToCommunityUserMap.get(email);
        
        if(aContact != NULL && liSetting.Sync_With_Contact__c){ // attach Contact record or not
            aCommunityUser.Contact__c = aContact.Id; // use existing contact 
        }
        if(aContact == NULL && liSetting.Create_New_Contact_record__c) { // contact doesn't exist and lithium setting asks to create one
            aContact = new Contact(); // No contact exists; create new record
            aContact.FirstName = aCommunityUser.First_Name__c;
            aContact.LastName = (aCommunityUser.Last_Name__c == NULL)?aCommunityUser.Name:aCommunityUser.Last_Name__c; // LastName is required for Contact; making sure it is not empty
            aContact.Email = aCommunityUser.Email_Address__c;
            contactsToInsert.add(aContact); // list of contacts to update/insert
            listOfCommunityUsers.add(aCommunityUser); // maintain a list of community users also; same order as contactsToInsert
        }           
    }
    
    if(!contactsToInsert.isEmpty()) {
        Database.SaveResult[] iResults = Database.insert(contactsToInsert, false); // insert/update contacts; continue DML operations if a failure occurs
        Integer i = 0;
        for(Database.SaveResult result : iResults) {
            // Database.SaveResult[] in same order as contactsToInsert
            // Safe to assume same index for community users list
            if(!result.isSuccess()) { // error occured in contact update/insert
                system.debug('error updating ' + result.getErrors()[0].getMessage());
                listOfCommunityUsers[i].addError('Error creating/updating Contact'); // add error to community user object;
            }
            else if(liSetting.Sync_With_Contact__c){  // attach new Contact record or not
                listOfCommunityUsers[i].Contact__c = result.getId(); // assign contact id; this is not available before contact is inserted, hence done here
            } 
            ++i;
        }
    }   
}