import Foundation
import Accelerate

struct HRVFrequencyMetrics {
    let lfPower: Double      // Low frequency (0.04-0.15 Hz)
    let hfPower: Double      // High frequency (0.15-0.4 Hz)
    let lfHfRatio: Double    // LF/HF ratio
    let totalPower: Double   // Total spectral power
    let vlfPower: Double     // Very low frequency (0.003-0.04 Hz)
    
    var interpretation: String {
        if lfHfRatio > 3.0 {
            return "Elevated sympathetic activity"
        } else if lfHfRatio < 0.5 {
            return "High parasympathetic dominance"
        } else if lfHfRatio > 2.0 {
            return "Mild sympathetic elevation"
        } else {
            return "Balanced autonomic state"
        }
    }
}

class HRVFrequencyAnalyzer {
    /// Perform frequency domain analysis on RR intervals
    /// Uses Welch's method for power spectral density estimation
    static func analyze(rrIntervals: [Double], samplingRate: Double = 4.0) -> HRVFrequencyMetrics? {
        guard rrIntervals.count >= 256 else { return nil }
        
        // Interpolate to regular sampling
        let interpolated = interpolateToRegular(rrIntervals, targetRate: samplingRate)
        guard interpolated.count >= 256 else { return nil }
        
        // Remove mean
        let mean = interpolated.reduce(0, +) / Double(interpolated.count)
        let detrended = interpolated.map { $0 - mean }
        
        // Apply Hamming window
        let windowed = applyHammingWindow(detrended)
        
        // Compute FFT
        guard let fft = computeFFT(windowed) else { return nil }
        
        // Compute power spectral density
        let n = fft.count
        let frequencies = (0..<n).map { Double($0) * samplingRate / Double(n) }
        let power = fft.map { $0 * $0 }
        
        // Integrate power in bands
        let vlfPower = integratePower(frequencies: frequencies, power: power, lowFreq: 0.003, highFreq: 0.04)
        let lfPower = integratePower(frequencies: frequencies, power: power, lowFreq: 0.04, highFreq: 0.15)
        let hfPower = integratePower(frequencies: frequencies, power: power, lowFreq: 0.15, highFreq: 0.4)
        let totalPower = vlfPower + lfPower + hfPower
        
        return HRVFrequencyMetrics(
            lfPower: lfPower,
            hfPower: hfPower,
            lfHfRatio: lfPower / max(hfPower, 0.001),
            totalPower: totalPower,
            vlfPower: vlfPower
        )
    }
    
    private static func interpolateToRegular(_ rrIntervals: [Double], targetRate: Double) -> [Double] {
        // Cumulative time
        var cumulativeTime: [Double] = [0]
        for rr in rrIntervals {
            cumulativeTime.append(cumulativeTime.last! + rr / 1000.0) // Convert ms to seconds
        }
        
        // Create regular time grid
        let duration = cumulativeTime.last!
        let numSamples = Int(duration * targetRate)
        let regularTimes = (0..<numSamples).map { Double($0) / targetRate }
        
        // Linear interpolation
        var interpolated: [Double] = []
        var rrIndex = 0
        for t in regularTimes {
            while rrIndex < cumulativeTime.count - 1 && cumulativeTime[rrIndex + 1] < t {
                rrIndex += 1
            }
            
            if rrIndex >= cumulativeTime.count - 1 {
                interpolated.append(rrIntervals.last!)
                continue
            }
            
            let t0 = cumulativeTime[rrIndex]
            let t1 = cumulativeTime[rrIndex + 1]
            let rr0 = rrIntervals[min(rrIndex, rrIntervals.count - 1)]
            let rr1 = rrIntervals[min(rrIndex + 1, rrIntervals.count - 1)]
            
            let fraction = (t - t0) / (t1 - t0)
            let value = rr0 + fraction * (rr1 - rr0)
            interpolated.append(value)
        }
        
        return interpolated
    }
    
    private static func applyHammingWindow(_ signal: [Double]) -> [Double] {
        let n = signal.count
        return signal.enumerated().map { i, value in
            let window = 0.54 - 0.46 * cos(2.0 * .pi * Double(i) / Double(n - 1))
            return value * window
        }
    }
    
    private static func computeFFT(_ signal: [Double]) -> [Double]? {
        let n = signal.count
        let log2n = vDSP_Length(log2(Double(n)))
        
        guard let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetupD(fftSetup) }
        
        var real = signal
        var imaginary = [Double](repeating: 0.0, count: n)
        
        real.withUnsafeMutableBufferPointer { realPtr in
            imaginary.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPDoubleSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                vDSP_fft_zripD(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
            }
        }
        
        // Compute magnitude
        var magnitudes = [Double](repeating: 0.0, count: n/2)
        for i in 0..<n/2 {
            magnitudes[i] = sqrt(real[i] * real[i] + imaginary[i] * imaginary[i])
        }
        
        return magnitudes
    }
    
    private static func integratePower(frequencies: [Double], power: [Double], lowFreq: Double, highFreq: Double) -> Double {
        var total = 0.0
        for i in 0..<frequencies.count {
            if frequencies[i] >= lowFreq && frequencies[i] <= highFreq {
                total += power[i]
            }
        }
        return total
    }
}
