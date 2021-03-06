import UIKit
import SafariServices

private let kAPIKeyURL = URL(string: "https://openradar.appspot.com/apikey")!
private let kOpenRadarUsername = "openradar"

final class LoginCoordinator {


	// MARK: - Properties

	let source: UIViewController
	var loginController: LoginViewController?
	let root = UINavigationController()


	// MARK: - Init/Deinit

	init(from source: UIViewController) {
		self.source = source
	}

	// MARK: - Public API

	func start() {
		let controller = LoginViewController.newFromStoryboard()
		controller.delegate = self
		root.viewControllers = [controller]
		root.modalPresentationStyle = .formSheet
		source.present(root, animated: true)
		loginController = controller
	}

	func finish() {
		source.dismiss(animated: true)
	}

	// MARK: - Private

	fileprivate func showError(_ error: LoginError) {
        let global = Localizable.Global.self

		let alert = UIAlertController(title: global.error.localized, message: error.localizedDescription, preferredStyle: .alert)
		let cancel = UIAlertAction(title: global.tryAgain.localized, style: .cancel) { [weak self] _ in
			self?.loginController?.dismiss(animated: true, completion: nil)
		}
		alert.addAction(cancel)
		loginController?.present(alert, animated: true, completion: nil)
	}
}


// MARK: - LoginViewDelegate Methods

extension LoginCoordinator: LoginViewDelegate {

	func submitTapped(user: User) {
		guard user.email.isValid else {
			showError(.invalidEmail)
			return
		}


		// Save to keychain
		Keychain.set(username: user.email.value, password: user.password, forKey: .radar)

		// Continue to open radar
		let openradar = OpenRadarViewController.newFromStoryboard()
		openradar.delegate = self
		root.show(openradar, sender: self)
	}

}


// MARK: - OpenRadarViewDelegate Method

extension LoginCoordinator: OpenRadarViewDelegate {

	func openSafariTapped() {
		let safari = SFSafariViewController(url: kAPIKeyURL)
		root.showDetailViewController(safari, sender: self)
	}

	func continueTapped(token: String) {
		// Save to keychain
		if token.isEmpty {
			Keychain.delete(.openRadar)
		} else {
			Keychain.set(username: kOpenRadarUsername, password: token, forKey: .openRadar)
		}

		finish()
	}

	func skipTapped() {
		finish()
	}

}
