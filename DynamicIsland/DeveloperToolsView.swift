import SwiftUI
import CommonCrypto
import Foundation

struct DeveloperToolsView: View {
    @State private var selectedTool: DeveloperTool = .curlGenerator
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
    @State private var qrStyle: QRStyle = .standard
    
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
    
    // cURL Generator
    @State private var curlURL: String = ""
    @State private var curlMethod: HTTPMethod = .GET
    @State private var curlHeaders: String = ""
    @State private var curlBody: String = ""
    @State private var curlResult: String = ""
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Tool Selector
            toolSelector
            
            // Tool Interface
            Group {
                switch selectedTool {
                case .curlGenerator:
                    curlGeneratorInterface
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
    
    // MARK: - cURL Generator
    private var curlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("cURL Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // HTTP Method dropdown
                Menu {
                    ForEach(HTTPMethod.allCases, id: \.self) { method in
                        Button(method.rawValue) {
                            curlMethod = method
                            generateCURL()
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(curlMethod.rawValue)
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
            
            // URL Input
            CompactInputArea(
                title: "URL",
                text: $curlURL,
                placeholder: "https://api.example.com/users",
                focusBinding: $isInputFocused
            )
            .onChange(of: curlURL) { _, _ in generateCURL() }
            
            // Headers Input (optional)
            CompactInputArea(
                title: "Headers (Optional)",
                text: $curlHeaders,
                placeholder: "Content-Type: application/json\nAuthorization: Bearer token",
                focusBinding: FocusState<Bool>().projectedValue
            )
            .onChange(of: curlHeaders) { _, _ in generateCURL() }
            
            // Body Input (for POST/PUT/PATCH)
            if curlMethod.hasBody {
                CompactInputArea(
                    title: "Request Body",
                    text: $curlBody,
                    placeholder: curlMethod.bodyPlaceholder,
                    focusBinding: FocusState<Bool>().projectedValue
                )
                .onChange(of: curlBody) { _, _ in generateCURL() }
            }
            
            // Quick action buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                ActionButton(title: "Sample API", icon: "doc.text") {
                    curlURL = "https://jsonplaceholder.typicode.com/posts/1"
                    curlMethod = .GET
                    curlHeaders = "Accept: application/json"
                    curlBody = ""
                    generateCURL()
                }
                
                ActionButton(title: "Clear", icon: "trash") {
                    curlURL = ""
                    curlHeaders = ""
                    curlBody = ""
                    curlResult = ""
                }
                
                Spacer()
            }
            
            if !curlResult.isEmpty {
                CompactOutputArea(
                    title: "Generated cURL Command",
                    text: curlResult
                ) {
                    copyToClipboard(curlResult)
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
                
                // Compact controls
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Count stepper with -/+ buttons
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Button("-") {
                            if uuidCount > 1 {
                                uuidCount -= 1
                            }
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(uuidCount > 1 ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                        .disabled(uuidCount <= 1)
                        .buttonStyle(.plain)
                        
                        Text("\(uuidCount)")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(width: 20)
                        
                        Button("+") {
                            if uuidCount < 10 {
                                uuidCount += 1
                            }
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(uuidCount < 10 ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                        .disabled(uuidCount >= 10)
                        .buttonStyle(.plain)
                    }
                    
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
                // Larger UUID output area
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Generated UUIDs")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Button("Copy") {
                            copyToClipboard(generatedUUID)
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    ScrollView {
                        Text(generatedUUID)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.sm)
                            .textSelection(.enabled)
                    }
                    .frame(height: 120) // Bigger height for better visibility
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
                
                // Compact controls - moved left and added style selector
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Style dropdown
                    Menu {
                        ForEach(QRStyle.allCases, id: \.self) { style in
                            Button(style.title) {
                                qrStyle = style
                                generateQRCode()
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(qrStyle.title)
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
                    
                    // Size dropdown
                    Menu {
                        ForEach(QRSize.allCases, id: \.self) { size in
                            Button(size.title) {
                                qrSize = size
                                generateQRCode()
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(qrSize.title)
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
                        .background(qrStyle.backgroundColor)
                        .cornerRadius(qrStyle.cornerRadius)
                    
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
    
    private func generateCURL() {
        guard !curlURL.isEmpty else {
            curlResult = ""
            return
        }
        
        var curlCommand = "curl"
        
        // Add method if not GET
        if curlMethod != .GET {
            curlCommand += " -X \(curlMethod.rawValue)"
        }
        
        // Add headers
        if !curlHeaders.isEmpty {
            let headerLines = curlHeaders.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for header in headerLines {
                curlCommand += " \\\n  -H '\(header.trimmingCharacters(in: .whitespaces))'"
            }
        }
        
        // Add body for methods that support it
        if curlMethod.hasBody && !curlBody.isEmpty {
            curlCommand += " \\\n  -d '\(curlBody)'"
        }
        
        // Add URL (always last)
        curlCommand += " \\\n  '\(curlURL)'"
        
        curlResult = curlCommand
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
            
            // Apply style transformations
            let styledImage = applyQRStyle(to: scaledImage, style: qrStyle)
            
            let rep = NSCIImageRep(ciImage: styledImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            qrImage = nsImage
        }
    }
    
    private func applyQRStyle(to image: CIImage, style: QRStyle) -> CIImage {
        switch style {
        case .standard:
            return image
        case .rounded:
            // Apply subtle rounding effect
            if let morphologyFilter = CIFilter(name: "CIMorphologyRectangleMinimum") {
                morphologyFilter.setValue(image, forKey: kCIInputImageKey)
                morphologyFilter.setValue(CIVector(x: 2, y: 2), forKey: kCIInputRadiusKey)
                return morphologyFilter.outputImage ?? image
            }
            return image
        case .colorfulBlue:
            return applyColorFilter(to: image, foregroundColor: CIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        case .colorfulGreen:
            return applyColorFilter(to: image, foregroundColor: CIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0))
        case .colorfulRed:
            return applyColorFilter(to: image, foregroundColor: CIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
        case .colorfulPurple:
            return applyColorFilter(to: image, foregroundColor: CIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0))
        case .gradientSunset:
            return applyGradientFilter(to: image, 
                                     color1: CIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), // Orange
                                     color2: CIColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0)) // Pink
        case .gradientOcean:
            return applyGradientFilter(to: image,
                                     color1: CIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0), // Light Blue
                                     color2: CIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0)) // Dark Blue
        case .gradientForest:
            return applyGradientFilter(to: image,
                                     color1: CIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0), // Light Green
                                     color2: CIColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0)) // Dark Green
        }
    }
    
    private func applyColorFilter(to image: CIImage, foregroundColor: CIColor) -> CIImage {
        if let colorFilter = CIFilter(name: "CIFalseColor") {
            colorFilter.setValue(image, forKey: kCIInputImageKey)
            colorFilter.setValue(foregroundColor, forKey: "inputColor0")
            colorFilter.setValue(CIColor.white, forKey: "inputColor1")
            return colorFilter.outputImage ?? image
        }
        return image
    }
    
    private func applyGradientFilter(to image: CIImage, color1: CIColor, color2: CIColor) -> CIImage {
        let gradientImage = createCustomGradientImage(size: image.extent.size, color1: color1, color2: color2)
        if let gradientImage = gradientImage,
           let blendFilter = CIFilter(name: "CIMultiplyBlendMode") {
            blendFilter.setValue(image, forKey: kCIInputImageKey)
            blendFilter.setValue(gradientImage, forKey: kCIInputBackgroundImageKey)
            return blendFilter.outputImage ?? image
        }
        return image
    }
    
    private func createCustomGradientImage(size: CGSize, color1: CIColor, color2: CIColor) -> CIImage? {
        let gradient = CIFilter(name: "CILinearGradient")
        gradient?.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
        gradient?.setValue(CIVector(x: size.width, y: size.height), forKey: "inputPoint1")
        gradient?.setValue(color1, forKey: "inputColor0")
        gradient?.setValue(color2, forKey: "inputColor1")
        
        return gradient?.outputImage?.cropped(to: CGRect(origin: .zero, size: size))
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
        curlURL = ""
        curlHeaders = ""
        curlBody = ""
        curlResult = ""
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
        qrStyle = .standard
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
    case curlGenerator, jwtDecoder, uuidGenerator, timestampConverter, textDiff, regexTester, qrGenerator, jsonFormatter, hashGenerator
    
    var title: String {
        switch self {
        case .curlGenerator: return "cURL"
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
        case .curlGenerator: return "terminal"
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
        case .curlGenerator: return DesignSystem.Colors.primary
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

enum HTTPMethod: String, CaseIterable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
    
    var hasBody: Bool {
        switch self {
        case .POST, .PUT, .PATCH: return true
        case .GET, .DELETE, .HEAD, .OPTIONS: return false
        }
    }
    
    var bodyPlaceholder: String {
        switch self {
        case .POST: return """
{
  "name": "John Doe",
  "email": "john@example.com"
}
"""
        case .PUT: return """
{
  "id": 1,
  "name": "Updated Name",
  "status": "active"
}
"""
        case .PATCH: return """
{
  "status": "completed"
}
"""
        default: return ""
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

enum QRStyle: CaseIterable {
    case standard, rounded, colorfulBlue, colorfulGreen, colorfulRed, colorfulPurple, gradientSunset, gradientOcean, gradientForest
    
    var title: String {
        switch self {
        case .standard: return "Standard"
        case .rounded: return "Rounded"
        case .colorfulBlue: return "Blue"
        case .colorfulGreen: return "Green"
        case .colorfulRed: return "Red"
        case .colorfulPurple: return "Purple"
        case .gradientSunset: return "Sunset"
        case .gradientOcean: return "Ocean"
        case .gradientForest: return "Forest"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .standard, .rounded: return Color.white
        case .colorfulBlue, .colorfulGreen, .colorfulRed, .colorfulPurple: return Color.white
        case .gradientSunset, .gradientOcean, .gradientForest: return Color.white
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .standard: return DesignSystem.BorderRadius.md
        case .rounded: return DesignSystem.BorderRadius.lg
        case .colorfulBlue, .colorfulGreen, .colorfulRed, .colorfulPurple: return DesignSystem.BorderRadius.md
        case .gradientSunset, .gradientOcean, .gradientForest: return DesignSystem.BorderRadius.md
        }
    }
    
    var isColorStyle: Bool {
        switch self {
        case .colorfulBlue, .colorfulGreen, .colorfulRed, .colorfulPurple: return true
        default: return false
        }
    }
    
    var isGradientStyle: Bool {
        switch self {
        case .gradientSunset, .gradientOcean, .gradientForest: return true
        default: return false
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