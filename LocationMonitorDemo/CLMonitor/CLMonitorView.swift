//
//  ContentView.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/07.
//

import SwiftUI
import CoreLocation

struct CLMonitorView: View {
    @State var locationMonitor = LocationMonitor.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
    }

    var body: some View {
        @Bindable var locationMonitor = locationMonitor

        VStack(spacing: 24) {
            Text("CLCircularGeographicCondition")
                .font(.title3)
                .fontWeight(.bold)


            Toggle("Start Monitor", isOn: $locationMonitor.monitorStarted)
                .frame(width: 200)
            
            if let error = locationMonitor.error {
                Text("Error: \(error.message)")
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.red)
            }

                
            List {
                Section {
                    let targetConditionEvents = locationMonitor.conditionEvents[locationMonitor.conditionIdentifier] ?? []
                    if targetConditionEvents.isEmpty {
                        Text("No Events Available yet.")
                    } else {
                        ForEach(0..<targetConditionEvents.count, id: \.self) { index in
                            let event: CLMonitor.Event = targetConditionEvents[index]
                            Text("\(dateFormatter.string(from: event.date)): \(event.state.string)")
                        }
                    }

                } header: {
                    VStack {
                        Text("Events for condition")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Center: \(locationMonitor.condition.center.latitude.twoDecimalString), \(locationMonitor.condition.center.longitude.twoDecimalString); Radius: \(locationMonitor.condition.radius.twoDecimalString)")
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .contentMargins(.vertical, 8)
        }
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

    }
}


#Preview {
    CLMonitorView()
}
