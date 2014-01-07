public with sharing class ContactSocialActivitiesController {
    
    public List<SocialActivityWrapper> allSocialActivities {get; set;}
    public Boolean hasPosts {get; private set;}
    
    public Contact cnt {get; private set;}

    public Boolean sourceIsContactDetailPage {get; private set;}
    
    private Id recordId {get; set;}
    
    public final static String fullPageMode = 'fullPage'; //for testing
    public final Integer inlineModeOffset = 4; //for testing 
    
    public Boolean getIsFullPageMode() {
        String mode = ApexPages.currentPage().getParameters().get('mode');
        if (mode != null && mode == fullPageMode) {
            return true;
        }

        return false;
    }
    
    // Required to bind the component
    public ContactSocialActivitiesController getController() {
        return this;
    }
    
     
    public ContactSocialActivitiesController(ApexPages.StandardController controller) {
        recordId = (controller.getRecord()).Id;
        
        String mode = ApexPages.currentPage().getParameters().get('mode');
        
        //Make it generic as this extension controller will be called by both Account and Contact        
        if (String.valueOf(recordId).startsWith('003')) {
            cnt = [select Id, Name from Contact where Id = :recordId];
            sourceIsContactDetailPage = true;
        }
        else if (String.valueOf(recordId).startsWith('001')) {
            //Get the Contact - assume only 1!
            List<Contact> contacts = [select Id, Name from Contact where AccountId = :recordId LIMIT 1];
            if (contacts != null && contacts.size() > 0) {
                cnt = contacts[0];
            }
            
            sourceIsContactDetailPage = false;
        }
        
        allSocialActivities = new List<SocialActivityWrapper>();
        if (cnt != null) {
            getAllSocialActivities();
        }
        
    }
    
    private void getAllSocialActivities()
    {        
        //Only if Contact exists (applicable for Account detail page)
        if (cnt != null) {
        
            //Retrieve Live Chats
            retrieveLiveChats();
            
            //Retrieve Lithium User Posts
            retrieveLithiumUserPosts();
            
            //Retrieve Lithium PostBack Comments (of the Cases associated with the Community User)
            retrieveLithiumPostbackComments();                                    
            
            //Retrieve Social Posts
            retrieveSocialPosts();
            
            //Sort - should be in chronological order
            allSocialActivities.sort();
            hasPosts = allSocialActivities.size() > 0 ? true : false;      
            
            if (!getIsFullPageMode()) {
                List<SocialActivityWrapper> itemsToDisplay = new List<SocialActivityWrapper> ();
                
                Integer i=1;
                for (SocialActivityWrapper item : allSocialActivities) {
                    if (i <= inlineModeOffset) {
                        itemsToDisplay.add(item);
                        i++;
                    }
                    else {
                        break;
                    }
                }
                
                allSocialActivities = itemsToDisplay;
                
            }
        }  
    }
    
    /*
     * Redirects to the FullPage mode of the Page
     */
    public PageReference showAll() {
        
        String socialPage = sourceIsContactDetailPage? 'ContactSocialActivities' : 'AccountContactSocialActivities';
        PageReference fullPage = new PageReference('/apex/' + socialPage + '?id=' + recordId + '&mode=' + fullPageMode);
        fullPage.setRedirect(true);
        return fullPage;
    }
    
    /*
     * Redirects to the original record's detail page
     */
    public PageReference back() {
        PageReference contactOrAccountPage = new PageReference('/'+ recordId);
        contactOrAccountPage.setRedirect(true);
        return contactOrAccountPage;
    }
    
    /*
     * Get all LiveChatTranscripts for the Contact
     */
    private void retrieveLiveChats() {
        List<LiveChatTranscript > liveChats = [select Id, EndTime, Body, Case.Id, CreatedBy.Name, Case.CaseNumber 
                                                from LiveChatTranscript where ContactId = :cnt.Id];
        
        for (LiveChatTranscript lct : liveChats) {
            allSocialActivities.add(new SocialActivityWrapper(lct.EndTime, 'Live Agent', lct.Body, lct.CreatedBy.Name, lct.Case, '/' + lct.Id));
        }        
    }
    
    /*
     * Get all Lithium User Posts for the Contact
     */
    private void retrieveLithiumUserPosts() {
        List<Li_Community_User__c> liUsers = [select Lithium_User_Id__c from Li_Community_User__c where Contact__c = :cnt.Id];
        
        if (liUsers != null && liUsers.size() > 0 && liUsers[0].Lithium_User_Id__c != null) {
            Li_Community_User__c liUser = liUsers[0];
            
            try {
                List<LithiumAPIUtil.LiMessage> postedMsgs = LithiumAPIUtil.getUserMessagePostHistory(liUser.Lithium_User_Id__c.format());
            
                for (LithiumAPIUtil.LiMessage msg : postedMsgs) {
                    allSocialActivities.add(new SocialActivityWrapper(msg.postTime, 'Talk Talk Community', msg.subject, cnt.Name, new Case(), msg.url));
                    
                    //get Case via Community User? but one User can have many..
                    
                }
            }
            catch (Exception e) {
                system.debug('***** Exception occured: ' + e.getMessage());
            }
        }
    }
    
    /*
     * Get all Lithium Postback Comments for Cases associated with the Contact
     */
    private void retrieveLithiumPostbackComments() {
        List<Case> communityUserCases = [select Id from Case where ContactId = :cnt.Id];
        
        Set<Id> caseIds = new Set<Id>();
        for (Case c : communityUserCases) {
            caseIds.add(c.Id);
        }
        
        List<Community_Postback_Comment__c> postbackCmnts = [Select Id, CreatedDate, Postback_Comment__c, CreatedBy.Name, Case__r.Id, Case__r.CaseNumber 
                                                             from Community_Postback_Comment__c c
                                                              where Case__c in :caseIds];
                                                              
        for (Community_Postback_Comment__c cmnt : postbackCmnts) {
            allSocialActivities.add(new SocialActivityWrapper(cmnt.CreatedDate, 'Talk Talk Community', cmnt.Postback_Comment__c, cmnt.CreatedBy.Name, cmnt.Case__r, '/' + cmnt.Id));
        }   
    }
    
    /*
     * Get all Social Posts (Facebook & Twitter) for Cases associated with the Contact
     */
    private void retrieveSocialPosts() {
        
        //Retrieve social posts for Social Persona of Contact
        // The below soql cannot query on Parent.CaseNumber: seems to be treating Parent as a polymorphic key although it clearly isn't! Separate query required..
        List<SocialPost> socialPosts = [select Id, CreatedDate, Content, ParentId, Parent.Id, MediaType from SocialPost where Persona.ParentId = :cnt.Id];
        
        Map<Id, Id> socialPostToCaseMap = new Map<Id, Id>();
        Set<Id> postCases = new Set<Id>();
        
        for (SocialPost sp : socialPosts) {
            socialPostToCaseMap.put(sp.Id, sp.ParentId);
            postCases.add(sp.ParentId);
        }
        
        Map<Id, Case> cases = new Map<Id, Case> ([select Id, CaseNumber from Case where Id in :postCases]);
        
        for (SocialPost sp : socialPosts) {
            allSocialActivities.add(new SocialActivityWrapper(sp.CreatedDate, sp.MediaType, sp.Content, cnt.Name, cases.get(socialPostToCaseMap.get(sp.Id)), '/' + sp.Id));
        } 
    }
    
    
    public class SocialActivityWrapper implements Comparable {
        
        public DateTime PostDate {get; set;}
        public String Channel {get; set;}
        public String Description {get; set;}
        public String PostedBy {get; set;}
        public Case RelatedCase {get; set;}
        public String PostId {get; set;}
        
        public SocialActivityWrapper(DateTime aDate, String aChannel, String aDescr, String who, Case aCase, String aPostId) {
            PostDate = aDate;
            Channel = aChannel;
            Description = aDescr;
            PostedBy = who;
            RelatedCase = aCase;
            PostId = aPostId;
        }
        
        public Integer compareTo(Object other) {
            DateTime otherPostDate = other != null ? ((SocialActivityWrapper)other).PostDate : System.now();           
            // use Datetime.getTime() to do get the numeric time in millis
            return ((otherPostDate > this.PostDate) ? -1 : 1);
            //return (otherPostDate.getTime() - this.PostDate.getTime()).intValue();
        }
    }


}