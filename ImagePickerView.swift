import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Select Photo")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Choose a photo from your library")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .colorScheme(.dark)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImageSelected(image)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ImagePickerView { _ in }
} 