# SSBSC Voice Communication in MATLAB

## Overview
This project implements a **Single Sideband Suppressed Carrier (SSBSC) modulation and demodulation system** for voice communication using MATLAB. It demonstrates real-time audio recording, SSBSC modulation via the Hilbert transform, transmission over both ideal and noisy channels, and performance analysis using multiple demodulation techniques.


## Features
- Real-time voice recording and playback  
- SSBSC modulation using the Hilbert transform (upper sideband)  
- Coherent, envelope, and square-law demodulation techniques  
- Simulation of transmission over **AWGN noisy channels**  
- Performance analysis through **SNR estimation** for each demodulator  
- Bit Error Rate (BER) simulation for BPSK over AWGN and comparison with theoretical BER  


## MATLAB Requirements
- MATLAB R2018b or later  
- Signal Processing Toolbox  


## Usage
1. Open `SSBSC_Project.m` in MATLAB.  
2. Configure parameters at the top of the script (sampling rate, carrier frequency, duration, SNR, etc.).  
3. Run the script:  
   - The program records your voice for the specified duration.  
   - Displays time-domain and frequency-domain plots for the original, modulated, and demodulated signals.  
   - Plays back both the original and demodulated audio.  
4. BER analysis and SNR comparison plots are automatically generated.  


## How It Works
1. **Recording:** Captures voice signals via MATLAB's `audiorecorder`.  
2. **Modulation:** Uses Hilbert transform to generate the analytic signal and performs SSBSC modulation.  
3. **Demodulation:** Supports:
   - Coherent detection  
   - Envelope detection  
   - Square-law detection  
4. **Noisy Channel Simulation:** Adds AWGN to test demodulator robustness.  
5. **Performance Analysis:** Computes SNR for each demodulator and BER for BPSK over AWGN.  


## Future Improvements
- Real-time GUI for easier input and parameter adjustment  
- Integration with actual hardware for voice transmission experiments  
- Extension to other modulation schemes (DSBSC, QAM) for comparison  
- Adaptive noise cancellation techniques for improved performance  

