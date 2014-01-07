/*
 * Social Media posts trigger handler!
 */
public class SocialPostTriggerHandler {

    public static void handleAfterInsertOrUpdate(List<SocialPost> newPosts) {
        map<id,id> idList = new map<id,Id>();
        for(SocialPost sp : newPosts){
            if(sp.parentid != null){
                system.debug('\n\nsp.parentid '+sp.parentid);
                idlist.put(sp.parentId,sp.parentID);
            }

        }

        list <Case> caseList = [Select c.Id, c.Case_Sub_Origin__c, (Select Id, R6Service__PostTags__c From Posts limit 2)
                                From Case c
                                where id in : idList.Keyset()];
        system.debug('\n\ncaseList.size  '+caseList.size());
        for (Case c : caseList){
            system.debug('\n\nc.posts.size()  '+c.posts.size());
            if(c.posts.size()==1){
                c.Case_Sub_Origin__c = c.posts[0].R6Service__PostTags__c;
            }
        }
        update(caseList);
    }

    public static void handleBeforeInsert(List<SocialPost> newPosts) {

    }

    /**
     *  After insert trigger handler.
     */
    public static void handleAfterInsert(map<id, SocialPost> newPosts) {
        System.Debug('>>>>>>>>>>>>>>>>>>>>>>>> Calling createSocialPostAndCaseAssociations()');
       // createSocialPostAndCaseAssociations(newPosts.keySet());
       updateCaseStatus(newPosts);

    }

