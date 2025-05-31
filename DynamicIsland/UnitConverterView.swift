import SwiftUI
import Foundation

struct UnitConverterView: View {
    @State private var selectedCategory: ConverterCategory = .length
    @State private var fromValue: String = "1"
    @State private var fromUnit: ConversionUnit = .meter
    @State private var toUnit: ConversionUnit = .feet
    @State private var isEditingInput = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Category Selector
            categorySelector
            
            // Conversion Interface
            conversionInterface
            
            // Quick Conversion Buttons
            quickConversions
            
            // Popular Conversions
            popularConversions
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .onChange(of: selectedCategory) { _, newCategory in
            // Reset to default units when category changes
            resetToDefaults(for: newCategory)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(ConverterCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(DesignSystem.Animation.gentle) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }
    
    private var conversionInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // From Unit
            ConversionRow(
                title: "From",
                value: $fromValue,
                unit: $fromUnit,
                availableUnits: availableUnits,
                isEditing: $isEditingInput,
                result: nil
            )
            
            // Swap Button
            swapButton
            
            // To Unit
            ConversionRow(
                title: "To",
                value: .constant(convertedValue),
                unit: $toUnit,
                availableUnits: availableUnits,
                isEditing: .constant(false),
                result: convertedValue
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(DesignSystem.Colors.surface.opacity(0.3))
        )
    }
    
    private var swapButton: some View {
        Button(action: swapUnits) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(0.9)
    }
    
