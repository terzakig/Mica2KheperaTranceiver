
// Khepera.h

// synchronizing timer interval
  enum {
    TIMER_INTERVAL = 100
  };
  
  // maximum number of messages in queue
  enum {
    MAX_QUEUE = 7
  };

  // message terminator
  enum {
   MESSAGE_END = '\n'
  };

  // UART identifier as a message destination (could also be the air)
  enum {
   THE_UART = 255
  };

  // the message structure 
  struct KnetMsg {
   
	  uint8_t destination; 
   
	  uint8_t plen;
   
	  uint8_t payload[21];    
  
  }mqueue[MAX_QUEUE], pmsg;
