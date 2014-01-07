public class LiveChatCreateCaseController{
    public Asset assetCLI;
    public string myTargetUrl;
    
    public LiveChatCreateCaseController(ApexPages.StandardController controller) {
        assetCLI = (Asset)controller.getRecord();
        myTargetUrl = '/apex/'+'LiveAgentCreateCase'+'?aid='+assetCLI.Id ;
    }
    
    public PageReference NavigateToCreateCase(){
        System.Debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Live Chat V2: '+assetCLI);
        PageReference pr = new PageReference('/apex/'+'LiveAgentCreateCase'+'?aid='+assetCLI.Id);
        pr.setRedirect(true);
        return pr;
    }

}