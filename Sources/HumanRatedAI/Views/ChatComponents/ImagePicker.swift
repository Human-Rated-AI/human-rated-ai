// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ImagePicker.swift
//  human-rated-ai
//
//  Created by Claude on 6/19/25.
//

import SwiftUI

#if !os(Android)
import UIKit
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImageURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    guard let image = image as? UIImage else { return }
                    
                    // Save image to temporary directory and get URL
                    DispatchQueue.main.async {
                        if let imageURL = self.saveImageToTemporary(image) {
                            self.parent.selectedImageURL = imageURL
                        }
                    }
                }
            }
        }
        
        private func saveImageToTemporary(_ image: UIImage) -> URL? {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let filename = "selected_image_\(UUID().uuidString).jpg"
            let fileURL = tempDirectory.appendingPathComponent(filename)
            
            do {
                try imageData.write(to: fileURL)
                return fileURL
            } catch {
                print("Error saving image to temporary directory: \(error)")
                return nil
            }
        }
    }
}
#endif
