//
//  ContentView.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 32) {
            
            HStack(spacing: 64) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "eyes.inverse")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32)
                }
            }
            .padding(.vertical, 24)
            
            Text("GeoFencings Two ways")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 32) {
                NavigationLink(destination: {
                    LocationTriggerView()
                    
                }, label: {
                    Text("With LocationNotificationTrigger")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.black))
                })
                
                NavigationLink(destination: {
                    CLMonitorView()
                    
                }, label: {
                    Text("With CLMonitor Condition")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.black))
                })
            }
            .font(.headline)
            .fixedSize(horizontal: true, vertical: true)
            
    
            HStack(spacing: 64) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "eyes.inverse")
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(180))
                        .frame(width: 32)
                }
            }
            .padding(.vertical, 24)

        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.2))

    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}

