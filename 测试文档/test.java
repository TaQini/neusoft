// then limit and scale the BPM value
   BPM = min(BPM,135);    // limit the highest BPM value to 135

// change color of background by the level of BPM 
   int tmp = BPM*2-15;
   if (tmp < 0) tmp = 0;  // when BPM is too low, set bg to black 
   BG_CLR = tmp*1 + (tmp<<8)/2 + (tmp<<16)*0; // RGB
