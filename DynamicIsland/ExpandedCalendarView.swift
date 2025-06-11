import SwiftUI
import MapKit

struct ExpandedCalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentTime = Date()
    @State private var selectedWorldTimeZone: WorldTimeZone?
    @State private var viewMode: CalendarViewMode = .month
    @State private var showingDatePicker = false
    
    // Timer for real-time updates
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum CalendarViewMode: String, CaseIterable {
        case month = "Month"
        case year = "Year"
        
        var icon: String {
            switch self {
            case .month: return "calendar"
            case .year: return "calendar.circle"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Main Content
                HStack(spacing: 0) {
                    // Left Panel - Calendar Views
                    leftPanel
                        .frame(width: max(400, geometry.size.width * 0.4))
                    
                    Divider()
                        .background(DesignSystem.Colors.border)
                    
                    // Right Panel - World Time & Details
                    rightPanel
                        .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color.clear)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Title and Controls
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar")
                        .font(DesignSystem.Typography.headline1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(formatSelectedDate())
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // View Mode Selector
                viewModeSelector
                
                // Today Button
                Button(action: { selectedDate = Date() }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                        Text("Today")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Current Time Display
            currentTimeDisplay
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        viewMode = mode
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(mode.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(viewMode == mode ? .white : DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .fill(viewMode == mode ? DesignSystem.Colors.primary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        )
    }
    
    private var currentTimeDisplay: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Local Time
            VStack(alignment: .leading, spacing: 2) {
                Text("Local Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .textCase(.uppercase)
                
                Text(formatTimeWithSeconds(currentTime))
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            // Date Info
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatFullDate(selectedDate))
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(formatWeekday(selectedDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .textCase(.uppercase)
            }
        }
    }
    
    // MARK: - Left Panel
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Calendar Navigation
            calendarNavigation
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Calendar Content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    switch viewMode {
                    case .month:
                        monthCalendarView
                    case .year:
                        yearCalendarView
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .background(.ultraThinMaterial)
    }
    
    private var calendarNavigation: some View {
        HStack {
            Button(action: previousPeriod) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Clickable Date Title
            Button(action: {
                showingDatePicker = true
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(navigationTitle)
                        .font(DesignSystem.Typography.headline2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Today Button
            Button(action: goToToday) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            Button(action: nextPeriod) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.xl)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
    }
    
    private var monthCalendarView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: DesignSystem.Spacing.sm) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        ExpandedCalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDate(date, inSameDayAs: Date()),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private var yearCalendarView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.lg) {
            ForEach(1...12, id: \.self) { month in
                YearCalendarMonthView(
                    month: month,
                    year: Calendar.current.component(.year, from: selectedDate),
                    selectedDate: $selectedDate
                )
            }
        }
    }
    
    // MARK: - Right Panel
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // World Time Header
            worldTimeHeader
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // World Map
            worldMapSection
            
            // Selected Time Zone Info
            if let selectedTimeZone = selectedWorldTimeZone {
                Divider()
                    .background(DesignSystem.Colors.border)
                
                selectedTimeZoneInfo(selectedTimeZone)
                    .padding(DesignSystem.Spacing.xl)
            }
        }
        .background(.ultraThinMaterial)
    }
    
    private var worldTimeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("World Time")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Tap cities to explore time zones")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if selectedWorldTimeZone != nil {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedWorldTimeZone = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
    
    private var worldMapSection: some View {
        WorldMapView(
            selectedTimeZone: $selectedWorldTimeZone,
            currentTime: currentTime
        )
        .frame(maxHeight: .infinity)
        .cornerRadius(DesignSystem.BorderRadius.lg)
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
    
    private func selectedTimeZoneInfo(_ timeZone: WorldTimeZone) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(timeZone.color)
                
                Text(timeZone.name)
                    .font(DesignSystem.Typography.headline3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Time")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .textCase(.uppercase)
                        
                        Text(formatTimeWithSecondsForTimeZone(currentTime, in: timeZone.timeZone))
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(isDaytimeInTimeZone(timeZone) ? "Daytime" : "Nighttime")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isDaytimeInTimeZone(timeZone) ? .orange : .purple)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((isDaytimeInTimeZone(timeZone) ? Color.orange : Color.purple).opacity(0.2))
                            )
                        
                        Text(offsetFormatterForTimeZone(timeZone))
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Additional time zone info
                VStack(spacing: DesignSystem.Spacing.sm) {
                    infoRow("Date", formatFullDate(currentTime, timeZone: timeZone.timeZone))
                    infoRow("Day of Week", formatWeekday(currentTime, timeZone: timeZone.timeZone))
                    infoRow("Time Zone", timeZone.identifier)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(timeZone.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(timeZone.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private func formatTimeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTimeWithSecondsForTimeZone(_ date: Date, in timeZone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.timeZone = timeZone ?? TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date, timeZone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeZone = timeZone ?? TimeZone.current
        return formatter.string(from: date)
    }
    
    private func formatWeekday(_ date: Date, timeZone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timeZone ?? TimeZone.current
        return formatter.string(from: date)
    }
    
    private var navigationTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: selectedDate)
    }
    
    private func previousPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let calendar = Calendar.current
            switch viewMode {
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            }
        }
    }
    
    private func nextPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let calendar = Calendar.current
            switch viewMode {
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            }
        }
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Date()
        }
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let range = calendar.range(of: .day, in: .month, for: selectedDate) ?? 1..<32
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDays = range.count
        
        var days: [Date?] = []
        
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isDaytimeInTimeZone(_ timeZone: WorldTimeZone) -> Bool {
        guard let tz = timeZone.timeZone else { return true }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: tz, from: currentTime)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 18
    }
    
    private func offsetFormatterForTimeZone(_ timeZone: WorldTimeZone) -> String {
        guard let tz = timeZone.timeZone else { return "" }
        let offset = tz.secondsFromGMT() / 3600
        let sign = offset >= 0 ? "+" : ""
        return "GMT\(sign)\(offset)"
    }
}

