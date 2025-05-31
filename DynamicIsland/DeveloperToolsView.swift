import SwiftUI
import CommonCrypto
import Foundation

struct DeveloperToolsView: View {
    @State private var selectedTool: DeveloperTool = .json
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var base64Mode: Base64Mode = .encode
    @State private var selectedHashType: HashType = .sha256
    @State private var showCopiedFeedback = false
    @State private var lastCopiedText = ""
    @State private var draggedFileName: String?
    @State private var draggedFileSize: String?
    @State private var isFileMode: Bool = false
    @State private var fileData: Data?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Tool Selector
            toolSelector
            
            // Tool Interface
            Group {
                switch selectedTool {
                case .json:
                    jsonFormatterInterface
                case .base64:
                    base64Interface
                case .hash:
                    hashInterface
                }
            }
            .animation(DesignSystem.Animation.smooth, value: selectedTool)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .onChange(of: inputText) { _, _ in
            processInput()
        }
        .onChange(of: selectedTool) { _, _ in
            inputText = ""
            outputText = ""
            isFileMode = false
            draggedFileName = nil
            draggedFileSize = nil
            fileData = nil
        }
        .onChange(of: base64Mode) { _, _ in
            if selectedTool == .base64 {
                processInput()
            }
        }
        .onChange(of: selectedHashType) { _, _ in
            if selectedTool == .hash {
                processInput()
            }
        }
    }
    
    private var toolSelector: some View {
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
        .padding(.horizontal, DesignSystem.Spacing.xs)
    }
    
    private var jsonFormatterInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // JSON Controls
            HStack {
                Text("JSON")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ActionButton(title: "Format", icon: "text.alignleft") {
                        formatJSON()
                    }
                    
                    ActionButton(title: "Minify", icon: "text.compress") {
                        minifyJSON()
                    }
                    
                    ActionButton(title: "Validate", icon: "checkmark.shield") {
                        validateJSON()
                    }
                }
            }
            
            // Input/Output
            inputOutputInterface
        }
    }
    
    private var base64Interface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Base64 Controls
            HStack {
                Text("Base64")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Mode Selector
                Picker("Mode", selection: $base64Mode) {
                    ForEach(Base64Mode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            // Input/Output
            inputOutputInterface
        }
    }
    
    private var hashInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Hash Controls
            HStack {
                Text("Hash")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Mode Toggle
                Button(action: {
                    withAnimation(DesignSystem.Animation.gentle) {
                        isFileMode.toggle()
                        inputText = ""
                        outputText = ""
                        draggedFileName = nil
                        draggedFileSize = nil
                        fileData = nil
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: isFileMode ? "doc.fill" : "textformat")
                            .font(.system(size: 10, weight: .medium))
                        Text(isFileMode ? "File" : "Text")
                            .font(DesignSystem.Typography.micro)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                
                // Hash Type Selector
                Menu {
                    ForEach(HashType.allCases, id: \.self) { hashType in
                        Button(action: {
                            selectedHashType = hashType
                        }) {
                            HStack {
                                Text(hashType.title)
                                if selectedHashType == hashType {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text(selectedHashType.title)
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
            }
            
            // Input/Output for hash
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Input
                if isFileMode {
                    fileDropArea
                } else {
                    textHashInput
                }
                
                // Hash Outputs
                if !inputText.isEmpty {
                    hashOutputs
                }
            }
        }
    }
    
    private var inputOutputInterface: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Input
            InputTextArea(
                title: selectedTool == .base64 ? (base64Mode == .encode ? "Text" : "Base64") : "Input",
                text: $inputText,
                placeholder: getPlaceholder()
            )
            
            // Output
            if !outputText.isEmpty {
                OutputTextArea(
                    title: selectedTool == .base64 ? (base64Mode == .encode ? "Base64" : "Text") : "Output",
                    text: outputText,
                    isSuccess: isOutputSuccess()
                ) {
                    copyToClipboard(outputText)
                }
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
                        if let fileSize = draggedFileSize {
                            Text("(\(fileSize))")
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
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
    
    private var textHashInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Input")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            
            TextEditor(text: $inputText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 80)
                .padding(DesignSystem.Spacing.sm)
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
                        if inputText.isEmpty {
                            HStack {
                                VStack {
                                    HStack {
                                        Text("Enter text to hash...")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                                            .padding(.leading, DesignSystem.Spacing.sm)
                                            .padding(.top, DesignSystem.Spacing.sm + 2)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
    
    private var hashOutputs: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(HashType.allCases, id: \.self) { hashType in
                HashOutputRow(
                    type: hashType,
                    hash: isFileMode && fileData != nil ? 
                        generateHashFromData(fileData!, type: hashType) : 
                        generateHash(inputText, type: hashType),
                    isSelected: selectedHashType == hashType
                ) {
                    let hash = isFileMode && fileData != nil ? 
                        generateHashFromData(fileData!, type: hashType) : 
                        generateHash(inputText, type: hashType)
                    copyToClipboard(hash)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func processInput() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        switch selectedTool {
        case .json:
            formatJSON()
        case .base64:
            processBase64()
        case .hash:
            outputText = generateHash(inputText, type: selectedHashType)
        }
    }
    
    private func formatJSON() {
        guard !inputText.isEmpty else { return }
        
        do {
            let jsonData = inputText.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            outputText = String(data: formattedData, encoding: .utf8) ?? "Invalid JSON"
        } catch {
            outputText = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func minifyJSON() {
        guard !inputText.isEmpty else { return }
        
        do {
            let jsonData = inputText.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            outputText = String(data: minifiedData, encoding: .utf8) ?? "Invalid JSON"
        } catch {
            outputText = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func validateJSON() {
        guard !inputText.isEmpty else { return }
        
        do {
            let jsonData = inputText.data(using: .utf8) ?? Data()
            _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
            outputText = "✅ Valid JSON"
        } catch {
            outputText = "❌ Invalid JSON: \(error.localizedDescription)"
        }
    }
    
    private func processBase64() {
        guard !inputText.isEmpty else { return }
        
        switch base64Mode {
        case .encode:
            let encoded = Data(inputText.utf8).base64EncodedString()
            outputText = encoded
        case .decode:
            guard let decodedData = Data(base64Encoded: inputText) else {
                outputText = "❌ Invalid Base64"
                return
            }
            outputText = String(data: decodedData, encoding: .utf8) ?? "❌ Invalid UTF-8"
        }
    }
    
    private func generateHash(_ input: String, type: HashType) -> String {
        let data = Data(input.utf8)
        
        switch type {
        case .md5:
            return data.md5
        case .sha1:
            return data.sha1
        case .sha256:
            return data.sha256
        case .sha512:
            return data.sha512
        }
    }
    
    private func generateHashFromData(_ data: Data, type: HashType) -> String {
        switch type {
        case .md5:
            return data.md5
        case .sha1:
            return data.sha1
        case .sha256:
            return data.sha256
        case .sha512:
            return data.sha512
        }
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
    
    private func getPlaceholder() -> String {
        switch selectedTool {
        case .json:
            return "Paste your JSON here..."
        case .base64:
            return base64Mode == .encode ? "Enter text to encode..." : "Paste Base64 to decode..."
        case .hash:
            return "Enter text to hash..."
        }
    }
    
    private func isOutputSuccess() -> Bool {
        return !outputText.hasPrefix("❌")
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
            let rawFileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileSize = formatFileSize(rawFileData.count)
            
            DispatchQueue.main.async {
                self.draggedFileName = fileName
                self.draggedFileSize = fileSize
                self.fileData = rawFileData
                // Set a placeholder for inputText to trigger hash display
                self.inputText = "FILE_DATA_LOADED"
            }
        } catch {
            DispatchQueue.main.async {
                self.outputText = "❌ Could not read file: \(error.localizedDescription)"
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
                    .font(.system(size: 16, weight: .medium))
                Text(tool.title)
                    .font(DesignSystem.Typography.micro)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isSelected ? tool.color : DesignSystem.Colors.surface.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

struct InputTextArea: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            
            TextEditor(text: $text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 80)
                .padding(DesignSystem.Spacing.sm)
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
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                                            .padding(.leading, DesignSystem.Spacing.sm)
                                            .padding(.top, DesignSystem.Spacing.sm + 2)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
}

struct OutputTextArea: View {
    let title: String
    let text: String
    let isSuccess: Bool
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Button(action: onCopy) {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .medium))
                        Text("Copy")
                            .font(DesignSystem.Typography.micro)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                HStack {
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(isSuccess ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    Spacer()
                }
            }
            .frame(height: 80)
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                    .fill(isSuccess ? DesignSystem.Colors.surface.opacity(0.2) : DesignSystem.Colors.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.md)
                            .stroke(isSuccess ? DesignSystem.Colors.border.opacity(0.3) : DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
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
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.sm)
                    .fill(DesignSystem.Colors.surface.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

struct HashOutputRow: View {
    let type: HashType
    let hash: String
    let isSelected: Bool
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            Text(type.title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text(hash)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            
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

// MARK: - Data Models

enum DeveloperTool: CaseIterable {
    case json, base64, hash
    
    var title: String {
        switch self {
        case .json: return "JSON"
        case .base64: return "Base64"
        case .hash: return "Hash"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "curlybraces"
        case .base64: return "textformat.abc.dottedunderline"
        case .hash: return "number.square"
        }
    }
    
    var color: Color {
        switch self {
        case .json: return DesignSystem.Colors.primary
        case .base64: return DesignSystem.Colors.success
        case .hash: return DesignSystem.Colors.warning
        }
    }
}

enum Base64Mode: CaseIterable {
    case encode, decode
    
    var title: String {
        switch self {
        case .encode: return "Encode"
        case .decode: return "Decode"
        }
    }
}

enum HashType: CaseIterable {
    case md5, sha1, sha256, sha512
    
    var title: String {
        switch self {
        case .md5: return "MD5"
        case .sha1: return "SHA1"
        case .sha256: return "SHA256"
        case .sha512: return "SHA512"
        }
    }
    
    var color: Color {
        switch self {
        case .md5: return DesignSystem.Colors.error
        case .sha1: return DesignSystem.Colors.warning
        case .sha256: return DesignSystem.Colors.success
        case .sha512: return DesignSystem.Colors.primary
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
    
    var sha512: String {
        let hash = self.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            CC_SHA512(bytes.baseAddress, CC_LONG(self.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
} 