import SwiftUI

struct CoverEditView: View {
    @Binding var originalImageData: Data?
    @Binding var currentAppliedOffset: CGSize // Offset applied to the image
    
    let targetBannerWidth: CGFloat     // Now represents a conceptual aspect ratio width
    let targetBannerHeight: CGFloat    // Now represents a conceptual aspect ratio height
    
    @EnvironmentObject var uiSettings: UISettings
    @Environment(\.dismiss) var dismiss
    
    @State private var nsImageToEdit: NSImage?
    @State private var imageOriginalSize: CGSize = .zero
    @State private var editableOffset: CGSize = .zero // Offset of the yellow box center from preview image center
    @State private var liveDragOffset: CGSize = .zero // For live dragging
    
    private var previewImageMaxDim: CGFloat { 300 * uiSettings.layoutScaleFactor }
    
    private var displayedImagePreviewSize: CGSize {
        guard let image = nsImageToEdit, image.size.width > 0, image.size.height > 0 else { return .zero }
        let originalAspectRatio = image.size.width / image.size.height
        
        var previewWidth = previewImageMaxDim
        var previewHeight = previewImageMaxDim
        
        if originalAspectRatio > 1 { // Landscape image
            previewHeight = previewWidth / originalAspectRatio
        } else { // Portrait or square image
            previewWidth = previewHeight * originalAspectRatio
        }
        
        // Ensure bounds after primary scaling
        if previewWidth > previewImageMaxDim {
            previewWidth = previewImageMaxDim
            previewHeight = previewWidth / originalAspectRatio
        }
        if previewHeight > previewImageMaxDim {
            previewHeight = previewImageMaxDim
            previewWidth = previewHeight * originalAspectRatio
        }
        
        return CGSize(width: previewWidth, height: previewHeight)
    }
    
    private var viewportSizeOnPreview: CGSize {
        guard targetBannerWidth > 0, targetBannerHeight > 0,
              self.displayedImagePreviewSize.width > 0, self.displayedImagePreviewSize.height > 0
        else { return .zero }

        let previewContainerSize = self.displayedImagePreviewSize
        // Aspect ratio of the conceptual banner (e.g., 3:1 passed in)
        let bannerAspectRatio = targetBannerWidth / targetBannerHeight

        // Aspect ratio of the container where the image preview is displayed
        let previewContainerAspectRatio = previewContainerSize.width / previewContainerSize.height

        var viewportFinalWidth: CGFloat
        var viewportFinalHeight: CGFloat

        if bannerAspectRatio > previewContainerAspectRatio {
            // Banner is relatively WIDER than the preview container.
            // Fit the viewport to the WIDTH of the preview container.
            viewportFinalWidth = previewContainerSize.width
            viewportFinalHeight = viewportFinalWidth / bannerAspectRatio
        } else {
            // Banner is relatively TALLER (or same aspect ratio) than the preview container.
            // Fit the viewport to the HEIGHT of the preview container.
            viewportFinalHeight = previewContainerSize.height
            viewportFinalWidth = viewportFinalHeight * bannerAspectRatio
        }

        return CGSize(width: viewportFinalWidth, height: viewportFinalHeight)
    }
    
