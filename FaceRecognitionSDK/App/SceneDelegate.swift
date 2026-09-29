import UIKit
import FaceRecognitionKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?


    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = IXColor.bg
        let nav = UINavigationController(rootViewController: ViewController())
        nav.view.backgroundColor = IXColor.bg
        window.rootViewController = nav
        window.tintColor = IXColor.accent
        window.makeKeyAndVisible()
        self.window = window
    }
}


/// Identixia workbench palette (cool paper + teal) — matches Android `colors.xml` / Gradio.
enum IXColor {
    static let bg = UIColor(red: 0.902, green: 0.914, blue: 0.937, alpha: 1)            // #E6E9EF
    static let surface = UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1)       // #F7F8FA
    static let surfaceAlt = UIColor(red: 0.875, green: 0.894, blue: 0.925, alpha: 1)    // #DFE4EC
    static let text = UIColor(red: 0.078, green: 0.102, blue: 0.133, alpha: 1)           // #141A22
    static let muted = UIColor(red: 0.353, green: 0.396, blue: 0.451, alpha: 1)          // #5A6573
    static let stroke = UIColor(red: 0.773, green: 0.800, blue: 0.847, alpha: 1)         // #C5CCD8
    static let accent = UIColor(red: 0.059, green: 0.463, blue: 0.431, alpha: 1)         // #0F766E
    static let onAccent = UIColor(red: 0.957, green: 1.0, blue: 0.988, alpha: 1)         // #F4FFFC
    static let purple = UIColor(red: 0.059, green: 0.463, blue: 0.431, alpha: 1)         // tile fill (teal)
    static let pinkTouch = UIColor(red: 0.043, green: 0.310, blue: 0.290, alpha: 1)      // #0B4F4A
    static let statusOk = UIColor(red: 0.082, green: 0.502, blue: 0.239, alpha: 1)       // #15803D
    static let statusInfo = UIColor(red: 0.043, green: 0.310, blue: 0.290, alpha: 1)
    static let statusError = UIColor(red: 0.725, green: 0.110, blue: 0.110, alpha: 1)    // #B91C1C
    static let overlay = UIColor(red: 0.902, green: 0.914, blue: 0.937, alpha: 0.88)
    static let captureScrimStart = UIColor(red: 0.078, green: 0.102, blue: 0.133, alpha: 0.55)
    static let captureScrimEnd = UIColor.black
    static let captureTertiary = UIColor(red: 0.369, green: 0.918, blue: 0.831, alpha: 1) // #5EEAD4
    static let livenessReal = UIColor(red: 0.059, green: 0.463, blue: 0.431, alpha: 1)
    static let livenessSpoof = UIColor(red: 0.725, green: 0.110, blue: 0.110, alpha: 1)
    static let livenessNeutral = UIColor(red: 0.078, green: 0.102, blue: 0.133, alpha: 1)
}


/// Shared nav bar so every pushed screen shows a labeled Back control.
enum ScreenChrome {
    static func showInnerBar(on viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = IXColor.bg
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: IXColor.text]
        let button = UIBarButtonItemAppearance()
        button.normal.titleTextAttributes = [.foregroundColor: IXColor.accent]
        appearance.buttonAppearance = button
        appearance.backButtonAppearance = button
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = IXColor.accent
        navigationController.navigationBar.barStyle = .black
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController.setNavigationBarHidden(false, animated: false)
    }
}
