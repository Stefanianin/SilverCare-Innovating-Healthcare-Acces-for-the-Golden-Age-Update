import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var session = SessionStore()

    var body: some View {
        Group {
            if session.currentUser == nil {
                LoginView()
            } else {
                TabView {
                    HomeView()
                        .tabItem { Label("Acasă", systemImage: "heart.text.square.fill") }
                    DictionaryView()
                        .tabItem { Label("Dicționar", systemImage: "book.fill") }
                    HouseLocationView()
                        .tabItem { Label("Casă", systemImage: "house.fill") }
                }
            }
        }
        .environmentObject(locationManager)
        .environmentObject(session)
        .tint(.red)
    }
}

struct HomeView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.openURL) private var openURL

    @State private var inputSymptoms = ""
    @State private var matches: [SymptomMatch] = []
    @State private var severityScore = 0
    @State private var didCheck = false
    @State private var showCriticalAlert = false
    @State private var callFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("SilverCare+")
                        .font(.largeTitle.bold())

                    patientCard
                    symptomForm

                    if didCheck {
                        resultCard
                    }

                    Text(locationManager.ambulanceLocationText)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Button {
                        callAmbulance()
                    } label: {
                        Label("Sună ambulanța", systemImage: "phone.fill")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Text("Această aplicație nu pune un diagnostic și nu prescrie medicamente. La urgență sunați la 112.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Cardiologie")
            .toolbar {
                Button("Ieșire") {
                    session.signOut()
                }
            }
            .alert("Posibilă urgență", isPresented: $showCriticalAlert) {
                Button("Sună 112", role: .destructive) { callAmbulance() }
                Button("Nu acum", role: .cancel) {}
            } message: {
                Text("Simptomele pot fi grave. \(locationManager.ambulanceLocationText)")
            }
            .alert("Apelul nu a pornit", isPresented: $callFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Formați 112 și spuneți: \(locationManager.ambulanceLocationText)")
            }
        }
    }

    private var patientCard: some View {
        Group {
            if let user = session.currentUser {
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.name)
                        .font(.title2.bold())
                    Text("Vârstă: \(user.age)")
                    Stepper(value: pulseBinding, in: 30...200) {
                        Text("Puls: \(user.pulse)")
                            .foregroundStyle(user.pulse < 60 || user.pulse > 100 ? Color.red : Color.green)
                    }
                    Stepper(value: temperatureBinding, in: 34...42, step: 0.1) {
                        Text(String(format: "Temperatură: %.1f °C", user.temperature))
                            .foregroundStyle(user.temperature > 37.5 ? Color.orange : Color.blue)
                    }
                    Toggle("Menopauză", isOn: menopauseBinding)
                        .foregroundStyle(user.menopause ? Color.purple : Color.secondary)
                }
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var pulseBinding: Binding<Int> {
        Binding(
            get: { session.currentUser?.pulse ?? 75 },
            set: { value in session.update { $0.pulse = value } }
        )
    }

    private var temperatureBinding: Binding<Double> {
        Binding(
            get: { session.currentUser?.temperature ?? 36.6 },
            set: { value in session.update { $0.temperature = value } }
        )
    }

    private var menopauseBinding: Binding<Bool> {
        Binding(
            get: { session.currentUser?.menopause ?? false },
            set: { value in session.update { $0.menopause = value } }
        )
    }

    private var symptomForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Simptome, separate prin virgulă")
                .font(.headline)
            TextField("de exemplu: durere în piept, lipsă de aer", text: $inputSymptoms, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Button {
                checkSymptoms()
            } label: {
                Label("Caută posibilele afecțiuni", systemImage: "stethoscope")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputSymptoms.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if matches.isEmpty {
                Text("Nicio afecțiune clară. Urmăriți simptomele.")
            } else {
                Text("Posibile afecțiuni")
                    .font(.headline)
                ForEach(matches.prefix(3)) { match in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.diagnostic.romanianName)
                            .font(.title3.bold())
                        Text(match.diagnostic.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(match.diagnostic.recommendation)
                    }
                    .padding(.vertical, 4)
                }
            }
            Text("Gravitate orientativă: \(severityScore)/10")
                .font(.headline)
                .foregroundStyle(severityColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var severityColor: Color {
        switch severityScore {
        case 0...3: .green
        case 4...6: .orange
        default: .red
        }
    }

    private func checkSymptoms() {
        let found = DiagnosisMatcher.match(inputSymptoms, in: CardiologyDictionary.diagnoses)
        matches = found
        severityScore = DiagnosisMatcher.severity(for: found)
        didCheck = true
        SpeechHelper.shared.speak(DiagnosisMatcher.spokenSummary(for: found))
        if severityScore >= 8 {
            showCriticalAlert = true
        }
    }

    private func callAmbulance() {
        let name = session.currentUser?.name ?? "persoana autentificată"
        SpeechHelper.shared.speak("Sun ambulanța pentru \(name). \(locationManager.ambulanceLocationText)")
        guard let url = URL(string: "tel:112") else { return }
        #if os(iOS)
        openURL(url) { accepted in
            if !accepted { callFailed = true }
        }
        #else
        callFailed = true
        #endif
    }
}

#Preview {
    ContentView()
}
