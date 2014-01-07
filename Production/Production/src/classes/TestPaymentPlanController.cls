@isTest
public class TestPaymentPlanController {
    
    static testMethod void createNewPP_NoApproval_CanSave() {
        
        TestHelper.createCollectionSettings(6);
        
        Billing_Account__c ba = TestHelper.createBillingAccount();
        
        Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Date_of_First_Installment__c = Date.today(), Use_New_Call_Limit__c = false);
        
        //Setup page params
        Apexpages.currentPage().getParameters().put('billAccountId', ba.Id);
        
        ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(pp);
        PaymentPlanController customCtrl = new PaymentPlanController(strctrl);
        
        system.assert(!customCtrl.planProduced);
        system.assert(!customCtrl.isReadOnlyMode);
        system.assert(!customCtrl.isExistingPP);
        system.assert(customCtrl.canSave);
        
        //Make selections and calculate payments
        pp.Date_of_First_Installment__c = Date.valueOf ('2013-11-04');
        pp.New_Call_Limit__c = 100;
        pp.Use_New_Call_Limit__c = false;
        pp.One_off_Payment__c = 50;
        pp.Proposed_Frequency__c = 'Weekly';
        pp.Number_of_Installments__c = 8;
        pp.MRC1__c = 2.00;
        
        customCtrl.calculatePayments();
        system.assert(customCtrl.planProduced);
        system.assert(customCtrl.ppItems.size() > 0);
        system.assert(customCtrl.ppItems[0].Due_Date__c == Common.getNextWorkingDay(pp.Date_of_First_Installment__c));
        system.assert(customCtrl.ppItems[0].Amount__c != null);
        
        system.assert(customCtrl.ppItems[customCtrl.ppItems.size()-1].Due_Date__c <= pp.Date_of_First_Installment__c.addMonths(2));
        system.assert(customCtrl.ppItems[customCtrl.ppItems.size()-1].Amount__c != null);
        
        Decimal mrc = 2.00;
        Integer mrcMultiplier = 1; // as it will be just one month included
         
        Decimal totalDue = (ba.Total_Over_Due__c - pp.One_off_Payment__c + ba.Unbilled_Amount__c + (mrcMultiplier * mrc));
                                    
        Decimal totalInstallmentsAmount = 0;
        for (Payment_Plan_Line_Item__c li : customCtrl.ppItems) {
            totalInstallmentsAmount += li.Amount__c;
        }
        
        //system.assertEquals(totalDue, totalInstallmentsAmount);
        
        customCtrl.savePP();
        
        customCtrl.cancel();
        
        // Retrieve and assert
        Payment_Plan__c savedPP = [select Billing_Account__c, Date_of_First_Installment__c, Last_Due_Date__c, New_Call_Limit__c, Number_of_Installments__c,
                                        One_off_Payment__c, Payment_Method__c, Proposed_Frequency__c, Status__c,
                                        (select Id, Name, Amount__c, Due_Date__c from Payment_Plan_Lines__r order by Due_Date__c asc)
                                    from Payment_Plan__c where Billing_Account__c = :ba.Id];
                                    
        List<Case> collectionCase = [select Record_Type_Name__c, Status  from Case where Billing_Account__c = :ba.Id];
                                    
        
        system.assertEquals(Date.valueOf ('2013-11-04'), savedPP.Date_of_First_Installment__c);
        system.assertEquals(savedPP.Payment_Plan_Lines__r[savedPP.Payment_Plan_Lines__r.size()-1].Due_Date__c, savedPP.Last_Due_Date__c);
        system.assertEquals(100, savedPP.New_Call_Limit__c);
        system.assert(savedPP.Number_of_Installments__c > 0);
        system.assertEquals(50, savedPP.One_off_Payment__c);
        system.assertEquals('Weekly', savedPP.Proposed_Frequency__c);
        system.assertEquals(8, savedPP.Number_of_Installments__c);
        system.assertEquals('Open', savedPP.Status__c);
        
