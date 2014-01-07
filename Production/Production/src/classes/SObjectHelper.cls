/**
 *	A helper class for SObject functionalities.
 */
public with sharing class SObjectHelper {
	
	/**
	 *	A cache for fields of objects.
	 */
	static map<string, Schema.SObjectField[]> cachedObjectsFields =  new map<string, Schema.SObjectField[]>();
	
	
	/**
 	 *	Returns a comma separated list of fields of the SObject with the given name, which can be used
 	 *	in SOQL queries.
 	 */ 
    public static String getFieldListForSOQL(string objectName) {
    	return getFieldListForSOQL(objectName, null, null);
    }
    
    /**
 	 *	Returns a comma separated list of fields of the SObject with the given name, which can be used
 	 *	in SOQL queries. The given prefix is added to all fields.
 	 */ 
    public static String getFieldListForSOQL(string objectName, string prefix) {
    	return getFieldListForSOQL(objectName, prefix, null);
    }
    
     /**
 	 *	Returns a comma separated list of fields of the SObject with the given name, which can be used
 	 *	in SOQL queries. Fields defined in ignoreFields will be ignored.
 	 */ 
    public static String getFieldListForSOQL(string objectName, set<string> ignoreFields) {
    	return getFieldListForSOQL(objectName, null, ignoreFields);
    }
 	/**
 	 *	Returns a comma separated list of fields of the SObject with the given name, which can be used
 	 *	in SOQL queries. Fields defined in ignoreFields will be ignored. The given prefix is added to all fields.
 	 */ 
    public static String getFieldListForSOQL(string objectName, string prefix, set<string> ignoreFields) {
    	
    	Schema.SObjectField[] objFields = getObjectFields(objectName);
    	
        String result = '';
        for (Schema.SObjectField f : objFields) {
    		string fName = f.getDescribe().Name;
    		if (ignoreFields == null || !ignoreFields.contains(fName)) {
            	result += (prefix != null ? prefix : '') + fName + ',';
    		}
        }
        
        // Remove last comma
        if (result.length() > 0) {
        	result = result.substring(0, result.length() - 1);
        }
        
        return result;
    }
    
     /**
     *	Returns list of fields of the object with the given name.
     */
    public static Schema.SObjectField[] getObjectFields(string objectName) {
   		if (cachedObjectsFields.containsKey(objectName)) {
    		return cachedObjectsFields.get(objectName);
    	} else {
    		SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        	if (objType == null) {
        		return null;
        	}
        	
        	Schema.SObjectField[] objFields = objType.getDescribe().fields.getMap().values();
        	cachedObjectsFields.put(objectName, objFields);
        	return objFields;
    	}
    }
    
      /**
     *  Converts a list of ids to a string containing a quoted comma separated list wrapped in parentheses 
     *  for use with the IN-clause in dynamic SOQL.
     */
     /* Commented out as not used at the moment
    public static string convertIdListToSoqlInListString(Id[] ids) {
    	if (ids != null && ids.size() > 0) {
            String listString = '(\'\')';
            if (ids.size() > 0) {
                listString = '(\''+ids[0]+'\'';
                for (Integer i = 1; i < ids.size(); i++) {
                    listString += ',\'' + ids[i]+'\'';
                }
                listString += ')';
            }
            return listString ;
        } else {
            return '(null)';
        }
    }
    */
    

}