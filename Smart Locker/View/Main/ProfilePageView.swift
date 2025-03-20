//
//  ProfilePageView.swift
//  Smart Locker
//
//  Created by Oğuzhan Sönmeztürk on 20.03.2025.
//

import SwiftUI

struct ProfilePageView: View {
    @State private var isDarkMode: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                        Text("Oğuzhan")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Ayarlar Listesi
                List {
                    HStack {
                        Image(systemName: "wallet.pass.fill")
                        Text("Balance")
                        Spacer()
                        Text("$200.00")
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink(destination: Text("QR Code Screen")) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("QR Code")
                        }
                    }
                    
                    NavigationLink(destination: Text("Password Change Screen")) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Password")
                        }
                    }
                    
                    NavigationLink(destination: Text("Mail Settings")) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Mail")
                            Spacer()
                            Text("oguzhan@gmail.com")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: "moon.fill")
                            Text("Dark Mode")
                        }
                    }
                    
                    NavigationLink(destination: Text("Reservation Screen")) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Reservation")
                        }
                    }
                }
                .listStyle(.plain)
                
                Spacer()
                
                // Çıkış Butonu
                Button(action: {
                    print("Signing out...")
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.white)
                            .bold()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfilePageView()
}