    var body: some View {
        VStack(spacing: uiSettings.spacing(10)) {
            Text("Drag Yellow Box to Set Banner Focus")
                .font(.title3)
                .padding(.top, uiSettings.padding())
                
            if let image = nsImageToEdit {
                let currentViewportSize = viewportSizeOnPreview
                let previewContainerSize = displayedImagePreviewSize
                
                if previewContainerSize.width > 0 && previewContainerSize.height > 0 && currentViewportSize.width > 0 && currentViewportSize.height > 0 {
                    ZStack {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: previewContainerSize.width, height: previewContainerSize.height)
                            .border(Color.black.opacity(0.2))
                            
                        RoundedRectangle(cornerRadius: uiSettings.cornerRadius(2))
                            .fill(Color.yellow.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: uiSettings.cornerRadius(2)).stroke(Color.yellow, lineWidth: 2))
                            .frame(width: currentViewportSize.width, height: currentViewportSize.height)
                            .offset(x: editableOffset.width + liveDragOffset.width,
                                    y: editableOffset.height + liveDragOffset.height)
                    }
                    .frame(width: previewContainerSize.width, height: previewContainerSize.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in liveDragOffset = value.translation }
                        .onEnded { value in
                            editableOffset.width += value.translation.width
                            editableOffset.height += value.translation.height
                            liveDragOffset = .zero
                            clampEditableOffset()
                        }
                    )
                    .padding(.vertical, uiSettings.padding())
                } else {
                    Text("Error: Image dimensions invalid or target banner results in zero-size preview.")
                        .font(.body).foregroundColor(.red)
                        .frame(height: previewImageMaxDim + uiSettings.padding(40)) // Matched frame
                }
            } else {
                VStack(spacing: uiSettings.spacing()) {
                    Text("Loading Image...").font(.body)
                    ProgressView()
                }
                .frame(height: previewImageMaxDim + uiSettings.padding(40)) // Matched frame
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.body).keyboardShortcut(.cancelAction)
                Spacer()
                Button("Set Focus") {
                    saveFocus()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.body.weight(.semibold))
                .disabled(nsImageToEdit == nil)
            }
            .padding([.horizontal, .bottom], uiSettings.padding())
        }
        .frame(minWidth: 400 * uiSettings.layoutScaleFactor, idealWidth: 500 * uiSettings.layoutScaleFactor,
               minHeight: 400 * uiSettings.layoutScaleFactor, idealHeight: 500 * uiSettings.layoutScaleFactor)
        .onAppear {
            if let data = originalImageData, let img = NSImage(data: data) {
                self.nsImageToEdit = img
                self.imageOriginalSize = img.size
            }
            
            let previewSize = self.displayedImagePreviewSize // Calculated after nsImageToEdit is set
            if imageOriginalSize.width > 0 && imageOriginalSize.height > 0 && previewSize.width > 0 && previewSize.height > 0 {
                let scaleOriginalToPreview = previewSize.width / imageOriginalSize.width // This scale is consistent for width and height
                
                // currentAppliedOffset stores (-deltaFocusRelToImageCenterX, -deltaFocusRelToImageCenterY) in original image coords
                // editableOffset should be (deltaFocusRelToPreviewCenterX, deltaFocusRelToPreviewCenterY) in preview coords
                self.editableOffset = CGSize(
                    width: -currentAppliedOffset.width * scaleOriginalToPreview,
                    height: -currentAppliedOffset.height * scaleOriginalToPreview
                )
            } else {
                self.editableOffset = .zero
            }
            clampEditableOffset()
        }
    }
    
    private func clampEditableOffset() {
        let vpSize = viewportSizeOnPreview
        let previewContainerSize = displayedImagePreviewSize
        
        guard vpSize.width > 0, vpSize.height > 0,
              previewContainerSize.width > 0, previewContainerSize.height > 0, // Added check for container
              previewContainerSize.width >= vpSize.width, // vpSize must fit in container
              previewContainerSize.height >= vpSize.height else {
            // editableOffset = .zero // Avoid resetting if it's just a transient invalid state during setup
            return
        }
        
        let maxAllowedX = (previewContainerSize.width - vpSize.width) / 2.0
        let maxAllowedY = (previewContainerSize.height - vpSize.height) / 2.0
        
        editableOffset.width = min(maxAllowedX, max(-maxAllowedX, editableOffset.width))
        editableOffset.height = min(maxAllowedY, max(-maxAllowedY, editableOffset.height))
    }
    
    private func saveFocus() {
        guard imageOriginalSize.width > 0, imageOriginalSize.height > 0,
              displayedImagePreviewSize.width > 0, displayedImagePreviewSize.height > 0 else {
            // dismiss(); // Don't dismiss if there's nothing to save, allow cancel
            return
        }
        
        let previewSize = displayedImagePreviewSize
        
        // Scale to convert offset from preview image coordinates to original image coordinates
        let scalePreviewToOriginal = imageOriginalSize.width / previewSize.width
        
        // editableOffset is the displacement of the yellow box's center from the preview image's center.
        // Positive editableOffset.width means yellow box is to the right of preview center.
        let deltaFocusRelToImageCenterX_original = editableOffset.width * scalePreviewToOriginal
        let deltaFocusRelToImageCenterY_original = editableOffset.height * scalePreviewToOriginal
        
        // currentAppliedOffset is stored as the amount to shift the image's top-left point.
        // If focus center is (deltaX, deltaY) from image center, we want to shift image by (-deltaX, -deltaY).
        currentAppliedOffset = CGSize(
            width: -deltaFocusRelToImageCenterX_original,
            height: -deltaFocusRelToImageCenterY_original
        )
    }
}
