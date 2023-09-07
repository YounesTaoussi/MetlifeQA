global class Metlife_TestingToolInvokeClass implements vlocity_ins.VlocityOpenInterface2, Callable{

    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }
    
    global Object invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options){
        Type batchableType = Type.forName('Database.Batchable');
        if(methodName == 'ExecuteBatch'){
            String BatchClassName = (String) input.get('BatchClassName');
            Integer Scope;
            if(input.get('Scope') instanceOf Integer ){
                Scope = (Integer) input.get('Scope');
            }else if(input.get('Scope') instanceOf Integer ){
                String s = (String) input.get('Scope');
                Scope = Integer.valueOf(s);
            }else{
                Scope = 1;
            }
            

            Type classType = Type.forName(BatchClassName);
            if (batchableType.isAssignableFrom( classType )){
                ID batchprocessid = Database.executeBatch((Database.Batchable<sObject>) classType.newInstance(), Scope);
                output.put('result', 'The batch is running');
                output.put('batchprocessid', batchprocessid);
            }else{
                output.put('result', 'The class is not batchable');
            }
        }else{
            output.put('result', 'The methof name is not supported');
        }
        return output;
    }
}