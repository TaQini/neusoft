/*
    THIS DATA HANDLER IS TO HANDLE RAW DATA FORM SENSOR
*/

import java.lang.Math;

public class DataHandler
{
  //  VARIABLES
  int BPM;                          // used to hold the pulse rate
  int Signal;                       // holds the incoming raw data
  int IBI;                          // holds the time between beats, must be seeded! 
  char Pulse;                       // true when pulse wave is high, false when it's low
  char QS;                          // becomes true when Arduoino finds a beat.
  int[] rate;                       // array to hold last ten IBI values
  long sampleCounter;               // used to determine pulse timing
  long lastBeatTime;                // used to find IBI
  int P;                            // used to find peak in pulse wave, seeded
  int T;                            // used to find trough in pulse wave, seeded
  int thresh;                       // used to find instant moment of heart beat, seeded
  int amp;                          // used to hold amplitude of pulse waveform, seeded
  long runningTotal;                // used to keep a running total of the last 10 IBI values
  char firstBeat;                   // used to seed rate array so we startup with reasonable BPM
  char secondBeat;                  // used to seed rate array so we startup with reasonable BPM
  
  // used for fast fourier transform function
  Complex[] tem;
  double Hmin;
  double Hmax;
  
  // Initilize DataHandler
  DataHandler()
  {
    rate = new int[10];
    tem = new Complex[1024];
    IBI = 600;
    Pulse = 0; 
    QS = 0;
    sampleCounter = 0;
    lastBeatTime = 0;
    P = 512;
    T = 512;
    thresh = 512;
    amp = 100;
    runningTotal = 0;
    firstBeat = 1;
    secondBeat = 0;
  }
  
  // Generate BMP and IBI value
  void handleData(int sensorData)
  {
    int i = 0;                                     // Index value for loop
    long Num = 0;                                  // monitor the time since the last beat to avoid noise
    Signal = sensorData;                           // read the Pulse Sensor
    sampleCounter += 2;                            // keep track of the time in mS with this variable
    Num = sampleCounter - lastBeatTime;            // monitor the time since the last beat to avoid noise  

    //  find the peak and trough of the pulse wave
    if (Signal < thresh && Num >(IBI / 5) * 3) {   // avoid dichrotic noise by waiting 3/5 of last IBI
      if (Signal < T) {                            // T is the trough
        T = Signal;                                // keep track of lowest point in pulse wave 
      }
    }

    if (Signal > thresh && Signal > P) {           // thresh condition helps avoid noise
      P = Signal;                                  // P is the peak
    }                                              // keep track of highest point in pulse wave

    //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
    // signal surges up in value every time there is a pulse
    if (Num > 250) {                               // avoid high frequency noise

      if ((Signal > thresh) && (Pulse == 0) && (Num > (IBI / 5) * 3)) {
        Pulse = 1;                                 // set the Pulse flag when we think there is a pulse 
        IBI = (int)(sampleCounter - lastBeatTime); // measure time between beats in mS
        lastBeatTime = sampleCounter;              // keep track of time for next pulse

        if (secondBeat!=0) {                       // if this is the second beat, if secondBeat == TRUE
          secondBeat = 0;                          // clear secondBeat flag
          for (i = 0; i <= 9; i++) {               // seed the running total to get a realisitic BPM at startup
            rate[i] = (int) IBI;
          }
        }

        if (firstBeat!=0) {                        // if it's the first time we found a beat, if firstBeat == TRUE
          firstBeat = 0;                           // clear firstBeat flag
          secondBeat = 1;                          // set the second beat flag
          return;                                  // IBI value is unreliable so discard it
        }

        // keep a running total of the last 10 IBI values
        runningTotal = 0;                          // clear the runningTotal variable    

        for (i = 0; i <= 8; i++) {                 // shift data in the rate array
          rate[i] = rate[i + 1];                   // and drop the oldest IBI value 
          runningTotal += rate[i];                 // add up the 9 oldest IBI values
        }

        rate[9] = (int) IBI;                       // add the latest IBI to the rate array
        runningTotal += rate[9];                   // add the latest IBI to runningTotal
        runningTotal /= 10;                        // average the last 10 IBI values 
        BPM = (int) (45029 / runningTotal);        // how many beats can fit into a minute? that's BPM!
        QS = 1;                                    // set Quantified Self flag 
                                                   // QS FLAG IS NOT CLEARED INSIDE THIS SECTION
      }
    }

    if (Signal < thresh && Pulse == 1) {           // when the values are going down, the beat is over
      Pulse = 0;                                   // reset the Pulse flag so we can do it again
      amp = P - T;                                 // get amplitude of the pulse wave
      thresh = amp / 2 + T;                        // set thresh at 50% of the amplitude
      P = thresh;                                  // reset these for next time
      T = thresh;
    }

    if (Num > 2500) {                              // if 2.5 seconds go by without a beat
      thresh = 512;                                // set thresh default
      P = 512;                                     // set P default
      T = 512;                                     // set T default
      lastBeatTime = sampleCounter;                // bring the lastBeatTime up to date        
      firstBeat = 1;                               // set these to avoid noise
      secondBeat = 0;                              // when we get the heartbeat back
    }
  }
  
  // For fft function
  void change(Complex y[], int len)
  {
    int i, j, k;
    for (i = 1, j = len / 2; i < len - 1; i++)
    {
      if (i < j) 
      {
          Complex newComplex = new Complex(0.0, 0.0);
          newComplex.x = y[i].x;
          newComplex.y = y[i].y;
          y[i].x = y[j].x;
          y[i].y = y[j].y;
          y[j].x = newComplex.x;
          y[j].y = newComplex.y;
      }
      k = len / 2;
      while (j >= k)
      {
        j -= k;
        k /= 2;
      }
      if (j < k) j += k;
    }
  }
  
  // fast fourier transform function
  void fft(Complex y[], int len, int on)
  {
    change(y, len); //<>//
    for (int h = 2; h <= len; h <<= 1)
    {
      Complex wn = new Complex(Math.cos(-on * 2.0 * Math.PI / h), Math.sin(-on * 2.0 * Math.PI / h));
      for (int j = 0; j < len; j += h)
      {
        Complex w = new Complex(1.0, 0.0);
        for (int k = j; k < j + h / 2; k++)
        {
          Complex u = y[k];
          Complex t = w.multi(y[k + h / 2]);
          y[k] = u.add(t);
          y[k + h / 2] = u.minus(t);
          w = w.multi(wn);
        }
      }
    }
    if (on == -1)
      for (int i = 0; i < len; i++)
        y[i].x /= len;
  }
  
  
  void solve(int m)
  {
    for (int i = 0; i < 1024; i++)
    {
      tem[i] = new Complex(0.0, 0.0);
    }
    
    for (int i = 0; i < 500; i++)
    { 
      tem[i].x = data[m][i];
    }
    
    fft(tem, 1024, 1); //<>//
    
    Hmin = 250;
    Hmax = 300;
    
    for(int i = (int)Hmin ; i < Hmax ; i++)
    {
      tem[i].x = 0.0;
      tem[i].y = 0.0;
    }
    for(int i = 512 ; i < 1024 ; i++)
    {
      tem[i].x = 0.0;
      tem[i].y = 0.0;
    }
     //<>//
    fft(tem, 1024, -1);

    for (int i = 0; i < 500; i++) 
    {
      data[m][i] = 100 + ((int) tem[i].x);
      //println(data[m][i]);
    }
    
  }
}