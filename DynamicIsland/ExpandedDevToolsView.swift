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
    
    // cURL Generator
    @State private var curlURL: String = ""
    @State private var curlMethod: HTTPMethod = .GET
    @State private var curlHeaders: String = ""
    @State private var curlBody: String = ""
    @State private var curlResult: String = ""
    
    // JWT Decoder
    @State private var jwtToken: String = ""
    @State private var jwtHeader: String = ""
    @State private var jwtPayload: String = ""
    @State private var jwtSignature: String = ""
    
    // GraphQL Generator
    @State private var graphqlOperation: GraphQLOperation = .query
    @State private var graphqlQuery: String = ""
    @State private var graphqlVariables: String = ""
    @State private var graphqlResult: String = ""
    
    // API Response Mockup
    @State private var apiResponseType: APIResponseType = .user
    @State private var apiResponseCount: Int = 1
    @State private var apiResponseResult: String = ""
    @State private var apiCustomSchema: String = ""
    
    // YAML ↔ JSON Converter
    @State private var yamlJsonInput: String = ""
    @State private var yamlJsonOutput: String = ""
    @State private var yamlJsonMode: YAMLJSONMode = .yamlToJson
    
    // Text Diff
    @State private var diffText1: String = ""
    @State private var diffText2: String = ""
    @State private var diffResult: [DiffLine] = []
    @State private var enhancedDiffResult: [DiffPair] = []
    @State private var diffStats: DiffStats = DiffStats()
    
    // Regex Tester
    @State private var regexPattern: String = ""
    @State private var regexText: String = ""
    @State private var regexMatches: [NSTextCheckingResult] = []
    @State private var regexFlags: Set<RegexFlag> = []
    
    // QR Code Generator
    @State private var qrText: String = ""
    @State private var qrCode: NSImage?
    @State private var qrStyle: QRStyle = .standard
    @State private var qrSize: QRSize = .medium
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            compactHeaderSection
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Main content area with side-by-side layout
            HStack(spacing: 0) {
                // Compact tool selector sidebar
                compactToolSidebar
                
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
    
    // MARK: - Compact Header Section
    
    private var compactHeaderSection: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: selectedTool.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedTool.color)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(selectedTool.displayName)
                        .font(DesignSystem.Typography.headline3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(selectedTool.subtitle)
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Quick copy feedback - more compact
            if showCopiedFeedback {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Copied")
                        .font(DesignSystem.Typography.micro)
                }
                .foregroundColor(DesignSystem.Colors.success)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.success.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
    }
    
    // MARK: - Compact Tool Sidebar
    
    private var compactToolSidebar: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(DeveloperTool.allCases, id: \.self) { tool in
                    Button(action: {
                        withAnimation(DesignSystem.Animation.gentle) {
                            selectedTool = tool
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTool == tool ? .white : tool.color)
                                .frame(width: 18)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tool.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selectedTool == tool ? .white : DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(tool.subtitle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedTool == tool ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTool == tool ? tool.color : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .frame(width: 220)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Tool Interface
    
    private var toolInterface: some View {
        VStack {
            switch selectedTool {
            case .jsonFormatter:
                compactJsonFormatterInterface
            case .hashGenerator:
                compactHashGeneratorInterface
            case .base64:
                compactBase64Interface
            case .uuidGenerator:
                compactUuidGeneratorInterface
            case .curlGenerator:
                compactCurlGeneratorInterface
            case .jwtDecoder:
                compactJwtDecoderInterface
            case .graphqlGenerator:
                compactGraphqlGeneratorInterface
            case .apiMockup:
                compactApiMockupInterface
            case .yamlJsonConverter:
                compactYamlJsonConverterInterface
            case .textDiff:
                compactTextDiffInterface
            case .regexTester:
                compactRegexTesterInterface
            case .qrGenerator:
                compactQrGeneratorInterface
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .animation(DesignSystem.Animation.smooth, value: selectedTool)
    }
    
    // MARK: - Compact JSON Formatter Interface
    
    private var compactJsonFormatterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Compact operation selector
            HStack(spacing: DesignSystem.Spacing.md) {
                Picker("Operation", selection: $jsonOperation) {
                    ForEach(JSONOperation.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if !jsonInput.isEmpty {
                        Button("Paste") {
                            if let clipboardString = NSPasteboard.general.string(forType: .string) {
                                jsonInput = clipboardString
                                processJSON()
                            }
                        }
                        .buttonStyle_custom(.ghost)
                    }
                    
                    Button("Clear") {
                        jsonInput = ""
                        jsonOutput = ""
                    }
                    .buttonStyle_custom(.ghost)
                }
            }
            
            // Compact Input/Output layout
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Input area - more compact
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Spacer()
                    }
                    
                    TextEditor(text: $jsonInput)
                        .font(.system(size: 12, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: jsonInput) { _, _ in
                            processJSON()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Compact arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Output area - more compact
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jsonOutput.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jsonOutput)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(6)
                        }
                    }
                    
                    ScrollView {
                        Text(jsonOutput.isEmpty ? "Formatted JSON will appear here..." : jsonOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(jsonOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.sm)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Compact Base64 Interface
    
    private var compactBase64Interface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Compact mode selector
            HStack {
                Picker("Mode", selection: $base64Mode) {
                    Text("Encode").tag(Base64Mode.encode)
                    Text("Decode").tag(Base64Mode.decode)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
                
                Spacer()
            }
            
            // Compact Input/Output layout
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $base64Input)
                        .font(.system(size: 12, design: .monospaced))
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: base64Input) { _, _ in
                            processBase64()
                        }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Output area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !base64Output.isEmpty {
                            Button("Copy") {
                                copyToClipboard(base64Output)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(6)
                        }
                    }
                    
                    ScrollView {
                        Text(base64Output.isEmpty ? "Result will appear here..." : base64Output)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(base64Output.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.md)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Compact Hash Generator Interface
    
    private var compactHashGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Compact controls
            HStack(spacing: DesignSystem.Spacing.lg) {
                Picker("Mode", selection: $isFileMode) {
                    Text("Text").tag(false)
                    Text("File").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                
                Picker("Hash", selection: $hashType) {
                    ForEach(HashType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
            }
            
            // Compact Input/Output
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isFileMode {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(draggedFileName ?? "Drop file or click to select")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Button("Select File") {
                                selectFile()
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignSystem.Colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(DesignSystem.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                )
                        )
                        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                            handleFileDrop(providers)
                        }
                    } else {
                        TextEditor(text: $hashInput)
                            .font(.system(size: 12, design: .monospaced))
                            .focused($isInputFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isInputFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .onChange(of: hashInput) { _, _ in
                                generateHash()
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hash (\(hashType.displayName))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !hashResult.isEmpty {
                            Button("Copy") {
                                copyToClipboard(hashResult)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(6)
                        }
                    }
                    
                    ScrollView {
                        Text(hashResult.isEmpty ? "Hash will appear here..." : hashResult)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(hashResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.md)
                            .textSelection(.enabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
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
    
    // MARK: - Placeholder Compact Implementations
    
    private var compactUuidGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Controls
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Count:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        TextField("Count", value: $uuidCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Stepper("", value: $uuidCount, in: 1...100)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format:")
                        .font(.system(size: 13, weight: .semibold))
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
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(uuid)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .textSelection(.enabled)
                            
                            Spacer()
                            
                            Button("Copy") {
                                copyToClipboard(uuid)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(4)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(DesignSystem.Colors.surface)
                        )
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
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
    
    private var compactCurlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Method and URL
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Method")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Method", selection: $curlMethod) {
                        ForEach(HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextField("https://api.example.com/users", text: $curlURL)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: curlURL) { _, _ in generateCURL() }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Headers and Body
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Headers (one per line)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $curlHeaders)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: curlHeaders) { _, _ in generateCURL() }
                }
                .frame(maxWidth: .infinity)
                
                if curlMethod.hasBody {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Request Body")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: $curlBody)
                            .font(.system(size: 12, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .onChange(of: curlBody) { _, _ in generateCURL() }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
            
            // Generated cURL
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Generated cURL Command")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !curlResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(curlResult)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(6)
                    }
                }
                
                ScrollView {
                    Text(curlResult.isEmpty ? "cURL command will appear here..." : curlResult)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(curlResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.md)
                        .textSelection(.enabled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: curlMethod) { _, _ in generateCURL() }
        .onAppear { generateCURL() }
    }
    
    private var compactJwtDecoderInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // JWT Token Input
            VStack(alignment: .leading, spacing: 8) {
                Text("JWT Token")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextEditor(text: $jwtToken)
                    .font(.system(size: 12, design: .monospaced))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                    .onChange(of: jwtToken) { _, _ in decodeJWT() }
            }
            .frame(height: 100)
            
            // Decoded sections
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Header")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jwtHeader.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jwtHeader)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(4)
                        }
                    }
                    
                    ScrollView {
                        Text(jwtHeader.isEmpty ? "Header will appear here..." : jwtHeader)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(jwtHeader.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.md)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Payload
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Payload")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jwtPayload.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jwtPayload)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(4)
                        }
                    }
                    
                    ScrollView {
                        Text(jwtPayload.isEmpty ? "Payload will appear here..." : jwtPayload)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(jwtPayload.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.md)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    private var compactGraphqlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Operation type selector
            HStack {
                Text("Operation Type:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Operation", selection: $graphqlOperation) {
                    ForEach(GraphQLOperation.allCases, id: \.self) { op in
                        Text(op.title).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
                
                Spacer()
            }
            
            // Query and Variables
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GraphQL \(graphqlOperation.title)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $graphqlQuery)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: graphqlQuery) { _, _ in generateGraphQLResult() }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Variables (JSON)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $graphqlVariables)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: graphqlVariables) { _, _ in generateGraphQLResult() }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 180)
            
            // Generated Result
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Generated Request")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !graphqlResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(graphqlResult)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(6)
                    }
                }
                
                ScrollView {
                    Text(graphqlResult.isEmpty ? "Generated request will appear here..." : graphqlResult)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(graphqlResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.md)
                        .textSelection(.enabled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: graphqlOperation) { _, _ in generateGraphQLResult() }
    }
    
    private var compactApiMockupInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Controls
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response Type:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Type", selection: $apiResponseType) {
                        ForEach(APIResponseType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Count:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        TextField("Count", value: $apiResponseCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Stepper("", value: $apiResponseCount, in: 1...100)
                    }
                }
                
                Spacer()
                
                Button("Generate") {
                    generateAPIResponse()
                }
                .buttonStyle_custom(.primary)
            }
            
            // Custom schema (for custom type)
            if apiResponseType == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Schema (JSON)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $apiCustomSchema)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .frame(height: 120)
            }
            
            // Generated Response
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Generated API Response")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !apiResponseResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(apiResponseResult)
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(6)
                    }
                }
                
                ScrollView {
                    Text(apiResponseResult.isEmpty ? "Generated response will appear here..." : apiResponseResult)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(apiResponseResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.md)
                        .textSelection(.enabled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: apiResponseType) { _, _ in generateAPIResponse() }
        .onChange(of: apiResponseCount) { _, _ in generateAPIResponse() }
        .onAppear { generateAPIResponse() }
    }
    
    private var compactYamlJsonConverterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Mode selector
            HStack {
                Text("Conversion:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Mode", selection: $yamlJsonMode) {
                    ForEach(YAMLJSONMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                
                Spacer()
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(yamlJsonMode.inputTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $yamlJsonInput)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: yamlJsonInput) { _, _ in convertYamlJson() }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(yamlJsonMode.outputTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !yamlJsonOutput.isEmpty {
                            Button("Copy") {
                                copyToClipboard(yamlJsonOutput)
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(6)
                        }
                    }
                    
                    ScrollView {
                        Text(yamlJsonOutput.isEmpty ? "Converted output will appear here..." : yamlJsonOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(yamlJsonOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(DesignSystem.Spacing.md)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: yamlJsonMode) { _, _ in convertYamlJson() }
    }
    
    private var compactTextDiffInterface: some View {
        textDiffInterface
    }
    
    private var compactRegexTesterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Pattern and flags
            VStack(alignment: .leading, spacing: 8) {
                Text("Regular Expression Pattern")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextField("Enter regex pattern...", text: $regexPattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: regexPattern) { _, _ in testRegex() }
                
                // Flags
                HStack {
                    Text("Flags:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(RegexFlag.allCases, id: \.self) { flag in
                        Toggle(flag.title, isOn: Binding(
                            get: { regexFlags.contains(flag) },
                            set: { isOn in
                                if isOn {
                                    regexFlags.insert(flag)
                                } else {
                                    regexFlags.remove(flag)
                                }
                                testRegex()
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                    
                    Spacer()
                }
            }
            
            // Test text and results
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $regexText)
                        .font(.system(size: 12, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: regexText) { _, _ in testRegex() }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Matches (\(regexMatches.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            ForEach(Array(regexMatches.enumerated()), id: \.offset) { index, match in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Match \(index + 1)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.success)
                                    
                                    let matchText = String(regexText[Range(match.range, in: regexText)!])
                                    Text(matchText)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .padding(.horizontal, DesignSystem.Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(DesignSystem.Colors.success.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignSystem.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    private var compactQrGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Input and settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Text to encode")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextEditor(text: $qrText)
                    .font(.system(size: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                    .onChange(of: qrText) { _, _ in generateQRCode() }
            }
            .frame(height: 100)
            
            // Style and size controls
            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Style:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Style", selection: $qrStyle) {
                        ForEach(QRStyle.allCases, id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Size", selection: $qrSize) {
                        ForEach(QRSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                Spacer()
                
                if qrCode != nil {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Button("Save Image") {
                            saveQRCode()
                        }
                        .buttonStyle_custom(.secondary)
                        
                        Button("Copy Image") {
                            copyQRCodeToClipboard()
                        }
                        .buttonStyle_custom(.primary)
                    }
                }
            }
            
            // Generated QR Code
            VStack(spacing: DesignSystem.Spacing.md) {
                if let qrCode = qrCode {
                    Image(nsImage: qrCode)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(qrSize.displaySize, 200), height: min(qrSize.displaySize, 200))
                        .background(qrStyle.backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: qrStyle.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: qrStyle.cornerRadius)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Colors.surface)
                        .frame(width: 200, height: 200)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 40, weight: .thin))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text("QR code will appear here")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: qrStyle) { _, _ in generateQRCode() }
        .onChange(of: qrSize) { _, _ in generateQRCode() }
        .onAppear { generateQRCode() }
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
    
    // MARK: - cURL Generator Interface
    
    private var curlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Method and URL
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Method")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Method", selection: $curlMethod) {
                        ForEach(HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("URL")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextField("https://api.example.com/users", text: $curlURL)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: curlURL) { _, _ in generateCURL() }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Headers and Body
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Headers (one per line)")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $curlHeaders)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: curlHeaders) { _, _ in generateCURL() }
                }
                .frame(maxWidth: .infinity)
                
                if curlMethod.hasBody {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Request Body")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: $curlBody)
                            .font(.system(size: 14, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .onChange(of: curlBody) { _, _ in generateCURL() }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            
            // Generated cURL
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Generated cURL Command")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !curlResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(curlResult)
                        }
                        .buttonStyle_custom(.primary)
                    }
                }
                
                ScrollView {
                    Text(curlResult.isEmpty ? "cURL command will appear here..." : curlResult)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(curlResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.lg)
                        .textSelection(.enabled)
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
            .frame(maxHeight: .infinity)
        }
        .onChange(of: curlMethod) { _, _ in generateCURL() }
        .onAppear { generateCURL() }
    }
    
    // MARK: - JWT Decoder Interface
    
    private var jwtDecoderInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // JWT Token Input
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("JWT Token")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextEditor(text: $jwtToken)
                    .font(.system(size: 14, design: .monospaced))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                    .onChange(of: jwtToken) { _, _ in decodeJWT() }
            }
            .frame(height: 120)
            
            // Decoded sections
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Header")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jwtHeader.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jwtHeader)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    ScrollView {
                        Text(jwtHeader.isEmpty ? "Header will appear here..." : jwtHeader)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(jwtHeader.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
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
                
                // Payload
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Payload")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !jwtPayload.isEmpty {
                            Button("Copy") {
                                copyToClipboard(jwtPayload)
                            }
                            .buttonStyle_custom(.ghost)
                        }
                    }
                    
                    ScrollView {
                        Text(jwtPayload.isEmpty ? "Payload will appear here..." : jwtPayload)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(jwtPayload.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
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
    
    // MARK: - GraphQL Generator Interface
    
    private var graphqlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Operation type selector
            HStack {
                Text("Operation Type:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Operation", selection: $graphqlOperation) {
                    ForEach(GraphQLOperation.allCases, id: \.self) { op in
                        Text(op.title).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
            }
            
            // Query and Variables
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("GraphQL \(graphqlOperation.title)")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $graphqlQuery)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: graphqlQuery) { _, _ in generateGraphQLResult() }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Variables (JSON)")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $graphqlVariables)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: graphqlVariables) { _, _ in generateGraphQLResult() }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 250)
            
            // Generated Result
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Generated Request")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !graphqlResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(graphqlResult)
                        }
                        .buttonStyle_custom(.primary)
                    }
                }
                
                ScrollView {
                    Text(graphqlResult.isEmpty ? "Generated request will appear here..." : graphqlResult)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(graphqlResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.lg)
                        .textSelection(.enabled)
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
            .frame(maxHeight: .infinity)
        }
        .onChange(of: graphqlOperation) { _, _ in generateGraphQLResult() }
    }
    
    // MARK: - API Mockup Interface
    
    private var apiMockupInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Controls
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Response Type:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Type", selection: $apiResponseType) {
                        ForEach(APIResponseType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Count:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        TextField("Count", value: $apiResponseCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        Stepper("", value: $apiResponseCount, in: 1...100)
                    }
                }
                
                Spacer()
                
                Button("Generate") {
                    generateAPIResponse()
                }
                .buttonStyle_custom(.primary)
            }
            
            // Custom schema (for custom type)
            if apiResponseType == .custom {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Custom Schema (JSON)")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $apiCustomSchema)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .frame(height: 150)
            }
            
            // Generated Response
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Generated API Response")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !apiResponseResult.isEmpty {
                        Button("Copy") {
                            copyToClipboard(apiResponseResult)
                        }
                        .buttonStyle_custom(.primary)
                    }
                }
                
                ScrollView {
                    Text(apiResponseResult.isEmpty ? "Generated response will appear here..." : apiResponseResult)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(apiResponseResult.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(DesignSystem.Spacing.lg)
                        .textSelection(.enabled)
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
            .frame(maxHeight: .infinity)
        }
        .onChange(of: apiResponseType) { _, _ in generateAPIResponse() }
        .onChange(of: apiResponseCount) { _, _ in generateAPIResponse() }
        .onAppear { generateAPIResponse() }
    }
    
    // MARK: - YAML-JSON Converter Interface
    
    private var yamlJsonConverterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Mode selector
            HStack {
                Text("Conversion:")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Picker("Mode", selection: $yamlJsonMode) {
                    ForEach(YAMLJSONMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                Spacer()
            }
            
            // Input/Output layout
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(yamlJsonMode.inputTitle)
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $yamlJsonInput)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: yamlJsonInput) { _, _ in convertYamlJson() }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text(yamlJsonMode.outputTitle)
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !yamlJsonOutput.isEmpty {
                            Button("Copy") {
                                copyToClipboard(yamlJsonOutput)
                            }
                            .buttonStyle_custom(.primary)
                        }
                    }
                    
                    ScrollView {
                        Text(yamlJsonOutput.isEmpty ? "Converted output will appear here..." : yamlJsonOutput)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(yamlJsonOutput.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.textPrimary)
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
        .onChange(of: yamlJsonMode) { _, _ in convertYamlJson() }
    }
    
    // MARK: - Text Diff Interface
    
    private var textDiffInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with action buttons
            HStack {
                Text("Text Comparison")
                    .font(DesignSystem.Typography.headline2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button("Clear") {
                        clearDiffInputs()
                    }
                    .buttonStyle_custom(.secondary)
                    
                    Button("Compare") {
                        generateTextDiff()
                    }
                    .buttonStyle_custom(.primary)
                    .disabled(diffText1.isEmpty && diffText2.isEmpty)
                }
            }
            
            // Side-by-side input
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(DesignSystem.Colors.error)
                        Text("Original Text")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    TextEditor(text: $diffText1)
                        .font(.system(size: 14, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: diffText1) { _, _ in 
                            if !diffText1.isEmpty || !diffText2.isEmpty {
                                generateTextDiff()
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                
                // Separator
                Rectangle()
                    .fill(DesignSystem.Colors.border)
                    .frame(width: 1)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("Modified Text")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    TextEditor(text: $diffText2)
                        .font(.system(size: 14, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: diffText2) { _, _ in 
                            if !diffText1.isEmpty || !diffText2.isEmpty {
                                generateTextDiff()
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 200)
            
            // Diff results - Side by side comparison
            if !diffResult.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Comparison Results")
                            .font(DesignSystem.Typography.bodySemibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        // Statistics
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Circle()
                                    .fill(DesignSystem.Colors.error)
                                    .frame(width: 8, height: 8)
                                Text("\(diffStats.removed) removed")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Circle()
                                    .fill(DesignSystem.Colors.success)
                                    .frame(width: 8, height: 8)
                                Text("\(diffStats.added) added")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Circle()
                                    .fill(DesignSystem.Colors.textSecondary)
                                    .frame(width: 8, height: 8)
                                Text("\(diffStats.unchanged) unchanged")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // Side-by-side diff display
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(enhancedDiffResult.enumerated()), id: \.offset) { index, diffPair in
                                HStack(spacing: 0) {
                                    // Left side (original)
                                    HStack {
                                        Text("\(diffPair.lineNumber)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .frame(width: 35, alignment: .trailing)
                                        
                                        Text(diffPair.original?.displayText ?? "")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(diffPair.original?.type.color ?? DesignSystem.Colors.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(diffPair.original?.type.backgroundColor ?? Color.clear)
                                    .frame(maxWidth: .infinity)
                                    
                                    // Center divider
                                    Rectangle()
                                        .fill(DesignSystem.Colors.border.opacity(0.5))
                                        .frame(width: 1)
                                    
                                    // Right side (modified)
                                    HStack {
                                        Text("\(diffPair.lineNumber)")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .frame(width: 35, alignment: .trailing)
                                        
                                        Text(diffPair.modified?.displayText ?? "")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(diffPair.modified?.type.color ?? DesignSystem.Colors.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(diffPair.modified?.type.backgroundColor ?? Color.clear)
                                    .frame(maxWidth: .infinity)
                                }
                                .overlay(
                                    // Top border for better separation
                                    Rectangle()
                                        .fill(DesignSystem.Colors.border.opacity(0.2))
                                        .frame(height: 0.5),
                                    alignment: .top
                                )
                            }
                        }
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
                .frame(maxHeight: .infinity)
            } else if !diffText1.isEmpty || !diffText2.isEmpty {
                // Empty state when texts are identical
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("No differences found")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("The texts are identical")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                        .fill(DesignSystem.Colors.success.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Regex Tester Interface
    
    private var regexTesterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Pattern and flags
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Regular Expression Pattern")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextField("Enter regex pattern...", text: $regexPattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14, design: .monospaced))
                    .onChange(of: regexPattern) { _, _ in testRegex() }
                
                // Flags
                HStack {
                    Text("Flags:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(RegexFlag.allCases, id: \.self) { flag in
                        Toggle(flag.title, isOn: Binding(
                            get: { regexFlags.contains(flag) },
                            set: { isOn in
                                if isOn {
                                    regexFlags.insert(flag)
                                } else {
                                    regexFlags.remove(flag)
                                }
                                testRegex()
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                    
                    Spacer()
                }
            }
            
            // Test text and results
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Test Text")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: $regexText)
                        .font(.system(size: 14, design: .monospaced))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .onChange(of: regexText) { _, _ in testRegex() }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Matches (\(regexMatches.count))")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            ForEach(Array(regexMatches.enumerated()), id: \.offset) { index, match in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Match \(index + 1)")
                                        .font(DesignSystem.Typography.captionMedium)
                                        .foregroundColor(DesignSystem.Colors.success)
                                    
                                    let matchText = String(regexText[Range(match.range, in: regexText)!])
                                    Text(matchText)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .padding(.horizontal, DesignSystem.Spacing.sm)
                                        .padding(.vertical, DesignSystem.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                                .fill(DesignSystem.Colors.success.opacity(0.1))
                                        )
                                }
                            }
                        }
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
    
    // MARK: - QR Generator Interface
    
    private var qrGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Input and settings
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Text to encode")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                TextEditor(text: $qrText)
                    .font(.system(size: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                    .onChange(of: qrText) { _, _ in generateQRCode() }
            }
            .frame(height: 120)
            
            // Style and size controls
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Style:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Style", selection: $qrStyle) {
                        ForEach(QRStyle.allCases, id: \.self) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Size:")
                        .font(DesignSystem.Typography.bodySemibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Size", selection: $qrSize) {
                        ForEach(QRSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                Spacer()
                
                if qrCode != nil {
                    Button("Save Image") {
                        saveQRCode()
                    }
                    .buttonStyle_custom(.secondary)
                    
                    Button("Copy Image") {
                        copyQRCodeToClipboard()
                    }
                    .buttonStyle_custom(.primary)
                }
            }
            
            // Generated QR Code
            VStack(spacing: DesignSystem.Spacing.lg) {
                if let qrCode = qrCode {
                    Image(nsImage: qrCode)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: qrSize.displaySize, height: qrSize.displaySize)
                        .background(qrStyle.backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: qrStyle.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: qrStyle.cornerRadius)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                        .fill(DesignSystem.Colors.surface)
                        .frame(width: qrSize.displaySize, height: qrSize.displaySize)
                        .overlay(
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text("QR code will appear here")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: qrStyle) { _, _ in generateQRCode() }
        .onChange(of: qrSize) { _, _ in generateQRCode() }
        .onAppear { generateQRCode() }
    }
    
    // MARK: - Helper Functions
    
    private func clearInputs() {
        jsonInput = ""
        jsonOutput = ""
        hashInput = ""
        hashResult = ""
        base64Input = ""
        base64Output = ""
        draggedFileName = nil
        fileData = nil
        
        // Clear new inputs
        curlURL = ""
        curlHeaders = ""
        curlBody = ""
        curlResult = ""
        jwtToken = ""
        jwtHeader = ""
        jwtPayload = ""
        jwtSignature = ""
        graphqlQuery = ""
        graphqlVariables = ""
        graphqlResult = ""
        apiResponseResult = ""
        apiCustomSchema = ""
        yamlJsonInput = ""
        yamlJsonOutput = ""
        diffText1 = ""
        diffText2 = ""
        diffResult = []
        regexPattern = ""
        regexText = ""
        regexMatches = []
        regexFlags = []
        qrText = ""
        qrCode = nil
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
    
    // MARK: - cURL Functions
    
    private func generateCURL() {
        guard !curlURL.isEmpty else {
            curlResult = ""
            return
        }
        
        var command = "curl -X \(curlMethod.rawValue) \\\n"
        command += "  '\(curlURL)'"
        
        // Add headers
        if !curlHeaders.isEmpty {
            let headers = curlHeaders.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for header in headers {
                command += " \\\n  -H '\(header.trimmingCharacters(in: .whitespaces))'"
            }
        }
        
        // Add body for methods that support it
        if curlMethod.hasBody && !curlBody.isEmpty {
            command += " \\\n  -d '\(curlBody)'"
        }
        
        curlResult = command
    }
    
    // MARK: - JWT Functions
    
    private func decodeJWT() {
        guard !jwtToken.isEmpty else {
            jwtHeader = ""
            jwtPayload = ""
            jwtSignature = ""
            return
        }
        
        let components = jwtToken.components(separatedBy: ".")
        guard components.count == 3 else {
            jwtHeader = "❌ Invalid JWT format"
            jwtPayload = "❌ Invalid JWT format"
            jwtSignature = "❌ Invalid JWT format"
            return
        }
        
        // Decode header
        if let headerData = base64URLDecode(components[0]),
           let headerString = String(data: headerData, encoding: .utf8) {
            jwtHeader = formatJSON(headerString)
        } else {
            jwtHeader = "❌ Failed to decode header"
        }
        
        // Decode payload
        if let payloadData = base64URLDecode(components[1]),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            jwtPayload = formatJSON(payloadString)
        } else {
            jwtPayload = "❌ Failed to decode payload"
        }
        
        jwtSignature = components[2]
    }
    
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let padding = base64.count % 4
        if padding > 0 {
            base64 += String(repeating: "=", count: 4 - padding)
        }
        
        return Data(base64Encoded: base64)
    }
    
    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]) else {
            return jsonString
        }
        return String(data: prettyData, encoding: .utf8) ?? jsonString
    }
    
    // MARK: - GraphQL Functions
    
    private func generateGraphQLResult() {
        guard !graphqlQuery.isEmpty else {
            graphqlResult = ""
            return
        }
        
        var result = "{\n  \"query\": \"\(escapeForJSON(graphqlQuery))\""
        
        if !graphqlVariables.isEmpty {
            if let data = graphqlVariables.data(using: .utf8),
               let _ = try? JSONSerialization.jsonObject(with: data) {
                result += ",\n  \"variables\": \(graphqlVariables)"
            } else {
                result += ",\n  \"variables\": ❌ Invalid JSON"
            }
        }
        
        result += "\n}"
        
        graphqlResult = result
    }
    
    private func escapeForJSON(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    // MARK: - API Response Generation
    
    private func generateAPIResponse() {
        switch apiResponseType {
        case .user:
            apiResponseResult = generateUserResponse()
        case .post:
            apiResponseResult = generatePostResponse()
        case .comment:
            apiResponseResult = generateCommentResponse()
        case .product:
            apiResponseResult = generateProductResponse()
        case .order:
            apiResponseResult = generateOrderResponse()
        case .custom:
            apiResponseResult = generateCustomResponse()
        }
    }
    
    private func generateUserResponse() -> String {
        let users = (1...apiResponseCount).map { i in
            """
            {
              "id": \(i),
              "name": "User \(i)",
              "email": "user\(i)@example.com",
              "username": "user\(i)",
              "phone": "+1-555-\(String(format: "%04d", i))",
              "website": "user\(i).example.com",
              "address": {
                "street": "\(100 + i) Main St",
                "suite": "Apt. \(i)",
                "city": "Sample City",
                "zipcode": "\(10000 + i)",
                "geo": {
                  "lat": "\(40.0 + Double(i) * 0.1)",
                  "lng": "\(-74.0 + Double(i) * 0.1)"
                }
              },
              "company": {
                "name": "Company \(i)",
                "catchPhrase": "Innovative solutions for tomorrow",
                "bs": "synergistic next-generation applications"
              }
            }
            """
        }
        
        return apiResponseCount == 1 ? users[0] : "[\n" + users.joined(separator: ",\n") + "\n]"
    }
    
    private func generatePostResponse() -> String {
        let posts = (1...apiResponseCount).map { i in
            """
            {
              "id": \(i),
              "userId": \((i - 1) % 10 + 1),
              "title": "Sample Post Title \(i)",
              "body": "This is the body content of post \(i). It contains some sample text to demonstrate what a typical post might look like."
            }
            """
        }
        
        return apiResponseCount == 1 ? posts[0] : "[\n" + posts.joined(separator: ",\n") + "\n]"
    }
    
    private func generateCommentResponse() -> String {
        let comments = (1...apiResponseCount).map { i in
            """
            {
              "id": \(i),
              "postId": \((i - 1) % 100 + 1),
              "name": "Sample Comment \(i)",
              "email": "commenter\(i)@example.com",
              "body": "This is a sample comment \(i). It provides feedback or additional information about the post."
            }
            """
        }
        
        return apiResponseCount == 1 ? comments[0] : "[\n" + comments.joined(separator: ",\n") + "\n]"
    }
    
    private func generateProductResponse() -> String {
        let products = (1...apiResponseCount).map { i in
            """
            {
              "id": \(i),
              "title": "Sample Product \(i)",
              "price": \(19.99 + Double(i) * 10.0),
              "description": "This is a high-quality product \(i) with excellent features and great value.",
              "category": "Electronics",
              "image": "https://via.placeholder.com/300/\(String(format: "%06x", i * 123456 % 0xFFFFFF))",
              "rating": {
                "rate": \(3.5 + Double(i % 3)),
                "count": \(50 + i * 10)
              }
            }
            """
        }
        
        return apiResponseCount == 1 ? products[0] : "[\n" + products.joined(separator: ",\n") + "\n]"
    }
    
    private func generateOrderResponse() -> String {
        let orders = (1...apiResponseCount).map { i in
            """
            {
              "id": \(i),
              "userId": \((i - 1) % 10 + 1),
              "date": "2024-01-\(String(format: "%02d", (i % 28) + 1))",
              "status": "\(["pending", "processing", "shipped", "delivered"][i % 4])",
              "total": \(50.0 + Double(i) * 25.0),
              "items": [
                {
                  "productId": \(i),
                  "quantity": \((i % 3) + 1),
                  "price": \(19.99 + Double(i) * 5.0)
                }
              ]
            }
            """
        }
        
        return apiResponseCount == 1 ? orders[0] : "[\n" + orders.joined(separator: ",\n") + "\n]"
    }
    
    private func generateCustomResponse() -> String {
        guard !apiCustomSchema.isEmpty else {
            return "❌ Please provide a custom schema"
        }
        
        guard let data = apiCustomSchema.data(using: .utf8),
              let schema = try? JSONSerialization.jsonObject(with: data) else {
            return "❌ Invalid JSON schema"
        }
        
        // For simplicity, just return the schema repeated
        let responses = (1...apiResponseCount).map { _ in apiCustomSchema }
        return apiResponseCount == 1 ? responses[0] : "[\n" + responses.joined(separator: ",\n") + "\n]"
    }
    
    // MARK: - YAML-JSON Conversion
    
    private func convertYamlJson() {
        guard !yamlJsonInput.isEmpty else {
            yamlJsonOutput = ""
            return
        }
        
        switch yamlJsonMode {
        case .yamlToJson:
            yamlJsonOutput = convertYamlToJson(yamlJsonInput)
        case .jsonToYaml:
            yamlJsonOutput = convertJsonToYaml(yamlJsonInput)
        }
    }
    
    private func convertYamlToJson(_ yaml: String) -> String {
        // Basic YAML to JSON conversion (simplified)
        // In a real implementation, you'd use a proper YAML parser
        return "❌ YAML parsing not implemented. Use a proper YAML library for full functionality."
    }
    
    private func convertJsonToYaml(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return "❌ Invalid JSON"
        }
        
        // Basic JSON to YAML conversion (simplified)
        return convertObjectToYaml(jsonObject, indent: 0)
    }
    
    private func convertObjectToYaml(_ object: Any, indent: Int) -> String {
        let indentString = String(repeating: "  ", count: indent)
        
        if let dict = object as? [String: Any] {
            return dict.map { key, value in
                if let dictValue = value as? [String: Any] {
                    return "\(indentString)\(key):\n\(convertObjectToYaml(dictValue, indent: indent + 1))"
                } else if let arrayValue = value as? [Any] {
                    return "\(indentString)\(key):\n\(convertObjectToYaml(arrayValue, indent: indent + 1))"
                } else {
                    return "\(indentString)\(key): \(value)"
                }
            }.joined(separator: "\n")
        } else if let array = object as? [Any] {
            return array.map { item in
                "\(indentString)- \(convertObjectToYaml(item, indent: indent + 1).trimmingCharacters(in: .whitespaces))"
            }.joined(separator: "\n")
        } else {
            return "\(object)"
        }
    }
    
    // MARK: - Text Diff Functions
    
    private func generateTextDiff() {
        let lines1 = diffText1.components(separatedBy: .newlines)
        let lines2 = diffText2.components(separatedBy: .newlines)
        
        diffResult = []
        enhancedDiffResult = []
        
        // Generate basic diff result for backward compatibility
        let maxCount = max(lines1.count, lines2.count)
        
        for i in 0..<maxCount {
            let line1 = i < lines1.count ? lines1[i] : ""
            let line2 = i < lines2.count ? lines2[i] : ""
            
            if line1 == line2 {
                diffResult.append(DiffLine(text: line1, type: .same))
            } else {
                if i < lines1.count {
                    diffResult.append(DiffLine(text: "- \(line1)", type: .removed))
                }
                if i < lines2.count {
                    diffResult.append(DiffLine(text: "+ \(line2)", type: .added))
                }
            }
        }
        
        // Generate enhanced side-by-side diff
        enhancedDiffResult = generateSideBySideDiff(lines1: lines1, lines2: lines2)
        
        // Calculate statistics
        var added = 0, removed = 0, unchanged = 0
        
        for pair in enhancedDiffResult {
            if let original = pair.original, let modified = pair.modified {
                if original.type == .same && modified.type == .same {
                    unchanged += 1
                } else if original.type == .removed && modified.type == .added {
                    // Line changed
                    added += 1
                    removed += 1
                }
            } else if pair.original?.type == .removed {
                removed += 1
            } else if pair.modified?.type == .added {
                added += 1
            } else {
                unchanged += 1
            }
        }
        
        diffStats = DiffStats(added: added, removed: removed, unchanged: unchanged)
    }
    
    private func generateSideBySideDiff(lines1: [String], lines2: [String]) -> [DiffPair] {
        var result: [DiffPair] = []
        let maxCount = max(lines1.count, lines2.count)
        
        for i in 0..<maxCount {
            let line1 = i < lines1.count ? lines1[i] : nil
            let line2 = i < lines2.count ? lines2[i] : nil
            
            var originalDiffLine: DiffLine?
            var modifiedDiffLine: DiffLine?
            
            // Determine the type and content for each side
            if let l1 = line1, let l2 = line2 {
                if l1 == l2 {
                    // Lines are identical
                    originalDiffLine = DiffLine(text: l1, type: .same)
                    modifiedDiffLine = DiffLine(text: l2, type: .same)
                } else {
                    // Lines are different
                    originalDiffLine = DiffLine(text: l1, type: .removed)
                    modifiedDiffLine = DiffLine(text: l2, type: .added)
                }
            } else if let l1 = line1 {
                // Line exists only in original
                originalDiffLine = DiffLine(text: l1, type: .removed)
                modifiedDiffLine = nil
            } else if let l2 = line2 {
                // Line exists only in modified
                originalDiffLine = nil
                modifiedDiffLine = DiffLine(text: l2, type: .added)
            }
            
            result.append(DiffPair(
                lineNumber: i + 1,
                original: originalDiffLine,
                modified: modifiedDiffLine
            ))
        }
        
        return result
    }
    
    private func clearDiffInputs() {
        diffText1 = ""
        diffText2 = ""
        diffResult = []
        enhancedDiffResult = []
        diffStats = DiffStats()
    }
    
    // MARK: - Regex Functions
    
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
            let range = NSRange(location: 0, length: regexText.utf16.count)
            regexMatches = regex.matches(in: regexText, options: [], range: range)
        } catch {
            regexMatches = []
        }
    }
    
    // MARK: - QR Code Functions
    
    private func generateQRCode() {
        guard !qrText.isEmpty else {
            qrCode = nil
            return
        }
        
        let data = qrText.data(using: .utf8)!
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: qrSize.rawValue / outputImage.extent.width,
                                                y: qrSize.rawValue / outputImage.extent.height)
                let scaledImage = outputImage.transformed(by: transform)
                
                let rep = NSCIImageRep(ciImage: scaledImage)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                
                qrCode = nsImage
            }
        }
    }
    
    private func saveQRCode() {
        guard let qrCode = qrCode else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "qrcode.png"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let tiffData = qrCode.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
    
    private func copyQRCodeToClipboard() {
        guard let qrCode = qrCode else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([qrCode])
        
        copyToClipboard("QR Code copied to clipboard")
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

// MARK: - Enhanced Diff Data Structures

struct DiffPair {
    let lineNumber: Int
    let original: DiffLine?
    let modified: DiffLine?
}

struct DiffStats {
    let added: Int
    let removed: Int
    let unchanged: Int
    
    init(added: Int = 0, removed: Int = 0, unchanged: Int = 0) {
        self.added = added
        self.removed = removed
        self.unchanged = unchanged
    }
}

// Extension to support enhanced diff functionality
extension DiffLine {
    var displayText: String {
        return text
    }
} 