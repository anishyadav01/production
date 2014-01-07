<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Radian6_Forum_Assignment</fullName>
        <field>OwnerId</field>
        <lookupValue>Social_Media_Other_Case_Queue</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Radian6 Forum Assignment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Radian6_Twitter_General_Assignment</fullName>
        <field>OwnerId</field>
        <lookupValue>Twitter_TalkTalk_Mentions</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Radian6 Twitter General Assignment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Radian6_Twitter_Mention_Queue</fullName>
        <field>OwnerId</field>
        <lookupValue>Twitter_talktalkcare_Mentions</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Radian6 Twitter Mention Queue</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_changed_to_Assigned</fullName>
        <description>Sets the status to Assigned when a case has been assigned an owner</description>
        <field>Status</field>
        <literalValue>Assigned</literalValue>
        <name>Status changed to Assigned</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Owner</fullName>
        <field>OwnerId</field>
        <lookupValue>TalkTalk_Community_Case_Queue</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Update Owner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Owner_to_Facebook_Queue</fullName>
        <field>OwnerId</field>
        <lookupValue>Social_Media_Facebook_Case_Queue</lookupValue>
        <lookupValueType>Queue</lookupValueType>
        <name>Update Owner to Facebook Queue</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_closed</fullName>
        <description>Updates the status of a Resolved case to Closed</description>
        <field>Status</field>
        <literalValue>Closed</literalValue>
        <name>Update status to closed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Lithium Case Assignment</fullName>
        <actions>
            <name>Update_Owner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Record_Type_Name__c</field>
            <operation>equals</operation>
            <value>TalkTalk Community</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Radian6 Facebook Assignment</fullName>
        <actions>
            <name>Update_Owner_to_Facebook_Queue</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND (2 or 4) AND 3</booleanFilter>
        <criteriaItems>
            <field>Case.Record_Type_Name__c</field>
            <operation>equals</operation>
            <value>Social Media</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.R6Service__MediaType__c</field>
            <operation>equals</operation>
            <value>Facebook</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Customer Responded</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Radian6 Forum Assignment</fullName>
        <actions>
            <name>Radian6_Forum_Assignment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND (2 OR 4) AND 3</booleanFilter>
        <criteriaItems>
            <field>Case.Record_Type_Name__c</field>
            <operation>equals</operation>
            <value>Social Media</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Case_Sub_Origin__c</field>
            <operation>equals</operation>
            <value>Forum</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Customer Responded</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Radian6 Twitter General Assignment</fullName>
        <actions>
            <name>Radian6_Twitter_General_Assignment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND (2 OR 4) AND 3</booleanFilter>
        <criteriaItems>
            <field>Case.Record_Type_Name__c</field>
            <operation>equals</operation>
            <value>Social Media</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Case_Sub_Origin__c</field>
            <operation>equals</operation>
            <value>Twitter General</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Customer Responded</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Radian6 Twitter Mention Assignment</fullName>
        <actions>
            <name>Radian6_Twitter_Mention_Queue</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND (2 OR 4) AND 3</booleanFilter>
        <criteriaItems>
            <field>Case.Record_Type_Name__c</field>
            <operation>equals</operation>
            <value>Social Media</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Case_Sub_Origin__c</field>
            <operation>equals</operation>
            <value>Twitter @mention</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Customer Responded</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Sets status to Assigned</fullName>
        <actions>
            <name>Status_changed_to_Assigned</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Sets status to Assigned once it has been assigned a case owner</description>
        <formula>AND( LastModifiedDate &gt;  CreatedDate, OR(Record_Type_Name__c=&apos;TalkTalk Community&apos;, Record_Type_Name__c=&apos;Social Media&apos;), ISPICKVAL(Status,&apos;New&apos;), NOT(Owned_by_Queue__c) )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Sets status to closed 72 hours</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Case.Status</field>
            <operation>equals</operation>
            <value>Resolved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>Social Media,TalkTalk Community,Live Agent</value>
        </criteriaItems>
        <description>Sets status to closed 72 hours after the status has been set to resolved if there have been no further status changes.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_status_to_closed</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>3</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
