import SwiftUI
import CoreLocation
import AVFoundation

// MARK: - MODELS

struct Diagnostic {
let name: String
let symptoms: [String]
let recommendation: String
let emergencyContact: String
}

struct Patient {
let name: String
let age: Int
var pulse: Int
var temperature: Double
var menopause: Bool
var diagnoses: [Diagnostic]
}

// MARK: - LOCATION

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
@Published var userLocation: CLLocationCoordinate2D?
private let manager = CLLocationManager()

override init() {
super.init()
manager.delegate = self
manager.requestWhenInUseAuthorization()
manager.startUpdatingLocation()
}

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
userLocation = locations.last?.coordinate
}
}

// MARK: - SPEECH

class SpeechHelper {
private let synthesizer = AVSpeechSynthesizer()

func speak(_ text: String) {
let utterance = AVSpeechUtterance(string: text)
utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
utterance.rate = 0.45
synthesizer.speak(utterance)
}
}

// MARK: - DATA

let cardiologyDiagnoses: [Diagnostic] = [
Diagnostic(
name: "Angina Pectoris",
symptoms: ["chest pain", "pressure", "fatigue"],
recommendation: "Stop activity, rest, use nitroglycerin if prescribed, take aspirin 75mg, call 112 if pain persists.",
emergencyContact: "Call 112 immediately if chest pain lasts more than 15 minutes."
),
Diagnostic(
name: "Myocardial Infarction",
symptoms: ["severe chest pain", "nausea", "sweating", "shortness of breath"],
recommendation: "Take aspirin, call 112 immediately. Life-threatening emergency.",
emergencyContact: "Emergency — Call 112 NOW."
),
Diagnostic(
name: "Chronic Heart Failure",
symptoms: ["swollen legs", "shortness of breath", "fatigue"],
recommendation: "Reduce salt and fluids, take prescribed diuretics (furosemide 40mg).",
emergencyContact: "Call 112 if severe shortness of breath."
),
Diagnostic(
name: "Pulmonary Edema",
symptoms: ["severe shortness of breath", "restlessness"],
recommendation: "Sit upright, call 112 immediately.",
emergencyContact: "Call 112 — medical emergency."
),
Diagnostic(
name: "Syncope",
symptoms: ["fainting", "loss of consciousness", "paleness"],
recommendation: "Lay the person on their side, call 112 if unconscious.",
emergencyContact: "Call 112 immediately."
),
Diagnostic(
name: "Lipothymia",
symptoms: ["lightheadedness", "dizziness"],
recommendation: "Sit or lie down, hydrate, call family if needed.",
emergencyContact: "Call family or 112 if condition worsens."
),
Diagnostic(
name: "Aortic Dissection",
symptoms: ["severe chest pain", "unequal pulse", "blood pressure difference"],
recommendation: "Call 112 immediately, remain calm, avoid movement.",
emergencyContact: "Call 112."
),
Diagnostic(
name: "Acute Limb Ischemia",
symptoms: ["leg pain", "cold leg", "absent pulse"],
recommendation: "Elevate leg, avoid massage/heat, call 112.",
emergencyContact: "Call 112 urgently."
),
Diagnostic(
name: "Thrombophlebitis",
symptoms: ["leg pain", "swelling", "tenderness"],
recommendation: "Elevate leg, cold compress, consult doctor, call 112 if severe.",
emergencyContact: "Call 112 if symptoms worsen."
),
Diagnostic(
name: "Pulmonary Embolism",
symptoms: ["shortness of breath", "agitation", "fainting"],
recommendation: "Call 112 urgently, diagnostic imaging, anticoagulant treatment.",
emergencyContact: "Call 112."
),
Diagnostic(
name: "Stroke",
symptoms: ["face paralysis", "speech difficulty", "arm weakness"],
recommendation: "Lay patient on side, call 112 immediately.",
emergencyContact: "Call 112."
),
Diagnostic(
name: "Cardiac Arrest",
symptoms: ["no pulse", "not breathing", "unconscious"],
recommendation: "Start CPR, call 112.",
emergencyContact: "Call 112 immediately."
),
Diagnostic(
name: "Endocarditis",
symptoms: ["fever", "fatigue", "shortness of breath", "heart murmur"],
recommendation: "Seek medical attention immediately, call 112 if severe.",
emergencyContact: "Call 112."
),
Diagnostic(
name: "Menopause-related Fainting",
symptoms: ["dizziness", "hot flashes", "syncope"],
recommendation: "Sit or lie down immediately, hydrate, call family and monitor pulse.",
emergencyContact: "Call family or 112 if unconscious."
)
]

