import SwiftUI
import CommonCrypto

struct ExpandedDevToolsView: View {
    @State private var selectedTool: DeveloperTool = .apiClient
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
    
    // UUID Generator
    @State private var generatedUUID: String = ""
    @State private var uuidCount: Int = 1
    @State private var uuidCountText: String = "1"
    @State private var uuidFormat: UUIDFormat = .uppercase
    
    // GraphQL Query Generator
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
    
    // API Client Tabs
    @State private var apiClientTabs: [APIRequestTab] = [APIRequestTab(name: "Request 1")]
    @State private var currentAPITabIndex: Int = 0
    @State private var nextTabNumber: Int = 2 // Track the next tab number to avoid duplicates
    
    var currentAPITab: APIRequestTab {
        guard currentAPITabIndex < apiClientTabs.count else {
            return APIRequestTab()
        }
        return apiClientTabs[currentAPITabIndex]
    }

    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Compact Tool Sidebar
            compactToolSidebar
            
            // Main Interface
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(selectedTool.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        clearInputs()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                    )
                    .buttonStyle(.plain)
                }
                .padding(.all, DesignSystem.Spacing.lg)
                
                Divider()
                
                // Tool Interface
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) { // Increased from lg to xl for more spacing
                        switch selectedTool {
                        case .apiClient:
                            compactApiClientInterface
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
                    .padding(.all, DesignSystem.Spacing.lg)
                }
                .frame(maxHeight: .infinity)
            }
        }
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
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selectedTool == tool ? .white : DesignSystem.Colors.textPrimary)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(tool.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(selectedTool == tool ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(selectedTool == tool ? tool.color : Color.clear)
                        )
                        .contentShape(Rectangle()) // This makes the entire area clickable
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.all, DesignSystem.Spacing.sm)
        }
        .frame(width: 220)
        .background(DesignSystem.Colors.surface.opacity(0.3))
    }
    
    // MARK: - Compact API Client Interface
    
    private var compactApiClientInterface: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(apiClientTabs.indices, id: \.self) { index in
                        APITabButton(
                            tab: apiClientTabs[index],
                            isSelected: index == currentAPITabIndex,
                            onSelect: {
                                currentAPITabIndex = index
                            },
                            onClose: {
                                closeAPITab(at: index)
                            },
                            canClose: apiClientTabs.count > 1
                        )
                    }
                    
                    // Add new tab button
                    Button(action: addNewAPITab) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.surface.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
            }
            
            // Request configuration
            VStack(spacing: DesignSystem.Spacing.md) {
                // Method and URL
                HStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Method")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Menu {
                            ForEach(HTTPMethod.allCases, id: \.self) { method in
                                Button(method.rawValue) {
                                    updateCurrentTab { tab in
                                        tab.method = method
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Text(currentAPITab.method.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                    .fill(DesignSystem.Colors.surface.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("https://api.example.com/endpoint", text: Binding(
                            get: { currentAPITab.url },
                            set: { newValue in
                                updateCurrentTab { tab in
                                    tab.url = newValue
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }
                
                // Headers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Headers")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    TextEditor(text: Binding(
                        get: { currentAPITab.headers },
                        set: { newValue in
                            updateCurrentTab { tab in
                                tab.headers = newValue
                            }
                        }
                    ))
                    .font(.system(size: 13, design: .monospaced)) // Increased font size
                    .frame(height: 100) // Increased from 80
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }
                
                // Body (for POST/PUT/PATCH)
                if currentAPITab.method.hasBody {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Request Body")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextEditor(text: Binding(
                            get: { currentAPITab.body },
                            set: { newValue in
                                updateCurrentTab { tab in
                                    tab.body = newValue
                                }
                            }
                        ))
                        .font(.system(size: 13, design: .monospaced)) // Increased font size
                        .frame(height: 150) // Increased from 120
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                }
                
                // Send button and status
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button(action: sendAPIRequest) {
                        HStack(spacing: 8) {
                            if currentAPITab.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            Text(currentAPITab.isLoading ? "Sending..." : "Send Request")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                .fill(currentAPITab.isLoading ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.primary)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(currentAPITab.url.isEmpty || currentAPITab.isLoading)
                    
                    if currentAPITab.statusCode > 0 {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("Status: \(currentAPITab.statusCode)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(statusCodeColor(currentAPITab.statusCode))
                            
                            if currentAPITab.responseTime > 0 {
                                Text("• \(Int(currentAPITab.responseTime * 1000))ms")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Response
            if !currentAPITab.response.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Response")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        Button("Copy") {
                            copyToClipboard(currentAPITab.response)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    ScrollView {
                        Text(currentAPITab.response)
                            .font(.system(size: 12, design: .monospaced)) // Slightly increased font
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.md) // Increased padding
                            .textSelection(.enabled)
                    }
                    .frame(height: 280) // Increased from 200
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .fill(DesignSystem.Colors.surface.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
            }
        }
        .onChange(of: currentAPITab.method) { _, newMethod in
            if newMethod.hasBody && currentAPITab.body.isEmpty {
                updateCurrentTab { tab in
                    tab.body = newMethod.bodyPlaceholder
                }
            }
        }
    }

    // MARK: - API Tab Button Component
    
    private struct APITabButton: View {
        let tab: APIRequestTab
        let isSelected: Bool
        let onSelect: () -> Void
        let onClose: () -> Void
        let canClose: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                // HTTP Method indicator with color
                Text(tab.method.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(tab.method.color)
                    )
                
                // Status indicator
                Circle()
                    .fill(tab.isLoading ? DesignSystem.Colors.warning : 
                          (tab.statusCode > 0 ? statusCodeColor(tab.statusCode) : DesignSystem.Colors.textSecondary.opacity(0.3)))
                    .frame(width: 6, height: 6)
                
                // Tab name
                Text(tab.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                
                // Close button
                if canClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 12, height: 12)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                    .fill(isSelected ? DesignSystem.Colors.surface : DesignSystem.Colors.surface.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .stroke(isSelected ? DesignSystem.Colors.border : Color.clear, lineWidth: 1)
                    )
            )
            .onTapGesture {
                onSelect()
            }
        }
        
        private func statusCodeColor(_ statusCode: Int) -> Color {
            switch statusCode {
            case 200..<300: return DesignSystem.Colors.success
            case 300..<400: return DesignSystem.Colors.warning
            case 400..<500: return DesignSystem.Colors.error
            case 500..<600: return DesignSystem.Colors.error
            default: return DesignSystem.Colors.textSecondary
            }
        }
    }
    
    // MARK: - Compact JSON Formatter Interface
    
    private var compactJsonFormatterInterface: some View {
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
                    text: jsonOutput,
                    height: 160 // Increased from 60
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
    
    // MARK: - Compact Hash Generator Interface
    
    private var compactHashGeneratorInterface: some View {
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
                    text: hashResult,
                    height: 140 // Increased from 60
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
    
    // MARK: - Compact Base64 Interface
    
    private var compactBase64Interface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Base64 Encoder/Decoder")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Mode toggle
                Menu {
                    Button("Encode") { base64Mode = .encode; processBase64() }
                    Button("Decode") { base64Mode = .decode; processBase64() }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(base64Mode == .encode ? "Encode" : "Decode")
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
                title: base64Mode == .encode ? "Text to Encode" : "Base64 to Decode",
                text: $base64Input,
                placeholder: base64Mode == .encode ? "Enter text to encode..." : "Enter Base64 string to decode...",
                focusBinding: $isInputFocused
            )
            .onChange(of: base64Input) { _, _ in processBase64() }
            
            if !base64Output.isEmpty {
                CompactOutputArea(
                    title: base64Mode == .encode ? "Base64 Encoded" : "Decoded Text",
                    text: base64Output,
                    height: 160 // Increased from 80
                ) {
                    copyToClipboard(base64Output)
                }
            }
        }
    }
    
    // MARK: - Compact UUID Generator Interface
    
    private var compactUuidGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("UUID Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Compact controls
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Count input field with label
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("Count:")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("1", text: $uuidCountText)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(width: 40)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: uuidCountText) { _, newValue in
                                // Validate and update the count
                                if let count = Int(newValue), count >= 1, count <= 1000 {
                                    uuidCount = count
                                } else if newValue.isEmpty {
                                    // Allow empty field temporarily
                                    uuidCount = 1
                                } else {
                                    // Revert to previous valid value
                                    DispatchQueue.main.async {
                                        uuidCountText = "\(uuidCount)"
                                    }
                                }
                            }
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
                    .frame(height: 180) // Increased from 120
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
    
    // MARK: - Compact cURL Generator Interface
    
    private var compactCurlGeneratorInterface: some View {
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
                focusBinding: nil
            )
            .onChange(of: curlHeaders) { _, _ in generateCURL() }
            
            // Body Input (for POST/PUT/PATCH)
            if curlMethod.hasBody {
                CompactInputArea(
                    title: "Request Body",
                    text: $curlBody,
                    placeholder: curlMethod.bodyPlaceholder,
                    focusBinding: nil
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
                    clearCURLInputs()
                }
            }
            
            // Output
            if !curlResult.isEmpty {
                CompactOutputArea(
                    title: "Generated cURL Command",
                    text: curlResult,
                    height: 140 // Increased from 60
                ) {
                    copyToClipboard(curlResult)
                }
            }
        }
    }
    
    // MARK: - Compact JWT Decoder Interface
    
    private var compactJwtDecoderInterface: some View {
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
                VStack(spacing: DesignSystem.Spacing.sm) { // Increased spacing
                    CompactOutputArea(title: "Header", text: jwtHeader, height: 120) { // Increased from 60
                        copyToClipboard(jwtHeader)
                    }
                    
                    CompactOutputArea(title: "Payload", text: jwtPayload, height: 140) { // Increased from 60
                        copyToClipboard(jwtPayload)
                    }
                    
                    if !jwtSignature.isEmpty {
                        CompactOutputArea(title: "Signature", text: jwtSignature, height: 100) { // Increased from 60
                            copyToClipboard(jwtSignature)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Compact GraphQL Generator Interface
    
    private var compactGraphqlGeneratorInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("GraphQL Query Generator")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Operation type dropdown
                Menu {
                    ForEach(GraphQLOperation.allCases, id: \.self) { operation in
                        Button(operation.title) {
                            graphqlOperation = operation
                            generateGraphQLQuery()
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(graphqlOperation.title)
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
                title: "GraphQL \(graphqlOperation.title)",
                text: $graphqlQuery,
                placeholder: graphqlOperation.placeholder,
                focusBinding: $isInputFocused
            )
            .onChange(of: graphqlQuery) { _, _ in generateGraphQLQuery() }
            
            CompactInputArea(
                title: "Variables (JSON)",
                text: $graphqlVariables,
                placeholder: graphqlOperation.variablesPlaceholder,
                focusBinding: nil
            )
            .onChange(of: graphqlVariables) { _, _ in generateGraphQLQuery() }
            
            // Quick action buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                ActionButton(title: "Sample Query", icon: "doc.text") {
                    graphqlOperation = .query
                    graphqlQuery = "users(limit: $limit) {\n  id\n  name\n  email\n  posts {\n    title\n    content\n  }\n}"
                    graphqlVariables = "{\n  \"limit\": 10\n}"
                    generateGraphQLQuery()
                }
                
                ActionButton(title: "Clear", icon: "trash") {
                    clearGraphQLInputs()
                }
            }
            
            // Output
            if !graphqlResult.isEmpty {
                CompactOutputArea(
                    title: "Complete GraphQL Request",
                    text: graphqlResult,
                    height: 300 // Increased from 240
                ) {
                    copyToClipboard(graphqlResult)
                }
            }
        }
    }
    
    // MARK: - Compact API Mockup Interface
    
    private var compactApiMockupInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("API Response Mockup")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Count stepper
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Button("-") {
                            if apiResponseCount > 1 {
                                apiResponseCount -= 1
                                generateAPIResponse()
                            }
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: 16, height: 16)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                        .buttonStyle(.plain)
                        
                        Text("\(apiResponseCount)")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(minWidth: 20)
                        
                        Button("+") {
                            if apiResponseCount < 50 {
                                apiResponseCount += 1
                                generateAPIResponse()
                            }
                        }
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: 16, height: 16)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                .fill(DesignSystem.Colors.surface.opacity(0.3))
                        )
                        .buttonStyle(.plain)
                    }
                    
                    // Response type dropdown
                    Menu {
                        ForEach(APIResponseType.allCases, id: \.self) { type in
                            Button(type.title) {
                                apiResponseType = type
                                generateAPIResponse()
                            }
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text(apiResponseType.title)
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
            
            if apiResponseType == .custom {
                CompactInputArea(
                    title: "Custom Schema (JSON)",
                    text: $apiCustomSchema,
                    placeholder: "{\n  \"name\": \"{{name}}\",\n  \"email\": \"{{email}}\",\n  \"age\": \"{{number}}\"\n}",
                    focusBinding: $isInputFocused
                )
                .onChange(of: apiCustomSchema) { _, _ in generateAPIResponse() }
            }
            
            // Quick action buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                ActionButton(title: "Generate", icon: "arrow.clockwise") {
                    generateAPIResponse()
                }
                
                ActionButton(title: "Clear", icon: "trash") {
                    clearAPIResponse()
                }
            }
            
            // Output
            if !apiResponseResult.isEmpty {
                CompactOutputArea(
                    title: "Generated API Response",
                    text: apiResponseResult,
                    height: 300 // Increased from 240
                ) {
                    copyToClipboard(apiResponseResult)
                }
            }
        }
    }
    
    // MARK: - Compact YAML/JSON Converter Interface
    
    private var compactYamlJsonConverterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("YAML ↔ JSON Converter")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Conversion mode dropdown
                Menu {
                    ForEach(YAMLJSONMode.allCases, id: \.self) { mode in
                        Button(mode.title) {
                            yamlJsonMode = mode
                            convertYAMLJSON()
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(yamlJsonMode.title)
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
                title: yamlJsonMode.inputTitle,
                text: $yamlJsonInput,
                placeholder: yamlJsonMode.placeholder,
                focusBinding: $isInputFocused
            )
            .onChange(of: yamlJsonInput) { _, _ in convertYAMLJSON() }
            
            // Quick action buttons
            HStack(spacing: DesignSystem.Spacing.xs) {
                ActionButton(title: "Sample K8s", icon: "doc.text") {
                    yamlJsonMode = .yamlToJson
                    yamlJsonInput = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
"""
                    convertYAMLJSON()
                }
                
                ActionButton(title: "Clear", icon: "trash") {
                    clearYAMLJSON()
                }
            }
            
            // Output
            if !yamlJsonOutput.isEmpty {
                CompactOutputArea(
                    title: yamlJsonMode.outputTitle,
                    text: yamlJsonOutput,
                    height: 300 // Increased from 240
                ) {
                    copyToClipboard(yamlJsonOutput)
                }
            }
        }
    }
    
    // MARK: - Compact Text Diff Interface
    
    private var compactTextDiffInterface: some View {
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
                    focusBinding: nil
                )
            }
            
            if !diffResult.isEmpty {
                DiffResultView(diffLines: diffResult)
            }
        }
    }
    
    // MARK: - Compact Regex Tester Interface
    
    private var compactRegexTesterInterface: some View {
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
                focusBinding: nil
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
    
    // MARK: - Compact QR Generator Interface
    
    private var compactQrGeneratorInterface: some View {
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
            
            if let qrCode = qrCode {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(nsImage: qrCode)
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
    
    // MARK: - Helper Views
    
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
                .frame(height: 120) // Increased from 80 for expanded view
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
    
    // MARK: - Supporting Views
    
    struct CompactInputArea: View {
        let title: String
        @Binding var text: String
        let placeholder: String
        var focusBinding: FocusState<Bool>.Binding?
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Group {
                    if let focusBinding = focusBinding {
                        TextEditor(text: $text)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(height: 120) // Increased from 60
                            .padding(DesignSystem.Spacing.md)
                            .focused(focusBinding)
                    } else {
                        TextEditor(text: $text)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(height: 120) // Increased from 60
                            .padding(DesignSystem.Spacing.md)
                    }
                }
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
                                            .font(.system(size: 14, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                                            .padding(.leading, DesignSystem.Spacing.md)
                                            .padding(.top, DesignSystem.Spacing.md + 2)
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
        let height: CGFloat
        let action: () -> Void
        
        init(title: String, text: String, height: CGFloat = 120, action: @escaping () -> Void) { // Increased default from 60
            self.title = title
            self.text = text
            self.height = height
            self.action = action
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) { // Increased spacing
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("Copy") {
                        action()
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                
                ScrollView {
                    Text(text)
                        .font(.system(size: 13, design: .monospaced)) // Increased font size
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DesignSystem.Spacing.md) // Increased padding
                        .textSelection(.enabled)
                }
                .frame(height: height)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(diffLines.indices, id: \.self) { index in
                        HStack {
                            Text(diffLines[index].text)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(diffLines[index].type.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(diffLines[index].type.backgroundColor)
                    }
                }
            }
            .frame(height: 180) // Increased from 120 for expanded view
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
    
    struct RegexResultView: View {
        let matches: [NSTextCheckingResult]
        let text: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("\(matches.count) match\(matches.count == 1 ? "" : "es") found")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.success)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ForEach(matches.indices, id: \.self) { index in
                            let match = matches[index]
                            let range = Range(match.range, in: text)
                            if let range = range {
                                HStack {
                                    Text("Match \(index + 1):")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    Text("\"\(String(text[range]))\"")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .padding(.horizontal, DesignSystem.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                                                .fill(DesignSystem.Colors.success.opacity(0.1))
                                        )
                                    
                                    Spacer()
                                    
                                    Text("Position: \(match.range.location)-\(match.range.location + match.range.length)")
                                        .font(.system(size: 9))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                }
                .frame(height: 140) // Increased from 100 for expanded view
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
    
    // MARK: - Processing Functions
    
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
    
    private func handleFileDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                self.draggedFileName = url.lastPathComponent
                do {
                    self.fileData = try Data(contentsOf: url)
                    self.processHash()
                } catch {
                    print("Failed to read file: \(error)")
                }
            }
        }
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
    
    private func clearCURLInputs() {
        curlURL = ""
        curlHeaders = ""
        curlBody = ""
        curlResult = ""
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
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        else {
            return jsonString
        }
        return String(data: prettyData, encoding: .utf8) ?? "Formatting failed"
    }
    
    private func generateGraphQLQuery() {
        guard !graphqlQuery.isEmpty else {
            graphqlResult = ""
            return
        }
        
        let operationType = graphqlOperation.title.lowercased()
        var result = "# GraphQL \(graphqlOperation.title)\n\n"
        
        result += "\(operationType) {\n"
        
        // Clean up the query - remove extra newlines and format properly
        let cleanQuery = graphqlQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = cleanQuery.components(separatedBy: .newlines)
        for line in lines {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result += "  \(line.trimmingCharacters(in: .whitespacesAndNewlines))\n"
            }
        }
        
        result += "}\n"
        
        // Add variables if present
        if !graphqlVariables.isEmpty {
            result += "\n# Variables:\n"
            result += graphqlVariables
        }
        
        // Add HTTP request example
        result += "\n\n# HTTP Request Example:\n"
        result += "POST /graphql\n"
        result += "Content-Type: application/json\n\n"
        result += "{\n"
        result += "  \"query\": \"\(cleanQuery.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\""
        
        if !graphqlVariables.isEmpty {
            result += ",\n  \"variables\": \(graphqlVariables.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        
        result += "\n}"
        
        graphqlResult = result
    }
    
    private func clearGraphQLInputs() {
        graphqlQuery = ""
        graphqlVariables = ""
        graphqlResult = ""
    }
    
    private func generateAPIResponse() {
        var result = ""
        
        if apiResponseType == .custom {
            guard !apiCustomSchema.isEmpty else {
                apiResponseResult = ""
                return
            }
            result = generateCustomAPIResponse()
        } else {
            result = generatePresetAPIResponse()
        }
        
        apiResponseResult = result
    }
    
    private func clearAPIResponse() {
        apiResponseResult = ""
        apiCustomSchema = ""
    }
    
    private func convertYAMLJSON() {
        guard !yamlJsonInput.isEmpty else {
            yamlJsonOutput = ""
            return
        }
        
        switch yamlJsonMode {
        case .yamlToJson:
            yamlJsonOutput = convertYAMLToJSON(yamlJsonInput)
        case .jsonToYaml:
            yamlJsonOutput = convertJSONToYAML(yamlJsonInput)
        }
    }
    
    private func clearYAMLJSON() {
        yamlJsonInput = ""
        yamlJsonOutput = ""
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
            qrCode = nil
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
            qrCode = nsImage
        }
    }
    
    private func saveQRCode() {
        guard let qrCode = qrCode else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "qrcode.png"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let tiffData = qrCode.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
    
    // MARK: - Helper Functions (placeholder implementations)
    
    private func generatePresetAPIResponse() -> String {
        return "{\n  \"message\": \"Preset API response generation not yet implemented in expanded view\"\n}"
    }
    
    private func generateCustomAPIResponse() -> String {
        return "{\n  \"message\": \"Custom API response generation not yet implemented in expanded view\"\n}"
    }
    
    private func convertYAMLToJSON(_ yaml: String) -> String {
        return "{\n  \"message\": \"YAML to JSON conversion not yet implemented in expanded view\"\n}"
    }
    
    private func convertJSONToYAML(_ json: String) -> String {
        return "message: \"JSON to YAML conversion not yet implemented in expanded view\""
    }
    
    private func applyQRStyle(to image: CIImage, style: QRStyle) -> CIImage {
        return image // Simplified for now
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
        
        // Clear API Client tabs
        apiClientTabs = [APIRequestTab(name: "Request 1")]
        currentAPITabIndex = 0
        nextTabNumber = 2
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
    
    private func statusCodeColor(_ statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300: return DesignSystem.Colors.success
        case 300..<400: return DesignSystem.Colors.warning
        case 400..<500: return DesignSystem.Colors.error
        case 500..<600: return DesignSystem.Colors.error
        default: return DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - HTTP Method Colors
extension HTTPMethod {
    var color: Color {
        switch self {
        case .GET: return Color.blue
        case .POST: return Color.green
        case .PUT: return Color.orange
        case .PATCH: return Color.purple
        case .DELETE: return Color.red
        case .HEAD: return Color.gray
        case .OPTIONS: return Color.brown
        }
    }
}

// MARK: - API Client Functions
extension ExpandedDevToolsView {
    private func updateCurrentTab(_ update: (inout APIRequestTab) -> Void) {
        guard currentAPITabIndex < apiClientTabs.count else { return }
        update(&apiClientTabs[currentAPITabIndex])
    }
    
    private func addNewAPITab() {
        let newTab = APIRequestTab(name: "Request \(nextTabNumber)")
        apiClientTabs.append(newTab)
        currentAPITabIndex = apiClientTabs.count - 1
        nextTabNumber += 1
    }
    
    private func duplicateCurrentTab() {
        guard currentAPITabIndex < apiClientTabs.count else { return }
        var newTab = apiClientTabs[currentAPITabIndex]
        newTab.id = UUID()
        newTab.name = "\(newTab.name) Copy"
        newTab.response = ""
        newTab.statusCode = 0
        newTab.responseTime = 0
        newTab.isLoading = false
        apiClientTabs.append(newTab)
        currentAPITabIndex = apiClientTabs.count - 1
    }
    
    private func closeAPITab(at index: Int) {
        guard apiClientTabs.count > 1 && index < apiClientTabs.count else { return }
        apiClientTabs.remove(at: index)
        if currentAPITabIndex >= apiClientTabs.count {
            currentAPITabIndex = apiClientTabs.count - 1
        } else if currentAPITabIndex > index {
            currentAPITabIndex -= 1
        }
    }
    
    private func sendAPIRequest() {
        guard !currentAPITab.url.isEmpty else { return }
        
        updateCurrentTab { tab in
            tab.isLoading = true
            tab.response = ""
            tab.statusCode = 0
            tab.responseTime = 0
        }
        
        let startTime = Date()
        
        // Create URL
        guard let url = URL(string: currentAPITab.url) else {
            updateCurrentTab { tab in
                tab.response = "❌ Invalid URL"
                tab.isLoading = false
            }
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = currentAPITab.method.rawValue
        request.timeoutInterval = 30
        
        // Add headers
        let headerLines = currentAPITab.headers.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        for header in headerLines {
            let components = header.components(separatedBy: ":")
            if components.count >= 2 {
                let key = components[0].trimmingCharacters(in: .whitespaces)
                let value = components.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body for applicable methods
        if currentAPITab.method.hasBody && !currentAPITab.body.isEmpty {
            request.httpBody = currentAPITab.body.data(using: .utf8)
        }
        
        // Perform request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let responseTime = Date().timeIntervalSince(startTime)
                
                self.updateCurrentTab { tab in
                    tab.responseTime = responseTime
                    tab.isLoading = false
                    
                    if let error = error {
                        tab.response = "❌ Error: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        tab.response = "❌ Invalid response"
                        return
                    }
                    
                    tab.statusCode = httpResponse.statusCode
                    
                    // Format response body
                    var responseText = ""
                    if let data = data {
                        if let string = String(data: data, encoding: .utf8) {
                            // Try to format as JSON if possible
                            if let jsonData = string.data(using: .utf8),
                               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                               let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                               let prettyJsonString = String(data: prettyJsonData, encoding: .utf8) {
                                responseText = prettyJsonString
                            } else {
                                responseText = string
                            }
                        } else {
                            responseText = "Binary data (\(data.count) bytes)"
                        }
                    } else {
                        responseText = "No response body"
                    }
                    
                    // Format headers
                    let headers = httpResponse.allHeaderFields.map { key, value in
                        "\(key): \(value)"
                    }.sorted().joined(separator: "\n")
                    
                    // Combine status info and body
                    let statusText = "Status: \(httpResponse.statusCode)\nTime: \(Int(responseTime * 1000))ms\n\nHeaders:\n\(headers)\n\nBody:\n\(responseText)"
                    tab.response = statusText
                }
            }
        }.resume()
    }
} 