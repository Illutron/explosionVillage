/*****************************************************************************
    TODO
    - fire sequence
    
    - lav signal ud til jonas og sonny
    
    - sleep mode
    - lystofr�reffekt
    - eeproom: times hits, energylevel
    
    - lav energi niveau over tid i stedet
    - define energylevelAcc as energy level plus

*****************************************************************************/


//*****************************************************************************
//    MAKROS
//*****************************************************************************


#define SET(x,y) (x |=(1<<y))                   //-Bit set/clear macros
#define CLR(x,y) (x &= (~(1<<y)))               // |
#define CHK(x,y) (x & (1<<y))                   // |
#define TOG(x,y) (x^=(1<<y))                    //-+


//*****************************************************************************
//    DEFINES
//*****************************************************************************

// dmx
#define T_BIT 8        
#define DmxOut 6
#define numDmx 16
#define numBoxesWithSound 3
#define numBoxesWithOutSound 8
#define energyChannel 11



// gas kanon
#define relay 24

#define tentFire 28
// Lystofr�r
#define data 25
#define clock 26
#define latch 27
#define numLights 4

// io
#define diode1 35
#define diode2 36
#define diode3 37
#define btn1 29
#define btn2 4
#define btn3 5


// sound in
#define numChannels 3


// other
#define DEBUG 1
#define maxVal 100.0
#define energyLevelGran 0.05 //20min =0.016 // 0.05 = 6.6min  0.01 = 33min 0.03 = 11min 0.02 = 16min // std 0.03
#define channelStart 2


// timers
#define timerEnergy 0
#define timerFire 1
#define timerBlink 2

//*****************************************************************************
//    VARIABLES
//*****************************************************************************

// Mappings

boolean switchlights = false;
  byte boxToDmx[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,22,23};
  

// Dmx
 int Dmx[numDmx];
 byte currentDmx =0;
 
 

// MIDI
 
 int midiInPos =0;
 int midiData[4];
 int notetest = 0;
 
// SYSTEM ENERGY
  float energyLevel =0;
  float energyLevelAcc = 0;
  int beatBox[numChannels];
  //byte lights[] ={99,4(1),9(2),5(3),99,99,11(6),1(7),10(8),99,99,6(11),7(12),8(13),99,2(15),99}; //placeringp�t�rn[datapos]
  byte lights[] ={0,0,0,0,0,0,0,0,0,0,3,4,2,1,0,0};
  // hvis 
// BEATS 14,13,11,12
  
  int channelVolume[numChannels];
  int channelGoingUp[numChannels];
  
  int currentChannel =0;
  
// Fire sequence

  boolean fireOn = false;


//*****************************************************************************
//    SETUP
//*****************************************************************************


void setup() {

 pinMode(DmxOut, OUTPUT);
 pinMode(relay, OUTPUT);
 pinMode(data, OUTPUT);
 pinMode(clock, OUTPUT);
 pinMode(latch, OUTPUT);
 pinMode(tentFire,OUTPUT);
 pinMode(diode1, OUTPUT);
 pinMode(diode2, OUTPUT);
 pinMode(diode3, OUTPUT);
 pinMode(btn1, INPUT);
 pinMode(btn2, INPUT);
 pinMode(btn3, INPUT);
 digitalWrite(relay,LOW);
 
 Serial1.begin(31250);
 Serial.begin(9600);
 for(int i =0;i < currentChannel;i++)
 {
  beatBox[i] = random(numDmx-1);
 }

}


 
//*****************************************************************************
//    LOOP - THE ART
//*****************************************************************************
boolean diode1Blink = false;
boolean shootfire = true;
boolean btn1State = true;
void loop() {
  
  
   digitalWrite(diode2,shootfire);
   if(digitalRead(btn1) != btn1State && btn1State)
   {
    //  shootfire = !shootfire;
      doFireSequence(true);
     
   }
   btn1State =digitalRead(btn1);
   
  if(timer(500,timerBlink))
  {
     digitalWrite(diode1,diode1Blink);
     diode1Blink = !diode1Blink;
  }

 for(int i=0; i < 20;i++)
 {
   for(int i=0;i < 6;i++)
   {
  soundInHandler();
  

   }

   // Energy
   energyHandler();

   
   // Handle fadeout on dmx
   DmxFadeOut();
   DmxSend();
   doFireSequence(false);
    
 }
 
  setLights();
  //testLights();
  
}

//*****************************************************************************
//    Timer
//*****************************************************************************
long times[10];
long last_millis =0;

