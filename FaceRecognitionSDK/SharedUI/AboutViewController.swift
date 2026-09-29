import UIKit
import FaceRecognitionKit


/// Android `AboutActivity` — logo, company, license, two body cards, site, copyright.
final class AboutViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = IXColor.bg
        title = "About"
        ScreenChrome.showInnerBar(on: self)


        let logo = UIImageView(image: UIImage(named: "IdentixiaLogo")?.withRenderingMode(.alwaysOriginal))
        logo.contentMode = .scaleAspectFit
        logo.isUserInteractionEnabled = true
        logo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSite)))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.heightAnchor.constraint(equalToConstant: 72).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 300).isActive = true


        let company = UILabel()
        company.text = "Identixia"
        company.textColor = IXColor.text
        company.font = .systemFont(ofSize: 22, weight: .bold)
        company.textAlignment = .center


        let product = UILabel()
        product.text = "Face Recognition SDK"
        product.textColor = IXColor.accent
        product.font = .systemFont(ofSize: 15)
        product.textAlignment = .center


        let licenseLabel = UILabel()
        licenseLabel.text = "License: …"
        licenseLabel.textColor = IXColor.text
        licenseLabel.font = .systemFont(ofSize: 13)
        licenseLabel.textAlignment = .center
        licenseLabel.numberOfLines = 0
        let licenseCard = wrapCard(licenseLabel)


        let companyBody = cardLabel(
            "Identixia builds on-device identity technology — face recognition, liveness, and document reading — so biometric data never has to leave the phone."
        )
        let productBody = cardLabel(
            "This app demos the Face Recognition SDK for iOS: enroll, identify, capture, and attribute analysis. Everything runs fully on-premise."
        )


        let website = UIButton(type: .system)
        website.setTitle("identixia.com", for: .normal)
        website.setTitleColor(IXColor.accent, for: .normal)
        website.titleLabel?.font = .systemFont(ofSize: 14)
        website.addTarget(self, action: #selector(openSite), for: .touchUpInside)


        let copyright = UILabel()
        copyright.text = "© 2026 Identixia. All rights reserved."
        copyright.textColor = IXColor.muted
        copyright.font = .systemFont(ofSize: 12)
        copyright.textAlignment = .center


        let logoWrap = UIView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logoWrap.addSubview(logo)
        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: logoWrap.topAnchor, constant: 24),
            logo.centerXAnchor.constraint(equalTo: logoWrap.centerXAnchor),
            logo.bottomAnchor.constraint(equalTo: logoWrap.bottomAnchor),
        ])


        let col = UIStackView(arrangedSubviews: [
            logoWrap, company, product, licenseCard, companyBody, productBody, website, copyright,
        ])
        col.axis = .vertical
        col.spacing = 16
        col.setCustomSpacing(4, after: company)
        col.setCustomSpacing(12, after: product)
        col.setCustomSpacing(20, after: productBody)
        col.setCustomSpacing(24, after: website)
        col.translatesAutoresizingMaskIntoConstraints = false


        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(col)
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            col.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            col.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            col.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            col.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            col.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
            licenseCard.widthAnchor.constraint(equalTo: col.widthAnchor),
            companyBody.widthAnchor.constraint(equalTo: col.widthAnchor),
            productBody.widthAnchor.constraint(equalTo: col.widthAnchor),
        ])


        DispatchQueue.global(qos: .userInitiated).async {
            let status = LicenseStatus.current()
            var text = "License: \(status.label)"
            if let missing = status.missingDatabasesMessage() {
                text += "\n\(missing)"
            }
            DispatchQueue.main.async {
                licenseLabel.text = text
            }
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
    }


    private func wrapCard(_ label: UILabel) -> UIView {
        label.translatesAutoresizingMaskIntoConstraints = false
        let pad = UIView()
        pad.backgroundColor = IXColor.surface
        pad.layer.cornerRadius = 12
        pad.clipsToBounds = true
        pad.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pad.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: pad.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: pad.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: pad.bottomAnchor, constant: -12),
        ])
        return pad
    }


    private func cardLabel(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.textColor = IXColor.text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false


        let pad = UIView()
        pad.backgroundColor = IXColor.surface
        pad.layer.cornerRadius = 12
        pad.clipsToBounds = true
        pad.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pad.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: pad.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: pad.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: pad.bottomAnchor, constant: -16),
        ])
        return pad
    }


    @objc private func openSite() {
        guard let url = URL(string: "https://identixia.com") else { return }
        UIApplication.shared.open(url)
    }
}
