import SwiftUI

struct DictionaryView: View {
    @State private var query = ""
    @State private var selected: Diagnostic?

    private var results: [Diagnostic] {
        CardiologyDictionary.search(query)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Căutați un diagnostic sau un simptom. Aplicația spune cu voce tare afecțiunile posibile. Nu înlocuiește medicul.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section("Rezultate") {
                    if results.isEmpty {
                        Text("Niciun diagnostic nu se potrivește.")
                    } else {
                        ForEach(results) { diagnosis in
                            Button {
                                selected = diagnosis
                                SpeechHelper.shared.speak(speech(for: diagnosis))
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(diagnosis.romanianName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(diagnosis.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(diagnosis.symptoms.prefix(3).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dicționar cardiologie")
            .searchable(text: $query, prompt: "Simptom sau diagnostic")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Spune posibilele") {
                        speakResults()
                    }
                    .disabled(results.isEmpty)
                }
            }
            .sheet(item: $selected) { diagnosis in
                DiagnosisDetailView(diagnosis: diagnosis)
            }
        }
    }

    private func speakResults() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            SpeechHelper.shared.speak("Scrieți un simptom sau un diagnostic, apoi apăsați din nou ca să audă posibilele afecțiuni.")
            return
        }
        let names = results.prefix(4).map(\.romanianName).joined(separator: ", ")
        SpeechHelper.shared.speak("Pentru \(trimmed), posibile afecțiuni: \(names).")
    }

    private func speech(for diagnosis: Diagnostic) -> String {
        "\(diagnosis.romanianName). Simptome: \(diagnosis.symptoms.prefix(4).joined(separator: ", ")). \(diagnosis.recommendation)"
    }
}

struct DiagnosisDetailView: View {
    let diagnosis: Diagnostic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(diagnosis.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Urgență \(diagnosis.urgency) din 10")
                        .font(.headline)
                        .foregroundStyle(diagnosis.urgency >= 8 ? Color.red : Color.orange)
                    labeled("Simptome", diagnosis.symptoms.joined(separator: ", "))
                    labeled("Ce puteți face", diagnosis.recommendation)
                    labeled("Urgență", diagnosis.emergencyContact)
                    Button {
                        SpeechHelper.shared.speak("\(diagnosis.romanianName). \(diagnosis.recommendation) \(diagnosis.emergencyContact)")
                    } label: {
                        Label("Spune cu voce tare", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle(diagnosis.romanianName)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Închide") { dismiss() }
                }
            }
        }
        .onAppear {
            SpeechHelper.shared.speak("\(diagnosis.romanianName). \(diagnosis.recommendation)")
        }
    }

    private func labeled(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