        system.assertEquals('New', collectionCase[0].Status);
        system.assertEquals(Constants.CaseRecordType_Collection, collectionCase[0].Record_Type_Name__c);
        
    }
    
    static testMethod void createNewPP_WithApproval_CanSave() {
        
        TestHelper.createCollectionSettings(6);
                
        Billing_Account__c ba = TestHelper.createBillingAccount();
        
        Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id);
        
        //Setup page params
        Apexpages.currentPage().getParameters().put('billAccountId', ba.Id);
        
        ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(pp);
        PaymentPlanController customCtrl = new PaymentPlanController(strctrl);
        
        system.assert(!customCtrl.planProduced);
        system.assert(!customCtrl.isReadOnlyMode);
        system.assert(!customCtrl.isExistingPP);
        system.assert(customCtrl.canSave);
        
        //Make selections and calculate payments
        pp.Date_of_First_Installment__c = Date.valueOf('2013-11-04');
        pp.New_Call_Limit__c = 100;
        pp.Use_New_Call_Limit__c = true;
        pp.One_off_Payment__c = 50;
        pp.Proposed_Frequency__c = 'Monthly';
        pp.Number_of_Installments__c = 8;
        pp.MRC1__c = 2.00;
                
        customCtrl.calculatePayments();
        system.assert(customCtrl.planProduced);
        system.assert(customCtrl.ppItems.size() > 0);
        system.assert(customCtrl.ppItems[0].Due_Date__c == Common.getNextWorkingDay (pp.Date_of_First_Installment__c));
        system.assert(customCtrl.ppItems[0].Amount__c != null);
        
        system.assert(customCtrl.ppItems[customCtrl.ppItems.size()-1].Due_Date__c <= pp.Date_of_First_Installment__c.addMonths(Integer.valueof(pp.Number_of_Installments__c)));
        
        system.assert(customCtrl.ppItems[customCtrl.ppItems.size()-1].Amount__c != null);
        
        Decimal mrcMultiplier = 7;
        Decimal totalDue = (ba.Total_Over_Due__c - pp.One_off_Payment__c + ba.Unbilled_Amount__c + (mrcMultiplier * pp.MRC1__c ) +  
                (mrcMultiplier * Integer.valueOf(pp.New_Call_Limit__c)) );
        
        Decimal totalInstallments = 0;
        for (Payment_Plan_Line_Item__c li : customCtrl.ppItems) {
            totalInstallments += li.Amount__c;
        }
        
        //system.assertEquals(totalDue, totalInstallments);
        
        customCtrl.savePP();
        
        customCtrl.cancel();
        
        // Retrieve and assert
        Payment_Plan__c savedPP = [select Billing_Account__c, Date_of_First_Installment__c, Last_Due_Date__c, New_Call_Limit__c, Number_of_Installments__c,
                                        One_off_Payment__c, Payment_Method__c, Proposed_Frequency__c, Status__c,
                                        (select Id, Name, Amount__c, Due_Date__c from Payment_Plan_Lines__r order by Due_Date__c asc)
                                    from Payment_Plan__c where Billing_Account__c = :ba.Id];
                                    
        List<Case> collectionCases = [select Record_Type_Name__c, Status  from Case where Billing_Account__c = :ba.Id];
                                    
        
        system.assertEquals(Date.valueOf ('2013-11-04'), savedPP.Date_of_First_Installment__c);
        system.assertEquals(savedPP.Payment_Plan_Lines__r[savedPP.Payment_Plan_Lines__r.size()-1].Due_Date__c, savedPP.Last_Due_Date__c);
        system.assertEquals(100, savedPP.New_Call_Limit__c);
        system.assert(savedPP.Number_of_Installments__c > 0);
        system.assertEquals(50, savedPP.One_off_Payment__c);
        system.assertEquals('Monthly', savedPP.Proposed_Frequency__c);
        system.assertEquals(pp.Number_of_Installments__c, savedPP.Number_of_Installments__c);
        system.assertEquals(Constants.PaymentPlanStatus_PendingApproval, savedPP.Status__c);
        
        system.assert(collectionCases.size() == 0);
        
        //Submit for approval
        //customCtrl.submitForApproval();
    }
    
    static testMethod void createNewPP_WithApproval_CannotSave() {
        
        TestHelper.createCollectionSettings(6);
        
        Billing_Account__c ba = TestHelper.createBillingAccount();
        
        //Create an active P2P
        Promise_to_Pay__c p2p = new Promise_to_Pay__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open, Proposed_Payment_Date__c = Date.today(), Amount_Due__c = 1000);
        insert p2p;
        
        Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id);
        
        //Setup page params
        Apexpages.currentPage().getParameters().put('billAccountId', ba.Id);
        
        ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(pp);
        PaymentPlanController customCtrl = new PaymentPlanController(strctrl);
        
        system.assert(!customCtrl.planProduced);
        system.assert(!customCtrl.isReadOnlyMode);
        system.assert(!customCtrl.isExistingPP);
        system.assert(!customCtrl.canSave);
        system.assertEquals(customCtrl.notClosedPPReason, customCtrl.cannotSaveReason);
        
        //Make selections and calculate payments
        pp.Date_of_First_Installment__c = Date.today();
        pp.New_Call_Limit__c = 100;
        pp.Use_New_Call_Limit__c = true;
        pp.One_off_Payment__c = ba.Total_Over_Due__c + 100;  // TRY
        pp.Proposed_Frequency__c = 'Weekly';
        pp.Number_of_Installments__c = 8;
        
        
        // Attempt to calc when entering a One off greater to Balance
        customCtrl.calculatePayments();
        
        system.assert(!customCtrl.planProduced);
        
        /*
        ApexPages.Message[] msgs = ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary().contains('The One off Payment cannot exceed the overdue amount'))
           {
              found=true;
           }
        }
        
        System.assert(found);
        */
        /*
        //Now enter a valid One off payment
        pp.One_off_Payment__c = ba.Total_Over_Due__c - 100; 
        
        customCtrl.calculatePayments();
        system.assert(customCtrl.planProduced);
        
        //Save
        customCtrl.savePP(); //This should display an error and exit
        
        msgs = ApexPages.getMessages();
        found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary().contains('error'))
           {
              found=true;
           }
        }
        
        System.assert(found);
                
        customCtrl.cancel();
        
        // Retrieve and assert
        List<Payment_Plan__c> savedPPs = [select Billing_Account__c, Date_of_First_Installment__c, Last_Due_Date__c, New_Call_Limit__c, Number_of_Installments__c,
                                        One_off_Payment__c, Payment_Method__c, Proposed_Frequency__c, Proposed_Term__c, Status__c,
                                        (select Id, Name, Amount__c, Due_Date__c from Payment_Plan_Lines__r order by Due_Date__c asc)
                                    from Payment_Plan__c where Billing_Account__c = :ba.Id];
                                            
        system.assertEquals(0, savedPPs.size());
        */
    }
    
    static testMethod void viewExistingSavedPP_AssertEditableMode() {
        
        TestHelper.createCollectionSettings(6);
        
        Billing_Account__c ba = TestHelper.createBillingAccount();
        
        Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Saved, 
                            Date_of_First_Installment__c = Date.today(),  Number_of_Installments__c = 3);
        insert pp;
        
        Payment_Plan_Line_Item__c li = new Payment_Plan_Line_Item__c(Payment_Plan__c = pp.Id, Amount__c = 20, Due_Date__c = Date.today());
        insert li;
        
        //DON'T Setup page params
        
        ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(pp);
        PaymentPlanController customCtrl = new PaymentPlanController(strctrl);
        
        system.assert(!customCtrl.planProduced);
        system.assert(!customCtrl.isReadOnlyMode);
        system.assert(customCtrl.isExistingPP);
        system.assert(customCtrl.canSave);
    }
    
    static testMethod void viewExistingOpenPP_AssertReadOnlyMode() {
        
        TestHelper.createCollectionSettings(6);
                
        Billing_Account__c ba = TestHelper.createBillingAccount();
        
        Payment_Plan__c pp = new Payment_Plan__c(Billing_Account__c = ba.Id, Status__c = Constants.PaymentPlanStatus_Open,
                    Date_of_First_Installment__c = Date.today(), Preferred_Communication_Method__c = Constants.PreferredCommMethod_Email,
                    Number_of_Installments__c = 1);
        insert pp;
        
        Payment_Plan_Line_Item__c li = new Payment_Plan_Line_Item__c(Payment_Plan__c = pp.Id, Amount__c = 20, Due_Date__c = Date.today());
        insert li;
        
        //DON'T Setup page params
        
        ApexPages.Standardcontroller strctrl = new ApexPages.Standardcontroller(pp);
        PaymentPlanController customCtrl = new PaymentPlanController(strctrl);
        
        system.assert(!customCtrl.planProduced);
        system.assert(customCtrl.isReadOnlyMode);
        system.assert(customCtrl.isExistingPP);
    }

}