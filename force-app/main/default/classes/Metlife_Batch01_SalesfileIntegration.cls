global class Metlife_Batch01_SalesfileIntegration implements Database.Batchable<sObject>, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string query = 'SELECT id,name, BTCHPO__c, BTCHPO_DATE__c, CPUBPO__c, DEFFPO_Date__c, LEADPO__c FROM SFI_SalesFlow_T11__c WHERE Status__c = \'Ready SFI\' AND UPSELL__c != \'Y\' AND NPOLPO__c = null '; 
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SFI_SalesFlow_T11__c> scope){
      
        Set<Id> t11Ids = new Set<Id>();
        for(SFI_SalesFlow_T11__c a : scope){
            t11Ids.add(a.Id);
        }

        List<SFI_CONCIL__c> concils = new List<SFI_CONCIL__c>([SELECT id, SalesFlow_T11__c, NumPolice__c FROM SFI_CONCIL__c WHERE SalesFlow_T11__c IN :t11Ids AND NumPolice__c != null ]);
        Map<Id, Boolean> hasConcils = new Map<Id, Boolean>();
        for (SFI_CONCIL__c c : concils){
            hasConcils.put(c.SalesFlow_T11__c, true);
        }

        for(SFI_SalesFlow_T11__c a : scope){
            Map<String, Object> ipInputSell = new Map<String, Object>();
            ipInputSell.put('contextId',  a.Id);
            Map<String, Object> ipOutSell = new Map<String, Object>();
            try{
                ipOutSell = createPolicyNewSaleIP(ipInputSell, ipOutSell, null);
                boolean success = false;
                if (ipOutSell.containsKey('PolicyId')){
                    String polId = (String) ipOutSell.get('PolicyId');
                    if (String.isNotBlank(polId)){
                        success = true;
                    }
                }
                if (!success){
                    if (!hasConcils.containsKey(a.Id)){
                        SFI_CONCIL__c concil = new SFI_CONCIL__c();
                        String s = JSON.serialize(ipOutSell);
                        Integer i = Math.min(224, s.length());
                        concil.LibRejet__c = 'Something went wrong : ' + s.substring(0, i);
                        concil.SalesFlow_T11__c = a.Id;
                        concil.CodeRejet__c = '9991';
                        concil.BTCHPO__c = a.BTCHPO__c;
                        concil.CodePub__c = a.CPUBPO__c;
                        concil.DateVente__c = a.BTCHPO_DATE__c;
                        concil.DateEffet__c = a.DEFFPO_Date__c;
                        concil.LeadNumber__c = a.LEADPO__c;
                        if (String.isNotBlank(a.BTCHPO__c) || a.BTCHPO__c.length() > 11){
                            concil.NumSequenceFichier__c = a.BTCHPO__c.substring(8,11);
                        }else{
                            concil.NumSequenceFichier__c = '999';
                        }    
                        concil.DateIntegration__c = Date.today();
                        concil.CodeSociete__c = '01';
                        concil.StatutVente__c = 'T2';
                        concil.ANP__c = 0;
                        insert concil;
                    }
                    SFI_SalesFlow_T11__c t11 = new SFI_SalesFlow_T11__c();
                    t11.Id = a.id;
                    t11.Status__c = 'Reject';
                    update t11;
                }
            }catch (Exception e){
                if (!hasConcils.containsKey(a.Id)){
                    SFI_CONCIL__c concil = new SFI_CONCIL__c( LibRejet__c = e.getMessage(), SalesFlow_T11__c = a.Id, CodeRejet__c = '999', BTCHPO__c = a.BTCHPO__c, CodePub__c = a.CPUBPO__c, DateVente__c = a.BTCHPO_DATE__c, DateEffet__c = a.DEFFPO_Date__c, LeadNumber__c = a.LEADPO__c, DateIntegration__c = Date.today(), CodeSociete__c = '01', StatutVente__c = 'T2', ANP__c = 0, NumSequenceFichier__c = '999' );
                    if (String.isNotBlank(a.BTCHPO__c) || a.BTCHPO__c.length() > 11){
                        concil.NumSequenceFichier__c = a.BTCHPO__c.substring(8,11);
                    }

                    /*
                    concil.LibRejet__c = e.getMessage();
                    concil.SalesFlow_T11__c = a.Id;
                    concil.CodeRejet__c = '999';
                    concil.BTCHPO__c = a.BTCHPO__c;
                    concil.CodePub__c = a.CPUBPO__c;
                    concil.DateVente__c = a.BTCHPO_DATE__c;
                    concil.DateEffet__c = a.DEFFPO_Date__c;
                    concil.LeadNumber__c = a.LEADPO__c;
                    if (String.isNotBlank(a.BTCHPO__c) || a.BTCHPO__c.length() > 11){
                        concil.NumSequenceFichier__c = a.BTCHPO__c.substring(8,11);
                    }else{
                        concil.NumSequenceFichier__c = '999';
                    } 
                    concil.DateIntegration__c = Date.today();
                    concil.CodeSociete__c = '01';
                    concil.StatutVente__c = 'T2';
                    concil.ANP__c = 0;
                    */
                    insert concil;
                }
                SFI_SalesFlow_T11__c t11 = new SFI_SalesFlow_T11__c(Id = a.id,Status__c = 'Reject');
                update t11;
            }
        }                
    }
    
    global void finish(Database.BatchableContext BC){
        // nothing needed
    }

    global void execute(SchedulableContext ctx) {
        Metlife_Batch01_SalesfileIntegration scheduleObj = new Metlife_Batch01_SalesfileIntegration();
        database.executebatch(scheduleObj,1);
    }

    public static Map<String,Object> createPolicyNewSaleIP(Map<String,Object> inputs, Map<String,Object> output, Map<String,Object> options){
        String t11_recordId = (String) inputs.get('contextId');
        inputs.put('contextId',t11_recordId) ;
        try{
            Map<String, Object> res = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationService('metLife_newSales', inputs, options);
            output.putAll(res);
        }catch(Exception e){
            output.clear();
            output.put('Error', 'a technical error occured in the integration of the IP please contact an admin ' + e.getMessage());
        }
        return output;
    }
}