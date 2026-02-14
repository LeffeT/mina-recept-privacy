//
//  SetupView.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-03.
//


import SwiftUI

struct SetupView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var cloudSyncStatus: CloudSyncStatus
    @Environment(\.dismiss) private var dismiss
    
    private var versionText: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return "\(version) (\(build))"
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
    
    private var lastSyncText: String? {
        guard let date = cloudSyncStatus.lastSyncDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = languageManager.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let time = formatter.string(from: date)
        return String(format: L("icloud_last_sync", languageManager), time)
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("settings_title", languageManager))
                            .font(.largeTitle.bold())
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        Text(L("settings_subtitle", languageManager))
                            .font(.subheadline)
                            .foregroundColor(
                                themeManager.currentTheme.primaryTextColor.opacity(0.7)
                            )
                    }
                    .padding(.top, 12)
                    
                    SettingsSection(
                        title: L("theme_section_title", languageManager),
                        subtitle: L("theme_section_subtitle", languageManager),
                        theme: themeManager.currentTheme
                    ) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(AppTheme.allCases) { theme in
                                    ThemeCard(
                                        theme: theme,
                                        title: themeTitle(for: theme),
                                        isSelected: theme == themeManager.currentTheme,
                                        accent: themeManager.currentTheme.accentColor
                                    ) {
                                        themeManager.currentTheme = theme
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    SettingsSection(
                        title: L("language", languageManager),
                        subtitle: nil,
                        theme: themeManager.currentTheme
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(AppLanguage.allCases) { language in
                                LanguageRow(
                                    title: language.title,
                                    isSelected: languageManager.selectedLanguage == language,
                                    theme: themeManager.currentTheme
                                ) {
                                    languageManager.selectedLanguage = language
                                }
                            }
                        }
                    }
                    
                    SettingsSection(
                        title: L("app_info_title", languageManager),
                        subtitle: nil,
                        theme: themeManager.currentTheme
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(L("version_label", languageManager))
                                Spacer()
                                Text(versionText)
                                    .foregroundColor(
                                        themeManager.currentTheme.primaryTextColor.opacity(0.7)
                                    )
                            }
                            
                            Divider().opacity(0.2)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(iCloudStatusColor)
                                    .frame(width: 8, height: 8)
                                Text(iCloudStatusText)
                            }
                            
                            if let lastSyncText {
                                Text(lastSyncText)
                                    .font(.caption)
                                    .foregroundColor(
                                        themeManager.currentTheme.primaryTextColor.opacity(0.6)
                                    )
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text(L("close", languageManager))
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(themeManager.currentTheme.buttonBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func themeTitle(for theme: AppTheme) -> String {
        switch theme {
        case .orange:
            return L("theme_name_orange", languageManager)
        case .green:
            return L("theme_name_green", languageManager)
        case .black:
            return L("theme_name_black", languageManager)
        case .blue:
            return L("theme_name_blue", languageManager)
        case .pink:
            return L("theme_name_pink", languageManager)
        case .red:
            return L("theme_name_red", languageManager)
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let theme: AppTheme
    let content: Content
    
    init(
        title: String,
        subtitle: String?,
        theme: AppTheme,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.primaryTextColor)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.primaryTextColor.opacity(0.6))
                }
            }
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.primaryTextColor.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ThemeCard: View {
    let theme: AppTheme
    let title: String
    let isSelected: Bool
    let accent: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.backgroundGradient)
                    .frame(width: 132, height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? accent : Color.white.opacity(0.18),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.primaryTextColor)
                    
                    Text("Aa")
                        .font(.caption2)
                        .foregroundColor(theme.primaryTextColor.opacity(0.7))
                }
                .padding(10)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct LanguageRow: View {
    let title: String
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.primaryTextColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
