trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert, after insert) {
    
    LiveChatTranscriptHandler lcth = new LiveChatTranscriptHandler();
    
    if(trigger.isBefore && trigger.isInsert)
        lcth.handleLCTBeforeInsert(trigger.New);
    
    else if(trigger.isAfter && trigger.isInsert)
        lcth.handleLCTAfterInsert(trigger.new);
}