public class CollectionBatchStartContoller {
	
	public CollectionBatchStartContoller(){
		
	}
	
	public void startJob(){
		Database.executeBatch( new PaymentAllocationBatch() );
	}

}