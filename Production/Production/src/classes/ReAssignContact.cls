public with sharing class ReAssignContact {
	/* 
------------------------------------------------------------
// Author:      SFDC(R.Sutherland)
// Function:    Controller for page ReassignContact, searches for contact/asset records
				returning two lists. Contains logic to ensure the search string is > x characters
// History:     02.09.2013 Created
------------------------------------------------------------
 */
 	public string searchTerm {get;set;}
	public List<Contact> searchResultsContact{get;set;}
	public List<Asset> searchResultsAsset{get;set;}
	public String selectId{get;set;}
	public string recordId ;
	
	public ReAssignContact(Apexpages.standardcontroller con){
		recordId = con.getId();
		searchTerm=apexpages.currentpage().getParameters().get('search');
		searchResultsContact = new List<Contact>();
		searchResultsAsset = new List<Asset> ();
	}
	public pagereference reAssign(){
		system.debug('\n\n1 ' + recordId);
		Case c = [select id,contactId,AccountId from Case where id = : recordId];
		Contact con = [select Id,accountId from contact where id = : selectId];
		string oldContactId = c.ContactId;
		c.ContactId = selectId;
		c.AccountId = con.AccountId;
		update(c);
		
		List<SocialPersona> spList = [Select s.ParentId, s.Id From SocialPersona s where s.parentid = : oldContactId];
		for (SocialPersona sp : spList){
			sp.ParentId = selectId;
		}
		update(spList);
		
		List<SocialPost> pList = [Select s.WhoId, s.Id From SocialPost s where s.WhoId = : oldContactId];
		for (SocialPost p : pList){
			p.WhoId = selectId;
		}
		update(pList);
		
		Contact oldCon = [select id, ownerId from Contact where id = : oldContactId];
		User u = [select id from User where id = : ContactReAssignSearchSettings__c.getinstance(userinfo.getProfileId()).New_Owner_Id__c];
		
		oldCon.Owner = u;
		update oldCon;
		
		return new pagereference('/' + c.id);
	}

	public pagereference doSearch(){
		
		integer chars = integer.valueof(ContactReAssignSearchSettings__c.getinstance(userinfo.getProfileId()).Number_Of_Characters__c);
		integer numCon =  integer.valueof(ContactReAssignSearchSettings__c.getinstance(userinfo.getProfileId()).Number_Of_Contact_Records__c);
		integer numAsset = integer.valueof(ContactReAssignSearchSettings__c.getinstance(userinfo.getProfileId()).Number_Of_Asset_Records__c);
		
		searchResultsContact = new List<Contact>();
		searchResultsAsset = new List<Asset> ();
		if (searchTerm.replace(' ', '').length() < chars){
			Apexpages.Message m = new apexpages.Message(ApexPages.Severity.ERROR, 'Search string must contain at least ' + chars + ' characters');
			apexpages.addMessage(m); 
		}else{
			searchTerm = string.escapeSingleQuotes(SearchTerm);
			List<List<SObject>> searchResults = [FIND :searchTerm IN ALL FIELDS RETURNING 
												Contact(Id,
														Name,
														Account.Name,
														Phone,
														MobilePhone, 
														Email,
														ISVIP__c, 
														recordType.name 
													order by lastname limit : numCon), 
												Asset(contact.Id,
													  CLI__c, 
													  contact.Account.Name,
													  contact.Name,
													  contact.Phone,
													  contact.MobilePhone, 
													  contact.Email,
													  contact.ISVIP__c,
													  contact.recordType.name  
													 order by contact.lastname limit : numAsset)];
			for(List<Sobject> soList : searchresults){
				for (sObject so : soList){
					if(so.getSObjectType() == Contact.sObjectType){
						searchResultsContact.add ((Contact) so);
					}else if(so.getSObjectType() == Asset.sObjectType){
						searchResultsAsset.add ((Asset) so);
					}
				}
			}	
		}
		return null;
	}
}