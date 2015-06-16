
includes Khepera;

module KheperaBaseM {

 provides interface StdControl;
 
 uses {
      
	  interface StdControl as RadioControl;
      interface BareSendMsg as RadioSend;
      interface ReceiveMsg as RadioReceive;
      
      interface Timer;
      interface Leds;
      
      interface HPLUART;
      
      // add here interface ADC (for sensor poling)
      }
}

implementation {
  
  
  
  uint8_t inuartstr[40];
  uint8_t iuslen;
  uint8_t uartreceiving;
  uint8_t uartsending;
  uint8_t usindex;
  uint8_t uartoutstr[40];

 
  uint8_t mqlen;
  
 

  TOS_MsgPtr inr;

  // handle a string from the UART (Khepera)
  task void handleinUartstr() {
   
	  // KnetMsg pmsg;
    
	  uint8_t i;
    
      pmsg.destination = inuartstr[0];
      pmsg.plen = iuslen;

      for (i=0; i <= iuslen-1; i++) 
			pmsg.payload[i] = inuartstr[i];

//    call do_message();
      
	  atomic {
        
		  iuslen = 0; 
	  }
      
	  atomic {
       
		  uartreceiving = 0; 
	  }
      
	  atomic {
       
		  mqlen = mqlen+1;
	  }
      
	  mqueue[mqlen-1].destination = pmsg.destination;
      mqueue[mqlen-1].plen = pmsg.plen;
      
	  for (i=0; i<=pmsg.plen-1; i++) 
			mqueue[mqlen-1].payload[i] = pmsg.payload[i];
       
  }

  // handle an incoming message from the radio
  task void handleinRadio() {
   
	  // KnetMsg pmsg;
   
	  uint8_t i;
   
	  pmsg.destination = THE_UART;
   
	  pmsg.plen = inr->length;
   
   
	  for (i=0; i <= inr->length-1; i++) 
		  pmsg.payload[i] = inr->data[i];

//    call do_message();
   
   
	  mqlen = mqlen+1; // something about the ++ operator...
   
	  mqueue[mqlen-1].destination = pmsg.destination;
   
	  mqueue[mqlen-1].plen = pmsg.plen;
   
   
	  for (i=0;i<=pmsg.plen-1;i++) 
		  mqueue[mqlen-1].payload[i] = pmsg.payload[i];

  }

  
   
      
   task void handle_messages() {
    
	   TOS_Msg tmsg;
		uint8_t i;
    
		if (mqlen>0 && !uartreceiving) {
		
			if (mqueue[mqlen-1].destination == THE_UART) {
			 
				if (!uartsending) {
				
					uartsending=1;
				
					usindex=0;
             
				
					for (i=0;i<=mqueue[mqlen-1].plen-1;i++) 
						uartoutstr[i]=mqueue[mqlen-1].payload[i];
				
					call HPLUART.put(uartoutstr[usindex]);

				} else {
					
					if (usindex<=mqueue[mqlen-1].plen-1) 
                           call HPLUART.put(uartoutstr[usindex]);
					else {
						
						call HPLUART.put(MESSAGE_END);
						uartsending=0;
						mqlen=mqlen-1;
						
					}	
				}
			}
	
		} else {
              
			tmsg.addr=(uint16_t)(mqueue[mqlen-1].destination);
            tmsg.length=mqueue[mqlen-1].plen;
              
			for (i = 0; i<=mqueue[mqlen-1].plen-1; i++) 
				tmsg.data[i]=mqueue[mqlen-1].payload[i];
              
			tmsg.type=0x0A;
			tmsg.group=0x7d;

            call RadioSend.send(&tmsg);  
		} 
  
   }

   command result_t StdControl.init() {
    
   uartreceiving = 0;
   uartsending = 0;
   
    iuslen = 0;
    mqlen = 0;
  
    return rcombine3(call RadioControl.init(), call Leds.init(), call HPLUART.init());
  }

  command result_t StdControl.start() {

	return rcombine(call RadioControl.start(), call Timer.start(TIMER_REPEAT, TIMER_INTERVAL));
  
  }
  

  // Implementing UART Communications events

  async event result_t HPLUART.get(uint8_t data) {

	  
	  if (!uartsending) {
    
		uartreceiving=1;
	
		if (data == MESSAGE_END) {
      
			uartreceiving=0;

			post handleinUartstr();
     
		} else {
        
			iuslen = iuslen+1; // something about the ++ operator...
        
			inuartstr[iuslen-1] = data;
       	 
		}
	  
	  }

 
	  return SUCCESS;
  }

  async event result_t HPLUART.putDone() {
  
	usindex=usindex+1;
	
	call Leds.yellowToggle();

	return SUCCESS;
  }

  // UART events done...

  // Implementing Radio Communications events

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
  
	inr = Msg; // incoming message
	
	post handleinRadio(); // 

  return NULL;
  }

  event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {
  
	  mqlen=mqlen-1;
  
	  call Leds.greenToggle();
  
	  return SUCCESS;
  }

  // Radio Communication events done

  
  // The Timer event ...

  event result_t Timer.fired() {
    
	  // post handle_messages();
	  return SUCCESS;
  }

  
  command result_t StdControl.stop() {

   return (call Timer.stop(), call RadioControl.stop());
  
  }

} // end module

