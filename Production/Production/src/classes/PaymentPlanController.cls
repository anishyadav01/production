public with sharing class PaymentPlanController {
     
/*
This is the Page used to create a new Payment Plan and Line Items. It also overrides the standard View and Edit buttons of Payment Plan.

There are 2 modes the page can be in:
Read-Only: If viewing/editing an existing Payment Plan of Status 'Pending Approval', 'Open' or 'Closed'. 
No Changes are allowed. Only the Line Items can be edited, specifically the Amount paid field (this is controlled by FLS, all else should be Read-Only)

Editable: If creating a new Payment Plan or viewing/editing an existing Payment Plan with Status 'Saved'. In these cases, the user can still amend
the calculation parameters (Payment Plan fields) and produce different Line Items accordingly. 
When satisfied with the outcome they cansave the Payment Plan. If editing an existing plan, the changes should override the existing/old fields and
the existing Line Items will be overwritten by the new /latest ones.

*/


    private Payment_Plan__c pp {get; private set;}
    public Billing_Account__c billingAccount {get; private set;}

    public List<Payment_Plan_Line_Item__c> ppItems {get; private set;}
    
    public List<DetailsOfCalculation> detailsOfCalculations {get; private set;}
    
    
    public String PP_Result {get; private set;} //displays summary of payment plan
    public Boolean planProduced {get; private set;}  //user has calculated a new plan  
    
    public Boolean accountDisconnected {get; private set;}   
    public String accountDisconnectedError {get; private set;}  
    
    public Collections_Settings__c collSettings {get; private set;} //public as accessed by Javascript

    private Boolean notClosedPPorP2PExists {get; private set;}
    //private Boolean paymentPlanExistedInLastSixMonths {get; private set;}
    
    public Boolean emailBrandExists {get; private set;}
    public String emailBrandExistsError {get; private set;}
    
    public Boolean debt60DayExists {get; private set;}
    public String  debt60DayExistsError {get; private set;}
    private Decimal debt_60_Plus_day  { private get; private set;}
    private Decimal min_Upfront_Payment = 0;
    
    private Boolean primaryContactExists; //added 14/10/2013
    
    private Decimal total_OverDue;
    
    //Hold values of params when Calculating Payments and check whether still the same when Saving
    private Decimal mrc_UsedToCalc;
    private Decimal oneOff_UsedToCalc;
    private Date dateOfFirstInstall_UsedToCalc;
    private Integer proposedTerm_UsedToCalc;
    private String proposedFreq_UsedToCalc;
    private Decimal imminentDebit_UsedToCalc;
    private Decimal newCallLimit_UsedToCalc;
    private Boolean useNewCallLimit_UsedToCalc;
    private Decimal imminentCredit_UsedToCalc;
        
    @TestVisible private final String notClosedPPReason = ' Open, Saved or Pending Approval Payment Plans or Promises to Pay already exist. You will only be able to save a new ' +
                                            'Payment Plan once you manually Close all other active Payment Plans or Promises to Pay.';
                                            
    //private final String recentPPExistsReason = ' a Payment Plan was setup in the last 6 months.';  
    
    public static map<string, Collections_One_Off_Charges__c> oneOffChargesMap = new map<string, Collections_One_Off_Charges__c>();
    public List<Payment_Plan_Charge__c> mrcAndChargesList {get; set;}
    public integer numberOfLines{get; set;}

    public string chargeToAdd {set; get;}
    public string chargeToRemove {set; get;}
            
    public List<SelectOption> chargeOptionsList = new List<SelectOption>();
    
    public decimal totalMRCAmount {get; set;}
    public decimal totalOneOffAmount {get; set;}

    public String dueDateOnResumeMessage {get; set;}
    private Integer proposedTermInMonths = 0;

    public map<string, Collections_One_Off_Charges__c> getOneOffChargesMap(){
        if (oneOffChargesMap.size() == 0){
            List<Collections_One_Off_Charges__c> oneOffChargesTemp = Collections_One_Off_Charges__c.getall().values();
            for ( Collections_One_Off_Charges__c charge : oneOffChargesTemp ){
                oneOffChargesMap.put (charge.name, charge);
            }
        }
        return oneOffChargesMap;
    }    
    
    public List<SelectOption> getOneTimeChargesAndAdjustment() {
        if (chargeOptionsList.size() == 0 ){
            List<SelectOption> options = new List<SelectOption>(); 
            for (Collections_One_Off_Charges__c oneOffCharge : getOneOffChargesMap().values() ){              
                String val = ( oneOffCharge.Monthly_Recurring__c ? 'Y':'N') + '~' + oneOffCharge.Amount__c;
                options.add(new SelectOption( 'charge_'+oneOffCharge.Name, oneOffCharge.Name + '- £' + oneOffCharge.Amount__c));   
            }
            //chargeOptionsList = updateWithMRCAdjustments (options) ;
        }
        return chargeOptionsList; 
    }    
    /*
    public List<SelectOption> updateWithMRCAdjustments ( List<SelectOption> options ){
        if ( billingAccount != null ){
                // check if all the required fields have value if not .... add
            if (billingAccount.Broadband_Boost__c == null || billingAccount.Broadband_Boost__c <= 0) {
                    options.add (new SelectOption( 'Broadband Boost', 'Broadband Boost'));
            }
            if (billingAccount.Line_Rental_Boost__c == null || billingAccount.Line_Rental_Boost__c <= 0) {
                    options.add (new SelectOption( 'Line Rental Boost', 'Line rental Boost'));
            }
            if (billingAccount.Package_Cost__c == null || billingAccount.Package_Cost__c <= 0) {
                    options.add (new SelectOption( 'Package cost', 'Package cost'));
            }
            if (billingAccount.TV_Boost__c == null || billingAccount.TV_Boost__c <= 0) {
                    options.add (new SelectOption( 'TV Boost', 'TV Boost'));
            }
            if (billingAccount.Voice_Boost__c == null || billingAccount.Voice_Boost__c <= 0) {
                    options.add (new SelectOption( 'Voice Boost', 'Voice Boost'));
            }
        } 
        return options; 
    }    
    */
    
    public void updateChargeOptionsList ( List<Payment_Plan_Charge__c> mrcAndChargesListTemp ){
        List<SelectOption> options = new List<SelectOption>(); 
        for (SelectOption option :  chargeOptionsList ){
            boolean found = false;
            for ( Payment_Plan_Charge__c mrc : mrcAndChargesListTemp ){
                if (mrc.Charge_Name__c.replaceAll ('charge_','') == option.getValue().replaceAll ('charge_','') ){
                    found = true;
                    break;
                }
            }
            if (!found){
                options.add (option);
            }
        } 
        chargeOptionsList = options;
    }
    
    private Payment_Plan_Charge__c getPaymentPlanCharge( String name, Decimal amount, string type ){
        return new Payment_Plan_Charge__c ( Charge_Name__c = name, Amount__c = amount, Charge_Type__c = type );
    }
    private Payment_Plan_Charge__c getPaymentPlanCharge( String name, Decimal amount, string type, string adjustmentType ){
        return new Payment_Plan_Charge__c ( Charge_Name__c = name, Amount__c = amount, Charge_Type__c = type, Adjustment_Type__c = adjustmentType );
    }    
    
    
    
                                              
    public Boolean canSave {
        get
        {
            return !notClosedPPorP2PExists; // && !paymentPlanExistedInLastSixMonths;
        }
    }
    
    public String cannotSaveReason {
        get {
            return (notClosedPPorP2PExists ? notClosedPPReason : ''); //was :recentPPExistsReason
         }
    }
    
    //Page should be in Read Only mode when Viewing an existing PP with Status anything but 'Saved'.
    public Boolean isReadOnlyMode {
        get {
            return isExistingPP && pp.Status__c != Constants.PaymentPlanStatus_Saved;
        }
    }
    
    public Boolean isExistingPP {
        get {
            return pp.Id != null;
            }
    }        

    public PaymentPlanController(ApexPages.StandardController controller) {
        
        pp = (Payment_Plan__c)controller.getRecord();
        String billingAccountId;
        
        List<Payment_Plan_Charge__c> mrcAndChargesListTemp = new List<Payment_Plan_Charge__c>();
        
        if (pp.Id != null) {
            ppItems = database.query('select ' + SObjectHelper.getFieldListForSOQL('Payment_Plan_Line_Item__c') + 
                                                        ' from Payment_Plan_Line_Item__c where Payment_Plan__c = \'' + pp.Id + '\'');

            mrcAndChargesListTemp = database.query('select Adjustment_Amount__c, Adjustment_Type__c, Amount__c, Charge_Name__c, Charge_Type__c, Payment_Plan__c' +
                                                    ' from Payment_Plan_Charge__c where Payment_Plan__c = \'' + pp.Id + '\'');

            PP_Result = getPaymentPlanSummary(pp.Number_of_Installments__c, ppItems[0].Amount__c, pp.One_off_Payment__c);
                                
            billingAccountId = pp.Billing_Account__c;
        }
        
        else {
            billingAccountId = ApexPages.currentPage().getParameters().get('billAccountId');
         }
        
        if (billingAccountId != null) {
            billingAccount = database.query('select Primary_Contact__r.Name, Primary_Contact__r.Email, Primary_Contact__r.Phone, ' + 
                                                SObjectHelper.getFieldListForSOQL('Billing_Account__c') + 
                                                        ' from Billing_Account__c where Id = \'' + billingAccountId + '\'');
        }
        
        List<Asset> assetsList = [Select a.Status__c, a.Billing_Account__c From Asset a where status__c =:'ACTIVE' and a.Billing_Account__c = :billingAccountId];
        if(assetsList == null || assetsList.size() == 0 ){
        	accountDisconnected = true;
        	accountDisconnectedError = 'You cannot have a PP for a Disconnected Account';
        }else{
        	accountDisconnected = false;
        }
        
        debt_60_Plus_day = billingAccount.DAYS_61_90__c + billingAccount.DAYS_91_120__c + billingAccount.DAYS_121_150__c + billingAccount.DAYS_151_180__c + 	
        					billingAccount.DAYS_181_210__c + billingAccount.DAYS_211_240__c + billingAccount.DAYS_241_270__c + billingAccount.DAYS_271_300__c + 	
        					billingAccount.DAYS_301_330__c + billingAccount.DAYS_331_360__c;
       
        					
        					
       System.debug('>>>>>>>>>>>>>>>>>>>billingAccount = '+billingAccount);
       System.debug('>>>>>>>>>>>>>>>>>>>debt_60_Plus_day = '+debt_60_Plus_day);
        debt60DayExists = false;
        
        if(!accountDisconnected && debt_60_Plus_day > 0){
        	min_Upfront_Payment = Math.round(billingAccount.Total_Over_Due__c * 0.20);
        	debt60DayExists = true;
        	debt60DayExistsError = 'The Debt is > 60days, So a minimum upfront payment of £'+Math.round(min_Upfront_Payment)+' is required to save this Payment Plan';	
        }  
        
        emailBrandExists = false;
        emailBrandExistsError = 'Please ensure';
        
        if(billingAccount.Brand__c == null ){
                emailBrandExists = true;
                emailBrandExistsError = emailBrandExistsError +' Brand ';
        } 
        
        if(billingAccount.Primary_Contact__c == null ){
                primaryContactExists = false;
                if(emailBrandExists){
                        emailBrandExistsError = emailBrandExistsError +' ,Primary Contact';
                }else{
                        emailBrandExistsError = emailBrandExistsError +' Primary Contact';
                        emailBrandExists = true;
                }
                emailBrandExistsError = emailBrandExistsError +' is populated on the Billing Account.';
        }else{
                primaryContactExists = true;
                emailBrandExistsError = emailBrandExistsError +' is populated on the Billing Account.';
                Contact con = [Select c.Email From Contact c where id =: billingAccount.Primary_Contact__c ];
                if(con.email == null){
                        if(emailBrandExists){
                                emailBrandExistsError = emailBrandExistsError +' Please ensure that the Primary Contact has email populated';
                        }else{
                                emailBrandExists = true;
                        emailBrandExistsError = ' Please ensure that the Primary Contact has email populated';
                        }
                }
        }
        
        //Initialise
        planProduced = false;
        
        //Get Collection Setting
        collSettings = Collections_Settings__c.getInstance(UserInfo.getUserId());
        
        //Check if an Open PP exists or a PP was created the last 6 months. This will determine the visibility of the Save button
        notClosedPPorP2PExists = false;  //init
        //paymentPlanExistedInLastSixMonths = false;  //init
        
        List<Payment_Plan__c> existingPlans = [select Id, Name, Status__c, Last_Due_Date__c, Billing_Account__c 
                                               from Payment_Plan__c
                                               where Billing_Account__c = :billingAccount.Id and Id != :pp.Id];
                                               
        List<Promise_to_Pay__c> existingP2PsForBillingAccount = [select Id, Name 
                                                                  from Promise_to_Pay__c
                                                                  where Billing_Account__c = :billingAccount.Id and 
                                                                        Status__c != :Constants.PaymentPlanStatus_Closed];
                                                    
        //Check ability to Save
        if (existingP2PsForBillingAccount != null && existingP2PsForBillingAccount.size() > 0) {
            notClosedPPorP2PExists = true;
        }
        else {
            for (Payment_Plan__c p : existingPlans) {
                if (p.Status__c != Constants.PaymentPlanStatus_Closed) {
                    notClosedPPorP2PExists = true;
                    break;
                }
                
                /* 27/09: EP commented out as requested during UAT
                else if (p.Last_Due_Date__c > Date.today().addMonths(-6) && p.Last_Due_Date__c < Date.today()) {
                    paymentPlanExistedInLastSixMonths = true;
                    break;
                }
                */
            }
        }
        
        detailsOfCalculations = new List<DetailsOfCalculation>();
        loadCharges (mrcAndChargesListTemp);
        updateChargeOptionsList (mrcAndChargesListTemp);
        
        updateMRCAndCharges();
    }
    
    public PageReference addChargesToList() {
        String chargeName = chargeToAdd;
        if ( chargeName != null && chargeName.indexof ('charge_') > -1 ){
            // its a charge add charge
            Collections_One_Off_Charges__c oneOff = getOneOffChargesMap().get( chargeName.replaceAll ('charge_', '')  );
            mrcAndChargesList.add ( getPaymentPlanCharge ( oneOff.name, oneOff.amount__c, 'Charge' )) ;
        }else {
                //it must be MRC line items
                mrcAndChargesList.add ( getPaymentPlanCharge ( chargeName, 0.00, 'MRC Line Item', 'Add' )) ;
        }
        
        // we need to remove the option from the list
        integer index = 0; 
        for ( SelectOption op : chargeOptionsList){
                if ( op.getValue() == chargeName ){
                        chargeOptionsList.remove (index);
                        break;  
                }
                index++;
        }
        updateMRCAndCharges() ;
        return null;
    }    
    
    
    
    public void updateMRCAndCharges() {
        system.debug('======>>>>>> updateMRCAndCharges mrcAndChargesList.size' + mrcAndChargesList.size() );          
        decimal totalMRCAmount = 0.00;

        for ( Payment_Plan_Charge__c ppCharge : mrcAndChargesList ){
                        if ( ppCharge != null ){
                                Collections_One_Off_Charges__c oneOff = getOneOffChargesMap().get( ppCharge.Charge_Name__C.replaceAll('charge_', '') );
                                if (oneOff != null && !oneOff.Monthly_Recurring__c ){
                                        // add to oneoff
                                        //totalOneOffAmount = totalOneOffAmount + ppCharge.Amount__c;
                                } else { 
                                        totalMRCAmount = totalMRCAmount + ppCharge.Amount__c;
                                        
                                        if (ppCharge.Adjustment_Amount__c != null && ppCharge.Adjustment_Amount__c > 0){
                                                if (ppCharge.Adjustment_Type__c == 'Add'){      
                                                        totalMRCAmount = totalMRCAmount + ppCharge.Adjustment_Amount__c;
                                                }else {
                                                        totalMRCAmount = totalMRCAmount - ppCharge.Adjustment_Amount__c;
                                                }
                                        }
                                }
                        }
        }
        //pp.MRC1__c = totalMRCAmount;
    }     
    
    
    public PageReference removeChargesFromList() {
        system.debug('======>>>>>> removeChargesFromList mrcAndChargesList.size' + mrcAndChargesList.size() );
        
        String chargeName = chargeToRemove;
        integer index = 0;
        for ( Payment_Plan_Charge__c ppCharge : mrcAndChargesList ){
                if ( ppCharge.Charge_Name__c == chargeName ){
                        // remove from list
                                mrcAndChargesList.remove (index);
                                
                        if ( ppCharge.Charge_Type__c == 'Charge' ){
                                        chargeOptionsList.add (new SelectOption('Charge_' + chargeName, chargeName +  + '- £' + ppCharge.Amount__c  ) );
                        } else {
                                chargeOptionsList.add (new SelectOption(chargeName, chargeName) );
                        }
                        
                        break;
                } 
                index++;       
        }
        system.debug('======>>>>>> removeChargesFromList just before going out mrcAndChargesList.size' + mrcAndChargesList.size() );
                updateMRCAndCharges() ;
        return null;
    }    
    
    
    
    private void loadCharges ( List<Payment_Plan_Charge__c> mrcAndChargesListTemp ){
        mrcAndChargesList = new List<Payment_Plan_Charge__c>(); 
        
        if (mrcAndChargesListTemp != null && mrcAndChargesListTemp.size() > 0){
            for(Payment_Plan_Charge__c ppCharge : mrcAndChargesListTemp){
                mrcAndChargesList.add ( new Payment_Plan_Charge__c (
                                                    Adjustment_Amount__c = ppCharge.Adjustment_Amount__c,
                                                    Adjustment_Type__c = ppCharge.Adjustment_Type__c,
                                                    Amount__c = ppCharge.Amount__c,
                                                    Charge_Name__c  = ppCharge.Charge_Name__c,
                                                    Charge_Type__c  = ppCharge.Charge_Type__c,
                                                    Payment_Plan__c = ppCharge.Payment_Plan__c ) );
            }
        }else{/*
            if ( billingAccount != null ){
                    // check if all the required fields have value if not .... add
                if (billingAccount.Broadband_Boost__c != null && billingAccount.Broadband_Boost__c > 0) {
                         mrcAndChargesList.add( getPaymentPlanCharge('Broadband Boost', billingAccount.Broadband_Boost__c, 'MRC Line Item') );
                }
                if (billingAccount.Line_Rental_Boost__c != null && billingAccount.Line_Rental_Boost__c > 0) {
                         mrcAndChargesList.add( getPaymentPlanCharge('Line Rental Boost', billingAccount.Line_Rental_Boost__c, 'MRC Line Item') );
                }
                if (billingAccount.Package_Cost__c != null && billingAccount.Package_Cost__c > 0) {
                         mrcAndChargesList.add( getPaymentPlanCharge('Package Cost', billingAccount.Package_Cost__c, 'MRC Line Item') );
                }
                if (billingAccount.TV_Boost__c != null && billingAccount.TV_Boost__c > 0) {
                         mrcAndChargesList.add( getPaymentPlanCharge('TV Boost', billingAccount.TV_Boost__c, 'MRC Line Item') );
                }
                if (billingAccount.Voice_Boost__c != null && billingAccount.Voice_Boost__c > 0) {
                         mrcAndChargesList.add( getPaymentPlanCharge('Voice Boost', billingAccount.Voice_Boost__c, 'MRC Line Item') );
                }
            }  */     
        }    
    }     
    private String getPaymentPlanSummary(Decimal instalmentsNo, Decimal recurringAmount, Decimal oneOffPayment) {
        if(collSettings == null){
                //Get Collection Setting
        collSettings = Collections_Settings__c.getInstance(UserInfo.getUserId());
        }
        
        //Integer proposedTermInMonths = Integer.valueOf(pp.Proposed_Term__c);
        String msg = instalmentsNo + ' installments of ' + recurringAmount.setScale(2);
        if(oneOffPayment != null && oneOffPayment > 0){
                msg = msg + ' with an upfront payment of ' + (oneOffPayment==null? 0 :oneOffPayment.setScale(2));
        }
        system.debug('====----======>>>>> proposedTermInMonths-' + proposedTermInMonths);
        //if((proposedTermInMonths != null && proposedTermInMonths > collSettings.Approval_Term_Threshold__c) && (collSettings.PP_Call_Limit__c < pp.New_Call_Limit__c && pp.Use_New_Call_Limit__c)){
        //}else 
        
        if(proposedTermInMonths != null && proposedTermInMonths > collSettings.Approval_Term_Threshold__c){
                msg = msg +'. This Patment Plan will require approval as the term is > ' + collSettings.Approval_Term_Threshold__c + ' months' ;
        }
        //else
        if(collSettings.PP_Call_Limit__c < pp.New_Call_Limit__c && pp.Use_New_Call_Limit__c){
                msg = msg +'. This Payment Plan will require approval as the Call limit is above the allowed limit';
        }
        return msg + '.';  
    }
    
    
    public PageReference calculatePayments() {
        system.debug('=========================calculatePayments=========1');
        detailsOfCalculations = new List<DetailsOfCalculation>();
        
        ppItems = new List<Payment_Plan_Line_Item__c>(); //init
        planProduced = false;
        boolean hasErrors = false;
        
        if(accountDisconnected){
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You cannot have a PP for a Disconnected Account'));
            hasErrors = true;//exit!
            return null;
        }
        
        if (pp.MRC1__c == null ) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Total MRC.'));
             hasErrors = true;//exit!
        system.debug('=========================calculatePayments=========1.1');
             
        }
    
        if (pp.Date_of_First_Installment__c == null ) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Date of First Installment.'));
             hasErrors = true;//exit!
        system.debug('=========================calculatePayments=========1.2');

        }
        if (pp.Proposed_Frequency__c == null  ) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select Proposed Frequency.'));
             hasErrors = true;//exit!
        system.debug('=========================calculatePayments=========1.3');
             
        }
        if (pp.Number_of_Installments__c == null ) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter Number of Installments.'));             
             hasErrors = true;//exit!
        system.debug('=========================calculatePayments=========1.4');
             
        }
		
		/*
        //Ensure the One off amount is less or equal to Overdue Balance
        if (pp.One_off_Payment__c != null && pp.One_off_Payment__c > billingAccount.Total_Over_Due__c) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The One off Payment cannot exceed the overdue amount.'));
        system.debug('=========================calculatePayments=========1.5');
             
             hasErrors = true;//exit! 
        }*/
        
        //Ensure call limit > 0
        Decimal newCallLimit = pp.New_Call_Limit__c;
        Boolean useNewCallLimit = pp.Use_New_Call_Limit__c;
        if (useNewCallLimit && (newCallLimit == null || newCallLimit <=0)){ 
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Call limit cannot be zero.'));
             hasErrors = true;//exit!
        system.debug('=========================calculatePayments=========1.6');
             
        }
        
        if(pp.One_off_Payment__c != null && pp.One_off_Payment__c < min_Upfront_Payment){
        	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please ensure the minimum upfront payment is made'));
             hasErrors = true;//exit!
        }
        
        
        
        
        if ( hasErrors ){
            return null;
        }
           
        //Based on params calculate when Payments should occur
