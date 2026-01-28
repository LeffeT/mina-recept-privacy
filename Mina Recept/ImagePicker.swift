//
//  ImagePicker.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-13.
//


import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    
    enum Source {
        case camera
        case photoLibrary
    }
    
    let source: Source
    let onImagePicked: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        switch source {
        case .camera:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
            } else {
                picker.sourceType = .photoLibrary
            }
        case .photoLibrary:
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // inget att uppdatera
    }
    
    final class Coordinator: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
        
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let image = info[.originalImage] as? UIImage
            parent.onImagePicked(image)
            
            //picker.dismiss(animated: false) {
                // 🔑 Tvinga iOS att släppa kamerans orientationslås
                UIDevice.current.setValue(
                    UIDevice.current.orientation.rawValue,
                    forKey: "orientation"
                )
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                }
                
            }
        }
    }


   
