import SwiftUI
import MapKit
import Foundation

// MARK: - Main Expanded Calendar View

struct ExpandedCalendarView: View {
    @State private var currentTime = Date()
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var events: [CalendarEvent] = []
    @State private var showingEventCreator = false
    @State private var eventToEdit: CalendarEvent?
    @State private var selectedTimeSlot: Date?
    
    // Timer for real-time updates
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar with enhanced glass effect
                sidebar
                    .frame(width: 280)
                    .padding(.top, 40) // Space for window controls within glass
                    .background(.clear) // Let the main glass background show through
                
                // Main Calendar Area with glass effect
                VStack(spacing: 0) {
                    // Header with space for window controls
                    calendarHeader
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .padding(.top, 40) // Space for window controls within glass
                        .background(.clear) // Let the main glass background show through
                    
                    // Calendar Content
                    mainCalendarArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.clear) // Let the main glass background show through
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            loadSampleEvents()
        }
        .sheet(isPresented: $showingEventCreator) {
            EventCreatorView(
                events: $events,
                initialDate: selectedTimeSlot ?? selectedDate,
                eventToEdit: eventToEdit
            )
            .onDisappear {
                eventToEdit = nil
                selectedTimeSlot = nil
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Real-time Clock
            realTimeClock
                .padding(.top, DesignSystem.Spacing.lg)
            
            // Mini Calendar Navigator
            miniCalendar
            
            // Quick Actions
            quickActions
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var realTimeClock: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Digital Time
            Text(currentTime.formatted(.dateTime.hour().minute().second()))
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Current Date
            Text(currentTime.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(DesignSystem.Typography.bodySemibold)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private var miniCalendar: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Mini Calendar Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Weekday headers
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(height: 20)
                }
                
                // Calendar days
                ForEach(miniCalendarDays, id: \.self) { date in
                    if let date = date {
                        MiniCalendarDayView(
                            date: date,
                            selectedDate: selectedDate,
                            currentDate: currentTime,
                            hasEvents: hasEvents(on: date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Text("")
                            .frame(height: 24)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    private var quickActions: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Today Button with glass effect
            Button(action: goToToday) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 16))
                    Text("Today")
                        .font(DesignSystem.Typography.captionSemibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.Colors.primary,
                            DesignSystem.Colors.primary.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.3),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            }
            .buttonStyle(.plain)
            
            // New Event Button with glass effect
            Button(action: createNewEvent) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("New Event")
                        .font(DesignSystem.Typography.captionSemibold)
                }
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 1
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        HStack {
            // View Mode Selector
            viewModeSelector
            
            Spacer()
            
            // Navigation
            navigationControls
        }
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewMode = mode
                    }
                }) {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewMode == mode ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewMode == mode ? DesignSystem.Colors.primary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.surface.opacity(0.5))
        )
    }
    
    private var navigationControls: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Period Title
            Text(periodTitle)
                .font(DesignSystem.Typography.headline2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Navigation Buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                Button(action: previousPeriod) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
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
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Main Calendar Area
    
    private var mainCalendarArea: some View {
        Group {
            switch viewMode {
            case .day:
                DayView(
                    date: selectedDate,
                    events: eventsForDate(selectedDate),
                    currentTime: currentTime,
                    onTimeSlotTap: handleTimeSlotTap,
                    onEventTap: handleEventTap
                )
            case .week:
                WeekView(
                    startDate: startOfWeek(selectedDate),
                    events: eventsForWeek(selectedDate),
                    currentTime: currentTime,
                    onTimeSlotTap: handleTimeSlotTap,
                    onEventTap: handleEventTap
                )
            case .month:
                MonthView(
                    date: selectedDate,
                    events: events,
                    currentTime: currentTime,
                    onDateTap: handleDateTap,
                    onEventTap: handleEventTap
                )
            case .year:
                YearView(
                    year: Calendar.current.component(.year, from: selectedDate),
                    events: events,
                    selectedDate: $selectedDate,
                    onDateTap: handleDateTap
                )
            case .agenda:
                AgendaView(
                    events: upcomingEvents,
                    onEventTap: handleEventTap
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewMode)
    }
    
    // MARK: - Helper Functions
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func previousPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let calendar = Calendar.current
            switch viewMode {
            case .day:
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            case .agenda:
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            }
        }
    }
    
    private func nextPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let calendar = Calendar.current
            switch viewMode {
            case .day:
                selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            case .agenda:
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            }
        }
    }
    
    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Date()
        }
    }
    
    private func createNewEvent() {
        selectedTimeSlot = selectedDate
        showingEventCreator = true
    }
    
    private func handleTimeSlotTap(date: Date) {
        selectedTimeSlot = date
        showingEventCreator = true
    }
    
    private func handleEventTap(event: CalendarEvent) {
        eventToEdit = event
        showingEventCreator = true
    }
    
    private func handleDateTap(date: Date) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = date
            viewMode = .day
        }
    }
    
    // MARK: - Data Helpers
    
    private var miniCalendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var periodTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        case .week:
            let startWeek = startOfWeek(selectedDate)
            let endWeek = Calendar.current.date(byAdding: .day, value: 6, to: startWeek)!
            return "\(startWeek.formatted(.dateTime.month().day())) - \(endWeek.formatted(.dateTime.month().day().year()))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        case .agenda:
            return "Upcoming Events"
        }
        return formatter.string(from: selectedDate)
    }
    
    private func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return events.contains { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func eventsForWeek(_ date: Date) -> [CalendarEvent] {
        let startWeek = startOfWeek(date)
        let endWeek = Calendar.current.date(byAdding: .day, value: 6, to: startWeek)!
        
        return events.filter { event in
            event.startDate >= startWeek && event.startDate <= endWeek
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private var upcomingEvents: [CalendarEvent] {
        let now = Date()
        return events.filter { event in
            event.startDate >= now
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func startOfWeek(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func loadSampleEvents() {
        // Sample events for demonstration
        let calendar = Calendar.current
        let today = Date()
        
        events = [
            CalendarEvent(
                id: UUID(),
                title: "Team Standup",
                startDate: calendar.date(byAdding: .hour, value: 2, to: today)!,
                endDate: calendar.date(byAdding: .hour, value: 3, to: today)!,
                category: .work,
                location: "Conference Room A"
            ),
            CalendarEvent(
                id: UUID(),
                title: "Lunch with Sarah",
                startDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 1, to: calendar.date(byAdding: .hour, value: 1, to: today)!)!,
                category: .personal,
                location: "Downtown Cafe"
            ),
            CalendarEvent(
                id: UUID(),
                title: "Product Review",
                startDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 2, to: calendar.date(byAdding: .hour, value: 2, to: today)!)!,
                category: .work,
                location: "Zoom"
            )
        ]
    }
}

// MARK: - Supporting Types

enum CalendarViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case agenda = "Agenda"
    
    var title: String {
        return self.rawValue
    }
}

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var category: EventCategory
    var location: String?
    var notes: String?
    var isAllDay: Bool = false
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, category: EventCategory, location: String? = nil, notes: String? = nil, isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case travel = "Travel"
    case social = "Social"
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .green
        case .health: return .red
        case .travel: return .orange
        case .social: return .purple
        }
    }
}

