import SwiftUI
import Foundation
import MapKit

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentTime = Date()
    @State private var showWorldClock = false
    @State private var selectedWorldTimeZone: WorldTimeZone?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Current Time Display
                currentTimeSection
                
                // Toggle between Calendar and World Clock
                viewToggle
                
                if showWorldClock {
                    // World Time Visualization
                    worldTimeSection
                } else {
                    // Calendar View
                    calendarSection
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Current Time Section
    
    private var currentTimeSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Current Time")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            
            HStack {
                Text(formatTimeWithSeconds(currentTime))
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentTime, style: .date)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(TimeZone.current.localizedName(for: .shortStandard, locale: .current) ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium // This includes seconds
        return formatter.string(from: date)
    }
    
    // MARK: - View Toggle
    
    private var viewToggle: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showWorldClock = false
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                    Text("Calendar")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(showWorldClock ? DesignSystem.Colors.textSecondary : .white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .fill(showWorldClock ? .clear : .orange)
                )
            }
            .buttonStyle(.plain)
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showWorldClock = true
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "globe")
                        .font(.system(size: 12, weight: .medium))
                    Text("World Time")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(!showWorldClock ? DesignSystem.Colors.textSecondary : .white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .fill(!showWorldClock ? .clear : .orange)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            calendarGrid
            
            if !Calendar.current.isDateInToday(selectedDate) {
                selectedDateInfo
            }
        }
    }
    
    private var calendarGrid: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Month/Year Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Days of Week
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Calendar Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: DesignSystem.Spacing.xs) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 32)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var selectedDateInfo: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Selected Date")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            
            Text(selectedDate, format: .dateTime.weekday(.wide).month().day().year())
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - World Time Section
    
    private var worldTimeSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("World Time Zones")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Interactive World Map with Day/Night Shadow
            interactiveWorldMap
            
            // Selected Time Zone Display
            if let selectedTimeZone = selectedWorldTimeZone {
                selectedTimeZoneDisplay(selectedTimeZone)
            }
            
            // Quick Access Time Zone Cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                ForEach(worldTimeZones.prefix(4), id: \.name) { timeZone in
                    WorldTimeCard(worldTimeZone: timeZone, currentTime: currentTime)
                }
            }
        }
    }
    
    private var interactiveWorldMap: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Interactive World Map")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("Tap regions to explore")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            // Real Apple MapKit World Map
            WorldMapView(
                selectedTimeZone: $selectedWorldTimeZone,
                currentTime: currentTime
            )
            .frame(height: 200)
            .cornerRadius(DesignSystem.BorderRadius.md)
            
            // Legend
            HStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(.yellow.opacity(0.8))
                        .frame(width: 8, height: 8)
                    Text("Daytime")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Rectangle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .cornerRadius(2)
                    Text("Nighttime")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Text("Updated: \(formatTimeWithSeconds(currentTime))")
                    .font(.system(size: 9))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    

    
    private func selectedTimeZoneDisplay(_ timeZone: WorldTimeZone) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(timeZone.color)
                
                Text("Selected: \(timeZone.name)")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedWorldTimeZone = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local Time")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text(formatTimeWithSecondsForTimeZone(currentTime, in: timeZone.timeZone))
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(isDaytimeInTimeZone(timeZone) ? "Daytime" : "Nighttime")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isDaytimeInTimeZone(timeZone) ? .orange : .purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                                                 .background(
                             Capsule()
                                 .fill((isDaytimeInTimeZone(timeZone) ? Color.orange : Color.purple).opacity(0.2))
                         )
                    
                    Text(offsetFormatterForTimeZone(timeZone))
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(timeZone.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .stroke(timeZone.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTimeWithSecondsForTimeZone(_ date: Date, in timeZone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.timeZone = timeZone ?? TimeZone.current
        return formatter.string(from: date)
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
    
    // MARK: - Calendar Logic
    
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
    
    // MARK: - World Time Data
    
    private var worldTimeZones: [WorldTimeZone] {
        [
            WorldTimeZone(name: "New York", identifier: "America/New_York", color: .blue),
            WorldTimeZone(name: "London", identifier: "Europe/London", color: .green),
            WorldTimeZone(name: "Tokyo", identifier: "Asia/Tokyo", color: .purple),
            WorldTimeZone(name: "Sydney", identifier: "Australia/Sydney", color: .orange),
            WorldTimeZone(name: "Dubai", identifier: "Asia/Dubai", color: .pink),
            WorldTimeZone(name: "Los Angeles", identifier: "America/Los_Angeles", color: .cyan),
            WorldTimeZone(name: "Mumbai", identifier: "Asia/Kolkata", color: .indigo),
            WorldTimeZone(name: "São Paulo", identifier: "America/Sao_Paulo", color: .mint)
        ]
    }
    

}



// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .semibold : .medium))
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? .orange :
                    isCurrentMonth ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textTertiary
                )
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected ? .orange :
                            isToday ? .orange.opacity(0.2) : .clear
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday && !isSelected ? .orange.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - World Time Models

struct WorldTimeZone {
    let name: String
    let identifier: String
    let color: Color
    
         func currentTime(from baseTime: Date) -> Date {
         guard let timeZone = TimeZone(identifier: identifier) else { return baseTime }
         let calendar = Calendar.current
         let components = calendar.dateComponents(in: timeZone, from: baseTime)
        return calendar.date(from: components) ?? baseTime
    }
    
    var timeZone: TimeZone? {
        TimeZone(identifier: identifier)
    }
}

// MARK: - World Time Card

struct WorldTimeCard: View {
    let worldTimeZone: WorldTimeZone
    let currentTime: Date
    
    private var timeInZone: Date {
        worldTimeZone.currentTime(from: currentTime)
    }
    
    private var offsetFormatter: String {
        guard let timeZone = worldTimeZone.timeZone else { return "" }
        let offset = timeZone.secondsFromGMT() / 3600
        let sign = offset >= 0 ? "+" : ""
        return "GMT\(sign)\(offset)"
    }
    
    private var isDaytime: Bool {
        guard let timeZone = worldTimeZone.timeZone else { return true }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: currentTime)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 18
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Circle()
                    .fill(worldTimeZone.color)
                    .frame(width: 8, height: 8)
                
                Text(worldTimeZone.name)
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Day/Night indicator
                Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isDaytime ? .orange : .purple)
            }
            
            HStack {
                Text(formatTimeWithSecondsInZone(currentTime, timeZone: worldTimeZone.timeZone))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            HStack {
                Text(offsetFormatter)
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTimeWithSecondsInZone(_ date: Date, timeZone: TimeZone?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium // Shows seconds
        formatter.timeZone = timeZone ?? TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - MapKit World Map View

struct WorldMapView: NSViewRepresentable {
    @Binding var selectedTimeZone: WorldTimeZone?
    let currentTime: Date
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsCompass = false
        mapView.showsZoomControls = false
        mapView.showsScale = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        // Set to show the entire world
        mapView.setVisibleMapRect(MKMapRect.world, animated: false)
        
        // Add city annotations
        let cities = [
            CityAnnotation(title: "New York", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), timeZone: "America/New_York", color: .blue),
            CityAnnotation(title: "London", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), timeZone: "Europe/London", color: .green),
            CityAnnotation(title: "Tokyo", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), timeZone: "Asia/Tokyo", color: .purple),
            CityAnnotation(title: "Sydney", coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), timeZone: "Australia/Sydney", color: .orange),
            CityAnnotation(title: "Los Angeles", coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), timeZone: "America/Los_Angeles", color: .systemTeal),
            CityAnnotation(title: "Dubai", coordinate: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708), timeZone: "Asia/Dubai", color: .systemPink)
        ]
        
        mapView.addAnnotations(cities)
        
        // Add day/night overlay
        let dayNightOverlay = DayNightOverlay(date: currentTime)
        mapView.addOverlay(dayNightOverlay)
        
        return mapView
    }
    
    func updateNSView(_ nsView: MKMapView, context: Context) {
        // Update day/night overlay
        nsView.removeOverlays(nsView.overlays)
        let dayNightOverlay = DayNightOverlay(date: currentTime)
        nsView.addOverlay(dayNightOverlay)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WorldMapView
        
        init(_ parent: WorldMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let cityAnnotation = view.annotation as? CityAnnotation else { return }
            
            // Update selected time zone
            let worldTimeZone = WorldTimeZone(
                name: cityAnnotation.title ?? "",
                identifier: cityAnnotation.timeZone,
                color: Color(cityAnnotation.color)
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                parent.selectedTimeZone = worldTimeZone
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let cityAnnotation = annotation as? CityAnnotation else { return nil }
            
            let identifier = "CityPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom pin appearance
            let pinSize: CGFloat = 12
            let pinView = NSView(frame: NSRect(x: 0, y: 0, width: pinSize, height: pinSize))
            
            let circleLayer = CALayer()
            circleLayer.frame = pinView.bounds
            circleLayer.cornerRadius = pinSize / 2
            circleLayer.backgroundColor = cityAnnotation.color.cgColor
            circleLayer.borderWidth = 2
            circleLayer.borderColor = NSColor.white.cgColor
            circleLayer.shadowColor = NSColor.black.cgColor
            circleLayer.shadowOpacity = 0.3
            circleLayer.shadowOffset = CGSize(width: 0, height: 1)
            circleLayer.shadowRadius = 2
            
            pinView.layer = CALayer()
            pinView.wantsLayer = true
            pinView.layer?.addSublayer(circleLayer)
            
            annotationView?.addSubview(pinView)
            annotationView?.frame = pinView.frame
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let dayNightOverlay = overlay as? DayNightOverlay {
                return DayNightOverlayRenderer(overlay: dayNightOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - City Annotation

class CityAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let timeZone: String
    let color: NSColor
    
    init(title: String, coordinate: CLLocationCoordinate2D, timeZone: String, color: NSColor) {
        self.title = title
        self.coordinate = coordinate
        self.timeZone = timeZone
        self.color = color
        super.init()
    }
}

// MARK: - Day/Night Overlay

class DayNightOverlay: NSObject, MKOverlay {
    let date: Date
    let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    let boundingMapRect: MKMapRect = MKMapRect.world
    
    init(date: Date) {
        self.date = date
        super.init()
    }
}

class DayNightOverlayRenderer: MKOverlayRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = self.overlay as? DayNightOverlay else { return }
        
        // Calculate solar position based on current time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: overlay.date)
        let hour = Double(components.hour ?? 12)
        let minute = Double(components.minute ?? 0)
        let timeOfDay = hour + minute / 60.0
        
        // Calculate longitude where it's solar noon (simplified)
        let solarNoonLongitude = ((timeOfDay - 12.0) / 24.0) * 360.0
        
        // Convert world coordinates to map coordinates
        let rect = self.rect(for: mapRect)
        
        // Draw night shadow (simplified - covers western hemisphere when it's night there)
        context.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        
        // Simple night/day division based on solar noon longitude
        let worldWidth = rect.width
        let nightStartX = (solarNoonLongitude + 180) / 360.0 * worldWidth
        let nightWidth = worldWidth / 2
        
        // Draw night region
        if nightStartX + nightWidth > worldWidth {
            // Night region wraps around
            context.fill(CGRect(x: 0, y: 0, width: nightStartX + nightWidth - worldWidth, height: rect.height))
            context.fill(CGRect(x: nightStartX, y: 0, width: worldWidth - nightStartX, height: rect.height))
        } else {
            context.fill(CGRect(x: nightStartX, y: 0, width: nightWidth, height: rect.height))
        }
    }
} 