    private var quickConversions: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Quick Values")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(quickValues, id: \.self) { value in
                        QuickValueButton(value: value) {
                            fromValue = value
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
            }
        }
    }
    
    private var popularConversions: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Popular")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: DesignSystem.Spacing.xxs) {
                ForEach(Array(popularConversionsForCategory.enumerated()), id: \.offset) { index, conversion in
                    PopularConversionRow(
                        from: conversion.0,
                        to: conversion.1,
                        isSelected: fromUnit == conversion.0 && toUnit == conversion.1
                    ) {
                        fromUnit = conversion.0
                        toUnit = conversion.1
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableUnits: [ConversionUnit] {
        selectedCategory.units
    }
    
    private var convertedValue: String {
        guard let inputValue = Double(fromValue) else { return "0" }
        let converted = fromUnit.convert(inputValue, to: toUnit)
        return formatNumber(converted)
    }
    
    private var quickValues: [String] {
        switch selectedCategory {
        case .length: return ["1", "5", "10", "25", "50", "100"]
        case .weight: return ["1", "2.5", "5", "10", "25", "50"]
        case .temperature: return ["0", "20", "25", "32", "100"]
        case .currency: return ["1", "10", "50", "100", "500", "1000"]
        }
    }
    
    private var popularConversionsForCategory: [(ConversionUnit, ConversionUnit)] {
        switch selectedCategory {
        case .length:
            return [(.meter, .feet), (.kilometer, .mile), (.centimeter, .inch), (.yard, .meter)]
        case .weight:
            return [(.kilogram, .pound), (.gram, .ounce), (.pound, .kilogram), (.ounce, .gram)]
        case .temperature:
            return [(.celsius, .fahrenheit), (.fahrenheit, .celsius), (.celsius, .kelvin)]
        case .currency:
            return [(.usd, .eur), (.usd, .gbp), (.eur, .usd), (.gbp, .usd)]
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetToDefaults(for category: ConverterCategory) {
        let defaults = category.defaultUnits
        fromUnit = defaults.0
        toUnit = defaults.1
        fromValue = "1"
    }
    
    private func swapUnits() {
        let temp = fromUnit
        fromUnit = toUnit
        toUnit = temp
        
        // Also swap the values
        fromValue = convertedValue
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        
        if abs(number) >= 1000000 {
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 2
        } else if abs(number) < 0.001 && number != 0 {
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 2
        }
        
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: ConverterCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(category.title)
                    .font(DesignSystem.Typography.micro)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isSelected ? category.color : DesignSystem.Colors.surface.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ConversionRow: View {
    let title: String
    @Binding var value: String
    @Binding var unit: ConversionUnit
    let availableUnits: [ConversionUnit]
    @Binding var isEditing: Bool
    let result: String?
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Title
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 30, alignment: .leading)
            
            // Value Input
            if result == nil {
                TextField("0", text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.trailing)
                    .onTapGesture {
                        isEditing = true
                    }
            } else {
                Text(result ?? "0")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Unit Selector
            Menu {
                ForEach(availableUnits, id: \.rawValue) { unitOption in
                    Button(action: {
                        unit = unitOption
                    }) {
                        HStack {
                            Text(unitOption.displayName)
                            if unit == unitOption {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Text(unit.symbol)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                        .fill(DesignSystem.Colors.surface.opacity(0.5))
                )
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)
        }
    }
}

struct QuickValueButton: View {
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                        .fill(DesignSystem.Colors.surface.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }
}

struct PopularConversionRow: View {
    let from: ConversionUnit
    let to: ConversionUnit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(from.symbol) → \(to.symbol)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Models

enum ConverterCategory: CaseIterable {
    case length, weight, temperature, currency
    
    var title: String {
        switch self {
        case .length: return "Length"
        case .weight: return "Weight"
        case .temperature: return "Temp"
        case .currency: return "Currency"
        }
    }
    
    var icon: String {
        switch self {
        case .length: return "ruler"
        case .weight: return "scalemass"
        case .temperature: return "thermometer"
        case .currency: return "dollarsign.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .length: return DesignSystem.Colors.primary
        case .weight: return DesignSystem.Colors.success
        case .temperature: return DesignSystem.Colors.warning
        case .currency: return DesignSystem.Colors.clipboard
        }
    }
    
    var units: [ConversionUnit] {
        switch self {
        case .length: return ConversionUnit.lengthUnits
        case .weight: return ConversionUnit.weightUnits
        case .temperature: return ConversionUnit.temperatureUnits
        case .currency: return ConversionUnit.currencyUnits
        }
    }
    
    var defaultUnits: (ConversionUnit, ConversionUnit) {
        switch self {
        case .length: return (.meter, .feet)
        case .weight: return (.kilogram, .pound)
        case .temperature: return (.celsius, .fahrenheit)
        case .currency: return (.usd, .eur)
        }
    }
}

enum ConversionUnit: String, CaseIterable {
    // Length
    case meter = "m"
    case kilometer = "km"
    case centimeter = "cm"
    case millimeter = "mm"
    case inch = "in"
    case feet = "ft"
    case yard = "yd"
    case mile = "mi"
    case nauticalMile = "nmi"
    
    // Weight
    case kilogram = "kg"
    case gram = "g"
    case pound = "lb"
    case ounce = "oz"
    case stone = "st"
    case ton = "t"
    
    // Temperature
    case celsius = "°C"
    case fahrenheit = "°F"
    case kelvin = "K"
    
    // Currency (simplified)
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    
    var symbol: String { rawValue }
    
    var displayName: String {
        switch self {
        case .meter: return "Meters"
        case .kilometer: return "Kilometers"
        case .centimeter: return "Centimeters"
        case .millimeter: return "Millimeters"
        case .inch: return "Inches"
        case .feet: return "Feet"
        case .yard: return "Yards"
        case .mile: return "Miles"
        case .nauticalMile: return "Nautical Miles"
        case .kilogram: return "Kilograms"
        case .gram: return "Grams"
        case .pound: return "Pounds"
        case .ounce: return "Ounces"
        case .stone: return "Stones"
        case .ton: return "Tons"
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        case .kelvin: return "Kelvin"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        }
    }
    
    static var lengthUnits: [ConversionUnit] {
        [.millimeter, .centimeter, .meter, .kilometer, .inch, .feet, .yard, .mile, .nauticalMile]
    }
    
    static var weightUnits: [ConversionUnit] {
        [.gram, .kilogram, .ounce, .pound, .stone, .ton]
    }
    
    static var temperatureUnits: [ConversionUnit] {
        [.celsius, .fahrenheit, .kelvin]
    }
    
    static var currencyUnits: [ConversionUnit] {
        [.usd, .eur, .gbp, .jpy, .cad, .aud, .chf, .cny]
    }
    
    func convert(_ value: Double, to targetUnit: ConversionUnit) -> Double {
        // Convert to base unit first, then to target
        let baseValue = convertToBase(value)
        return targetUnit.convertFromBase(baseValue)
    }
    
    private func convertToBase(_ value: Double) -> Double {
        switch self {
        // Length (base: meter)
        case .meter: return value
        case .kilometer: return value * 1000
        case .centimeter: return value * 0.01
        case .millimeter: return value * 0.001
        case .inch: return value * 0.0254
        case .feet: return value * 0.3048
        case .yard: return value * 0.9144
        case .mile: return value * 1609.344
        case .nauticalMile: return value * 1852
            
        // Weight (base: gram)
        case .gram: return value
        case .kilogram: return value * 1000
        case .ounce: return value * 28.3495
        case .pound: return value * 453.592
        case .stone: return value * 6350.29
        case .ton: return value * 1000000
            
        // Temperature (base: celsius)
        case .celsius: return value
        case .fahrenheit: return (value - 32) * 5/9
        case .kelvin: return value - 273.15
            
        // Currency (simplified rates - real app would use API)
        case .usd: return value
        case .eur: return value * 1.1 // Simplified rate
        case .gbp: return value * 1.25
        case .jpy: return value * 0.007
        case .cad: return value * 0.75
        case .aud: return value * 0.65
        case .chf: return value * 1.05
        case .cny: return value * 0.14
        }
    }
    
    private func convertFromBase(_ baseValue: Double) -> Double {
        switch self {
        // Length (from meter)
        case .meter: return baseValue
        case .kilometer: return baseValue / 1000
        case .centimeter: return baseValue / 0.01
        case .millimeter: return baseValue / 0.001
        case .inch: return baseValue / 0.0254
        case .feet: return baseValue / 0.3048
        case .yard: return baseValue / 0.9144
        case .mile: return baseValue / 1609.344
        case .nauticalMile: return baseValue / 1852
            
        // Weight (from gram)
        case .gram: return baseValue
        case .kilogram: return baseValue / 1000
        case .ounce: return baseValue / 28.3495
        case .pound: return baseValue / 453.592
        case .stone: return baseValue / 6350.29
        case .ton: return baseValue / 1000000
            
        // Temperature (from celsius)
        case .celsius: return baseValue
        case .fahrenheit: return (baseValue * 9/5) + 32
        case .kelvin: return baseValue + 273.15
            
        // Currency (from USD)
        case .usd: return baseValue
        case .eur: return baseValue / 1.1
        case .gbp: return baseValue / 1.25
        case .jpy: return baseValue / 0.007
        case .cad: return baseValue / 0.75
        case .aud: return baseValue / 0.65
        case .chf: return baseValue / 1.05
        case .cny: return baseValue / 0.14
        }
    }
} 