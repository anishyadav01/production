public class Common {
	
	/**
	 *  Returns a unique key (external ID).
	 */
	 
	 static integer keyCounter = 0;
     
     public static string getUniqueKey(string name) {
        keyCounter++;
        string key = 'key__' + datetime.now().format('yyyMMdd_HHmmss') + '__' + keyCounter + '__' + string.valueof(Math.random()) +  '__' + name;
        if (key.length() > 255) {
            key = key.substring(0, 255);
        }
        return key;
    }
    
    /**
		Returns the next working day for the passed in date
		will consider weekends and public holidays
	*/
    public static date getNextWorkingDay ( date passedInDate ) {
		return getWorkingDay ( passedInDate, true);    	
    }

    /**
		Returns the previous working day for the passed in date
		will consider weekends and public holidays
	*/
    public static date getPreviousWorkingDay ( date passedInDate ) {
    	return getWorkingDay ( passedInDate, false);   
    }


    /**
		Returns the working day for the passed in date
		will consider weekends and public holidays
		if nextDay is true it gets the next working day else the previous
	*/
    public static date getWorkingDay ( date passedInDate, boolean nextDay ) {
    	integer dayToAdd = 1;
    	if ( !nextDay ) dayToAdd = -1;
    	
    	DateTime dt = datetime.newInstance(passedInDate.year(), passedInDate.month(), passedInDate.day());
    	system.debug('-------------dt.format(E)----' + dt.format('E'));
    	if ( isWeekDay ( dt.format('E') ) ){
    		// check if it falls on a holiday
            system.debug('------------ inside weekday if-------');
    		if ( isHoliday ( passedInDate ) ) {
    			return getWorkingDay ( passedInDate + dayToAdd, nextday);
    		}else {
            system.debug('------------ inside weekday if-------');

                return passedInDate;
    		}	
    	} else {
                        system.debug('------------ inside weekday else-------');

    		return getWorkingDay ( passedInDate + dayToAdd, nextday);
    	}
    }

    
    /**
		Returns true if the day passed in is weekend
	*/
    public static boolean isWeekDay ( String day ) {
    	//TODO code to get the next working day
    	if ( day != null && (day == 'Sat' || day == 'Sun') ){
    		return false;
    	} else {
    		return true;
    	}
    }
    
    /**
		Returns true if the day passed in is holiday
	*/    
    public static boolean isHoliday ( date passedInDate ) {
    	if ( getAllHolidays().contains(passedInDate) ){
    		return true;
    	} 
    	return false;
    }   
    
    public static Set<date> getAllHolidays () {
    	//TODO cache if possible...
    	Set<date> holidayList = new Set<date>(); 
    	List<Holiday> holidays = [Select h.Name, h.ActivityDate From Holiday h];
    	for (Holiday hday : holidays){
    		holidayList.add ( hDay.ActivityDate );
    	}
    	return holidayList;
    }

	public static string getBlankIfNull ( String strToCheck ){
		if( strToCheck == null ) {
			strToCheck = '';
		}
		return strToCheck;
	}

	static testMethod void validateDates() {
        Holiday justOne = new Holiday ( Name = 'Bank Holiday', ActivityDate = date.newinstance(2013, 9, 16) );
		insert justOne;        
        
		date weekDaysDateToPass = date.newinstance(2013, 9, 12); // Thursday
		// no change test
		date returnedDate = getNextWorkingDay( weekDaysDateToPass );
		system.assertEquals(weekDaysDateToPass, returnedDate);
		
		returnedDate = getPreviousWorkingDay( weekDaysDateToPass );
		system.assertEquals(weekDaysDateToPass, returnedDate);
		

        // weekend
		date weekendDaysDateToPass = date.newinstance(2013, 9, 14); // Saturday
		// no change test
		returnedDate = getNextWorkingDay( weekendDaysDateToPass );
		system.assertEquals(weekendDaysDateToPass + 2 + 1 , returnedDate); // +2 to take on monday ... +1 as monday is holiday
		
		returnedDate = getPreviousWorkingDay( weekendDaysDateToPass );
		system.assertEquals(weekendDaysDateToPass -1, returnedDate);
        
        system.assert(getUniqueKey('test') != null);
        system.assert(getUniqueKey('testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest') != null);
        system.assert(getBlankIfNull(null) != null);
    }
    
    
     
}