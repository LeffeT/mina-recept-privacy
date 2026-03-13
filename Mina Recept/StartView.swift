//
//  StartView.swift
//  Matlagning
//
//  Created by Leif Tarvainen on 2025-12-20.
//


import SwiftUI
import os
import UIKit

struct StartView: View {
 


    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var cloudSyncStatus: CloudSyncStatus
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass


    @State private var goToHome = false
    @State private var showSetup = false
    @State private var isPressing = false
    @State private var showICloudAlert = false
    @State private var didScheduleICloudRefresh = false

    
    private func isICloudAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private var iCloudStatusText: String {
        switch cloudSyncStatus.state {
        case .syncing:
            return L("icloud_status_syncing", languageManager)
        case .error:
            return L("icloud_status_error", languageManager)
        case .unavailable:
            return L("icloud_status_off", languageManager)
        case .idle:
            if cloudSyncStatus.lastSyncDate == nil {
                return L("icloud_status_starting", languageManager)
            }
            return L("icloud_status_active", languageManager)
        }
    }

    private var iCloudStatusColor: Color {
        switch cloudSyncStatus.state {
        case .syncing:
            return themeManager.currentTheme.accentColor
        case .error:
            return .orange
        case .unavailable:
            return .red
        case .idle:
            return cloudSyncStatus.lastSyncDate == nil
                ? themeManager.currentTheme.accentColor
                : .green
        }
    }

    private func scheduleICloudRefreshIfNeeded() {
        guard !didScheduleICloudRefresh else { return }
        didScheduleICloudRefresh = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            cloudSyncStatus.refresh()
        }
    }

    private func isLandscape(_ size: CGSize) -> Bool {
        size.width > size.height
    }

    private func startImageHeight(containerSize: CGSize, isPad: Bool, landscape: Bool) -> CGFloat {
        if isPad {
            let ratio: CGFloat = landscape ? 0.70 : 0.62
            let heightFromScreen = containerSize.height * ratio
            let minHeight: CGFloat = landscape ? 320 : 360
            let maxHeight: CGFloat = landscape ? 560 : 700
            return min(max(heightFromScreen, minHeight), maxHeight)
        }

        // iPhone: trim a bit more upward to avoid clipping the top.
        let ratio: CGFloat = landscape ? 0.62 : 0.60
        return min(max(containerSize.height * ratio, 280), 580)
    }

    @ViewBuilder
    private func startImageView(containerSize: CGSize) -> some View {
        let isPad = horizontalSizeClass == .regular
        let landscape = isLandscape(containerSize)
        let portraitName = isPad ? "startbild_iPad" : "startbild"
        let landscapeName = "startbild_iPad_landscape"

        if landscape && !isPad {
            EmptyView()
        } else if isPad && landscape {
            if let uiImage = UIImage(named: landscapeName) {
                let aspect = uiImage.size.width > 0
                    ? (uiImage.size.height / uiImage.size.width)
                    : 0.5625
                let targetHeight = min(containerSize.height, containerSize.width * aspect)

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: containerSize.width,
                        height: targetHeight,
                        alignment: .bottom
                    )
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(
                        color: themeManager.currentTheme.primaryTextColor.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .allowsHitTesting(false)
            } else {
                // Fallback: avoid cropping by fitting the portrait iPad image.
                Image(portraitName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: containerSize.width * 0.9)
                    .frame(
                        height: min(containerSize.height * 0.6, containerSize.width * 0.6)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(
                        color: themeManager.currentTheme.primaryTextColor.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .allowsHitTesting(false)
            }
        } else if isPad {
            if let uiImage = UIImage(named: portraitName) {
                let aspect = uiImage.size.width > 0
                    ? (uiImage.size.height / uiImage.size.width)
                    : 0.75
                let baseHeight = startImageHeight(
                    containerSize: containerSize,
                    isPad: true,
                    landscape: false
                )
                let targetHeight = min(
                    containerSize.height,
                    max(baseHeight, containerSize.width * aspect)
                )

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: containerSize.width,
                        height: targetHeight,
                        alignment: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(
                        color: themeManager.currentTheme.primaryTextColor.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .allowsHitTesting(false)
            } else {
                Image(portraitName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: containerSize.width,
                        height: startImageHeight(
                            containerSize: containerSize,
                            isPad: true,
                            landscape: false
                        ),
                        alignment: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(
                        color: themeManager.currentTheme.primaryTextColor.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                    .allowsHitTesting(false)
            }
        } else {
            Image(portraitName)
                .resizable()
                .scaledToFill()
                .frame(
                    width: containerSize.width,
                    height: startImageHeight(
                        containerSize: containerSize,
                        isPad: false,
                        landscape: landscape
                    ),
                    alignment: .bottom
                )
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .shadow(
                    color: themeManager.currentTheme.primaryTextColor.opacity(0.15),
                    radius: 10,
                    x: 0,
                    y: 6
                )
                .allowsHitTesting(false)
        }
    }


    var body: some View {
        GeometryReader { geo in
            ZStack {

                // =========================
                // TEMA-BAKGRUND
                // =========================
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()

                startImageView(containerSize: geo.size)

                VStack(spacing: 0) {

                    // =========================
                    // TITEL
                    // =========================
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
                            .frame(
                                maxWidth: horizontalSizeClass == .regular
                                    ? min(geo.size.width * 0.82, 920)
                                    : (verticalSizeClass == .compact ? 420 : .infinity)
                            )
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
                    // ICLOUD WARNING (ONLY WHEN NEEDED)
                    // =========================
                    if cloudSyncStatus.state == .unavailable || cloudSyncStatus.state == .error {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(iCloudStatusColor)
                                .frame(width: 8, height: 8)
                            Text(iCloudStatusText)
                                .font(.footnote)
                                .foregroundColor(
                                    themeManager.currentTheme.primaryTextColor.opacity(0.7)
                                )
                        }
                        .padding(.top, 12)
                    }

                    Spacer()
                }
            }
            .onAppear {
                #if DEBUG
                AppLog.cloudkit.debug(
                    "Identity token: \(String(describing: FileManager.default.ubiquityIdentityToken), privacy: .private)"
                )
                #endif
                if !isICloudAvailable() {
                    showICloudAlert = true
                }
                scheduleICloudRefreshIfNeeded()
            }
            .alert(
                L("icloud_required_title", languageManager),
                isPresented: $showICloudAlert
            ) {
                Button(L("icloud_open_settings", languageManager)) {
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
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
