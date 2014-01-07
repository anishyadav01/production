public with sharing class LiveAgentDeploymentController {
	public String CLI{ get;set; }

	public LiveAgentDeploymentController() {
		CLI = Apexpages.currentPage().getParameters().get('CLI');
	}
}