clc; close all;
%Config
Fs      = 44100;      % Sampling rate (Hz)
dur_sec = 8;          % Recording duration (seconds)
fc      = 10000;      % Carrier frequency (Hz)
lpf_cut = 3500;       % Baseband LPF cutoff (Hz)
SNR_dB  = 10;         % AWGN SNR for noisy test (dB)

%Record voice
recObj = audiorecorder(Fs, 16, 1);  
disp('Get ready to speak...');
pause(1.0);
disp('Recording... Speak now');
recordblocking(recObj, dur_sec);
disp('Recording finished.');
message = getaudiodata(recObj);
message = message(:);
t = (0:length(message)-1)'/Fs;

% Normalize message for consistent levels
message = message / max(abs(message) + 1e-12);

% original
disp('Playing original message...');
sound(message, Fs);
pause(dur_sec + 1);

%Helper: Time + FFT plotting
function plot_time_freq(x, t, Fs, title_str)
    % Time-domain
    subplot(2,1,1);
    plot(t, x); grid on;
    xlabel('Time (s)'); ylabel('Amplitude');
    title([title_str ' (Time Domain)']);

    % Frequency-domain
    N = length(x);
    X = fftshift(fft(x .* hann(N)));   
    f = (-N/2:N/2-1)*(Fs/N);
    subplot(2,1,2);
    plot(f, abs(X)/max(abs(X)+eps), 'LineWidth', 1);
    grid on; xlabel('Frequency (Hz)'); ylabel('Normalized Magnitude');
    title([title_str ' (Frequency Domain)']);
end

% SSBSC modulation (upper sideband via Hilbert)
x_a = hilbert(message);                                % Analytic signal of baseband
ssb_complex = x_a .* exp(1j*2*pi*fc*t);                % Complex analytic SSB (upper sideband)
ssb_real    = real(ssb_complex);                       % Real-valued version for transmission

% Plot analytic SSB spectrum
figure;
plot_time_freq(hilbert(ssb_complex), t, Fs, 'SSBSC Signal (Time)');
N = length(ssb_complex);
X = fftshift(fft(ssb_complex .* hann(N)));
f = (-N/2:N/2-1)*(Fs/N);
figure;
plot(f, abs(X)/max(abs(X)+eps), 'LineWidth', 1);
grid on; xlabel('Frequency (Hz)'); ylabel('Normalized Magnitude');
title('SSBSC spectrum');

% Ideal channel (pass-through first) 
tx_signal = ssb_real;

% Coherent demodulation
rx_mix = tx_signal .* cos(2*pi*fc*t);                   % Multiply by local carrier
[blpf,alpf] = butter(6, lpf_cut/(Fs/2));                % Baseband LPF
rx_coherent = filter(blpf, alpf, rx_mix);
rx_coherent = rx_coherent / max(abs(rx_coherent)+1e-12);

figure;
plot_time_freq(hilbert(rx_coherent), t, Fs, 'Recovered Message (Coherent)');

disp('Playing coherent demodulated signal...');
sound(rx_coherent, Fs);
pause(dur_sec + 1);

% Envelope detector (for comparison; not ideal for SSBSC) 
env_out = abs(hilbert(tx_signal));                      
env_out = env_out / max(abs(env_out)+1e-12);

figure;
plot_time_freq(hilbert(env_out), t, Fs, 'Envelope Detector Output');

%Square-law detector 
sq = tx_signal.^2;                                      % Square-law
sq_bb = filter(blpf, alpf, sq);                         % Baseband LPF
sq_bb = sq_bb / max(abs(sq_bb)+1e-12);

figure;
plot_time_freq(hilbert(sq_bb), t, Fs, 'Square-Law Detector Output');

%Add AWGN and demodulate 
noisy_signal = awgn(tx_signal, SNR_dB, 'measured');     % AWGN at desired SNR
rx_noisy_mix = noisy_signal .* cos(2*pi*fc*t);
rx_noisy = filter(blpf, alpf, rx_noisy_mix);
rx_noisy = rx_noisy / max(abs(rx_noisy)+1e-12);

