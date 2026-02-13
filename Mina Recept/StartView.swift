//
//  StartView.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-20.
//


import SwiftUI

struct StartView: View {
 


    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager


    @State private var goToHome = false
    @State private var showSetup = false
    @State private var isPressing = false
    @State private var showICloudAlert = false

    
    private func isICloudAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }


    var body: some View {
        ZStack {
            
            // =========================
            // TEMA-BAKGRUND
            // =========================
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // =========================
                // TITEL
                // =========================
                //Text("My Recipes")
                Text(L("app_title", languageManager))
                
                
                
                
                
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                
                // =========================
                // START-KNAPP
                // =========================
                Button {
                    goToHome = true
                } label: {
                    Text(L("recipes", languageManager))
                    
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    themeManager.currentTheme.buttonBackground
                                        .opacity(isPressing ? 0.75 : 0.45)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            themeManager.currentTheme.accentColor
                                                .opacity(isPressing ? 0.35 : 0),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: themeManager.currentTheme.accentColor
                                        .opacity(isPressing ? 0.30 : 0),
                                    radius: isPressing ? 18 : 0
                                )
                        )
                        .animation(.easeOut(duration: 0.25), value: isPressing)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.15)
                        .onChanged { _ in isPressing = true }
                        .onEnded { _ in isPressing = false }
                )
                
                // =========================
                // INSTÄLLNINGAR
                // =========================
                Button {
                    showSetup = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                        Text(L("settings", languageManager))
                        
                    }
                    .font(.subheadline)
                    .foregroundColor(
                        themeManager.currentTheme.primaryTextColor.opacity(0.75)
                    )
                    .padding(.top, 14)
                }
                .buttonStyle(.plain)
                
                // =========================
                // BILD UNDER INSTÄLLNINGAR
                // =========================
                Image("panna") // byt till ditt asset-namn
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .opacity(0.85)
                    .padding(.top, 24)
                
                // =========================
                // TRYCK NER RESTEN
                // =========================
                Spacer()
            }
            // }
            //}
            .onAppear {
                print("Identity token:", FileManager.default.ubiquityIdentityToken as Any)
                if !isICloudAvailable() {
                    showICloudAlert = true
                }
            }
            .alert(
                L("icloud_required_title", languageManager),
                isPresented: $showICloudAlert
            ) {
                Button(L("open_settings", languageManager)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                
                Button("OK", role: .cancel) {}
            } message: {
                Text(L("icloud_required_message", languageManager))
            }
        }
    
   
        // =========================
        // NAVIGATION
        // =========================
        .navigationDestination(isPresented: $goToHome) {
            HomeView()
           
        }
        .sheet(isPresented: $showSetup) {
            SetupView()
                .toolbar(.hidden, for: .navigationBar)   // 🔑 TAR BORT RESERVERAD YTA
                        .navigationBarTitleDisplayMode(.inline)
            
        }
    }
}
