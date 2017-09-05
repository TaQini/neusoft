/*
  trigger after a certain number of data elements are read
*/

long sum = 0;           // used to find sum in a cycle
long max = 0;           // used to find max data in a cycle
long min = 3000;        // used to find min data in a cycle

void serialEvent(Serial port)
{ 
   String inData = new String(port.readBytesUntil('\n')); // read data from port
   inData = trim(inData);                                 // cut off white space (carriage return)
   
   // When cycle doesn't end
   if(ms < 500)
   {
     data[second][ms++] = int(inData);                    // transform inData from string to int
     sum += data[second][ms-1];                           // add every element
     
     if(data[second][ms-1] > max)
     {
       max = data[second][ms-1];                          // update max value
     }
     if(data[second][ms-1] < min)
     {
       min = data[second][ms-1];                          // update min value
     }
   }
   // Cycle end, begin to handle data
   else
   {
     dataHandler.solve(second);                           // use fft to handle data
     
     int cnt = 0;                                         // use to count specfic data in a cycle
     double avg = (double)sum / 500.0;                    // use to find average data in a cycle
     double D = 0;                                        // usd to find variance
     
     for(int i = 0; i < 500; i++)
     {
       if((double)data[second][i] < avg + 25.0 && (double)data[second][i] > avg - 25.0) // data fits in (avg-25, avg+25)
       {
         cnt++;
       }
     }
     for(int i = 0; i < 500; i++)
     {
       D += ((double)data[second][i]-avg) * ((double)data[second][i]-avg);              // calculate variance
     }
     cut = 100;
     // if more than 420 data is in a small interval, illegal
     // if the max minus the min is bigger than 600, illegal
     // if variance is smaller than 600000, illegal
     if(cnt > 420 || (max - min) > 600 || D < 570000)
     {
       BPM = 0;
       IBI = 0;
       cut = 0;
       for(int i = 0; i < 500; i++)
       {
         data[second][i] = 510;          // set data to default value
       }
       port.write(0);                    // write data to STM32F103CB, no beat
     }
     
     
     if(cnt > 420){cut+=1;}
     if((max - min) > 600){cut+=2;}
     if(D < 570000){cut+=4;}
     
     
     // Initialize valuable
     // Initialize begin
     ms = 0;
     second = (second + 1) % 20;
     data[second][ms++] = int(inData);
     sum = data[second][ms-1];
     max = data[second][ms-1];
     min = data[second][ms-1];
     // Initialize end
   }
   
   if(second == 1) waveBegin = true;                       // 1s after, 500 datas collected
   
   if(waveBegin)                                           // begin to draw wave form
   {
     dataHandler.handleData(data[(second-1+20)%20][ms-1]); // handle data set collected last second
     Sensor = data[(second-1+20)%20][ms-1];                // set Sensor
   }
   
   if(dataHandler.QS == 1) {                  // find a valuable pulse
   
     BPM = dataHandler.BPM;                   // set BPM
     beat = true;                             // set beat flag to advance heart rate graph
     heart = 20;                              // begin heart image 'swell' timer
     
     IBI = dataHandler.IBI;                   // convert the string to usable int
     
     port.write((char)IBI / 4);               // send IBI data to STM32F103CB
     
     dataHandler.QS = 0;                      // set Quantified Self flag false 
   }
}