// MARK: - Mini Calendar Day View

struct MiniCalendarDayView: View {
    let date: Date
    let selectedDate: Date
    let currentDate: Date
    let hasEvents: Bool
    let onTap: () -> Void
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? DesignSystem.Colors.primary : (isToday ? DesignSystem.Colors.primary.opacity(0.2) : Color.clear))
                
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : (isToday ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary))
                    
                    if hasEvents {
                        Circle()
                            .fill(isSelected ? .white : DesignSystem.Colors.primary)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 24)
    }
}

// MARK: - Event Creator View (Placeholder)

struct EventCreatorView: View {
    @Binding var events: [CalendarEvent]
    let initialDate: Date
    let eventToEdit: CalendarEvent?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var category: EventCategory = .work
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { 
                    dismiss() 
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text(eventToEdit == nil ? "New Event" : "Edit Event")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Save") { 
                    saveEvent() 
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(.regularMaterial, in: Rectangle())
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
            
            // Content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Event Title")
                            .font(DesignSystem.Typography.captionSemibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        TextField("Enter event title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Date & Time")
                            .font(DesignSystem.Typography.captionSemibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Start")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                DatePicker("", selection: $startDate)
                                    .datePickerStyle(.compact)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("End")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                DatePicker("", selection: $endDate)
                                    .datePickerStyle(.compact)
                            }
                        }
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Category")
                            .font(DesignSystem.Typography.captionSemibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Picker("Category", selection: $category) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 12, height: 12)
                                    Text(category.rawValue)
                                }.tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Location")
                            .font(DesignSystem.Typography.captionSemibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        TextField("Enter location (optional)", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Notes")
                            .font(DesignSystem.Typography.captionSemibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        TextField("Enter notes (optional)", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .frame(minHeight: 60)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        if let event = eventToEdit {
            title = event.title
            startDate = event.startDate
            endDate = event.endDate
            category = event.category
            location = event.location ?? ""
            notes = event.notes ?? ""
        } else {
            startDate = initialDate
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: initialDate) ?? initialDate
        }
    }
    
    private func saveEvent() {
        let event = CalendarEvent(
            id: eventToEdit?.id ?? UUID(),
            title: title,
            startDate: startDate,
            endDate: endDate,
            category: category,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        
        if let editIndex = events.firstIndex(where: { $0.id == eventToEdit?.id }) {
            events[editIndex] = event
        } else {
            events.append(event)
        }
        
        dismiss()
    }
}

// MARK: - Calendar View Components (Placeholders for now)

struct DayView: View {
    let date: Date
    let events: [CalendarEvent]
    let currentTime: Date
    let onTimeSlotTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // All-day events section
            if allDayEvents.count > 0 {
                allDayEventsSection
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(.ultraThinMaterial, in: Rectangle())
            }
            
            // Hourly timeline
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            HourSlotView(
                                hour: hour,
                                date: date,
                                events: eventsForHour(hour),
                                currentTime: currentTime,
                                isToday: Calendar.current.isDateInToday(date),
                                onTimeSlotTap: onTimeSlotTap,
                                onEventTap: onEventTap
                            )
                            .id("hour-\(hour)")
                        }
                    }
                }
                .onAppear {
                    // Scroll to current hour if viewing today
                    if Calendar.current.isDateInToday(date) {
                        let currentHour = Calendar.current.component(.hour, from: currentTime)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("hour-\(max(0, currentHour - 2))", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var allDayEvents: [CalendarEvent] {
        events.filter { $0.isAllDay }
    }
    
    private var timedEvents: [CalendarEvent] {
        events.filter { !$0.isAllDay }
    }
    
    private var allDayEventsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("All Day")
                .font(DesignSystem.Typography.captionSemibold)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ForEach(allDayEvents) { event in
                Button(action: { onEventTap(event) }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(event.category.color)
                            .frame(width: 8, height: 8)
                        
                        Text(event.title)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(event.category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        timedEvents.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}

struct HourSlotView: View {
    let hour: Int
    let date: Date
    let events: [CalendarEvent]
    let currentTime: Date
    let isToday: Bool
    let onTimeSlotTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    @State private var isHovered = false
    
    private var hourDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }
    
    private var isCurrentHour: Bool {
        isToday && Calendar.current.component(.hour, from: currentTime) == hour
    }
    
    private var currentTimeIndicatorPosition: CGFloat {
        guard isCurrentHour else { return 0 }
        let minutes = Calendar.current.component(.minute, from: currentTime)
        return CGFloat(minutes) / 60.0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Time label
            VStack {
                Text(hourString)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(isCurrentHour ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                Spacer()
            }
            .frame(width: 60)
            .padding(.top, DesignSystem.Spacing.xs)
            
            // Time slot area
            ZStack(alignment: .topLeading) {
                // Background
                Rectangle()
                    .fill(
                        isCurrentHour ? DesignSystem.Colors.primary.opacity(0.05) :
                        isHovered ? DesignSystem.Colors.surface.opacity(0.3) :
                        Color.clear
                    )
                    .frame(height: 60)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(DesignSystem.Colors.surface),
                        alignment: .top
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTimeSlotTap(hourDate)
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovered = hovering
                        }
                    }
                
                // Current time indicator
                if isCurrentHour {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(height: 2)
                    }
                    .offset(y: currentTimeIndicatorPosition * 60)
                    .zIndex(10)
                }
                
                // Events
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventBlockView(
                        event: event,
                        onEventTap: onEventTap
                    )
                    .offset(x: CGFloat(index * 4)) // Slight offset for overlapping events
                }
            }
        }
        .frame(height: 60)
    }
    
    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: hourDate)
    }
}

