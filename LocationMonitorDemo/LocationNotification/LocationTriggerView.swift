//
//  LocationTriggerView.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/08.
//

import SwiftUI

struct LocationTriggerView: View {
    @State private var manager = NotificationManager.shared
    var body: some View {
        @Bindable var manager = manager
        
        VStack(spacing: 48) {
            Text("UNLocationNotificationTrigger")
                .font(.title3)
                .fontWeight(.bold)
            
            Toggle("Register Trigger", isOn: $manager.triggerRegistered)
                .frame(width: 240)
            
            if let error = manager.error {
                Text("Error: \(error.message)")
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}


#Preview {
    LocationTriggerView()
}