boolean timer(int time, byte num)
{
  timer( time, num, true);
}
boolean timer(int time, byte num, boolean reset)
{
  if (millis() < last_millis) 
  {
    for(int i=0;i< 10;i++)
    {
      times[i] = 0; 
    }
   
  }
  if (millis() > times[num] + time)
  {
    if(reset)
    times[num] = millis();
    return true; 
  }
  else
  {
    return false;
  }
}

void timerReset(byte num)
{
   times[num] = millis();
}


//*****************************************************************************
//      Energy
//*****************************************************************************


void energyHandler()
{
  
  Dmx[energyChannel] = 100;

  if(energyLevelAcc >= maxVal && !fireOn)
  {
    energyLevelAcc = 100;
    doFireSequence(true);
   }
   if (timer(200,timerEnergy))
   {
     if(energyLevel > 50) 
     {
        energyLevelAcc += energyLevelGran;
        energyLevelAcc = min(energyLevelAcc,maxVal); 
     }
     DP('E',(int)energyLevel, 'A', (int)energyLevelAcc);
     energyLevel = max(0,energyLevel-1);
     noteOut(0xB0, 19,100-energyLevel);
    //xxx noteOut(0xB0, 20,energyLevelAcc);
      
   } 
  
}
//*****************************************************************************
//      Fire
//*****************************************************************************

void doFireSequence(boolean start)
{  
   if (shootfire)
   {
   if(start)
     {
       digitalWrite(relay,HIGH);
       digitalWrite(tentFire,HIGH);
       noteOut(0x91,10, 126); 
       fireOn = true;
       timerReset(timerFire);
       if(DEBUG)
        {
        Serial.println("Fire on");
        }
     }
   if(fireOn)
   {
    Dmx[(int)random(numDmx-1)] =(int) random(100);
    energyLevelAcc =(int)random(100);
  
   if(timer(20000,timerFire))// xx bug!!!
   {
      digitalWrite(relay,LOW);
      digitalWrite(tentFire,LOW);
      fireOn = false;
       energyLevelAcc =0;
    
      if(DEBUG)
      {
        Serial.println("Fire off");
      }
   }
    
   }
   }
   
}

void startFireSequence()
{
  
}



//*****************************************************************************
//      Sound in
//*****************************************************************************
int tmpcounter = 0;
void soundInHandler()
{
 
 int volume  =  (analogRead(currentChannel)- 412);
// DP('S', volume, currentChannel);

 
 boolean tmpUp = volume > channelVolume[currentChannel];

  
 if (!tmpUp && channelGoingUp[currentChannel] && channelVolume[currentChannel] > 15) // beat detected
 {
    switchlights = !switchlights;
    //DP('B',(currentChannel+1));
    // send dmx
    if(!fireOn)
    {
   // noteOut(0x92, 40 + currentChannel, min(volume,127)); 
    }
   // tempxxxx
  
  
    
    // raise energy
    energyLevel += 7;
  
    energyLevel = min(energyLevel, maxVal);
   
    
    // set dmx
    Dmx[boxToDmx[currentChannel]] = maxVal;
    
    if(((int)random(5))==1)
    {
    // make dmx effect on the rest of the boxes
    
    Dmx[boxToDmx[beatBox[currentChannel]+ numBoxesWithSound]] = maxVal;
    beatBox[currentChannel]++;
    if (beatBox[currentChannel]>= numBoxesWithOutSound)
    {
       beatBox[currentChannel] = 0; 
    }
    }
  
    
 }
 

 channelGoingUp[currentChannel] = tmpUp;
 channelVolume[currentChannel] = volume;
 
 currentChannel++;
 currentChannel = currentChannel % numChannels;
}






//*****************************************************************************
//     MIDI
//*****************************************************************************


void noteOut(char cmd, char data1, char data2) {
 Serial1.print(cmd, BYTE);
 Serial1.print(data1, BYTE);
 Serial1.print(data2, BYTE);
}

void noteIn()
{
 /// MIDI IN
 while (Serial1.available()>0)
 {
    int value = Serial1.read();

     if (value < 0)
      {
        midiInPos = 0;
        midiData[0] = 0;
        midiData[1] = 0;
        midiData[2] = 0;

      }
    else
      {
        midiInPos++;
        if (midiInPos > 2)
        {
           midiInPos =1;
        }
      }

      midiData[midiInPos] = value;

     
  }

 
  
  if (midiInPos == 2)
    {
     
      //Serial.println( midiData[1]);
     
    } 
}

//*****************************************************************************
//      Lystofr�r
//*****************************************************************************

int currentlight =0;