struct EventBlockView: View {
    let event: CalendarEvent
    let onEventTap: (CalendarEvent) -> Void
    
    var body: some View {
        Button(action: { onEventTap(event) }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(event.category.color, in: RoundedRectangle(cornerRadius: 4))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .frame(height: eventHeight)
    }
    
    private var eventHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return max(24, CGFloat(hours) * 60) // Minimum 24pt height
    }
}

struct WeekView: View {
    let startDate: Date
    let events: [CalendarEvent]
    let currentTime: Date
    let onTimeSlotTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    private var weekDays: [Date] {
        var days: [Date] = []
        for i in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                days.append(day)
            }
        }
        return days
    }
    
    private var allDayEvents: [CalendarEvent] {
        events.filter { $0.isAllDay }
    }
    
    private var timedEvents: [CalendarEvent] {
        events.filter { !$0.isAllDay }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header with day names and dates
            weekHeader
                .background(.ultraThinMaterial, in: Rectangle())
            
            // All-day events section
            if allDayEvents.count > 0 {
                allDayEventsSection
                    .background(.ultraThinMaterial, in: Rectangle())
            }
            
            // Hourly timeline
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            WeekHourSlotView(
                                hour: hour,
                                weekDays: weekDays,
                                events: eventsForHour(hour),
                                currentTime: currentTime,
                                onTimeSlotTap: onTimeSlotTap,
                                onEventTap: onEventTap
                            )
                            .id("hour-\(hour)")
                        }
                    }
                }
                .onAppear {
                    // Scroll to current hour if viewing current week
                    if Calendar.current.isDate(Date(), equalTo: startDate, toGranularity: .weekOfYear) {
                        let currentHour = Calendar.current.component(.hour, from: currentTime)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("hour-\(max(0, currentHour - 2))", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var weekHeader: some View {
        HStack(spacing: 0) {
            // Time column header
            VStack {
                Spacer()
            }
            .frame(width: 60)
            
            // Day headers
            ForEach(weekDays, id: \.self) { day in
                Button(action: {
                    // Create a date at the start of the day
                    let dayStart = Calendar.current.startOfDay(for: day)
                    onTimeSlotTap(dayStart)
                }) {
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(
                                Calendar.current.isDateInToday(day) ? .white : DesignSystem.Colors.textPrimary
                            )
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Calendar.current.isDateInToday(day) ? DesignSystem.Colors.primary : Color.clear)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var allDayEventsSection: some View {
        HStack(spacing: 0) {
            // Time column placeholder
            VStack {
                Text("all-day")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Spacer()
            }
            .frame(width: 60)
            
            // All-day events for each day
            ForEach(weekDays, id: \.self) { day in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(allDayEventsForDay(day)) { event in
                        Button(action: { onEventTap(event) }) {
                            Text(event.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(event.category.color, in: RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32)
                .frame(alignment: .top)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func allDayEventsForDay(_ day: Date) -> [CalendarEvent] {
        allDayEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: day)
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        timedEvents.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}

struct WeekHourSlotView: View {
    let hour: Int
    let weekDays: [Date]
    let events: [CalendarEvent]
    let currentTime: Date
    let onTimeSlotTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    @State private var hoveredDay: Date? = nil
    
    private var hourString: String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
    
    private var isCurrentHour: Bool {
        Calendar.current.component(.hour, from: currentTime) == hour
    }
    
    private var currentTimeIndicatorPosition: CGFloat {
        guard isCurrentHour else { return 0 }
        let minutes = Calendar.current.component(.minute, from: currentTime)
        return CGFloat(minutes) / 60.0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Time label
            VStack {
                Text(hourString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCurrentHour ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                Spacer()
            }
            .frame(width: 60)
            .padding(.top, DesignSystem.Spacing.xs)
            
            // Day columns
            ForEach(weekDays, id: \.self) { day in
                let dayEvents = eventsForDay(day)
                let isToday = Calendar.current.isDateInToday(day)
                let hourDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
                let isHovered = hoveredDay == day
                
                ZStack(alignment: .topLeading) {
                    // Background
                    Rectangle()
                        .fill(
                            isToday && isCurrentHour ? DesignSystem.Colors.primary.opacity(0.05) :
                            isHovered ? DesignSystem.Colors.surface.opacity(0.3) :
                            Color.clear
                        )
                        .frame(height: 60)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(DesignSystem.Colors.surface),
                            alignment: .top
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 0.5)
                                .foregroundColor(DesignSystem.Colors.surface.opacity(0.5)),
                            alignment: .trailing
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTimeSlotTap(hourDate)
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredDay = hovering ? day : nil
                            }
                        }
                    
                    // Current time indicator (only for today)
                    if isToday && isCurrentHour {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 6, height: 6)
                            
                            Rectangle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(height: 2)
                        }
                        .offset(y: currentTimeIndicatorPosition * 60)
                        .zIndex(10)
                    }
                    
                    // Events
                    ForEach(Array(dayEvents.enumerated()), id: \.element.id) { index, event in
                        WeekEventBlockView(
                            event: event,
                            onEventTap: onEventTap
                        )
                        .offset(x: CGFloat(index * 2)) // Slight offset for overlapping events
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 60)
    }
    
    private func eventsForDay(_ day: Date) -> [CalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: day)
        }
    }
}

struct WeekEventBlockView: View {
    let event: CalendarEvent
    let onEventTap: (CalendarEvent) -> Void
    
    var body: some View {
        Button(action: { onEventTap(event) }) {
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(event.category.color, in: RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .frame(height: eventHeight)
    }
    
    private var eventHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return max(20, CGFloat(hours) * 60) // Minimum 20pt height for week view
    }
}

struct MonthView: View {
    let date: Date
    let events: [CalendarEvent]
    let currentTime: Date
    let onDateTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthDays: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete the grid (6 weeks max)
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            weekdayHeaderView
                .background(.ultraThinMaterial, in: Rectangle())
            
            // Calendar grid
            calendarGrid
        }
    }
    
    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdayHeaders, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { index, day in
                MonthDayCell(
                    date: day,
                    events: day != nil ? eventsForDate(day!) : [],
                    isToday: day != nil && calendar.isDateInToday(day!),
                    isCurrentMonth: day != nil && calendar.isDate(day!, equalTo: date, toGranularity: .month),
                    onDateTap: onDateTap,
                    onEventTap: onEventTap
                )
                .frame(height: 100)
                .border(DesignSystem.Colors.surface.opacity(0.3), width: 0.5)
            }
        }
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }.sorted { $0.startDate < $1.startDate }
    }
}

struct MonthDayCell: View {
    let date: Date?
    let events: [CalendarEvent]
    let isToday: Bool
    let isCurrentMonth: Bool
    let onDateTap: (Date) -> Void
    let onEventTap: (CalendarEvent) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 2) {
            if let date = date {
                // Date number
                HStack {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(
                            isToday ? .white :
                            isCurrentMonth ? DesignSystem.Colors.textPrimary :
                            DesignSystem.Colors.textTertiary
                        )
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(isToday ? DesignSystem.Colors.primary : Color.clear)
                        )
                    
                    Spacer()
                }
                
                // Events (max 3 visible)
                VStack(spacing: 1) {
                    ForEach(Array(events.prefix(3).enumerated()), id: \.element.id) { index, event in
                        MonthEventView(event: event, onEventTap: onEventTap)
                    }
                    
                    // More events indicator
                    if events.count > 3 {
                        HStack {
                            Text("+\(events.count - 3) more")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
        .background(
            Rectangle()
                .fill(
                    isHovered ? DesignSystem.Colors.surface.opacity(0.5) :
                    isCurrentMonth ? Color.clear :
                    DesignSystem.Colors.surface.opacity(0.1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let date = date {
                onDateTap(date)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct MonthEventView: View {
    let event: CalendarEvent
    let onEventTap: (CalendarEvent) -> Void
    
    var body: some View {
        Button(action: { onEventTap(event) }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(event.category.color)
                    .frame(width: 6, height: 6)
                
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.category.color.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

struct YearView: View {
    let year: Int
    let events: [CalendarEvent]
    @Binding var selectedDate: Date
    let onDateTap: (Date) -> Void
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthsOfYear: [Date] {
        var months: [Date] = []
        for month in 1...12 {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) {
                months.append(date)
            }
        }
        return months
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 3), spacing: DesignSystem.Spacing.lg) {
                ForEach(monthsOfYear, id: \.self) { month in
                    YearMonthView(
                        month: month,
                        events: eventsForMonth(month),
                        selectedDate: $selectedDate,
                        onDateTap: onDateTap
                    )
                    .frame(height: 180) // Fixed height for consistency
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
    
    private func eventsForMonth(_ month: Date) -> [CalendarEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, equalTo: month, toGranularity: .month)
        }
    }
}

struct YearMonthView: View {
    let month: Date
    let events: [CalendarEvent]
    @Binding var selectedDate: Date
    let onDateTap: (Date) -> Void
    
    @State private var isHovered = false
    private var calendar: Calendar { Calendar.current }
    
    private var monthDays: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Month header
            Button(action: {
                onDateTap(month)
            }) {
                Text(monthFormatter.string(from: month))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(isHovered ? DesignSystem.Colors.surface.opacity(0.5) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            
            // Weekday headers (abbreviated)
            HStack(spacing: 2) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 12)
                }
            }
            
            // Mini calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { index, day in
                    YearDayCell(
                        date: day,
                        hasEvents: day != nil && hasEventsOnDate(day!),
                        isToday: day != nil && calendar.isDateInToday(day!),
                        isSelected: day != nil && calendar.isDate(day!, inSameDayAs: selectedDate),
                        onDateTap: onDateTap
                    )
                    .frame(height: 18) // Fixed height for day cells
                }
            }
            .frame(maxHeight: .infinity) // Allow grid to expand to fill remaining space
            
            Spacer(minLength: 0) // Push everything to top but allow flexibility
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func hasEventsOnDate(_ date: Date) -> Bool {
        events.contains { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

struct YearDayCell: View {
    let date: Date?
    let hasEvents: Bool
    let isToday: Bool
    let isSelected: Bool
    let onDateTap: (Date) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Group {
            if let date = date {
                Button(action: { onDateTap(date) }) {
                    ZStack {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(
                                isToday ? .white :
                                isSelected ? DesignSystem.Colors.primary :
                                DesignSystem.Colors.textPrimary
                            )
                        
                        // Event indicator
                        if hasEvents {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(isToday ? .white : DesignSystem.Colors.primary)
                                        .frame(width: 3, height: 3)
                                }
                            }
                        }
                    }
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(
                                isToday ? DesignSystem.Colors.primary :
                                isSelected ? DesignSystem.Colors.primary.opacity(0.2) :
                                isHovered ? DesignSystem.Colors.surface.opacity(0.5) :
                                Color.clear
                            )
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                    }
                }
            } else {
                // Empty cell for padding
                Color.clear
                    .frame(width: 18, height: 18)
            }
        }
    }
}

struct AgendaView: View {
    let events: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Upcoming Events")
                    .font(DesignSystem.Typography.headline3)
                    .padding(.horizontal)
                
                ForEach(events.prefix(20)) { event in
                    Button(action: { onEventTap(event) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(DesignSystem.Typography.bodySemibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text(event.startDate.formatted(.dateTime.weekday().month().day().hour().minute()))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                if let location = event.location {
                                    Text(location)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textTertiary)
                                }
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(event.category.color)
                                .frame(width: 12, height: 12)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}