figure;
plot_time_freq(hilbert(noisy_signal), t, Fs, 'Noisy SSBSC Signal');

figure;
plot_time_freq(hilbert(rx_noisy), t, Fs, 'Noisy Recovered Message (Coherent)');

disp('Playing noisy coherent demodulated signal...');
sound(rx_noisy, Fs);

% --- SNR Estimation for all three demodulators ---
seg = round(linspace(round(0.1*length(message)), round(0.9*length(message)), 5));
winN = round(0.2*Fs);
idx = seg(3):min(seg(3)+winN-1, length(rx_noisy));

% Coherent
signal_power_c = mean(rx_noisy(idx).^2);
noise_est_c = rx_noisy - rx_coherent * (norm(rx_noisy(idx))/max(norm(rx_coherent(idx)),1e-12));
noise_power_c  = mean(noise_est_c(idx).^2);
SNR_coherent_dB = 10*log10(signal_power_c / max(noise_power_c,1e-12));

% Envelope
signal_power_e = mean(env_out(idx).^2);
noise_est_e = env_out - message * (norm(env_out(idx))/max(norm(message(idx)),1e-12));
noise_power_e  = mean(noise_est_e(idx).^2);
SNR_envelope_dB = 10*log10(signal_power_e / max(noise_power_e,1e-12));

% Square-law
signal_power_s = mean(sq_bb(idx).^2);
noise_est_s = sq_bb - message * (norm(sq_bb(idx))/max(norm(message(idx)),1e-12));
noise_power_s  = mean(noise_est_s(idx).^2);
SNR_squarelaw_dB = 10*log10(signal_power_s / max(noise_power_s,1e-12));

fprintf('Estimated baseband SNR (Coherent): %.2f dB\n', SNR_coherent_dB);
fprintf('Estimated baseband SNR (Envelope): %.2f dB\n', SNR_envelope_dB);
fprintf('Estimated baseband SNR (Square-law): %.2f dB\n', SNR_squarelaw_dB);

% --- BER Performance of BPSK over AWGN ---
N_bits = 1e6;                          % Number of bits
EbN0_dB = 0:2:20;                      % SNR range in dB
ber_sim = zeros(size(EbN0_dB));        % Simulated BER
ber_theory = zeros(size(EbN0_dB));     % Theoretical BER

% Generate random bits
bits = randi([0 1], N_bits, 1);
bpsk_symbols = 2*bits - 1;             

for i = 1:length(EbN0_dB)
    EbN0 = 10^(EbN0_dB(i)/10);
    noise_std = sqrt(1/(2*EbN0));      % AWGN noise std dev
    noise = noise_std * randn(N_bits,1);
    
    % Transmit over AWGN
    rx = bpsk_symbols + noise;
    
    % Decision and BER
    bits_rx = rx > 0;
    ber_sim(i) = mean(bits_rx ~= bits);
    
    % Theoretical BER
    ber_theory(i) = qfunc(sqrt(2*EbN0));
end

% Plot BER vs Eb/N0 + SNR curves of demodulators
figure;
semilogy(EbN0_dB, ber_theory, 'r--', 'LineWidth', 2); hold on;
semilogy(EbN0_dB, ber_sim, 'bo-', 'LineWidth', 2);

% Add SNR points for demodulators
plot(SNR_coherent_dB, 1e-2, 'ks', 'MarkerSize', 10, 'LineWidth', 2); % Coherent
plot(SNR_envelope_dB, 1e-2, 'gd', 'MarkerSize', 10, 'LineWidth', 2); % Envelope
plot(SNR_squarelaw_dB, 1e-2, 'm^', 'MarkerSize', 10, 'LineWidth', 2); % Square-law

grid on;
xlabel('E_b/N_0 (dB) SNR');
ylabel('Bit Error Rate (BER)');
title('BER Performance of BPSK over AWGN + SNR Comparison');
legend('Theoretical BER', 'Simulated BER', ...
       'Coherent Demod SNR', 'Envelope Demod SNR', 'Square-law Demod SNR');