void testLights()
{
  if(digitalRead(btn1) != btn1State && btn1State)
   {
     currentlight ++;
     currentlight = currentlight % 5;
      DP('l',currentlight);
     
   }
   btn1State =digitalRead(btn1);
   digitalWrite(latch,HIGH);
    delayMicroseconds(1);
   
  for(int b = 5; b >=0; b >b--)
   {
     if(b==3)
       digitalWrite(data,currentlight > 0);
      else if(b==2)
       digitalWrite(data,currentlight > 1);
      else if(b==0)
       digitalWrite(data,currentlight > 2);
      else if(b==1)
       digitalWrite(data, currentlight > 3);
      else
      digitalWrite(data,false);
     
     //digitalWrite(data,switchlights);
     delayMicroseconds(1);
     digitalWrite(clock, HIGH);
     delayMicroseconds(1);
     digitalWrite(clock, LOW);
      delayMicroseconds(1);
     
   }
   digitalWrite(latch,LOW);
   delayMicroseconds(1);
   digitalWrite(latch,HIGH);
    delayMicroseconds(1);
}

void setLights()
{
   digitalWrite(latch,HIGH);
    delayMicroseconds(1);
    currentlight = round((float)(numLights+1) * energyLevelAcc/maxVal);
    //DP('l',currentlight);
  for(int b = 5; b >= 0; b--)
   {
        if(b==3)
       digitalWrite(data,currentlight > 0);
      else if(b==2)
       digitalWrite(data,currentlight > 1);
      else if(b==0)
       digitalWrite(data,currentlight > 2);
      else if(b==1)
       digitalWrite(data, currentlight > 3);
      else
      digitalWrite(data,false);
  
     delayMicroseconds(1);
     digitalWrite(clock, HIGH);
     delayMicroseconds(1);
     digitalWrite(clock, LOW);
      delayMicroseconds(1);
     
   }
   digitalWrite(latch,LOW);
   delayMicroseconds(1);
   digitalWrite(latch,HIGH);
    delayMicroseconds(1);
}


//*****************************************************************************
//      Send Dmx
//*****************************************************************************

void DmxFadeOut()
{
  // Dmx[currentDmx] = Dmx[currentDmx] * 0.95;
  if(currentDmx >= numChannels)
  {
     Dmx[currentDmx] = max(Dmx[currentDmx]-4,0);
  }
  else
  {
   Dmx[currentDmx] = max(Dmx[currentDmx]-10,0); 
  }

  
}

unsigned int heartBeatPos;

int DmxSend()
{
   if (currentDmx ==0)
   {
     digitalWrite(DmxOut, LOW);
     delayMicroseconds(100);
     digitalWrite(DmxOut, HIGH);
     delayMicroseconds(10);
     sends(0);
   }
   
  int valueDmx;
   heartBeatPos = heartBeatPos +2;
  heartBeatPos = heartBeatPos % 47000;
  if (currentDmx >= numBoxesWithSound)
  {
   float heartBeat = (sin(((float)heartBeatPos)/1000 + PI/2*currentDmx)+1)*7+36;
   
    valueDmx = 2.55*50.0*(sin((PI* ((Dmx[currentDmx])/2+heartBeat))/100.0 - PI/2.0)+1.0);
  }
  else
  {
     
   valueDmx = 2.55*50.0*(sin((PI* ((Dmx[currentDmx])))/100.0 - PI/2.0)+1.0);
  }

   sends((int)valueDmx);
  // DP('D', valueDmx, currentDmx == 4);
  
   

   currentDmx++;
   currentDmx = currentDmx % numDmx;
  
}

int sends(char s)
{
 cli();
       unsigned int t;
       unsigned char bit;
       CLR(PORTD,DmxOut);

       for(t=0;t<T_BIT;t++)
               asm("NOP");
       for(bit=0;bit<8;bit++)
       {
               if(s&0x01)
                       SET(PORTD,DmxOut);

               else
                       CLR(PORTD,DmxOut);

               s=s>>1;

          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");asm("NOP");asm("NOP");asm("NOP");asm("NOP");
          asm("NOP");
       }
       SET(PORTD,DmxOut);

       for(t=0;t<T_BIT;t++)
               asm("NOP");
       for(t=0;t<T_BIT;t++)
               asm("NOP");
sei();
       return 0;

}

void DP(char t, int v, boolean printit)
{
  if (printit)
    DP(t,v);
}

void DP(char t, int v)
{
  if (DEBUG)
  {
    Serial.print(t);
    Serial.println(v);
  }
}

void DP(char t, int v, char t2, int v2)
{
  if (DEBUG)
  {
    Serial.print(t);
    Serial.print(v);
    Serial.print(' ');
    Serial.print(t2);
    Serial.println(v2);
  }
}
