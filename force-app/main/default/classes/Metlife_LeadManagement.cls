@JsonAccess(serializable='always')
global class Metlife_LeadManagement implements vlocity_ins.VlocityOpenInterface2, Callable{

    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    global Object invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options){
        
        switch on methodName
		{
			when 'ConvertLead'{
				return ConvertLead(input, output, options);
			}
            when 'GenerateTestData'{
                return GenerateTestData(input, output, options);
            }
            when else{
				output.put('hasErrors', true);
				output.put('errorMessage', 'No Apex method found for name: ' + methodName);
				return output;
			}
        }
    }

    public static Map<String,Object> ConvertLead(Map<String,Object> inputs,
	                                                  Map<String,Object> output,
	                                                  Map<String,Object> options){
        String CampaignMemberId = (String) inputs.get('CampaignMemberId');
        String LeadId = (String) inputs.get('LeadId');
        String AccountId = (String) inputs.get('AccountId');
        String OpportunityId = (String) inputs.get('OpportunityId');
        String ConvertedLeadStatus = (String) inputs.get('ConvertedLeadStatus');

        output.put('hasErrors', false);
        output.put('createOpp', false);

        if (String.isBlank(LeadId)){
            output.put('AccountId', AccountId);
            if (String.isBlank(OpportunityId)){
                output.put('createOpp', true);
                output.put('Message', 'No Lead conversion needed as the campaign member is already an account, but Opp already created');
            }else{
                output.put('OpportunityId', OpportunityId);
                output.put('Message', 'No Lead conversion needed as account and opp apready exists');
            }
			return output;
        }else{
            if (ConvertedLeadStatus == 'Converted'){
                output.put('AccountId', AccountId);
                if (String.isBlank(OpportunityId)){
                    output.put('createOpp', true);
                    output.put('Message', 'No Lead conversion needed as the campaign member is already an account, but Opp already created');
                }else{
                    output.put('OpportunityId', OpportunityId);
                    output.put('Message', 'No Lead conversion needed as account and opp apready exists');
                }
            }else{
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(LeadId);
                lc.setConvertedStatus('Converted');
                if(!String.isBlank(AccountId)){
                    lc.setAccountId(AccountId);
                }
                Try{
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    if (lcr.isSuccess()){
                        output.put('AccountId', lcr.getAccountId());
                        output.put('OpportunityId', lcr.getOpportunityId());
                    }else{
                        output.put('hasErrors', true);
                        output.put('Message', 'Failed To Convert the lead' );
                        return output;
                    }
                }catch (Exception e){
                    output.put('hasErrors', true);
                    output.put('Message', e.getMessage() );
                    return output;
                }
            }
        }
        return output;
    }

    public static Map<String,Object> GenerateTestData(Map<String,Object> inputs,
	                                                  Map<String,Object> output,
	                                                  Map<String,Object> options){
        String CampaignId = (String) inputs.get('CampaignId');
        String D2CFirstName = (String) inputs.get('D2CFirstName');
        String D2CLastName = (String) inputs.get('D2CLastName');
        String D2CBirthDate_Str = (String) inputs.get('D2CBirthDate');
        Date D2CBirthDate;
        if (String.isNotBlank(D2CLastName))
            D2CBirthDate =  date.valueOf(D2CBirthDate_Str);

        String TestUseCase = (String) inputs.get('UseCase');

        List<RecordType> recordTypes = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE
            (
                SobjectType = 'Account'
                AND DeveloperName = 'PersonAccount'
            ) 
            OR 
            (
                SobjectType = 'Opportunity'
                AND DeveloperName = 'X00_Client_final_ou_client_assur'
            ) 
            OR 
            (
                SobjectType = 'Lead'
                AND DeveloperName = 'x00_client_final_ou_client_assure_Personne_physique'
            ) 
            OR 
            (
                SobjectType = 'CampaignMember'
                AND DeveloperName = 'X00_Campagne_Grande_Branche'
            )];

        String AccountRecordTypeId = '';
        String OpportunityRecordTypeId = '';
        String LeadRecordTypeId = '';
        String CampaignMemberRecordTypeId = '';

        for (Recordtype r : recordTypes){
            switch on r.SobjectType
		    {
			    when 'Account'{
                    AccountRecordTypeId = r.id;
                }
                when 'Opportunity'{
                    OpportunityRecordTypeId = r.id;
                }
                when 'Lead'{
                    LeadRecordTypeId = r.id;   
                }
                when 'CampaignMember'{
                    CampaignMemberRecordTypeId = r.id;
                }
            }
        }
        System.debug('########### TestUseCase : ' + TestUseCase);
        switch on TestUseCase
		{
			when 'CampaignMemberAsLeadConverted','CampaignMemberAsLeadNotConverted'{
				Lead l = new Lead();
                l.FirstName = D2CFirstName;
                l.LastName = D2CLastName;
                l.Birthdate__c = D2CBirthDate;
                l.recordTypeId = LeadRecordTypeId;
                l.Status = 'Pending';

                Insert l;

                System.debug('########### CreatedLead : ' + l.Name + ' ' + l.Id );

                CampaignMember cm = new CampaignMember ();
                cm.LeadId = l.Id;
                cm.CampaignId = CampaignId;

                Insert cm;

                CampaignMember cm2 = [SELECT id, Lead_number__c FROM CampaignMember WHERE Id = :cm.Id LIMIT 1 ];
                System.debug('########### CreatedCampaignMember : ' + cm2.Id + ' ' + cm2.Lead_number__c );

                output.put('Lead_number__c', cm2.Lead_number__c);

                if (TestUseCase == 'CampaignMemberAsLeadConverted'){
                    Map<String,Object> inputs1 = new Map<String,Object>();
                    Map<String,Object> output1 = new Map<String,Object>();
                    Map<String,Object> options1 = new Map<String,Object>();
                    inputs1.put('CampaignMemberId',cm.Id);
                    inputs1.put('LeadId',l.Id);
                    inputs1.put('AccountId','');
                    inputs1.put('OpportunityId','');
                    inputs1.put('ConvertedLeadStatus','Pending');

                    Metlife_LeadManagement.ConvertLead(inputs1,output1,options1);

                    System.debug('########### ConvertedResult : ' + output1);
                    System.debug('########### ConvertedAccountResult : ' + output1.get('AccountId') );
                    System.debug('########### ConvertedOpportunityResult : ' + output1.get('Opportu nityId') );

                }
			}when 'CampaignMemberAsAccountWithOpp','CampaignMemberAsAccountWithoutOpp'{
				Account a = new Account();
                a.FirstName = D2CFirstName;
                a.LastName = D2CLastName;
                a.PersonBirthdate = D2CBirthDate;
                a.RecordTypeId = AccountRecordTypeId;

                insert a;

                Contact c = [SELECT id, accountId FROM Contact WHERE accountId = :a.Id LIMIT 1 ];
                System.debug('########### CreatedAccount : ' + a.Name + ' ' + a.Id );

                CampaignMember cm = new CampaignMember ();
                cm.ContactId = c.Id;
                cm.CampaignId = CampaignId;
                Insert cm;

                CampaignMember cm2 = [SELECT id, Lead_number__c FROM CampaignMember WHERE Id = :cm.Id LIMIT 1 ];
                System.debug('########### CreatedCampaignMember : ' + cm2.Id + ' ' + cm2.Lead_number__c );
                output.put('Lead_number__c', cm2.Lead_number__c);

                if (TestUseCase == 'CampaignMemberAsAccountWithOpp'){
                    Opportunity o = new Opportunity();
                    o.AccountId = a.Id;
                    o.CampaignId = CampaignId;
                    o.recordTypeId = opportunityRecordTypeId;
                    o.Name = 'OPP ' + cm2.Lead_number__c;
                    o.StageName = 'Qualification';
                    o.CloseDate = Date.today();

                    insert o;
                    System.debug('########### CreatedOpportunity : ' + o.Name + ' ' + o.Id );

                }
            }
            when else{
				DateTime dt = datetime.now();
                String nowStr = String.valueOf(dt.getTime());
                String leadPO = 'TT' + nowStr.left(10);
                output.put('Lead_number__c', leadPO);
                System.debug('########### GeneatedLeadNumber : ' + leadPO );

			}
        }
        return output;
    }
}