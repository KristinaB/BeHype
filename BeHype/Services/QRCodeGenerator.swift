//
//  QRCodeGenerator.swift
//  BeHype
//
//  QR Code generation service using CoreImage with BeHype design colors
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    private init() {}
    
    /// Generate QR code image using CoreImage with BeHype design colors
    func generateQRCode(for text: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard !text.isEmpty else { return nil }
        
        // For Hyperliquid addresses, use the address directly
        let dataString = text
        
        // Convert string to data
        guard let data = dataString.data(using: .utf8) else { return nil }
        
        // Create QR code generator
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        // Get the output image
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale the image to the desired size
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage and apply BeHype colors
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        // Apply BeHype design colors to the QR code
        return applyBeHypeColors(to: UIImage(cgImage: cgImage), size: size)
    }
    
    /// Apply BeHype design colors to the QR code
    private func applyBeHypeColors(to qrImage: UIImage, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // White background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw the QR code directly
            guard let cgImage = qrImage.cgImage else { return }
            
            // Create color filter to replace black with BeHype blue
            if let coloredImage = createColoredQRCode(from: cgImage, size: size) {
                cgContext.draw(coloredImage, in: CGRect(origin: .zero, size: size))
            }
            
            // Add BeHype logo in center
            addCenterLogo(to: cgContext, size: size)
        }
    }
    
    /// Create colored QR code by replacing black pixels with BeHype blue
    private func createColoredQRCode(from cgImage: CGImage, size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Create bitmap context
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // Draw original QR code
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        // Get pixel data
        guard let data = context.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        // BeHype brand colors (blue from primaryGradientStart)
        let beHypeBlueR: UInt8 = 51  // 0.2 * 255
        let beHypeBlueG: UInt8 = 102 // 0.4 * 255  
        let beHypeBlueB: UInt8 = 255 // 1.0 * 255
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                
                // Check if pixel is black (or dark)
                let r = buffer[pixelIndex]
                let g = buffer[pixelIndex + 1]
                let b = buffer[pixelIndex + 2]
                
                if r < 128 && g < 128 && b < 128 { // Dark pixel
                    buffer[pixelIndex] = beHypeBlueR
                    buffer[pixelIndex + 1] = beHypeBlueG
                    buffer[pixelIndex + 2] = beHypeBlueB
                    buffer[pixelIndex + 3] = 255 // Full alpha
                }
            }
        }
        
        return context.makeImage()
    }
    
    /// Add BeHype logo in the center of the QR code
    private func addCenterLogo(to context: CGContext, size: CGSize) {
        let logoSize = size.width * 0.12 // Smaller to not interfere with QR scanning
        let logoRect = CGRect(
            x: (size.width - logoSize) / 2,
            y: (size.height - logoSize) / 2,
            width: logoSize,
            height: logoSize
        )
        
        // White circle background
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: logoRect)
        
        // BeHype brand color border
        context.setStrokeColor(UIColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1).cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: logoRect)
        
        // "BH" text logo for BeHype
        let textRect = logoRect.insetBy(dx: 2, dy: 2)
        let font = UIFont.systemFont(ofSize: logoSize * 0.3, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1)
        ]
        
        let text = "BH"
        let textSize = text.size(withAttributes: attributes)
        let textOrigin = CGPoint(
            x: textRect.midX - textSize.width / 2,
            y: textRect.midY - textSize.height / 2
        )
        
        text.draw(at: textOrigin, withAttributes: attributes)
    }
}

// MARK: - SwiftUI Integration

struct QRCodeView: View {
    let text: String
    let size: CGSize
    
    init(text: String, size: CGSize = CGSize(width: 200, height: 200)) {
        self.text = text
        self.size = size
    }
    
    var body: some View {
        if let qrImage = QRCodeGenerator.shared.generateQRCode(for: text, size: size) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
        } else {
            // Fallback placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: size.width, height: size.height)
                .overlay(
                    VStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: size.width * 0.4))
                            .foregroundColor(.gray)
                        Text("QR Code")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        QRCodeView(text: "0x3f847d4390b5a2783ea4aed6887474de8ffffa95")
            .frame(width: 200, height: 200)
        
        QRCodeView(text: "test-hyperliquid-address-12345")
            .frame(width: 250, height: 250)
        
        Text("BeHype QR Code Test")
            .font(.caption)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}