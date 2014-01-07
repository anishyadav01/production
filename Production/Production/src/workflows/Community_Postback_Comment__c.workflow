<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <outboundMessages>
        <fullName>Community_Postback</fullName>
        <apiVersion>22.0</apiVersion>
        <endpointUrl>http://cloudsquadsdev.stage.lithium.com/soap/salesforce</endpointUrl>
        <fields>Board_ID__c</fields>
        <fields>Case__c</fields>
        <fields>FullId__c</fields>
        <fields>Id</fields>
        <fields>Name</fields>
        <fields>Postback_Comment__c</fields>
        <fields>Salesforce_Agent__c</fields>
        <fields>Thread_ID__c</fields>
        <fields>isNew__c</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>layla.drury@talktalkplc.com</integrationUser>
        <name>Community Postback</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>Community Postback</fullName>
        <actions>
            <name>Community_Postback</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <formula>OR(isNew__c  =  1, ISCHANGED(Postback_Comment__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
