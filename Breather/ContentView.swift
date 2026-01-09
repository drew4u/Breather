//
//  ContentView.swift
//  Breather
//
//  Created by Andrew Sibert on 1/8/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timeRemaining: TimeInterval = 600 // 10 minutes
    @State private var breatheScale: CGFloat = 1.0
    @State private var showMilestoneAnimation = false
    @State private var milestoneText = ""
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    
    private let totalTime: TimeInterval = 600 // 10 minutes
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Breathing gradient background
                BreathingBackground(breatheScale: breatheScale)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("breather")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.black.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Main content area
                    if !isRunning {
                        // Start screen
                        StartView(onStart: startMeditation)
                    } else {
                        // Timer screen
                        TimerView(
                            timeRemaining: timeRemaining,
                            totalTime: totalTime,
                            isPaused: isPaused,
                            breatheScale: breatheScale,
                            onPause: togglePause,
                            onFinish: finishMeditation
                        )
                    }
                    
                    Spacer()
                }
                
                // Milestone animation overlay
                if showMilestoneAnimation {
                    MilestoneOverlay(text: milestoneText)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.15
        }
    }
    
    private func startMeditation() {
        timeRemaining = totalTime
        isRunning = true
        isPaused = false
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    
                    // Check for milestones
                    if timeRemaining == 300 { // 5 minutes
                        triggerMilestone(text: "Halfway there")
                    } else if timeRemaining == 0 {
                        triggerMilestone(text: "Session complete")
                        finishMeditation()
                    }
                }
            }
        }
    }
    
    private func triggerMilestone(text: String) {
        milestoneText = text
        playBellSound()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showMilestoneAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMilestoneAnimation = false
            }
        }
    }
    
    private func playBellSound() {
        // Play system sound - a gentle tone
        AudioServicesPlaySystemSound(1013) // Gentle chime
    }
    
    private func togglePause() {
        isPaused.toggle()
    }
    
    private func finishMeditation() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = totalTime
    }
}

// MARK: - Breathing Background

struct BreathingBackground: View {
    let breatheScale: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base cream/pink gradient
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.96),
                        Color(red: 1.0, green: 0.92, blue: 0.90),
                        Color(red: 0.98, green: 0.85, blue: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Soft radial glow that breathes
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.7, blue: 0.6).opacity(0.4),
                        Color(red: 1.0, green: 0.8, blue: 0.75).opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: geometry.size.width * 0.8
                )
                .scaleEffect(breatheScale)
                .offset(y: geometry.size.height * 0.1)
            }
        }
    }
}

// MARK: - Start View

struct StartView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Title text
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus /")
                Text("Breathe /")
                Text("Relax /")
            }
            .font(.custom("Georgia", size: 42))
            .fontWeight(.regular)
            .foregroundColor(.black.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Sun illustration
            SunView()
                .frame(width: 280, height: 180)
            
            Spacer()
            
            // Start button
            Button(action: onStart) {
                VStack(spacing: 4) {
                    Text("TAP TO")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(.black.opacity(0.5))
                    Text("START")
                        .font(.custom("Georgia", size: 38))
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Sun View

struct SunView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sun semicircle with gradient
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.3),
                                Color(red: 1.0, green: 0.6, blue: 0.4),
                                Color(red: 0.95, green: 0.4, blue: 0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .offset(y: geometry.size.width * 0.35)
                    .clipShape(
                        Rectangle()
                            .size(width: geometry.size.width, height: geometry.size.height)
                    )
                
                // Soft glow beneath
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.5, blue: 0.6).opacity(0.5),
                                Color(red: 0.98, green: 0.7, blue: 0.75).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: geometry.size.width * 0.7
                        )
                    )
                    .frame(width: geometry.size.width * 1.4, height: geometry.size.width * 0.8)
                    .offset(y: geometry.size.height * 0.5)
            }
        }
    }
}

// MARK: - Timer View

struct TimerView: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let isPaused: Bool
    let breatheScale: CGFloat
    let onPause: () -> Void
    let onFinish: () -> Void
    
    var progress: CGFloat {
        CGFloat(timeRemaining / totalTime)
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 60) {
            // Breathing circle with timer
            ZStack {
                // Outer breathing ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.5).opacity(0.3),
                                Color(red: 0.95, green: 0.5, blue: 0.6).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(breatheScale)
                
                // Progress ring
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
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.7).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(breatheScale)
                
                // Timer text
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.custom("Georgia", size: 56))
                        .fontWeight(.light)
                        .foregroundColor(.black.opacity(0.85))
                    
                    Text(isPaused ? "PAUSED" : "BREATHE")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(3)
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            // Control buttons
            HStack(spacing: 40) {
                // Pause/Resume button
                Button(action: onPause) {
                    VStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black.opacity(0.7))
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .frame(width: 80, height: 70)
                }
                
                // Finish button
                Button(action: onFinish) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black.opacity(0.7))
                        Text("Finish")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .frame(width: 80, height: 70)
                }
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Milestone Overlay

struct MilestoneOverlay: View {
    let text: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            // Milestone card
            VStack(spacing: 16) {
                // Animated rings
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color.white.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(60 + index * 30), height: CGFloat(60 + index * 30))
                            .scaleEffect(scale)
                    }
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                Text(text)
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(50)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.55, blue: 0.5),
                                Color(red: 0.9, green: 0.4, blue: 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}
