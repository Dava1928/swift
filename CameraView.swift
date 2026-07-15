import SwiftUI
import UIKit

/// Presents the device camera for capturing a photo.
/// Falls back to photo library when running in Simulator (no camera hardware).
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Coordinator

    class Coordinator: NSObject,
                       UINavigationControllerDelegate,
                       UIImagePickerControllerDelegate {

        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker        = UIImagePickerController()
        picker.delegate   = context.coordinator
        picker.allowsEditing = false

        // Use camera on real device; fall back on Simulator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType       = .camera
            picker.cameraCaptureMode = .photo
            picker.cameraDevice     = .rear
        } else {
            picker.sourceType = .photoLibrary   // Simulator only
        }

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}
}
