//
//  ContentView.swift
//  Breather
//
//  Created by Andrew Sibert on 1/8/26.
//

import SwiftUI
import AVFoundation
import HealthKit

struct ContentView: View {
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var selectedMinutes: Int = 10
    @State private var timeRemaining: TimeInterval = 600
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var meditationStartTime: Date?
    @State private var showDurationPicker = false
    
    private var totalTime: TimeInterval {
        TimeInterval(selectedMinutes * 60)
    }
    private let bellSoundName = "tibetan-bowl-medium-soft-hit-aroshanti-1-00-17"
    private let healthStore = HKHealthStore()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Breathing gradient background
                BreathingBackground(isRunning: isRunning, isPaused: isPaused)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    Spacer()
                    
                    // Main circle - unified view for both states
                    MainCircleView(
                        isRunning: isRunning,
                        isPaused: isPaused,
                        timeRemaining: timeRemaining,
                        totalTime: totalTime,
                        selectedMinutes: selectedMinutes,
                        onStart: startMeditation,
                        onPause: togglePause,
                        onFinish: finishMeditation,
                        onTapDuration: { showDurationPicker = true }
                    )
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            requestHealthKitAuthorization()
        }
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(selectedMinutes: $selectedMinutes)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.light)
    }
    
    private func startMeditation() {
        meditationStartTime = Date()
        playBellSound()
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
            timeRemaining = totalTime
            isRunning = true
            isPaused = false
        }
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                if timeRemaining > 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        timeRemaining -= 1
                    }
                    
                    // Session complete
                    if timeRemaining == 0 {
                        playBellSound()
                        finishMeditation()
                    }
                }
            }
        }
    }
    
    private func playBellSound() {
        // Configure audio session to play even in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // Load sound from asset catalog
        guard let soundData = NSDataAsset(name: bellSoundName)?.data else {
            // Fallback to system sound if asset not found
            AudioServicesPlaySystemSound(1013)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: soundData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            // Fallback to system sound on error
            AudioServicesPlaySystemSound(1013)
        }
    }
    
    private func togglePause() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPaused.toggle()
        }
    }
    
    private func finishMeditation() {
        timer?.invalidate()
        timer = nil
        
        // Save meditation to HealthKit
        if let startTime = meditationStartTime {
            let meditatedDuration = totalTime - timeRemaining
            if meditatedDuration > 0 {
                saveMeditationToHealth(startDate: startTime, duration: meditatedDuration)
            }
        }
        meditationStartTime = nil
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
            isRunning = false
            isPaused = false
            timeRemaining = totalTime
        }
    }
    
    // MARK: - HealthKit
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        healthStore.requestAuthorization(toShare: [mindfulType], read: [mindfulType]) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveMeditationToHealth(startDate: Date, duration: TimeInterval) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let endDate = startDate.addingTimeInterval(duration)
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        
        healthStore.save(sample) { success, error in
            if success {
                print("✓ Meditation saved to Health: \(Int(duration / 60)) minutes")
            } else if let error = error {
                print("✗ Error saving to Health: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Main Circle View

struct MainCircleView: View {
    let isRunning: Bool
    let isPaused: Bool
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let selectedMinutes: Int
    let onStart: () -> Void
    let onPause: () -> Void
    let onFinish: () -> Void
    let onTapDuration: () -> Void
    
    @State private var breatheScale: CGFloat = 1.0
    
    private let circleSize: CGFloat = 280
    private let breatheDuration: Double = 4.0
    
    var progress: CGFloat {
        CGFloat(timeRemaining / totalTime)
    }
    
    var formattedDuration: String {
        if selectedMinutes >= 60 {
            let hours = selectedMinutes / 60
            let mins = selectedMinutes % 60
            if mins == 0 {
                return "\(hours) hr"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(selectedMinutes) min"
    }
    
    var body: some View {
        VStack(spacing: 50) {
            ZStack {
                // Outer decorative rings that breathe
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.75, blue: 0.5).opacity(0.15 - Double(index) * 0.04),
                                    Color(red: 0.95, green: 0.5, blue: 0.6).opacity(0.15 - Double(index) * 0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: circleSize + CGFloat(index * 40), height: circleSize + CGFloat(index * 40))
                        .scaleEffect(breatheScale)
                }
                
                // Main circle background with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color(red: 1.0, green: 0.95, blue: 0.92).opacity(0.8),
                                Color(red: 1.0, green: 0.88, blue: 0.85).opacity(0.6)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: circleSize / 2
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .scaleEffect(breatheScale)
                    .shadow(color: Color(red: 0.95, green: 0.6, blue: 0.55).opacity(0.3), radius: 40, x: 0, y: 20)
                
                // Progress ring (only visible when running)
                if isRunning {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.75, blue: 0.4),
                                    Color(red: 0.95, green: 0.45, blue: 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: circleSize - 20, height: circleSize - 20)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(breatheScale)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Content inside circle
                if isRunning {
                    // Timer display
                    VStack(spacing: 12) {
                        AnimatedTimerText(timeRemaining: timeRemaining)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                } else {
                    // Start prompt with duration
                    VStack(spacing: 20) {
                        // Tappable duration
                        Button(action: onTapDuration) {
                            HStack(spacing: 6) {
                                Text(formattedDuration)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.black.opacity(0.8))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                        
                        // Start button
                        Button(action: onStart) {
                            Text("TAP TO START")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(.black.opacity(0.4))
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                }
            }
            
            // Control buttons (only when running)
            if isRunning {
                HStack(spacing: 50) {
                    // Pause/Resume button
                    Button(action: onPause) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                                
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }
                    
                    // Finish button
                    Button(action: onFinish) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                                
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            Text("Finish")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: isRunning) { oldValue, newValue in
            if newValue && !isPaused {
                startBreathing()
            } else if !newValue {
                withAnimation(.easeOut(duration: 0.5)) {
                    breatheScale = 1.0
                }
            }
        }
        .onChange(of: isPaused) { oldValue, newValue in
            if isRunning {
                if newValue {
                    // Pause: hold current position
                    pauseBreathing()
                } else {
                    // Resume: restart animation
                    startBreathing()
                }
            }
        }
    }
    
    private func startBreathing() {
        // First reset to base, then start breathing animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            breatheScale = 1.0
        }
        // Start the repeating breath after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(
                .easeInOut(duration: breatheDuration)
                .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.12
            }
        }
    }
    
    private func pauseBreathing() {
        // Shrink down to indicate paused state
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
            breatheScale = 0.88
        }
    }
}

// MARK: - Animated Timer Text

struct AnimatedTimerText: View {
    let timeRemaining: TimeInterval
    
    private var minutes: Int {
        Int(timeRemaining) / 60
    }
    
    private var seconds: Int {
        Int(timeRemaining) % 60
    }
    
    private var minuteTens: Int { minutes / 10 }
    private var minuteOnes: Int { minutes % 10 }
    private var secondTens: Int { seconds / 10 }
    private var secondOnes: Int { seconds % 10 }
    
    var body: some View {
        HStack(spacing: 0) {
            // Minutes
            AnimatedDigit(digit: minuteTens)
            AnimatedDigit(digit: minuteOnes)
            
            // Colon
            Text(":")
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.1))
            
            // Seconds
            AnimatedDigit(digit: secondTens)
            AnimatedDigit(digit: secondOnes)
        }
    }
}

// MARK: - Animated Single Digit

struct AnimatedDigit: View {
    let digit: Int
    
    var body: some View {
        Text("\(digit)")
            .font(.system(size: 52, weight: .bold, design: .rounded))
            .foregroundColor(.black.opacity(0.1))
            .frame(width: 38)
            .contentTransition(.numericText(countsDown: true))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: digit)
    }
}

// MARK: - Breathing Background

struct BreathingBackground: View {
    let isRunning: Bool
    let isPaused: Bool
    
    @State private var breatheScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.25
    
    private let breatheDuration: Double = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.96),
                        Color(red: 1.0, green: 0.94, blue: 0.91),
                        Color(red: 0.99, green: 0.88, blue: 0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Animated radial glow
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.7, blue: 0.6).opacity(glowOpacity),
                        Color(red: 1.0, green: 0.8, blue: 0.75).opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: geometry.size.width * 0.9
                )
                .scaleEffect(breatheScale)
                
                // Subtle floating orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.7).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.2)
                    .scaleEffect(breatheScale * 0.95)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.6, blue: 0.65).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(x: geometry.size.width * 0.35, y: geometry.size.height * 0.25)
                    .scaleEffect(breatheScale * 1.05)
            }
        }
        .onChange(of: isRunning) { oldValue, newValue in
            if newValue && !isPaused {
                startBreathing()
            } else if !newValue {
                stopBreathing()
            }
        }
        .onChange(of: isPaused) { oldValue, newValue in
            if isRunning {
                if newValue {
                    pauseBreathing()
                } else {
                    startBreathing()
                }
            }
        }
    }
    
    private func startBreathing() {
        // Reset first, then animate
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            breatheScale = 1.0
            glowOpacity = 0.35
        }
        // Start breathing cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(
                .easeInOut(duration: breatheDuration)
                .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.15
                glowOpacity = 0.45
            }
        }
    }
    
    private func pauseBreathing() {
        // Shrink and dim to indicate paused
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
            breatheScale = 0.92
            glowOpacity = 0.2
        }
    }
    
    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.5)) {
            breatheScale = 1.0
            glowOpacity = 0.25
        }
    }
}

// MARK: - Duration Picker Sheet

struct DurationPickerSheet: View {
    @Binding var selectedMinutes: Int
    @Environment(\.dismiss) private var dismiss
    
    private let durations = [1, 2, 3, 5, 10, 15, 20, 25, 30, 45, 60, 90]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Picker
                Picker("Duration", selection: $selectedMinutes) {
                    ForEach(durations, id: \.self) { minutes in
                        Text(formatMinutes(minutes))
                            .tag(minutes)
                    }
                }
                .pickerStyle(.wheel)
                .padding()
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.96),
                        Color(red: 1.0, green: 0.94, blue: 0.91)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Session Length")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.5))
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour"
            }
            return "\(hours) hr \(mins) min"
        }
        return "\(minutes) minutes"
    }
}

#Preview {
    ContentView()
}
