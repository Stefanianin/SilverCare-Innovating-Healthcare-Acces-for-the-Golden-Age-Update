import MapKit
import SwiftUI

struct HouseLocationView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var session: SessionStore
    @Environment(\.openURL) private var openURL

    @State private var camera: MapCameraPosition = .automatic
    @State private var callFailed = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Atingeți camera în care se află \(session.currentUser?.name ?? "persoana"). Telefonul nu poate vedea prin pereți, așa că camera se alege aici. GPS-ul dă ambulanței poziția casei.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(HouseRoom.allCases) { room in
                            Button {
                                locationManager.select(room: room)
                                SpeechHelper.shared.speak("Locația din casă este \(room.rawValue).")
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: room.symbol)
                                        .font(.title)
                                    Text(room.rawValue)
                                        .font(.headline)
                                    if locationManager.currentRoom == room {
                                        Image(systemName: "figure.stand")
                                            .font(.title2)
                                            .accessibilityLabel("Persoana este aici")
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .padding(8)
                                .background(locationManager.currentRoom == room ? Color.red.opacity(0.18) : Color.gray.opacity(0.12))
                                .foregroundStyle(locationManager.currentRoom == room ? Color.red : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(locationManager.currentRoom == room ? .isSelected : [])
                        }
                    }

                    Text(locationManager.ambulanceLocationText)
                        .font(.title3.weight(.semibold))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let coordinate = locationManager.userLocation {
                        Map(position: $camera) {
                            Marker("Persoana", coordinate: coordinate)
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onAppear {
                            camera = .region(region(for: coordinate))
                        }
                        .onChange(of: coordinate.latitude) { _, _ in
                            camera = .region(region(for: coordinate))
                        }
                    } else {
                        Text(locationManager.lastError ?? "Se caută locația GPS a casei…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button("Cere permisiunea de locație") {
                            locationManager.requestPermissionIfNeeded()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        callAmbulance()
                    } label: {
                        Label("Sună ambulanța din \(locationManager.currentRoom.rawValue)", systemImage: "phone.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
            .navigationTitle("Unde este în casă")
            .alert("Apelul nu a pornit", isPresented: $callFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Pe acest dispozitiv formați 112 și spuneți: \(locationManager.ambulanceLocationText)")
            }
        }
    }

    private func region(for coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
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