var patient = Patient(
name: "Jane Doe",
age: 62,
pulse: 78,
temperature: 36.8,
menopause: true,
diagnoses: cardiologyDiagnoses
)

// MARK: - MAIN VIEW

struct ContentView: View {

@State private var inputSymptoms = ""
@State private var result = ""
@State private var severityScore = 0

@State private var emergencyAlert = false
@State private var familyAlert = false
@State private var fallAlert = false

@StateObject private var locationManager = LocationManager()
@Environment(\.openURL) var openURL

let speech = SpeechHelper()

var body: some View {
NavigationView {
ScrollView {
VStack(spacing: 20) {

Text("🫀 SilverCare+ PRO")
.font(.largeTitle)
.bold()

// MARK: PATIENT CARD
VStack(alignment: .leading, spacing: 8) {
Text("👤 \(patient.name)")
Text("🎂 Age: \(patient.age)")

Text("💓 Pulse: \(patient.pulse)")
.foregroundColor(patient.pulse < 60 || patient.pulse > 100 ? .red : .green)

Text("🌡️ \(patient.temperature, specifier: "%.1f")°C")
.foregroundColor(patient.temperature > 37.5 ? .orange : .blue)

Text("⚠️ Menopause: \(patient.menopause ? "Yes" : "No")")
.foregroundColor(patient.menopause ? .purple : .gray)
}
.padding()
.background(Color.gray.opacity(0.1))
.cornerRadius(12)

// MARK: INPUT
TextField("Enter symptoms (comma separated)", text: $inputSymptoms)
.textFieldStyle(RoundedBorderTextFieldStyle())
.padding(.horizontal)

// MARK: BUTTON
Button("🔍 Check Diagnosis") {
let (text, severity) = checkSymptoms(inputSymptoms)
result = text
severityScore = severity

speech.speak("Analysis complete")

if severity >= 8 {
emergencyAlert = true
speech.speak("Critical condition detected")
}
}
.buttonStyle(.borderedProminent)

// MARK: RESULT
if !result.isEmpty {
VStack(alignment: .leading, spacing: 10) {
Text(result)
Text("⚠️ Severity: \(severityScore)/10")
.foregroundColor(severityColor())
.bold()
}
.padding()
.background(Color.blue.opacity(0.1))
.cornerRadius(12)
}

// MARK: LOCATION
if let loc = locationManager.userLocation {
Text("📍 \(loc.latitude), \(loc.longitude)")
.font(.caption)
.foregroundColor(.gray)
}

// MARK: EMERGENCY BUTTON
Button("📿 Emergency Button") {
familyAlert = true
speech.speak("Emergency activated, contacting help")

if let url = URL(string: "tel://112") {
openURL(url)
}
}
.buttonStyle(.borderedProminent)
.tint(.red)

// MARK: AMBULANCE BUTTON
Button("🚑 Call Ambulance") {
emergencyAlert = true
speech.speak("Calling ambulance")

if let url = URL(string: "tel://112") {
openURL(url)
}
}
.buttonStyle(.bordered)
.tint(.orange)
}
.padding()
}
}
}

// MARK: - HELPERS

func severityColor() -> Color {
switch severityScore {
case 0...3: return .green
case 4...6: return .orange
default: return .red
}
}

func checkSymptoms(_ input: String) -> (String, Int) {
let symptoms = input.lowercased().split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

var bestMatch: Diagnostic?
var bestScore = 0

for diag in patient.diagnoses {
let score = diag.symptoms.filter { symptoms.contains($0) }.count
if score > bestScore {
bestScore = score
bestMatch = diag
}
}

if let match = bestMatch {
return ("Possible diagnosis: \(match.name)\n\(match.recommendation)", bestScore * 2)
} else {
return ("No clear diagnosis found. Monitor symptoms.", 1)
}
}
}
