import SwiftUI
import CommonCrypto
import Foundation

struct ExpandedDevToolsView: View {
    @State private var selectedTool: DeveloperTool = .jsonFormatter
    @State private var showCopiedFeedback = false
    @State private var lastCopiedText = ""
    
    // JSON Formatter
    @State private var jsonInput: String = ""
    @State private var jsonOutput: String = ""
    @State private var jsonOperation: JSONOperation = .format
    
    // Hash Generator
    @State private var hashInput: String = ""
    @State private var hashType: HashType = .sha256
    @State private var hashResult: String = ""
    @State private var isFileMode: Bool = false
    @State private var draggedFileName: String?
    @State private var fileData: Data?
    
    // Base64 Encoder/Decoder
    @State private var base64Input: String = ""
    @State private var base64Output: String = ""
    @State private var base64Mode: Base64Mode = .encode
    
    // URL Encoder/Decoder
    @State private var urlText: String = ""
    @State private var urlMode: URLMode = .encode
    @State private var urlResult: String = ""
    
    // UUID Generator
    @State private var generatedUUIDs: [String] = []
    @State private var uuidCount: Int = 1
    @State private var uuidFormat: UUIDFormat = .uppercase
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Main content area with side-by-side layout
            HStack(spacing: 0) {
                // Tool selector sidebar
                toolSidebar
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Main tool interface
                toolInterface
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.clear)
        .onChange(of: selectedTool) { _, _ in
            clearInputs()
        }
        .onAppear {
            generateUUIDs()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Tools")
                    .font(DesignSystem.Typography.headline1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(selectedTool.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Quick copy feedback
            if showCopiedFeedback {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Copied to clipboard")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(DesignSystem.Colors.success)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.success.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    // MARK: - Tool Sidebar
    
    private var toolSidebar: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            ForEach(DeveloperTool.allCases, id: \.self) { tool in
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        selectedTool = tool
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTool == tool ? .white : tool.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.displayName)
                                .font(DesignSystem.Typography.bodySemibold)
                                .foregroundColor(selectedTool == tool ? .white : DesignSystem.Colors.textPrimary)
                            
                            Text(tool.subtitle)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(selectedTool == tool ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(selectedTool == tool ? tool.color : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Tool Interface
    
    private var toolInterface: some View {
        VStack {
            switch selectedTool {
            case .jsonFormatter:
                jsonFormatterInterface
            case .hashGenerator:
                hashGeneratorInterface
            case .base64:
                base64Interface
            case .uuidGenerator:
                uuidGeneratorInterface
            case .curlGenerator:
                curlGeneratorInterface
            case .jwtDecoder:
                jwtDecoderInterface
            case .graphqlGenerator:
                graphqlGeneratorInterface
            case .apiMockup:
                apiMockupInterface
            case .yamlJsonConverter:
                yamlJsonConverterInterface
            case .textDiff:
                textDiffInterface
            case .regexTester:
                regexTesterInterface
            case .qrGenerator:
                qrGeneratorInterface
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .animation(DesignSystem.Animation.smooth, value: selectedTool)
    }
    
    // MARK: - JSON Formatter Interface
    
    private var jsonFormatterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Operation selector
            HStack {
                Text("Operation:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Operation", selection: $jsonOperation) {
                    ForEach(JSONOperation.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                Spacer()
                
                Button("Clear") {
                    jsonInput = ""
                    jsonOutput = ""
                }
                .buttonStyle_custom(.ghost)
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Input area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Input")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jsonInput.isEmpty {
                            Button("Paste") {
                                if let clipboardString = NSPasteboard.general.string(forType: .string) {
                                    jsonInput = clipboardString
                                    processJSON()
                                }
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    TextEditor(text: $jsonInput)
                        .font(.system(size: 14, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: jsonInput) { _, _ in
                            processJSON()
                        }
                }
                .frame(maxWidth: .infinity)
                
                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Output area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Output")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jsonOutput.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jsonOutput)
                            }
                            .buttonStyle_custom(.primary)
                        }
                    }
                    
                    ScrollView {
                        Text(jsonOutput.isEmpty ? "Formatted JSON will appear here..." : jsonOutput)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(jsonOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Hash Generator Interface
    
    private var hashGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Mode and hash type selectors
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Mode:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Mode", selection: $isFileMode) {
                        Text("Text").tag(false)
                        Text("File").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
                    Text("Hash Type:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Hash Type", selection: $hashType) {
                        ForEach(HashType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Input area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Input")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isFileMode {
                        // File drop area
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(draggedFileName ?? "Drop a file here")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Button("Select File") {
                                selectFile()
                            }
                            .buttonStyle_custom(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                .fill(DesignSystem.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                        .stroke(DesignSystem.Colors.border, style: StrokeStyle(lineWidth: 2, dash: [10]))
                                )
                        )
                        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                            handleFileDrop(providers)
                        }
                    } else {
                        // Text input
                        TextEditor(text: $hashInput)
                            .font(.system(size: 14, design: .monospaced))
                            .focused($isInputFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .onChange(of: hashInput) { _, _ in
                                generateHash()
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Output area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Hash (\(hashType.displayName))")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !hashResult.isEmpty {
                            Button("Copy") {
                                copyToClipboard(hashResult)
                            }
                            .buttonStyle_custom(.primary)
                        }
                    }
                    
                    ScrollView {
                        Text(hashResult.isEmpty ? "Hash will appear here..." : hashResult)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(hashResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: isFileMode) { _, _ in
            hashInput = ""
            hashResult = ""
            draggedFileName = nil
            fileData = nil
        }
        .onChange(of: hashType) { _, _ in
            if isFileMode && fileData != nil {
                generateHashFromFile()
            } else if !hashInput.isEmpty {
                generateHash()
            }
        }
    }
    
    // MARK: - Base64 Interface
    
    private var base64Interface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Mode selector
            HStack {
                Text("Operation:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Mode", selection: $base64Mode) {
                    Text("Encode").tag(Base64Mode.encode)
                    Text("Decode").tag(Base64Mode.decode)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                
                Spacer()
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Input area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Input")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $base64Input)
                        .font(.system(size: 14, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: base64Input) { _, _ in
                            processBase64()
                        }
                }
                .frame(maxWidth: .infinity)
                
                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Output area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Output")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !base64Output.isEmpty {
                            Button("Copy") {
                                copyToClipboard(base64Output)
                            }
                            .buttonStyle_custom(.primary)
                        }
                    }
                    
                    ScrollView {
                        Text(base64Output.isEmpty ? "Result will appear here..." : base64Output)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(base64Output.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.lg)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: base64Mode) { _, _ in
            processBase64()
        }
    }
    
    // MARK: - UUID Generator Interface
    
    private var uuidGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Controls
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Count:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        TextField("Count", value: $uuidCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Stepper("", value: $uuidCount, in: 1...100)
                    }
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Format:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Format", selection: $uuidFormat) {
                        ForEach(UUIDFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                Spacer()
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Button("Generate New") {
                        generateUUIDs()
                    }
                    .buttonStyle_custom(.primary)
                    
                    Button("Copy All") {
                        copyToClipboard(generatedUUIDs.joined(separator: "\n"))
                    }
                    .buttonStyle_custom(.secondary)
                }
            }
            
            // Generated UUIDs
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(generatedUUIDs.enumerated()), id: \.offset) { index, uuid in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(uuid)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .textSelection(.enabled)
                            
                            Spacer()
                            
                            Button("Copy") {
                                copyToClipboard(uuid)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                .fill(DesignSystem.Colors.surface)
                        )
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
        }
        .onChange(of: uuidCount) { _, _ in
            generateUUIDs()
        }
        .onChange(of: uuidFormat) { _, _ in
            generateUUIDs()
        }
    }
    
    // MARK: - Placeholder Interfaces (to be implemented)
    
    private var curlGeneratorInterface: some View {
        ComingSoonView(toolName: "cURL Generator")
    }
    
    private var jwtDecoderInterface: some View {
        ComingSoonView(toolName: "JWT Decoder")
    }
    
    private var graphqlGeneratorInterface: some View {
        ComingSoonView(toolName: "GraphQL Generator")
    }
    
    private var apiMockupInterface: some View {
        ComingSoonView(toolName: "API Mockup")
    }
    
    private var yamlJsonConverterInterface: some View {
        ComingSoonView(toolName: "YAML ↔ JSON Converter")
    }
    
    private var textDiffInterface: some View {
        ComingSoonView(toolName: "Text Diff")
    }
    
    private var regexTesterInterface: some View {
        ComingSoonView(toolName: "Regex Tester")
    }
    
    private var qrGeneratorInterface: some View {
        ComingSoonView(toolName: "QR Generator")
    }
    
    // MARK: - Helper Functions
    
    private func clearInputs() {
        jsonInput = ""
        jsonOutput = ""
        hashInput = ""
        hashResult = ""
        base64Input = ""
        base64Output = ""
        urlText = ""
        urlResult = ""
        draggedFileName = nil
        fileData = nil
    }
    
    private func processJSON() {
        guard !jsonInput.isEmpty else {
            jsonOutput = ""
            return
        }
        
        do {
            let data = jsonInput.data(using: .utf8) ?? Data()
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            switch jsonOperation {
            case .format:
                let formatted = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                jsonOutput = String(data: formatted, encoding: .utf8) ?? "Error formatting JSON"
            case .minify:
                let minified = try JSONSerialization.data(withJSONObject: json, options: [])
                jsonOutput = String(data: minified, encoding: .utf8) ?? "Error minifying JSON"
            case .validate:
                jsonOutput = "✅ Valid JSON"
            }
        } catch {
            jsonOutput = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func generateHash() {
        guard !hashInput.isEmpty else {
            hashResult = ""
            return
        }
        
        let data = hashInput.data(using: .utf8) ?? Data()
        hashResult = data.hashFromDeveloperTools(type: hashType)
    }
    
    private func generateHashFromFile() {
        guard let data = fileData else {
            hashResult = ""
            return
        }
        
        hashResult = data.hashFromDeveloperTools(type: hashType)
    }
    
    private func processBase64() {
        guard !base64Input.isEmpty else {
            base64Output = ""
            return
        }
        
        switch base64Mode {
        case .encode:
            let data = base64Input.data(using: .utf8) ?? Data()
            base64Output = data.base64EncodedString()
        case .decode:
            guard let data = Data(base64Encoded: base64Input) else {
                base64Output = "❌ Invalid Base64"
                return
            }
            base64Output = String(data: data, encoding: .utf8) ?? "❌ Unable to decode as UTF-8"
        }
    }
    
    private func generateUUIDs() {
        generatedUUIDs = (0..<uuidCount).map { _ in UUID().uuidString }
        switch uuidFormat {
        case .uppercase:
            break
        case .lowercase:
            generatedUUIDs = generatedUUIDs.map { $0.lowercased() }
        case .noDashes:
            generatedUUIDs = generatedUUIDs.map { $0.replacingOccurrences(of: "-", with: "") }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            draggedFileName = url.lastPathComponent
            do {
                fileData = try Data(contentsOf: url)
                generateHashFromFile()
            } catch {
                hashResult = "❌ Error reading file: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            draggedFileName = url.lastPathComponent
                            do {
                                fileData = try Data(contentsOf: url)
                                generateHashFromFile()
                            } catch {
                                hashResult = "❌ Error reading file: \(error.localizedDescription)"
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCopiedFeedback = false
        }
    }
}

// MARK: - Coming Soon View

struct ComingSoonView: View {
    let toolName: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(DesignSystem.Colors.developer)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("\(toolName)")
                    .font(DesignSystem.Typography.headline1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Coming Soon")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("This tool will be available in a future update")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Data Extension for Expanded View

extension Data {
    func hashFromDeveloperTools(type: HashType) -> String {
        switch type {
        case .md5:
            return hexString(from: md5Data())
        case .sha1:
            return hexString(from: sha1Data())
        case .sha256:
            return hexString(from: sha256Data())
        case .sha384:
            return hexString(from: sha384Data())
        case .sha512:
            return hexString(from: sha512Data())
        }
    }
    
    private func hexString(from data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    private func md5Data() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_MD5(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    
    private func sha1Data() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_SHA1(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    
    private func sha256Data() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    
    private func sha384Data() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_SHA384(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
    
    private func sha512Data() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            CC_SHA512(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
} 