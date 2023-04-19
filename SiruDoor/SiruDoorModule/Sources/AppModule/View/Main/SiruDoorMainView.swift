//
//  SiruDoorMainView.swift
//  SiruDoor
//
//  Created by Katsuhiko Terada on 2022/08/15.
//

import Domain
import SwiftUI

public struct SiruDoorMainView: View {
    @StateObject var nearPeerNotifier = NearPeerNotifier.shared

    @State var navigationTitle: String = TabItem.analyzing.title
    @State var tabIndex: Int = 0

    public init() {}

    public var body: some View {
        NavigationView {
            TabView(selection: $tabIndex) {
                SoundPatternRecordingView()
                    .tabMaker(item: .recording)

                SoundPatternAnalyzingView()
                    .environmentObject(nearPeerNotifier)
                    .tabMaker(item: .analyzing)

                MonitorView()
                    .environmentObject(nearPeerNotifier)
                    .tabMaker(item: .monitor)

                SettingView()
                    .environmentObject(nearPeerNotifier)
                    .tabMaker(item: .setting)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: tabIndex) { tabIndex in
                let selectedTab = TabItem(rawValue: tabIndex) ?? .analyzing
                navigationTitle = selectedTab.title
                AppUserDefault.tabIndex = tabIndex
            }
            .onAppear {
                tabIndex = AppUserDefault.tabIndex
            }
        }
        .onOpenURL { _ in
            // logger.debug("Received Deep Link \(url.absoluteString)")
        }
        .onAppear {
            // Use this if NavigationBarTitle is with Large Font
            // UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.red]

            // Use this if NavigationBarTitle is with displayMode = .inline
            // UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.red]
        }
        .navigationBarColor(backgroundColor: .clear, titleColor: .darkGray)
    }
}

extension View {
    func tabMaker(item: TabItem) -> some View {
        tabItem {
            Label {
                Text(item.tabName)
            } icon: {
                Image(systemName: item.imageName)
            }
        }
        .tag(item.rawValue) // 👀 rawValueじゃなくてもいいのか
    }
}

struct NavigationBarModifier: ViewModifier {
    var backgroundColor: UIColor?
    var titleColor: UIColor?

    init(backgroundColor: UIColor?, titleColor: UIColor?) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = backgroundColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor ?? .white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor ?? .clear)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

extension View {
    func navigationBarColor(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        modifier(NavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}
