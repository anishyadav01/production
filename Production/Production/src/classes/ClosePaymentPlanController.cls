public with sharing class ClosePaymentPlanController {
/* This is called to Close either a PP or a P2P.
  Same actions regarding Case Closure should occur in both situations
*/


    public PageReference closePaymentPlan() {
        
        Id ppId = Apexpages.currentPage().getParameters().get('ppId');
        Id p2pId = Apexpages.currentPage().getParameters().get('p2pId');
        Id billingAccId = Apexpages.currentPage().getParameters().get('billingAccId');        

        PageReference baPage;
		if ( ppId != null ){
			// its the payment Plan that needs closing
			PaymentPlanPromise2PayHelper.closePaymentPlan ( ppId, true ); // to force close the plan 
		} else if ( p2pId != null ) {
			// its the promise to pay to close
			PaymentPlanPromise2PayHelper.closePromiseToPay ( p2pId, true ); // to force close the plan
		}

	    baPage = new PageReference('/'+ billingAccId );
	    baPage.setRedirect(true);
        
        return baPage;
    }

}