
configuration KheperaBase {
}

implementation {
  
  components Main, HPLUARTC, KheperaBaseM, RadioCRCPacket as Comm, TimerC, LedsC;

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> KheperaBaseM;
  

  KheperaBaseM.HPLUART -> HPLUARTC;
  KheperaBaseM.Timer -> TimerC.Timer[unique("Timer")];
  KheperaBaseM.Leds -> LedsC;

  KheperaBaseM.RadioControl -> Comm;
  KheperaBaseM.RadioSend -> Comm;
  KheperaBaseM.RadioReceive -> Comm;
  
}

