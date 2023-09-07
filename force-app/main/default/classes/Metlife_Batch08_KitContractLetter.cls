global class Metlife_Batch08_KitContractLetter implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string query = 'Select Id from Task where Status = \'Not Started\' AND Type = \'Kit contract\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Task> scope){
        Map<String, object> ipInput = new Map<String, object>();
        Map<String, object> ipOutput = new Map<String, object>();
        Map<String, Id> input;
        List<Map<String,Id>> data = new List<Map<String,Id>>(); 
        for(Task t : scope){
            input = new Map<String, Id>();
            input.put('Id', t.Id);
            data.add(input);         
        }
        ipInput.put('data',data);
        ipInput.put('duplicata','Non');
        ipOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationService('metLife_kitContract', ipInput, null);
                        
    }
    
    global void finish(Database.BatchableContext BC){
        // nothing needed
    }

    global void execute(SchedulableContext ctx) {
        Metlife_Batch08_KitContractLetter scheduleObj = new Metlife_Batch08_KitContractLetter();
        database.executebatch(scheduleObj,10);
    }
}