import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTestRunning = false
    @State private var isWaiting = false
    @State private var bgColor = Color.white
    @State private var startTime: Date?
    @State private var reactionTime: Double?
    @State private var showFilePicker = false
    @State private var reactionColor: String = ""
    @State private var reactionDataList: [ReactionData] = []
    @State private var showIgnoreConfirmation = false
    @State private var currentReactionData: ReactionData?
    @State private var isTestRun = false

    var body: some View {
        NavigationView {
            VStack {
                if isTestRunning || reactionTime != nil {
                    ZStack {
                        bgColor
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                if isWaiting {
                                    return
                                }
                                if isTestRunning {
                                    endTest()
                                }
                            }

                        if !isTestRunning && reactionTime != nil {
                            VStack {
                                Text("Reaction Time: \(reactionTime ?? 0, specifier: "%.2f") ms")
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)

                                HStack {
                                    Button("Go to Main Menu") {
                                        reactionTime = nil
                                    }
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)

                                    if !isTestRun {
                                        Button("Ignore This Test") {
                                            showIgnoreConfirmation = true
                                        }
                                        .padding()
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .alert(isPresented: $showIgnoreConfirmation) {
                                            Alert(
                                                title: Text("Ignore This Test"),
                                                message: Text("Are you sure you want to ignore this test? The data will be marked as ignored."),
                                                primaryButton: .destructive(Text("Ignore")) {
                                                    reactionDataList[reactionDataList.count-1].ignore = true
                                                    reactionTime = nil
                                                },
                                                secondaryButton: .cancel()
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        Button("Start Test") {
                            isTestRun = false
                            startTest()
                        }
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Test Run") {
                            isTestRun = true
                            startTest()
                        }
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        if !reactionDataList.isEmpty {
                            Button("Export Data to JSON") {
                                showFilePicker.toggle()
                            }
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .sheet(isPresented: $showFilePicker) {
                                DocumentPickerView(reactionDataList: reactionDataList.filter { !$0.ignore })
                            }
                        }
                    }
                }
            }
            .navigationTitle(isTestRunning ? "" : "Reaction Time Test")
        }
    }

    func startTest() {
        isTestRunning = true
        reactionTime = nil
        bgColor = Color.white
        isWaiting = true
        currentReactionData = nil

        let waitTime = Double.random(in: 2...6)
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            changeColor()
        }
    }

    func changeColor() {
        let colors: [Color] = [.red, .green, .blue]
        let colorNames = ["Red", "Green", "Blue"]
        if let index = colors.indices.randomElement() {
            bgColor = colors[index]
            reactionColor = colorNames[index]
        } else {
            bgColor = .white
            reactionColor = "Unknown"
        }
        isWaiting = false
        startTime = Date()
    }

    func endTest() {
        if let startTime = startTime {
            reactionTime = Date().timeIntervalSince(startTime) * 1000
            if let reactionTime = reactionTime, !isTestRun {
                currentReactionData = ReactionData(timestamp: Date(), reactionTime: reactionTime, color: reactionColor, ignore: false)
                reactionDataList.append(currentReactionData!)
            }
        }
        isTestRunning = false
    }
}

struct ReactionData: Codable {
    let timestamp: Date
    let reactionTime: Double
    let color: String
    var ignore: Bool

    enum CodingKeys: String, CodingKey {
        case timestamp
        case reactionTime
        case color
        case ignore
    }

    // Custom encoder to format the date
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: timestamp)
        try container.encode(dateString, forKey: .timestamp)
        try container.encode(reactionTime, forKey: .reactionTime)
        try container.encode(color, forKey: .color)
        try container.encode(ignore, forKey: .ignore) 
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    var reactionDataList: [ReactionData]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let tempURL = createTempFile()
        let picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                let jsonData = try JSONEncoder().encode(parent.reactionDataList)
                try jsonData.write(to: url)
                print("Data saved to \(url)")
            } catch {
                print("Failed to save data: \(error.localizedDescription)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
    }

    private func createTempFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("ReactionData.json")
        do {
            let jsonData = try JSONEncoder().encode(reactionDataList)
            try jsonData.write(to: tempFileURL)
        } catch {
            print("Failed to create temp file: \(error.localizedDescription)")
        }
        return tempFileURL
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
 
