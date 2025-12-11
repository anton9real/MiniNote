import SwiftUI
import PDFKit
import PencilKit

struct ContentView: View {
    // We start with a blank PDF for testing since we can't easily drag files in Playgrounds initially
    @State private var pdfData: Data? = nil
    @State private var showFileImporter = false
    @State private var toggleTools = true
    
    var body: some View {
        ZStack(alignment: .top) {
            if let data = pdfData {
                // The Drawing Engine
                PDFKitView(data: data)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture(count: 2) {
                        withAnimation { toggleTools.toggle() }
                    }
            } else {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Document Open")
                        .font(.title2)
                    Button("Import PDF") {
                        showFileImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Minimalist Floating Toolbar
            if toggleTools && pdfData != nil {
                HStack {
                    Image(systemName: "pencil.tip")
                    Text("MiniNote")
                        .font(.caption)
                        .bold()
                    Spacer()
                    Button(action: { showFileImporter = true }) {
                        Label("Open", systemImage: "folder")
                    }
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 5)
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    // In Playgrounds, it's safer to load data into memory immediately
                    if let data = try? Data(contentsOf: url) {
                        self.pdfData = data
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - The Engine
struct PDFKitView: UIViewRepresentable {
    let data: Data
    let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        pdfView.usePageViewController = true
        pdfView.displayDirection = .horizontal
        
        pdfView.pageOverlayViewProvider = context.coordinator
        
        // Setup Pencil Tool Picker
        toolPicker.setVisible(true, forFirstResponder: pdfView)
        toolPicker.addObserver(pdfView)
        pdfView.becomeFirstResponder()
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // If data changed, update document
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, PDFPageOverlayViewProvider {
        var pageCanvasMap = [PDFPage: PKCanvasView]()

        func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            if let existing = pageCanvasMap[page] {
                return existing
            }
            
            let canvas = PKCanvasView(frame: .zero)
            canvas.drawingPolicy = .anyInput
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            
            pageCanvasMap[page] = canvas
            return canvas
        }
    }
}