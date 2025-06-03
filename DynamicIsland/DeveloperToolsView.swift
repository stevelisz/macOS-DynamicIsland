import SwiftUI
import CommonCrypto
import Foundation

struct DeveloperToolsView: View {
    @State private var selectedTool: DeveloperTool = .urlEncoder
    @State private var showCopiedFeedback = false
    @State private var lastCopiedText = ""
    
    // URL Encoder/Decoder
    @State private var urlText: String = ""
    @State private var urlMode: URLMode = .encode
    @State private var urlResult: String = ""
    
    // JWT Decoder
    @State private var jwtToken: String = ""
    @State private var jwtHeader: String = ""
    @State private var jwtPayload: String = ""
    @State private var jwtSignature: String = ""
    
    // UUID Generator
    @State private var generatedUUID: String = ""
    @State private var uuidCount: Int = 1
    @State private var uuidFormat: UUIDFormat = .uppercase
    
    // Timestamp Converter
    @State private var timestampInput: String = ""
    @State private var timestampMode: TimestampMode = .toHuman
    @State private var timestampResult: String = ""
    
    // Text Diff
    @State private var diffText1: String = ""
    @State private var diffText2: String = ""
    @State private var diffResult: [DiffLine] = []
    
    // Regex Tester
    @State private var regexPattern: String = ""
    @State private var regexText: String = ""
    @State private var regexMatches: [NSTextCheckingResult] = []
    @State private var regexFlags: Set<RegexFlag> = []
    
    // QR Code
    @State private var qrText: String = ""
    @State private var qrImage: NSImage?
    @State private var qrSize: QRSize = .medium
    
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
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Tool Selector
            toolSelector
            