    /* Via Social Persona that created the post, check if there are already Cases for the Persona (get most recent first)
     * For each post:
     * If there is a case and has been created < 72hrs from now, attach Social Post to the existing Case
     * If there is a case but was created > 72 hrs from now, create new Case and attach Social Post to the Case
     * If there is no case, create new Case and attach Social Post to the Case.

    public static void createSocialPostAndCaseAssociations(Set<Id> newPostIds) {
        System.Debug('>>>>>>>>>>>>>>>>>>>>>>>> Inside createSocialPostAndCaseAssociations(): '+newPostIds);
        List<Case> casesToUpsert = new List<Case>();

        //Retrieve posts again as the Case__r relationship is required
        Set<String> ignoreFields = new Set<string>{'ParentId'};
       // List<SocialPost> newPostsCustom = database.query('select Parent.id, ' + SObjectHelper.getFieldListForSOQL('SocialPost',ignoreFields) +
       //                                                 ' from SocialPost where id IN :newPostIds');

       List<SocialPost> newPostsCustom = database.query( ' select Content,ExternalPostId,Name,R6PostId,R6SourceId,R6TopicId,PersonaId,MediaProvider,R6Service__IsOutbound__c,R6Service__PostTags__c'+
                                                           ' from SocialPost where id IN :newPostIds');


        //Get Case Record Types
        List<RecordType> caseRecordTypes = [select Id, Name from RecordType where SObjectType = 'Case'];
        Map<String, String> caseRecordTypeMapping = new Map<String, String>();
        for (RecordType rt : caseRecordTypes) {
            caseRecordTypeMapping.put(rt.Name, rt.Id);
            caseRecordTypeMapping.put(rt.Id, rt.Name);
        }

        //Get all socialPersonas that created the posts
        Set<Id> socialPersonaIds = new Set<Id>();
        for (SocialPost post : newPostsCustom) {
            if(!String.isBlank(post.PersonaId))
                socialPersonaIds.add(post.PersonaId);
        }

        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Social person Ids: '+socialPersonaIds);
        //Get existing Cases created by the Social Personas, order by most recent
        List<Case> socialPersonaCases = [select Id, R6Service__SocialPersona__c, CreatedDate, Record_Type_Name__c, Status, Key__c
                                            from Case
                                            where R6Service__SocialPersona__c in :socialPersonaIds
                                            order by CreatedDate desc];

        //Create a map of Social Personas and their cases in chron order (most recent first)
        Map<Id, List<Case>> socialPersonaCasesMap = new Map<Id, List<Case>>();

        for (Case c : socialPersonaCases) {
            if (!socialPersonaCasesMap.containsKey(c.R6Service__SocialPersona__c)) {
                socialPersonaCasesMap.put(c.R6Service__SocialPersona__c, new List<Case> {c});
            }
            else {
                socialPersonaCasesMap.get(c.R6Service__SocialPersona__c).add(c);
            }
        }

        //Now check if new Case should be created or post should be attached to existing one
        for (SocialPost p : newPostsCustom) {

            //If Social Persona already has cases
            if (socialPersonaCasesMap.containsKey(p.PersonaId) && socialPersonaCasesMap.get(p.PersonaId) != null && socialPersonaCasesMap.get(p.PersonaId).size() > 0) {
                if (socialPersonaCasesMap.get(p.PersonaId).get(0).Status != Constants.CaseStatus_Closed) {

                    // If there is a case and is still not Closed, attach Social Post to the existing Case

                    Case existingCase = socialPersonaCasesMap.get(p.PersonaId).get(0);
                    //p.ParentId = existingCase.Id; //new Case (Key__c = existingCase.Key__c);

                    //if inbound post & RecordType is Social Media & Status='Resolved'
                    if (existingCase.Record_Type_Name__c == Constants.CaseRecordType_SocialMedia && existingCase.Status == Constants.CaseStatus_Resolved && !p.R6Service__IsOutbound__c) {

                        existingCase.Status = Constants.CaseStatus_CustomerResponded;
                        casesToUpsert.add(existingCase);
                        system.debug('******* Existing Social Media Resolved Case with new inbound comment will be updated: ' + existingCase.Id);
                    }
                    else if (existingCase.Record_Type_Name__c == Constants.CaseRecordType_SocialMedia && p.R6Service__IsOutbound__c &&
                                (existingCase.Status == Constants.CaseStatus_CustomerResponded || existingCase.Status == Constants.CaseStatus_Assigned)
                        ) {

                        existingCase.Status = Constants.CaseStatus_Resolved;
                        casesToUpsert.add(existingCase);
                        system.debug('******* Existing Social Media CustResponded/Assigned Case with new outbound comment will be updated: ' + existingCase.Id);
                    }
                }
                else {
                    // If there is a case but was created > 72 hrs from now, create new Case and attach Social Post to the Case
                    String key = Common.getUniqueKey('case');
                    Case newCase = new Case(Key__c = key, RecordTypeId = caseRecordTypeMapping.get('Social Media'), Status = Constants.CaseStatus_New,
                                                Origin = 'Social Media', Case_Sub_Origin__c = p.R6Service__PostTags__c,
                                                R6Service__SocialPersona__c = p.PersonaId,R6Service__MediaProvider__c=p.MediaProvider,
                                                R6Service__InitialPostId__c = p.Id );

                    p.Parent = new Case (Key__c = newCase.Key__c);

                    casesToUpsert.add(newCase);

                    system.debug('******* New Social Media Case will be created as no recent found for Social Persona: ' + p.Persona);
                }
            }

            // If there is no case, create new Case and attach Social Post to the Case.
            else {
                String key = Common.getUniqueKey('case');
                Case newCase = new Case(Key__c = key, RecordTypeId = caseRecordTypeMapping.get('Social Media'), Status = Constants.CaseStatus_New ,
                                                Origin = 'Social Media', Case_Sub_Origin__c = p.R6Service__PostTags__c,
                                                R6Service__SocialPersona__c = p.PersonaId,R6Service__MediaProvider__c=p.MediaProvider,
                                                R6Service__InitialPostId__c = p.Id);
                p.Parent = new Case (Key__c = newCase.Key__c);

                casesToUpsert.add(newCase);

                system.debug('******* New Social Media Case will be created as no cases at all were found for Social Persona: ' + p.Persona);
            }
        }

        upsert casesToUpsert;
        update newPostsCustom;

    }
     */
    public static void updateCaseStatus(Map<Id,SocialPost> newPosts){
        List<Case> incomingCasesToUpdate = new List<Case>();
        List<Case> outgoingCasesToUpdate = new List<Case>();
        set<id> incomingPostCases =  new set<id>();
        set<id> outgoingPostCases =  new set<id>();
        Set<Id> caseIds = newPosts.keySet();

        //Prepare Map of Cases related to Incoming and Outgoing Post
        for(SocialPost sp : newPosts.values()){
            if (!sp.R6Service__IsOutbound__c){
                incomingPostCases.add(sp.ParentId);
            }
            else
                outgoingPostCases.add(sp.ParentId);

        }

        incomingCasesToUpdate = [select id,status,Record_Type_Name__c from case where id in :incomingPostCases];
        for(case c : incomingCasesToUpdate){
            if(c.Record_Type_Name__c == Constants.CaseRecordType_SocialMedia && c.Status == Constants.CaseStatus_Resolved)
                c.Status=Constants.CaseStatus_CustomerResponded;
        }

        outgoingCasesToUpdate = [select id,status,Record_Type_Name__c from case where id in :outgoingPostCases];
        for(case c : outgoingCasesToUpdate){
            if(c.Record_Type_Name__c == Constants.CaseRecordType_SocialMedia &&
                            (c.Status == Constants.CaseStatus_CustomerResponded || c.Status == Constants.CaseStatus_Assigned
                            || c.Status == Constants.CaseStatus_New))
                c.Status=Constants.CaseStatus_Resolved;
        }

        if(!incomingCasesToUpdate.isEmpty())
            update incomingCasesToUpdate;

        if(!outgoingCasesToUpdate.isEmpty())
            update outgoingCasesToUpdate;

    }

}