import SwiftUI
import Foundation

struct TimerView: View {
    @StateObject private var timerManager = TimerManager.shared
    @State private var selectedSession: SessionType = .work
    @State private var showingCompletion = false
    @State private var completedSessionType: SessionType = .work
    
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Spacing.sm) {
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
            .padding(DesignSystem.Spacing.md)
            .onAppear {
                // Sync the selected session with timer manager
                selectedSession = timerManager.currentSession
                
                // Check if a session completed while window was closed
                if timerManager.hasCompletedSession {
                    showCompletionAlert()
                    timerManager.hasCompletedSession = false
                }
            }
            
            // Session Completion Overlay
            if showingCompletion {
                sessionCompletionOverlay
            }
        }
        .onReceive(timerManager.$sessionCompleted) { completed in
            if completed {
                showCompletionAlert()
                timerManager.sessionCompleted = false
            }
        }
    }
    
    private var sessionCompletionOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Completion card
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: completedSessionType == .work ? "checkmark.circle.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(completedSessionType.color)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Session Complete!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(completedSessionType.title) session finished")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Button("Continue") {
                    withAnimation(DesignSystem.Animation.gentle) {
                        showingCompletion = false
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(completedSessionType.color)
                )
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .scaleEffect(showingCompletion ? 1.0 : 0.8)
            .opacity(showingCompletion ? 1.0 : 0.0)
        }
    }
    
    private func showCompletionAlert() {
        completedSessionType = timerManager.lastCompletedSessionType
        withAnimation(DesignSystem.Animation.bounce) {
            showingCompletion = true
        }
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if showingCompletion {
                withAnimation(DesignSystem.Animation.gentle) {
                    showingCompletion = false
                }
            }
        }
        
        // Post notification to show window if it's closed
        NotificationCenter.default.post(name: .sessionCompleted, object: nil)
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
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: session.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(session.title)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(selectedSession == session ? .white : DesignSystem.Colors.textSecondary)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
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
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Text("Custom Time")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Decrease time button
                Button(action: {
                    timerManager.adjustTime(by: -5 * 60) // -5 minutes
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                
                // Current time display
                Text(timerManager.timeString)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(minWidth: 70)
                
                // Increase time button
                Button(action: {
                    timerManager.adjustTime(by: 5 * 60) // +5 minutes
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(selectedSession.color)
                }
                .buttonStyle(.plain)
            }
            
            // Direct time input
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("Set:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("25", text: $timerManager.customTimeInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 35)
                    .multilineTextAlignment(.center)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.surface.opacity(0.5))
                    )
                    .onSubmit {
                        timerManager.applyCustomTimeInput()
                    }
                
                Text("min")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(DesignSystem.Animation.smooth, value: timerManager.isRunning)
    }
    
    private var timerDisplay: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.surface.opacity(0.3), lineWidth: 6)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        selectedSession.color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerManager.progress)
                
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    Text(timerManager.timeString)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(selectedSession.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Reset Button
            Button(action: { timerManager.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, height: 40)
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
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, height: 40)
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
    static let shared = TimerManager()
    
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var currentSession: SessionType = .work
    @Published var completedSessions = 0
    @Published var totalFocusMinutes = 0
    @Published var todaySessions = 0
    @Published var customTimeInput: String = ""
    @Published var sessionCompleted = false
    @Published var hasCompletedSession = false
    
    var lastCompletedSessionType: SessionType = .work
    
    private var timer: Timer?
    private var totalDuration: TimeInterval = 25 * 60
    private var customDuration: TimeInterval? = nil
    private var startTime: Date?
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private init() {
        loadStats()
        loadTimerState()
        updateCustomTimeInput()
        
        // Resume timer if it was running
        if isRunning {
            start()
        }
    }
    
    func setSession(_ session: SessionType) {
        guard !isRunning else { return }
        currentSession = session
        
        // Use custom duration if set, otherwise use default
        let duration = customDuration ?? session.defaultDuration
        timeRemaining = duration
        totalDuration = duration
        updateCustomTimeInput()
        saveTimerState()
    }
    
    func setCustomTime(_ seconds: TimeInterval) {
        guard !isRunning else { return }
        customDuration = seconds
        timeRemaining = seconds
        totalDuration = seconds
        updateCustomTimeInput()
        saveTimerState()
    }
    
    func adjustTime(by seconds: TimeInterval) {
        guard !isRunning else { return }
        let newTime = max(60, timeRemaining + seconds) // Minimum 1 minute
        customDuration = newTime
        timeRemaining = newTime
        totalDuration = newTime
        updateCustomTimeInput()
        saveTimerState()
    }
    
    func start() {
        isRunning = true
        startTime = Date()
        saveTimerState()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        saveTimerState()
    }
    
    func reset() {
        pause()
        let duration = customDuration ?? currentSession.defaultDuration
        timeRemaining = duration
        totalDuration = duration
        updateCustomTimeInput()
        saveTimerState()
    }
    
    func skipWithoutStats() {
        // Skip to next session without counting stats
        pause()
        moveToNextSession()
    }
    
    func applyCustomTimeInput() {
        guard let minutes = Int(customTimeInput), minutes > 0 else { 
            updateCustomTimeInput() // Reset to current value if invalid
            return 
        }
        setCustomTime(TimeInterval(minutes * 60))
    }
    
    private func updateCustomTimeInput() {
        let minutes = Int(timeRemaining) / 60
        customTimeInput = "\(minutes)"
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            saveTimerState()
        } else {
            completeSession()
            moveToNextSession()
        }
    }
    
    private func completeSession() {
        lastCompletedSessionType = currentSession
        
        // Only count work sessions toward stats, not breaks
        if currentSession == .work {
            completedSessions += 1
            // Calculate actual focus time based on original duration
            let focusMinutes = Int(totalDuration) / 60
            totalFocusMinutes += focusMinutes
            todaySessions += 1
            saveStats()
        }
        
        // Trigger completion notification
        sessionCompleted = true
        hasCompletedSession = true
        
        // Show notification and post to NotificationCenter on main queue
        sendNotification()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sessionCompleted, object: nil)
        }
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
    
    private func saveTimerState() {
        UserDefaults.standard.set(timeRemaining, forKey: "timer_time_remaining")
        UserDefaults.standard.set(totalDuration, forKey: "timer_total_duration")
        UserDefaults.standard.set(isRunning, forKey: "timer_is_running")
        UserDefaults.standard.set(currentSession.rawValue, forKey: "timer_current_session")
        UserDefaults.standard.set(customDuration, forKey: "timer_custom_duration")
        
        if let startTime = startTime {
            UserDefaults.standard.set(startTime, forKey: "timer_start_time")
        }
    }
    
    private func loadTimerState() {
        timeRemaining = UserDefaults.standard.double(forKey: "timer_time_remaining")
        totalDuration = UserDefaults.standard.double(forKey: "timer_total_duration")
        isRunning = UserDefaults.standard.bool(forKey: "timer_is_running")
        customDuration = UserDefaults.standard.object(forKey: "timer_custom_duration") as? TimeInterval
        
        if let sessionRaw = UserDefaults.standard.string(forKey: "timer_current_session"),
           let session = SessionType(rawValue: sessionRaw) {
            currentSession = session
        }
        
        // Handle time that passed while app was closed
        if isRunning, let savedStartTime = UserDefaults.standard.object(forKey: "timer_start_time") as? Date {
            let elapsedTime = Date().timeIntervalSince(savedStartTime)
            let adjustedTimeRemaining = timeRemaining - elapsedTime
            
            if adjustedTimeRemaining <= 0 {
                // Session completed while app was closed
                timeRemaining = 0
                isRunning = false
                hasCompletedSession = true
                lastCompletedSessionType = currentSession
                completeSession()
                moveToNextSession()
            } else {
                timeRemaining = adjustedTimeRemaining
            }
        }
        
        // Set defaults if nothing was saved
        if timeRemaining == 0 && totalDuration == 0 {
            timeRemaining = currentSession.defaultDuration
            totalDuration = currentSession.defaultDuration
        }
    }
}

extension SessionType: RawRepresentable {
    var rawValue: String {
        switch self {
        case .work: return "work"
        case .shortBreak: return "shortBreak"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "work": self = .work
        case "shortBreak": self = .shortBreak
        default: return nil
        }
    }
}

extension Notification.Name {
    static let sessionCompleted = Notification.Name("sessionCompleted")
} 