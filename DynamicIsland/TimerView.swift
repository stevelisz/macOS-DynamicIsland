import SwiftUI
import Foundation

struct TimerView: View {
    @StateObject private var timerManager = TimerManager()
    @State private var selectedSession: SessionType = .work
    @State private var showTimeCustomizer = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Session Type Selector
            sessionSelector
            
            // Custom Time Controls (when not running)
            if !timerManager.isRunning {
                timeCustomizer
            }
            
            // Main Timer Display
            timerDisplay
            
            // Control Buttons
            controlButtons
            
            // Session Stats with Reset Button
            statsSection
        }
        .padding(DesignSystem.Spacing.lg)
        .onDisappear {
            timerManager.pause()
        }
        .onAppear {
            // Sync the selected session with timer manager
            selectedSession = timerManager.currentSession
        }
    }
    
    private var sessionSelector: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(SessionType.allCases, id: \.self) { session in
                Button(action: {
                    if !timerManager.isRunning {
                        selectedSession = session
                        timerManager.setSession(session)
                    }
                }) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: session.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(session.title)
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(selectedSession == session ? .white : DesignSystem.Colors.textSecondary)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(selectedSession == session ? session.color : DesignSystem.Colors.surface.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
                .disabled(timerManager.isRunning)
                .opacity(timerManager.isRunning && selectedSession != session ? 0.5 : 1.0)
            }
        }
    }
    
    private var timeCustomizer: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Custom Time")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Decrease time button
                Button(action: {
                    timerManager.adjustTime(by: -5 * 60) // -5 minutes
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                
                // Current time display
                Text(timerManager.timeString)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(minWidth: 80)
                
                // Increase time button
                Button(action: {
                    timerManager.adjustTime(by: 5 * 60) // +5 minutes
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(selectedSession.color)
                }
                .buttonStyle(.plain)
            }
            
            // Quick time presets
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach([5, 15, 25, 45], id: \.self) { minutes in
                    Button("\(minutes)m") {
                        timerManager.setCustomTime(minutes * 60)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
                    .buttonStyle(.plain)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(DesignSystem.Animation.smooth, value: timerManager.isRunning)
    }
    
    private var timerDisplay: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surface.opacity(0.3), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        selectedSession.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerManager.progress)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(timerManager.timeString)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(selectedSession.title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Reset Button
            Button(action: { timerManager.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
            }
            .buttonStyle(.plain)
            
            // Play/Pause Button
            Button(action: { 
                if timerManager.isRunning {
                    timerManager.pause()
                } else {
                    timerManager.start()
                }
            }) {
                Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(selectedSession.color)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(timerManager.isRunning ? 1.0 : 1.05)
            .animation(.easeInOut(duration: 0.1), value: timerManager.isRunning)
            
            // Skip Button (doesn't count towards stats)
            Button(action: { timerManager.skipWithoutStats() }) {
                Image(systemName: "forward.end")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Stats
            HStack(spacing: DesignSystem.Spacing.lg) {
                StatItem(
                    title: "Completed",
                    value: "\(timerManager.completedSessions)",
                    icon: "checkmark.circle.fill",
                    color: DesignSystem.Colors.success
                )
                
                StatItem(
                    title: "Focus Time",
                    value: "\(timerManager.totalFocusMinutes)m",
                    icon: "brain.head.profile",
                    color: DesignSystem.Colors.primary
                )
                
                StatItem(
                    title: "Sessions",
                    value: "\(timerManager.todaySessions)",
                    icon: "calendar",
                    color: DesignSystem.Colors.clipboard
                )
            }
            
            // Reset Stats Button
            Button("Reset All Stats") {
                timerManager.resetAllStats()
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                    .fill(DesignSystem.Colors.surface.opacity(0.3))
            )
            .buttonStyle(.plain)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

enum SessionType: CaseIterable {
    case work, shortBreak
    
    var title: String {
        switch self {
        case .work: return "Focus"
        case .shortBreak: return "Break"
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .work: return 25 * 60 // 25 minutes
        case .shortBreak: return 5 * 60 // 5 minutes
        }
    }
    
    var color: Color {
        switch self {
        case .work: return DesignSystem.Colors.success
        case .shortBreak: return DesignSystem.Colors.primary
        }
    }
}

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var currentSession: SessionType = .work
    @Published var completedSessions = 0
    @Published var totalFocusMinutes = 0
    @Published var todaySessions = 0
    
    private var timer: Timer?
    private var totalDuration: TimeInterval = 25 * 60
    private var customDuration: TimeInterval? = nil
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init() {
        loadStats()
    }
    
    func setSession(_ session: SessionType) {
        guard !isRunning else { return }
        currentSession = session
        
        // Use custom duration if set, otherwise use default
        let duration = customDuration ?? session.defaultDuration
        timeRemaining = duration
        totalDuration = duration
    }
    
    func setCustomTime(_ seconds: TimeInterval) {
        guard !isRunning else { return }
        customDuration = seconds
        timeRemaining = seconds
        totalDuration = seconds
    }
    
    func adjustTime(by seconds: TimeInterval) {
        guard !isRunning else { return }
        let newTime = max(60, timeRemaining + seconds) // Minimum 1 minute
        customDuration = newTime
        timeRemaining = newTime
        totalDuration = newTime
    }
    
    func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        pause()
        let duration = customDuration ?? currentSession.defaultDuration
        timeRemaining = duration
        totalDuration = duration
    }
    
    func skipWithoutStats() {
        // Skip to next session without counting stats
        pause()
        moveToNextSession()
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeSession()
            moveToNextSession()
        }
    }
    
    private func completeSession() {
        // Only count work sessions toward stats, not breaks
        if currentSession == .work {
            completedSessions += 1
            // Calculate actual focus time based on original duration
            let focusMinutes = Int(totalDuration) / 60
            totalFocusMinutes += focusMinutes
            todaySessions += 1
            saveStats()
        }
        
        // Show notification
        sendNotification()
    }
    
    private func moveToNextSession() {
        pause()
        
        // Simple alternating logic: Work -> Break -> Work -> Break
        if currentSession == .work {
            setSession(.shortBreak)
        } else {
            setSession(.work)
        }
        
        // Clear custom duration when switching sessions
        customDuration = nil
    }
    
    private func sendNotification() {
        // Basic notification - could be enhanced with actual notifications
        NSSound.beep()
    }
    
    func resetAllStats() {
        completedSessions = 0
        totalFocusMinutes = 0
        todaySessions = 0
        saveStats()
    }
    
    private func saveStats() {
        UserDefaults.standard.set(completedSessions, forKey: "timer_completed_sessions")
        UserDefaults.standard.set(totalFocusMinutes, forKey: "timer_total_focus_minutes")
        UserDefaults.standard.set(todaySessions, forKey: "timer_today_sessions")
    }
    
    private func loadStats() {
        completedSessions = UserDefaults.standard.integer(forKey: "timer_completed_sessions")
        totalFocusMinutes = UserDefaults.standard.integer(forKey: "timer_total_focus_minutes")
        todaySessions = UserDefaults.standard.integer(forKey: "timer_today_sessions")
    }
} 