            // Tool Interface
            Group {
                switch selectedTool {
                case .urlEncoder:
                    urlEncoderInterface
                case .jwtDecoder:
                    jwtDecoderInterface
                case .uuidGenerator:
                    uuidGeneratorInterface
                case .timestampConverter:
                    timestampConverterInterface
                case .textDiff:
                    textDiffInterface
                case .regexTester:
                    regexTesterInterface
                case .qrGenerator:
                    qrGeneratorInterface
                case .jsonFormatter:
                    jsonFormatterInterface
                case .hashGenerator:
                    hashGeneratorInterface
                }
            }
            .animation(DesignSystem.Animation.smooth, value: selectedTool)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .onChange(of: selectedTool) { _, _ in
            clearAllInputs()
            focusInput()
        }
        .onAppear {
            focusInput()
        }
    }
    
    // MARK: - Tool Selector
    private var toolSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(DeveloperTool.allCases, id: \.self) { tool in
                    ToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool
                    ) {
                        withAnimation(DesignSystem.Animation.gentle) {
                            selectedTool = tool
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
    }
    
    // MARK: - URL Encoder/Decoder
    private var urlEncoderInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("URL Encoder/Decoder")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Picker("Mode", selection: $urlMode) {
                    ForEach(URLMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 130)
                .onChange(of: urlMode) { _, _ in processURL() }
            }
            
            CompactInputArea(
                title: urlMode == .encode ? "Plain Text" : "Encoded URL",
                text: $urlText,
                placeholder: urlMode == .encode ? "Enter text to encode..." : "Enter URL to decode...",
                focusBinding: $isInputFocused
            )
            .onChange(of: urlText) { _, _ in processURL() }
            
            if !urlResult.isEmpty {
                CompactOutputArea(
                    title: urlMode == .encode ? "Encoded URL" : "Decoded Text",
                    text: urlResult
                ) {
                    copyToClipboard(urlResult)
                }
            }
        }
    }
    
    // MARK: - JWT Decoder
    private var jwtDecoderInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("JWT Token Decoder")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if !jwtToken.isEmpty && jwtPayload.isEmpty {
                    Text("❌ Invalid JWT")
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            
            CompactInputArea(
                title: "JWT Token",
                text: $jwtToken,
                placeholder: "Paste JWT token here...",
                focusBinding: $isInputFocused
            )
            .onChange(of: jwtToken) { _, _ in processJWT() }
            
            if !jwtHeader.isEmpty {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    CompactOutputArea(title: "Header", text: jwtHeader) {
                        copyToClipboard(jwtHeader)
                    }
                    
                    CompactOutputArea(title: "Payload", text: jwtPayload) {
                        copyToClipboard(jwtPayload)
                    }
                    
                    if !jwtSignature.isEmpty {
                        CompactOutputArea(title: "Signature", text: jwtSignature) {
                            copyToClipboard(jwtSignature)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UUID Generator
    private var uuidGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("UUID Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Compact dropdown controls
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Count dropdown
                    Menu {
                        ForEach(1...10, id: \.self) { count in
                            Button("\(count) UUID\(count > 1 ? "s" : "")") {
                                uuidCount = count
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text("\(uuidCount)")
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Format dropdown
                    Menu {
                        ForEach(UUIDFormat.allCases, id: \.self) { format in
                            Button(format.title) {
                                uuidFormat = format
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(uuidFormat.title)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                ActionButton(title: "Generate", icon: "arrow.clockwise") {
                    generateUUIDs()
                }
                
                if !generatedUUID.isEmpty {
                    ActionButton(title: "Copy All", icon: "doc.on.doc") {
                        copyToClipboard(generatedUUID)
                    }
                }
                
                Spacer()
            }
            
            if !generatedUUID.isEmpty {
                CompactOutputArea(title: "Generated UUIDs", text: generatedUUID) {
                    copyToClipboard(generatedUUID)
                }
            }
        }
    }
    
    // MARK: - Timestamp Converter
    private var timestampConverterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Timestamp Converter")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Compact mode dropdown
                Menu {
                    ForEach(TimestampMode.allCases, id: \.self) { mode in
                        Button(mode.title) {
                            timestampMode = mode
                            processTimestamp()
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(timestampMode.title)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                CompactInputArea(
                    title: timestampMode == .toHuman ? "Unix Timestamp" : "Date/Time",
                    text: $timestampInput,
                    placeholder: timestampMode == .toHuman ? "1640995200" : "2025-01-01 12:00:00",
                    focusBinding: $isInputFocused
                )
                .onChange(of: timestampInput) { _, _ in processTimestamp() }
                
                VStack {
                    Spacer()
                    ActionButton(title: "Now", icon: "clock") {
                        if timestampMode == .toHuman {
                            timestampInput = String(Int(Date().timeIntervalSince1970))
                        } else {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            timestampInput = formatter.string(from: Date())
                        }
                        processTimestamp()
                    }
                    Spacer()
                }
            }
            
            if !timestampResult.isEmpty {
                CompactOutputArea(
                    title: timestampMode == .toHuman ? "Human Readable" : "Unix Timestamp",
                    text: timestampResult
                ) {
                    copyToClipboard(timestampResult)
                }
            }
        }
    }
    
    // MARK: - Text Diff
    private var textDiffInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Text Diff Tool")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                ActionButton(title: "Compare", icon: "eye") {
                    compareDiff()
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                CompactInputArea(
                    title: "Text 1",
                    text: $diffText1,
                    placeholder: "Enter first text...",
                    focusBinding: $isInputFocused
                )
                
                CompactInputArea(
                    title: "Text 2",
                    text: $diffText2,
                    placeholder: "Enter second text...",
                    focusBinding: FocusState<Bool>().projectedValue
                )
            }
            
            if !diffResult.isEmpty {
                DiffResultView(diffLines: diffResult)
            }
        }
    }
    
    // MARK: - Regex Tester
    private var regexTesterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Regex Tester")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(RegexFlag.allCases, id: \.self) { flag in
                        Button(flag.rawValue) {
                            if regexFlags.contains(flag) {
                                regexFlags.remove(flag)
                            } else {
                                regexFlags.insert(flag)
                            }
                            testRegex()
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(regexFlags.contains(flag) ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(regexFlags.contains(flag) ? DesignSystem.Colors.primary : DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                }
            }
            
            CompactInputArea(
                title: "Regex Pattern",
                text: $regexPattern,
                placeholder: "Enter regex pattern...",
                focusBinding: $isInputFocused
            )
            .onChange(of: regexPattern) { _, _ in testRegex() }
            
            CompactInputArea(
                title: "Test Text",
                text: $regexText,
                placeholder: "Enter text to test against...",
                focusBinding: FocusState<Bool>().projectedValue
            )
            .onChange(of: regexText) { _, _ in testRegex() }
            
            if !regexMatches.isEmpty {
                RegexResultView(matches: regexMatches, text: regexText)
            } else if !regexPattern.isEmpty && !regexText.isEmpty {
                Text("No matches found")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
            }
        }
    }
    
    // MARK: - QR Code Generator
    private var qrGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("QR Code Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Picker("Size", selection: $qrSize) {
                    ForEach(QRSize.allCases, id: \.self) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
                .onChange(of: qrSize) { _, _ in generateQRCode() }
            }
            
            CompactInputArea(
                title: "Text/URL",
                text: $qrText,
                placeholder: "Enter text or URL to encode...",
                focusBinding: $isInputFocused
            )
            .onChange(of: qrText) { _, _ in generateQRCode() }
            
            if let qrImage = qrImage {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: qrSize.displaySize, height: qrSize.displaySize)
                        .background(Color.white)
                        .cornerRadius(DesignSystem.BorderRadius.md)
                    
                    ActionButton(title: "Save Image", icon: "square.and.arrow.down") {
                        saveQRCode()
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .fill(DesignSystem.Colors.surface.opacity(0.3))
                )
            }
        }
    }
    
    // MARK: - JSON Formatter
    private var jsonFormatterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("JSON Formatter")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Compact operation dropdown
                Menu {
                    ForEach(JSONOperation.allCases, id: \.self) { operation in
                        Button(operation.title) {
                            jsonOperation = operation
                            processJSON()
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(jsonOperation.title)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
            
            CompactInputArea(
                title: "JSON Input",
                text: $jsonInput,
                placeholder: "Paste your JSON here...",
                focusBinding: $isInputFocused
            )
            .onChange(of: jsonInput) { _, _ in processJSON() }
            
            if !jsonOutput.isEmpty {
                CompactOutputArea(
                    title: jsonOperation.outputTitle,
                    text: jsonOutput
                ) {
                    copyToClipboard(jsonOutput)
                }
            }
            
            // Quick actions
            HStack(spacing: DesignSystem.Spacing.xs) {
                ActionButton(title: "Sample JSON", icon: "doc.text") {
                    jsonInput = """
{
  "name": "John Doe",
  "age": 30,
  "email": "john@example.com",
  "hobbies": ["coding", "reading"],
  "address": {
    "street": "123 Main St",
    "city": "New York"
  }
}
"""
                    processJSON()
                }
                
                ActionButton(title: "Clear", icon: "trash") {
                    jsonInput = ""
                    jsonOutput = ""
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Hash Generator
    private var hashGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Hash Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Compact dropdown controls
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Mode dropdown
                    Menu {
                        Button("Text Mode") {
                            withAnimation(DesignSystem.Animation.gentle) {
                                isFileMode = false
                                hashInput = ""
                                hashResult = ""
                                draggedFileName = nil
                                fileData = nil
                            }
                        }
                        Button("File Mode") {
                            withAnimation(DesignSystem.Animation.gentle) {
                                isFileMode = true
                                hashInput = ""
                                hashResult = ""
                                draggedFileName = nil
                                fileData = nil
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Image(systemName: isFileMode ? "doc.fill" : "textformat")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text(isFileMode ? "File" : "Text")
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Hash type dropdown
                    Menu {
                        ForEach(HashType.allCases, id: \.self) { type in
                            Button(type.title) {
                                hashType = type
                                processHash()
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(hashType.title)
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isFileMode {
                fileDropArea
            } else {
                CompactInputArea(
                    title: "Text Input",
                    text: $hashInput,
                    placeholder: "Enter text to hash...",
                    focusBinding: $isInputFocused
                )
                .onChange(of: hashInput) { _, _ in processHash() }
            }
            
            if !hashResult.isEmpty {
                CompactOutputArea(
                    title: "\(hashType.title) Hash",
                    text: hashResult
                ) {
                    copyToClipboard(hashResult)
                }
            }
            
            // All hash types output (for text mode)
            if !isFileMode && !hashInput.isEmpty {
                allHashesView
            }
        }
    }
    
    private var fileDropArea: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Drop File")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if let fileName = draggedFileName {
                    Spacer()
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.success)
                        Text(fileName)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
            
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                .fill(DesignSystem.Colors.surface.opacity(0.3))
                .frame(height: 80)
                .overlay(
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: draggedFileName != nil ? "checkmark.circle.fill" : "doc.badge.plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(draggedFileName != nil ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                        
                        Text(draggedFileName != nil ? "File loaded" : "Drop file here")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                )
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    handleFileDrop(providers: providers)
                    return true
                }
        }
    }
    
    private var allHashesView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("All Hash Types")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(HashType.allCases, id: \.self) { type in
                    HashRow(
                        type: type,
                        hash: generateHashFromText(hashInput, type: type),
                        isSelected: hashType == type
                    ) {
                        copyToClipboard(generateHashFromText(hashInput, type: type))
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(DesignSystem.Colors.surface.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Processing Functions
    
    private func processURL() {
        guard !urlText.isEmpty else {
            urlResult = ""
            return
        }
        
        switch urlMode {
        case .encode:
            urlResult = urlText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Encoding failed"
        case .decode:
            urlResult = urlText.removingPercentEncoding ?? "Decoding failed"
        }
    }
    
    private func processJWT() {
        guard !jwtToken.isEmpty else {
            jwtHeader = ""
            jwtPayload = ""
            jwtSignature = ""
            return
        }
        
        let parts = jwtToken.components(separatedBy: ".")
        guard parts.count >= 2 else {
            jwtHeader = ""
            jwtPayload = ""
            jwtSignature = ""
            return
        }
        
        // Decode header
        if let headerData = base64Decode(parts[0]),
           let headerString = String(data: headerData, encoding: .utf8) {
            jwtHeader = formatJSON(headerString)
        }
        
        // Decode payload
        if let payloadData = base64Decode(parts[1]),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            jwtPayload = formatJSON(payloadString)
        }
        
        // Store signature (no need to decode)
        if parts.count > 2 {
            jwtSignature = parts[2]
        }
    }
    
    private func generateUUIDs() {
        var uuids: [String] = []
        for _ in 0..<uuidCount {
            let uuid = UUID().uuidString
            switch uuidFormat {
            case .uppercase:
                uuids.append(uuid)
            case .lowercase:
                uuids.append(uuid.lowercased())
            case .noDashes:
                uuids.append(uuid.replacingOccurrences(of: "-", with: ""))
            }
        }
        generatedUUID = uuids.joined(separator: "\n")
    }
    
    private func processTimestamp() {
        guard !timestampInput.isEmpty else {
            timestampResult = ""
            return
        }
        
        switch timestampMode {
        case .toHuman:
            if let timestamp = Double(timestampInput) {
                let date = Date(timeIntervalSince1970: timestamp)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss (EEEE)"
                formatter.timeZone = TimeZone.current
                timestampResult = formatter.string(from: date)
            } else {
                timestampResult = "Invalid timestamp"
            }
        case .toUnix:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = formatter.date(from: timestampInput) {
                timestampResult = String(Int(date.timeIntervalSince1970))
            } else {
                timestampResult = "Invalid date format"
            }
        }
    }
    
    private func compareDiff() {
        let lines1 = diffText1.components(separatedBy: .newlines)
        let lines2 = diffText2.components(separatedBy: .newlines)
        
        diffResult = []
        let maxLines = max(lines1.count, lines2.count)
        
        for i in 0..<maxLines {
            let line1 = i < lines1.count ? lines1[i] : ""
            let line2 = i < lines2.count ? lines2[i] : ""
            
            if line1 == line2 {
                diffResult.append(DiffLine(text: line1, type: .same))
            } else {
                if !line1.isEmpty {
                    diffResult.append(DiffLine(text: "- \(line1)", type: .removed))
                }
                if !line2.isEmpty {
                    diffResult.append(DiffLine(text: "+ \(line2)", type: .added))
                }
            }
        }
    }
    
    private func testRegex() {
        guard !regexPattern.isEmpty && !regexText.isEmpty else {
            regexMatches = []
            return
        }
        
        do {
            var options: NSRegularExpression.Options = []
            if regexFlags.contains(.caseInsensitive) {
                options.insert(.caseInsensitive)
            }
            if regexFlags.contains(.multiline) {
                options.insert(.anchorsMatchLines)
            }
            if regexFlags.contains(.dotMatchesLineSeparators) {
                options.insert(.dotMatchesLineSeparators)
            }
            
            let regex = try NSRegularExpression(pattern: regexPattern, options: options)
            regexMatches = regex.matches(in: regexText, options: [], range: NSRange(location: 0, length: regexText.count))
        } catch {
            regexMatches = []
        }
    }
    
    private func generateQRCode() {
        guard !qrText.isEmpty else {
            qrImage = nil
            return
        }
        
        let data = qrText.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter?.outputImage {
            let scaleX = qrSize.rawValue / outputImage.extent.size.width
            let scaleY = qrSize.rawValue / outputImage.extent.size.height
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            let rep = NSCIImageRep(ciImage: scaledImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            qrImage = nsImage
        }
    }
    
    private func saveQRCode() {
        guard let qrImage = qrImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "qrcode.png"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let tiffData = qrImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
    
    private func processJSON() {
        guard !jsonInput.isEmpty else {
            jsonOutput = ""
            return
        }
        
        switch jsonOperation {
        case .format:
            formatJSON()
        case .minify:
            minifyJSON()
        case .validate:
            validateJSON()
        }
    }
    
    private func formatJSON() {
        do {
            let jsonData = jsonInput.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            jsonOutput = String(data: formattedData, encoding: .utf8) ?? "Formatting failed"
        } catch {
            jsonOutput = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func minifyJSON() {
        do {
            let jsonData = jsonInput.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            jsonOutput = String(data: minifiedData, encoding: .utf8) ?? "Minification failed"
        } catch {
            jsonOutput = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func validateJSON() {
        do {
            let jsonData = jsonInput.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            // Get JSON info
            let size = jsonData.count
            let keys = extractKeys(from: jsonObject)
            
            jsonOutput = """
✅ Valid JSON

📊 Statistics:
• Size: \(size) bytes
• Keys found: \(keys.count)
• Type: \(type(of: jsonObject))

🔑 Keys:
\(keys.isEmpty ? "No keys found" : keys.joined(separator: ", "))
"""
        } catch {
            jsonOutput = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func extractKeys(from object: Any) -> [String] {
        var keys: [String] = []
        
        if let dict = object as? [String: Any] {
            keys.append(contentsOf: dict.keys)
            for value in dict.values {
                keys.append(contentsOf: extractKeys(from: value))
            }
        } else if let array = object as? [Any] {
            for item in array {
                keys.append(contentsOf: extractKeys(from: item))
            }
        }
        
        return Array(Set(keys)).sorted()
    }
    
    private func processHash() {
        if isFileMode {
            if let fileData = fileData {
                hashResult = generateHashFromData(fileData, type: hashType)
            } else {
                hashResult = ""
            }
        } else {
            guard !hashInput.isEmpty else {
                hashResult = ""
                return
            }
            hashResult = generateHashFromText(hashInput, type: hashType)
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        processDroppedFile(url: url)
                    } else if let url = item as? URL {
                        processDroppedFile(url: url)
                    }
                }
            }
        }
    }
    
    private func processDroppedFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            DispatchQueue.main.async {
                self.draggedFileName = fileName
                self.fileData = data
                self.processHash()
            }
        } catch {
            DispatchQueue.main.async {
                self.hashResult = "❌ Could not read file: \(error.localizedDescription)"
            }
        }
    }
    
    private func generateHashFromText(_ text: String, type: HashType) -> String {
        let data = Data(text.utf8)
        return generateHashFromData(data, type: type)
    }
    
    private func generateHashFromData(_ data: Data, type: HashType) -> String {
        switch type {
        case .md5:
            return data.md5
        case .sha1:
            return data.sha1
        case .sha256:
            return data.sha256
        case .sha384:
            return data.sha384
        case .sha512:
            return data.sha512
        }
    }
    
    // MARK: - Helper Functions
    
    private func base64Decode(_ string: String) -> Data? {
        // Add padding if needed
        var base64 = string
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
    
    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        withAnimation(DesignSystem.Animation.gentle) {
            showCopiedFeedback = true
            lastCopiedText = text.prefix(20) + (text.count > 20 ? "..." : "")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(DesignSystem.Animation.gentle) {
                showCopiedFeedback = false
            }
        }
    }
    
    private func clearAllInputs() {
        urlText = ""
        urlResult = ""
        jwtToken = ""
        jwtHeader = ""
        jwtPayload = ""
        jwtSignature = ""
        timestampInput = ""
        timestampResult = ""
        diffText1 = ""
        diffText2 = ""
        diffResult = []
        regexPattern = ""
        regexText = ""
        regexMatches = []
        qrText = ""
        qrImage = nil
        jsonInput = ""
        jsonOutput = ""
        jsonOperation = .format
        hashInput = ""
        hashType = .sha256
        hashResult = ""
        isFileMode = false
        draggedFileName = nil
        fileData = nil
    }
    
    private func focusInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
        }
    }
}

// MARK: - Supporting Views

struct ToolButton: View {
    let tool: DeveloperTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: tool.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(tool.title)
                    .font(DesignSystem.Typography.micro)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .frame(width: 80)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isSelected ? tool.color : DesignSystem.Colors.surface.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactInputArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var focusBinding: FocusState<Bool>.Binding?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextEditor(text: $text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 60)
                .padding(DesignSystem.Spacing.sm)
                .focused(focusBinding ?? FocusState<Bool>().projectedValue)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                        .fill(DesignSystem.Colors.surface.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                        )
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            HStack {
                                VStack {
                                    HStack {
                                        Text(placeholder)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                                            .padding(.leading, DesignSystem.Spacing.sm)
                                            .padding(.top, DesignSystem.Spacing.sm + 2)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }
                )
        }
    }
}

struct CompactOutputArea: View {
    let title: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button("Copy") {
                    action()
                }
                .font(DesignSystem.Typography.micro)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            ScrollView {
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
            }
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(DesignSystem.Colors.surface.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(DesignSystem.Typography.micro)
            }
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct DiffResultView: View {
    let diffLines: [DiffLine]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Differences")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(diffLines.enumerated()), id: \.offset) { _, line in
                        HStack {
                            Text(line.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(line.type.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 1)
                        .background(line.type.backgroundColor)
                    }
                }
            }
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(DesignSystem.Colors.surface.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct RegexResultView: View {
    let matches: [NSTextCheckingResult]
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("\(matches.count) matches found")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.success)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(matches.enumerated()), id: \.offset) { index, match in
                        let range = Range(match.range, in: text)
                        if let range = range {
                            HStack {
                                Text("#\(index + 1):")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text(String(text[range]))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(DesignSystem.Colors.success)
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(DesignSystem.Colors.success.opacity(0.1))
                            .cornerRadius(DesignSystem.BorderRadius.sm)
                        }
                    }
                }
            }
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(DesignSystem.Colors.surface.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct HashRow: View {
    let type: HashType
    let hash: String
    let isSelected: Bool
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            Text(type.title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 60, alignment: .leading)
            
            Text(hash)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                .fill(isSelected ? type.color.opacity(0.1) : DesignSystem.Colors.surface.opacity(0.2))
        )
    }
}

// MARK: - Supporting Types

enum DeveloperTool: CaseIterable {
    case urlEncoder, jwtDecoder, uuidGenerator, timestampConverter, textDiff, regexTester, qrGenerator, jsonFormatter, hashGenerator
    
    var title: String {
        switch self {
        case .urlEncoder: return "URL"
        case .jwtDecoder: return "JWT"
        case .uuidGenerator: return "UUID"
        case .timestampConverter: return "Time"
        case .textDiff: return "Diff"
        case .regexTester: return "Regex"
        case .qrGenerator: return "QR"
        case .jsonFormatter: return "JSON"
        case .hashGenerator: return "Hash"
        }
    }
    
    var icon: String {
        switch self {
        case .urlEncoder: return "link"
        case .jwtDecoder: return "key"
        case .uuidGenerator: return "number.square"
        case .timestampConverter: return "clock"
        case .textDiff: return "doc.text.magnifyingglass"
        case .regexTester: return "textformat.size"
        case .qrGenerator: return "qrcode"
        case .jsonFormatter: return "doc.text"
        case .hashGenerator: return "lock"
        }
    }
    
    var color: Color {
        switch self {
        case .urlEncoder: return DesignSystem.Colors.primary
        case .jwtDecoder: return DesignSystem.Colors.success
        case .uuidGenerator: return DesignSystem.Colors.warning
        case .timestampConverter: return DesignSystem.Colors.files
        case .textDiff: return DesignSystem.Colors.error
        case .regexTester: return DesignSystem.Colors.developer
        case .qrGenerator: return DesignSystem.Colors.ai
        case .jsonFormatter: return DesignSystem.Colors.files
        case .hashGenerator: return DesignSystem.Colors.files
        }
    }
}

enum URLMode: CaseIterable {
    case encode, decode
    
    var title: String {
        switch self {
        case .encode: return "Encode"
        case .decode: return "Decode"
        }
    }
}

enum UUIDFormat: CaseIterable {
    case uppercase, lowercase, noDashes
    
    var title: String {
        switch self {
        case .uppercase: return "UPPER"
        case .lowercase: return "lower"
        case .noDashes: return "nodash"
        }
    }
}

enum TimestampMode: CaseIterable {
    case toHuman, toUnix
    
    var title: String {
        switch self {
        case .toHuman: return "To Human"
        case .toUnix: return "To Unix"
        }
    }
}

enum QRSize: CGFloat, CaseIterable {
    case small = 128
    case medium = 256
    case large = 512
    
    var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var displaySize: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 160
        }
    }
}

enum RegexFlag: String, CaseIterable {
    case caseInsensitive = "i"
    case multiline = "m"
    case dotMatchesLineSeparators = "s"
    
    var title: String {
        switch self {
        case .caseInsensitive: return "Case Insensitive"
        case .multiline: return "Multiline"
        case .dotMatchesLineSeparators: return "Dot All"
        }
    }
}

struct DiffLine {
    let text: String
    let type: DiffType
}

enum DiffType {
    case same, added, removed
    
    var color: Color {
        switch self {
        case .same: return DesignSystem.Colors.textPrimary
        case .added: return DesignSystem.Colors.success
        case .removed: return DesignSystem.Colors.error
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .same: return Color.clear
        case .added: return DesignSystem.Colors.success.opacity(0.1)
        case .removed: return DesignSystem.Colors.error.opacity(0.1)
        }
    }
}

enum JSONOperation: CaseIterable {
    case format, minify, validate
    
    var title: String {
        switch self {
        case .format: return "Format"
        case .minify: return "Minify"
        case .validate: return "Validate"
        }
    }
    
    var outputTitle: String {
        switch self {
        case .format: return "Formatted JSON"
        case .minify: return "Minified JSON"
        case .validate: return "JSON Validation"
        }
    }
}

enum HashType: CaseIterable {
    case md5, sha1, sha256, sha384, sha512
    
    var title: String {
        switch self {
        case .md5: return "MD5"
        case .sha1: return "SHA-1"
        case .sha256: return "SHA-256"
        case .sha384: return "SHA-384"
        case .sha512: return "SHA-512"
        }
    }
    
    var color: Color {
        switch self {
        case .md5: return DesignSystem.Colors.error
        case .sha1: return DesignSystem.Colors.warning
        case .sha256: return DesignSystem.Colors.success
        case .sha384: return DesignSystem.Colors.primary
        case .sha512: return DesignSystem.Colors.ai
        }
    }
}

// MARK: - Crypto Extensions

extension Data {
    var md5: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var sha1: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var sha256: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var sha384: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
            CC_SHA384(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var sha512: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            CC_SHA512(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
} 