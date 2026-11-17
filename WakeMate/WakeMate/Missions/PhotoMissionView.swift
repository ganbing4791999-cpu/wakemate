import SwiftUI
import UIKit

struct PhotoMissionView: View {
    let onSuccess: () -> Void

    @State private var showingCamera = false
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 24) {
            Text("拍照打卡")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text("对准你睡前设定的目标（例如洗手间镜子）拍一张，走到那里就已经醒了。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("已拍摄的打卡照片")
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.quaternary)
                    .frame(height: 240)
                    .overlay(
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    )
                    .accessibilityLabel("尚未拍照")
            }

            Button {
                showingCamera = true
            } label: {
                Text(image == nil ? "打开相机" : "重新拍摄")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: 300)
            .accessibilityLabel("打开相机拍照")

            if image != nil {
                Button("完成打卡") { onSuccess() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: 300, minHeight: 50)
                    .accessibilityLabel("完成拍照打卡")
            }
        }
        .padding(24)
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $image)
                .ignoresSafeArea()
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