/*        List<Date> paymentDates = new List<Date>(); //hold the calculated Payment Dates based on term, frequency and 1st Installment date
        Date lastPaymentDate; //based on calculated dates, on frequency
        Date endOfTermDate; //based on Proposed Term. LAST POSSIBLE DATE a payment could occur
        Integer proposedTermInMonths = Integer.valueOf(pp.Proposed_Term__c);
        
        endOfTermDate = pp.Date_of_First_Installment__c.addMonths(proposedTermInMonths); //LAST POSSIBLE DATE
        lastPaymentDate = pp.Date_of_First_Installment__c; //keep as is
        paymentDates.add(Common.getNextWorkingDay(pp.Date_of_First_Installment__c));
        
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'Last payment can be on: ' + endOfTermDate));
        
        //Define the Payment Days based on 1st Installment date, Proposed Term and Proposed Frequency
        
        //EP change on 12/09/2013: was '=<' on lines 159 & 167, however for a Term of 2 months it was producing 3 installments.
        //If need to revert, then multiply mrc by (Term +1) (when calculating the totalDue)
        while (lastPaymentDate <= endOfTermDate) {
            if (pp.Proposed_Frequency__c == 'Monthly') {
                lastPaymentDate = lastPaymentDate.addMonths(1);
            }
            else {
                lastPaymentDate = lastPaymentDate.addDays(calcFrequencyInDays());
            }
            
            if (lastPaymentDate <= endOfTermDate) {
                paymentDates.add(Common.getNextWorkingDay(lastPaymentDate));
            }
        }
        
        Integer noOfInstallments = paymentDates.size();*/
        
        List<Date> paymentDates = new List<Date>(); //hold the calculated Payment Dates based on term, frequency and 1st Installment date
        Integer numberOfInstallments = Integer.valueOf(pp.Number_of_Installments__c);//Integer.valueOf(pp.Proposed_Term__c);
        system.debug('=========================calculatePayments========numberOfInstallments='+numberOfInstallments);
        
        //from first date of installment add number of installments..
        Date nextPaymentDate = pp.Date_of_First_Installment__c; //set to first payment
        Date lastPaymentDate;
        /*for ( Integer instNumber = 0; instNumber < numberOfInstallments; instNumber++ ){
            // add the payment
            lastPaymentDate = nextPaymentDate; // so that when we exit we have the last payment date
            paymentDates.add( Common.getNextWorkingDay( nextPaymentDate ) );
            
            // based on the frequency find the nextPaymentDate
            nextPaymentDate = getNextPaymentDate (nextPaymentDate, pp.Proposed_Frequency__c);
        }
*/
        for ( Integer instNumber = 0; instNumber < numberOfInstallments; instNumber++ ){
            // add the payment
            lastPaymentDate = nextPaymentDate; // so that when we exit we have the last payment date
            paymentDates.add(  nextPaymentDate  );
            
            // based on the frequency find the nextPaymentDate
            nextPaymentDate = getNextPaymentDate (pp.Date_of_First_Installment__c, pp.Proposed_Frequency__c, instNumber+1 );
        }
        system.debug('=========================calculatePayments========numberOfInstallments='+numberOfInstallments);
        
        // here all the instalment dates are processed ... get the proposed terms in month                 
        Integer proposedTermInMonthsTemp = pp.Date_of_First_Installment__c.monthsBetween( lastPaymentDate );
        //if (lastPaymentDate.day() >= pp.Date_of_First_Installment__c.day()) proposedTermInMonthsTemp++;
        
        if (lastPaymentDate.month() > pp.Date_of_First_Installment__c.month()) proposedTermInMonthsTemp = 0;
        
        if (proposedTermInMonthsTemp > 23 ) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Proposed term should not be more than 24 months. '));             
             return null;
        }       
        
        system.debug('=========================calculatePayments=========3');
        
        
        Decimal oneOffAmount = pp.One_off_Payment__c == null ? 0 : pp.One_off_Payment__c;
        Decimal unbilledAmount = billingAccount.UNBILLED_AMOUNT__c == null ? 0 : billingAccount.UNBILLED_AMOUNT__c;
        //Decimal mrc = billingAccount.MRC__c == null ? 0 : billingAccount.MRC__c;
        Decimal mrc = pp.MRC1__c;
        Decimal imminentCredit = pp.Imminent_Credit__c == null ? 0 : pp.Imminent_Credit__c;
        Decimal imminentDebit = pp.Imminent_Debit__c == null ? 0 : pp.Imminent_Debit__c;
        
        //EP added 17-09-2013: May need to check whether last payment falls in the last month in order to take this setting into account
        
        // get the first billing due date after the payment plan
        Date previousBillingDate = Date.valueOf ( system.today().year() + '-' + system.today().month() + '-' + billingAccount.Billing_Day_in_Month__c);
        if ( system.today() <=  previousBillingDate ){
            // bill for this month will be generated in future so reduce one month for getting the correct  previousBillingDate
            previousBillingDate = previousBillingDate.addMonths(-1);
        }
        
        // from today to end of term... check how many bills will be generated  
         Integer mrcMultiplier = 0;
         date nextPayDate = previousBillingDate.addMonths(1); 

        system.debug('=========================lastPaymentDate========='+lastPaymentDate);
        system.debug('=========================nextPayDate========='+nextPayDate);
        // between the first and last dates check how many times does the bill gets generated
         while (nextPayDate < lastPaymentDate){
            mrcMultiplier++; 
            nextPayDate = nextPayDate.addMonths(1);     
         } 
        system.debug('=========================calculatePayments=========mrcMultiplier'+mrcMultiplier);
          
        // the date when the bill will be due after the agreement is over
        Date firstDueDateAfterResume = nextPayDate;
        Integer billingMethodTolerance = 7;
        if(pp.Billing_Account__r.Billing_Method__c == 'PAPER'){
            billingMethodTolerance = 14;
        } 
        
        firstDueDateAfterResume = firstDueDateAfterResume.addDays( billingMethodTolerance );        
  
         if (pp.Include_Additional_MRC__c){
            mrcMultiplier ++;
            firstDueDateAfterResume = firstDueDateAfterResume.addMonths(1);
         }          
        system.debug('=========================calculatePayments=========6');

        //Added 14/10/2013
        //pp.MRC1__c = totalMRCAmount;
        mrc_UsedToCalc = pp.MRC1__c;
        oneOff_UsedToCalc = pp.One_off_Payment__c;
        dateOfFirstInstall_UsedToCalc = pp.Date_of_First_Installment__c;
        proposedTerm_UsedToCalc = proposedTermInMonthsTemp;
        proposedFreq_UsedToCalc = pp.Proposed_Frequency__c;
        imminentDebit_UsedToCalc = pp.Imminent_Debit__c;
        newCallLimit_UsedToCalc = pp.New_Call_Limit__c;
        useNewCallLimit_UsedToCalc = pp.Use_New_Call_Limit__c;
        imminentCredit_UsedToCalc = pp.Imminent_Credit__c;
        system.debug('=========================calculatePayments=========mrcMultiplier'+mrcMultiplier);
        
        Decimal optionalParam = (useNewCallLimit ? (newCallLimit* mrcMultiplier) : 0);
        
        Decimal totalDue = (billingAccount.Total_Over_Due__c - oneOffAmount + unbilledAmount + (mrc*mrcMultiplier) + optionalParam + imminentDebit - imminentCredit);
        
        Decimal recurringAmount = (totalDue / numberOfInstallments).setScale(2);
        system.debug('=========================calculatePayments=========7');
        
        //Create Payment Plan Line Items
        for (Integer i=0; i < paymentDates.size(); i++) {
            Payment_Plan_Line_Item__c newPPLI = new Payment_Plan_Line_Item__c(Name = 'Payment ' + (i+1), Amount__c = recurringAmount, Due_Date__c = paymentDates[i] , Sequence__c = i+1 );
            if (i != (paymentDates.size() - 1)) {
                newPPLI.Next_Payment_Due_Date__c = paymentDates[i+1];
            }
            
           ppItems.add(newPPLI);
        }
        
        //The total amount of installments needs to equal the Total due. Any decimal place adjustment will be reflected in the last payment
        Decimal lastInstallmentAmount = totalDue - ((numberOfInstallments - 1) * recurringAmount);
        
        system.debug('***** lastInstallmentAmount: ' + lastInstallmentAmount);
       
       
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'***** recurringAmount: ' + recurringAmount));
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'***** lastInstallmentAmount: ' + lastInstallmentAmount));
        
        
        ppItems[ppItems.size()-1].Amount__c = lastInstallmentAmount;
        //Populate extra field on Payment Plan
        proposedTermInMonths = proposedTermInMonthsTemp;                     
        PP_Result = getPaymentPlanSummary(numberOfInstallments, recurringAmount, oneOffAmount);
        planProduced = true;
        

        
        pp.Number_of_Installments__c = numberOfInstallments;
        pp.Last_Due_Date__c = ppItems.get(ppItems.size()-1).Due_Date__c; //Due date of last item

        dueDateOnResumeMessage = 'Please note the first payment due date after payment plan would be ' + firstDueDateAfterResume.format();        
        
        DetailsOfCalculation overDueCal = new DetailsOfCalculation();
        overDueCal.calculationFormula = 'Total Overdue:';
        overDueCal.total = billingAccount.Total_Over_Due__c;
        detailsOfCalculations.add(overDueCal);
        
        
        DetailsOfCalculation unbilledAmountCal = new DetailsOfCalculation();
        unbilledAmountCal.calculationFormula = '+ Unbilled Amount:';
        unbilledAmountCal.total = unbilledAmount;
        detailsOfCalculations.add( unbilledAmountCal);
        
        
        DetailsOfCalculation MRCCal = new DetailsOfCalculation();
        MRCCal.calculationFormula = '+ MRC ('+mrc+'*'+mrcMultiplier+'):';
        MRCCal.total = mrc*mrcMultiplier;
        detailsOfCalculations.add(MRCCal);
        
        if(useNewCallLimit){
          DetailsOfCalculation optionalCal = new DetailsOfCalculation();
          optionalCal.calculationFormula = '+ Call Limit ('+newCallLimit+'*'+mrcMultiplier+'):';
          optionalCal.total = (newCallLimit*mrcMultiplier).setScale(2);
          detailsOfCalculations.add(optionalCal);       
        }
        
       
        DetailsOfCalculation imminentDebitPaymentCal = new DetailsOfCalculation();
        imminentDebitPaymentCal.calculationFormula = '+ Imminent Debit:';
        imminentDebitPaymentCal.total = imminentDebit.setScale(2);
        detailsOfCalculations.add(imminentDebitPaymentCal);
        
        DetailsOfCalculation imminentCreditPaymentCal = new DetailsOfCalculation();
        imminentCreditPaymentCal.calculationFormula = '- Imminent Credit:';
        imminentCreditPaymentCal.total = (imminentCredit - (imminentCredit * 2)).setScale(2);
        detailsOfCalculations.add(imminentCreditPaymentCal);
        
        DetailsOfCalculation oneOffPaymentCal = new DetailsOfCalculation();
        oneOffPaymentCal.calculationFormula = '- One off Payment:';
        oneOffPaymentCal.total = (oneOffAmount - (oneOffAmount * 2)).setScale(2);
        detailsOfCalculations.add(oneOffPaymentCal);
        
        DetailsOfCalculation totalvalueCal = new DetailsOfCalculation();
        totalvalueCal.calculationFormula = 'Total:';
        totalvalueCal.total = totalDue.setScale(2);
        detailsOfCalculations.add(totalvalueCal);
        
        return null;
    }
    
    private Date getNextPaymentDate (Date nextPaymentDate, String frequency, Integer installmentNumber){
        integer daysToAdd = 0;
        if (pp.Proposed_Frequency__c == 'Monthly') {
            nextPaymentDate = nextPaymentDate.addMonths( installmentNumber );
        } else {  
            if (pp.Proposed_Frequency__c == 'Weekly') {
                daysToAdd = 7;
            } else if (pp.Proposed_Frequency__c == 'Fortnightly') {
                daysToAdd = 2*7;
            } else if (pp.Proposed_Frequency__c == '4-Weeks') {
                daysToAdd = 4*7;
            }
            nextPaymentDate = nextPaymentDate.addDays(daysToAdd * installmentNumber);
        }        
        return nextPaymentDate;
    }
    
    private Date getNextPaymentDate (Date nextPaymentDate, String frequency){
        integer daysToAdd = 0;
        if (pp.Proposed_Frequency__c == 'Monthly') {
            nextPaymentDate = nextPaymentDate.addMonths(1);
        } else {  
            if (pp.Proposed_Frequency__c == 'Weekly') {
                daysToAdd = 7;
            } else if (pp.Proposed_Frequency__c == 'Fortnightly') {
                daysToAdd = 2*7;
            } else if (pp.Proposed_Frequency__c == '4-Weeks') {
                daysToAdd = 4*7;
            }
            nextPaymentDate = nextPaymentDate.addDays(daysToAdd);
        }        
        return nextPaymentDate;
    }    
    
    /*
    private Integer calcFrequencyInDays() {
        
        if (pp.Proposed_Frequency__c == 'Weekly') {
            return 7;
        }
       else if (pp.Proposed_Frequency__c == 'Fortnightly') {
            return 2*7;
        }
        else if (pp.Proposed_Frequency__c == '4-Weeks') {
            return 4*7;
        }
        
        //This should not be called!
        else if (pp.Proposed_Frequency__c == 'Monthly') {
            return 30;
        }  
        
        return 1;
    }
    */
    
    
    /*
     * Check whether any calculation params have change since payments were last calculated by the user
     */
    private Boolean calcParamsHaveChangedSinceLastCalculation() {
    
        if (mrc_UsedToCalc != pp.MRC1__c || oneOff_UsedToCalc != pp.One_off_Payment__c || dateOfFirstInstall_UsedToCalc != pp.Date_of_First_Installment__c ||
            proposedTerm_UsedToCalc != proposedTermInMonths || proposedFreq_UsedToCalc != pp.Proposed_Frequency__c ||
            imminentDebit_UsedToCalc != pp.Imminent_Debit__c || newCallLimit_UsedToCalc != pp.New_Call_Limit__c || 
            useNewCallLimit_UsedToCalc != pp.Use_New_Call_Limit__c || imminentCredit_UsedToCalc != pp.Imminent_Credit__c) {
            
            return true; 
        }
        else {
            return false;
        }
    }
    
    /*
    *   Save can only be called if creating a new PP or editing an existing 'Saved' one.
    */
    public PageReference savePP() {
        /*
        //Ensure nothing has gone wrong
        if ((pp.Id != null && pp.Status__c != Constants.PaymentPlanStatus_Saved) || !canSave) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You cannot override this Payment Plan. Please contact your administrator as an error has occurred'));
            return null;
        }
        */
        
        //added 14/10/2013
        if (!primaryContactExists) {
            return null;
         }
        
        if (ppItems == null || ppItems.size() == 0) {
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please Calculate the payments before saving.'));
             return null;
        } else if (calcParamsHaveChangedSinceLastCalculation()) { //added 14/10/2013
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You have modified one or more parameters. Please recalculate the payments before saving.'));
             return null;
        }
    
        //Save Payment Plan with appropriate Status
        
        //EP added 14/10/2013
        //calculatePayments(); //force recalc in case calc params have changed
        
        
        if (collSettings != null && !String.isEmpty(collSettings.Payment_Plan_Path__c)) {
        
            List<Collection_Path__c> paths = [select Id, Name from Collection_Path__c where Name = :collSettings.Payment_Plan_Path__c];
            
            //error handling!!!
            
            pp.Collection_Path__c = paths[0].Id;
            pp.Name = paths[0].Name;
            pp.Billing_Account__c = billingAccount.Id;
                        
            // If approval required based on Term and user is not a 'CPS Team Lead'
            Id userProfileId = UserInfo.getProfileId();
            System.debug('******************Profile ID' + userProfileId + '***proposedTermInMonths***' + proposedTermInMonths);
            List<Profile> profiles = [Select Name from Profile where Id =: userProfileId];
                        
            Boolean forApproval = false; 
            if(profiles[0].Name != 'CPS Team Lead' && debt_60_Plus_day > 0){
            	pp.Status__c =  Constants.PaymentPlanStatus_Saved;
                forApproval = true;
            }
            else if (profiles[0].Name != 'CPS Team Lead' && 
                ((collSettings.Approval_Term_Threshold__c != null && collSettings.Approval_Term_Threshold__c < proposedTermInMonths )
                || (collSettings.PP_Call_Limit__c < pp.New_Call_Limit__c && pp.Use_New_Call_Limit__c))
                ) {
                pp.Status__c =  Constants.PaymentPlanStatus_Saved;
                forApproval = true; 
            }
            else {
                pp.Status__c =  Constants.PaymentPlanStatus_Open;
            }
            
            //EP added 24/09/2013
            Savepoint sp = Database.setSavepoint();
            try {
                system.debug ('==============>>>>>>Before upsert -- pp');
                upsert pp;
                system.debug ('==============>>>>>>After upsert -- pp');
                // ---- Create/overwrite Payment Plan Line Items if modified ----
                //delete any existing and save
                if (pp.Id != null && !planProduced) {} //do nothing as PPLIs have not changed}
                else  {
                    system.debug ('==============>>>>>>After upsert -- pp');
                    if (pp.Id != null) {
                        List<Payment_Plan_Charge__c> existingPPCharges = [select Id from Payment_Plan_Charge__c where Payment_Plan__c = :pp.Id];
                        if (existingPPCharges != null && existingPPCharges.size() > 0) {
                            delete existingPPCharges; //clear existing charges if any
                         }
                     }
                
                    for (Payment_Plan_Charge__c li : mrcAndChargesList) {
                        //Only assign Parent relationship if not assigned already (they might click on Save without making changes on existing ones), 
                        //otherwise field is not writeable!
                        if (li.Payment_Plan__c == null) {
                            li.Payment_Plan__c = pp.Id;
                            li.id = null;
                            if(li.Adjustment_Amount__c == null ){
                                li.Adjustment_Type__c = null;
                            }
                        }
                    }
                    system.debug ('==============>>>>>>After before -- mrcAndChargesList' + mrcAndChargesList);
                    
                    insert mrcAndChargesList;                   
                    system.debug ('==============>>>>>>After upsert -- mrcAndChargesList');
                    
                    if (pp.Id != null) {
                        List<Payment_Plan_Line_Item__c> existingPPLIs = [select Id from Payment_Plan_Line_Item__c where Payment_Plan__c = :pp.Id];
                        if (existingPPLIs != null && existingPPLIs.size() > 0) {
                            delete existingPPLIs; //clear existing PPLIs if any
                         }
                     }
                
                    for (Payment_Plan_Line_Item__c li : ppItems) {
                        //Only assign Parent relationship if not assigned already (they might click on Save without making changes on existing ones), 
                        //otherwise field is not writeable!
                        li.id = null;
                        if (li.Payment_Plan__c == null) {
                            li.Payment_Plan__c = pp.Id;
                        }
                    }
                    
                    insert ppItems;
                }
             }
             catch (DmlException e) {
                 Database.rollback(sp);

                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getdmlMessage(0)));
                 return null; //stay on page and display the error
            }
             catch (Exception e) {
                 Database.rollback(sp);

                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
                 return null; //stay on page and display the error
            }
            
            //If everything ok so far, carry on
            if(forApproval){
               submitForApproval();
            }
            return redirectToBillingAccountPage(); 
        }
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No Payment Path has been defined in Custom Settings.'));
            return null;
        }
    }
    
    public PageReference cancel() {
         return redirectToBillingAccountPage();   
    }
    
    public PageReference submitForApproval() {
    
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(pp.id);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        return redirectToBillingAccountPage();
    }
    
    private PageReference redirectToBillingAccountPage() {
        PageReference billAccountPage = new PageReference('/'+ billingAccount.Id);
        billAccountPage.setRedirect(true);
        return billAccountPage;
    }
    
    public class DetailsOfCalculation{
        public String calculationFormula {get; set;}
        public Decimal total {get; set;}
    }

}