// MARK: - Expanded Calendar Day View

struct ExpandedCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .semibold : .medium))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? .orange :
                        isCurrentMonth ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textTertiary
                    )
                
                // Event indicator dots (placeholder)
                HStack(spacing: 2) {
                    if isToday && !isSelected {
                        Circle()
                            .fill(.orange)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(
                        isSelected ? .orange :
                        isToday ? .orange.opacity(0.1) : 
                        Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .stroke(
                        isToday && !isSelected ? .orange.opacity(0.5) : .clear, 
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            HStack {
                Text("Select Date")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    selectedDate = tempDate
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Date Picker
            DatePicker(
                "Select Date",
                selection: $tempDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .frame(maxWidth: 400)
            
            // Quick Actions
            HStack(spacing: DesignSystem.Spacing.md) {
                Button("Today") {
                    tempDate = Date()
                }
                .buttonStyle(.bordered)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(minWidth: 450, minHeight: 450)
        .background(.regularMaterial)
    }
}

// MARK: - Year Calendar Month View

struct YearCalendarMonthView: View {
    let month: Int
    let year: Int
    @Binding var selectedDate: Date
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date)
    }
    
    private var monthDate: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month)) ?? Date()
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<32
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDays = range.count
        
        var days: [Date?] = []
        
        // Empty cells for days before month starts
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Actual days of the month
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Month header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = monthDate
                }
            }) {
                Text(monthName.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            
            // Mini calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                                .foregroundColor(
                                    isSelected ? .white :
                                    isToday ? .orange :
                                    DesignSystem.Colors.textPrimary
                                )
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(
                                            isSelected ? .orange :
                                            isToday ? .orange.opacity(0.2) :
                                            Color.clear
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
        )
    }
}