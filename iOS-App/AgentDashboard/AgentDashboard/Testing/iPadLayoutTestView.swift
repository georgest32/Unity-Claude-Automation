//
//  iPadLayoutTestView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  iPad layout testing and validation framework
//

import SwiftUI

// MARK: - iPad Layout Testing View

struct iPadLayoutTestView: View {
    @State private var selectedDevice: iPadDeviceType = .current()
    @State private var selectedOrientation: DeviceOrientation = .portrait
    @State private var testResults: [LayoutTestResult] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Device and orientation selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test Configuration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Device Type")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Device", selection: $selectedDevice) {
                                ForEach([iPadDeviceType.iPadMini, .iPad, .iPadAir, .iPadPro11, .iPadPro12_9], id: \.self) { device in
                                    Text(device.displayName).tag(device)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Orientation")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Orientation", selection: $selectedOrientation) {
                                ForEach(DeviceOrientation.allCases, id: \.self) { orientation in
                                    Text(orientation.rawValue).tag(orientation)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Layout preview
                iPadLayoutPreview(
                    device: selectedDevice,
                    orientation: selectedOrientation
                )
                
                // Test results
                if !testResults.isEmpty {
                    iPadTestResultsView(results: testResults)
                }
                
                Spacer()
                
                // Test actions
                HStack(spacing: 16) {
                    Button("Run Layout Tests") {
                        runLayoutTests()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Clear Results") {
                        testResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("iPad Layout Testing")
        }
    }
    
    private func runLayoutTests() {
        testResults.removeAll()
        
        let devices: [iPadDeviceType] = [.iPadMini, .iPad, .iPadAir, .iPadPro11, .iPadPro12_9]
        let orientations: [DeviceOrientation] = [.portrait, .landscape]
        
        for device in devices {
            for orientation in orientations {
                let result = performLayoutTest(device: device, orientation: orientation)
                testResults.append(result)
            }
        }
    }
    
    private func performLayoutTest(device: iPadDeviceType, orientation: DeviceOrientation) -> LayoutTestResult {
        // Simulate layout testing
        let screenSize = getScreenSize(for: device, orientation: orientation)
        let columnCount = calculateOptimalColumns(for: screenSize.width)
        let readabilityScore = calculateReadabilityScore(for: screenSize)
        let usabilityScore = calculateUsabilityScore(for: device, orientation: orientation)
        
        return LayoutTestResult(
            device: device,
            orientation: orientation,
            screenSize: screenSize,
            columnCount: columnCount,
            readabilityScore: readabilityScore,
            usabilityScore: usabilityScore,
            passed: readabilityScore > 0.8 && usabilityScore > 0.7
        )
    }
    
    private func getScreenSize(for device: iPadDeviceType, orientation: DeviceOrientation) -> CGSize {
        let baseSizes: [iPadDeviceType: CGSize] = [
            .iPadMini: CGSize(width: 744, height: 1133),
            .iPad: CGSize(width: 820, height: 1180),
            .iPadAir: CGSize(width: 820, height: 1180),
            .iPadPro11: CGSize(width: 834, height: 1194),
            .iPadPro12_9: CGSize(width: 1024, height: 1366)
        ]
        
        guard let baseSize = baseSizes[device] else {
            return CGSize(width: 820, height: 1180)
        }
        
        return orientation == .landscape ? 
            CGSize(width: baseSize.height, height: baseSize.width) : 
            baseSize
    }
    
    private func calculateOptimalColumns(for width: CGFloat) -> Int {
        switch width {
        case 0...800:
            return 2
        case 801...1000:
            return 3
        case 1001...1200:
            return 4
        default:
            return 5
        }
    }
    
    private func calculateReadabilityScore(for screenSize: CGSize) -> Double {
        // Mock readability calculation based on screen size
        let aspectRatio = screenSize.width / screenSize.height
        let idealRatio: Double = 1.4 // Golden ratio approximation
        
        let ratioScore = 1.0 - abs(aspectRatio - idealRatio) / idealRatio
        return max(0.0, min(1.0, ratioScore))
    }
    
    private func calculateUsabilityScore(for device: iPadDeviceType, orientation: DeviceOrientation) -> Double {
        // Mock usability score based on device and orientation
        var score: Double = 0.8
        
        // Adjust for device type
        switch device {
        case .iPadPro12_9:
            score += 0.1
        case .iPadPro11, .iPadAir:
            score += 0.05
        case .iPadMini:
            score -= 0.1
        default:
            break
        }
        
        // Adjust for orientation
        if orientation == .landscape {
            score += 0.05 // Landscape generally better for productivity apps
        }
        
        return max(0.0, min(1.0, score))
    }
}

// MARK: - Test Models

enum DeviceOrientation: String, CaseIterable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}

struct LayoutTestResult {
    let device: iPadDeviceType
    let orientation: DeviceOrientation
    let screenSize: CGSize
    let columnCount: Int
    let readabilityScore: Double
    let usabilityScore: Double
    let passed: Bool
    
    var overallScore: Double {
        (readabilityScore + usabilityScore) / 2.0
    }
}

// MARK: - iPad Layout Preview

struct iPadLayoutPreview: View {
    let device: iPadDeviceType
    let orientation: DeviceOrientation
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Layout Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("\(device.displayName) - \(orientation.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Mock layout preview
            GeometryReader { geometry in
                let previewSize = calculatePreviewSize(geometry.size)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .overlay(
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(height: 20)
                            }
                        }
                        .padding(8)
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func calculatePreviewSize(_ containerSize: CGSize) -> CGSize {
        let screenSize = getScreenSize(for: device, orientation: orientation)
        let aspectRatio = screenSize.width / screenSize.height
        
        let maxWidth = containerSize.width * 0.8
        let maxHeight = containerSize.height * 0.8
        
        if aspectRatio > 1 {
            // Landscape
            let width = min(maxWidth, maxHeight * aspectRatio)
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            // Portrait
            let height = min(maxHeight, maxWidth / aspectRatio)
            return CGSize(width: height * aspectRatio, height: height)
        }
    }
    
    private func getScreenSize(for device: iPadDeviceType, orientation: DeviceOrientation) -> CGSize {
        // Simplified screen size calculation
        let baseSizes: [iPadDeviceType: CGSize] = [
            .iPadMini: CGSize(width: 744, height: 1133),
            .iPad: CGSize(width: 820, height: 1180),
            .iPadAir: CGSize(width: 820, height: 1180),
            .iPadPro11: CGSize(width: 834, height: 1194),
            .iPadPro12_9: CGSize(width: 1024, height: 1366)
        ]
        
        guard let baseSize = baseSizes[device] else {
            return CGSize(width: 820, height: 1180)
        }
        
        return orientation == .landscape ? 
            CGSize(width: baseSize.height, height: baseSize.width) : 
            baseSize
    }
}

// MARK: - Test Results View

struct iPadTestResultsView: View {
    let results: [LayoutTestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(results.indices, id: \.self) { index in
                let result = results[index]
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(result.device.displayName) - \(result.orientation.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Columns: \(result.columnCount), Score: \(String(format: "%.1f", result.overallScore * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.passed ? .green : .red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(result.passed ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}