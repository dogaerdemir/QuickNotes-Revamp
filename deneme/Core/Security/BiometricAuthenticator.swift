import Foundation
import LocalAuthentication

protocol BiometricAuthenticating {
    func authenticate(reason: String, completion: @escaping (Result<Void, Error>) -> Void)
}

enum BiometricAuthError: LocalizedError {
    case unavailable
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Face ID / Touch ID bu cihazda kullanılamıyor."
        case .cancelled:
            return nil
        case let .failed(message):
            return message
        }
    }
}

final class BiometricAuthenticator: BiometricAuthenticating {
    func authenticate(reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var authError: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            evaluate(policy: .deviceOwnerAuthenticationWithBiometrics, context: context, reason: reason, completion: completion)
            return
        }

        // Biometric kullanılamıyorsa (enroll edilmemiş, lockout, vb.) cihaz parolasına düş.
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            evaluate(policy: .deviceOwnerAuthentication, context: context, reason: reason, completion: completion)
            return
        }

        if let laError = authError as? LAError {
            completion(.failure(BiometricAuthError.failed(message(for: laError))))
            return
        }

        completion(.failure(BiometricAuthError.unavailable))
    }

    private func evaluate(
        policy: LAPolicy,
        context: LAContext,
        reason: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        context.evaluatePolicy(policy, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                    return
                }

                guard let laError = error as? LAError else {
                    completion(.failure(BiometricAuthError.failed(error?.localizedDescription ?? "Doğrulama başarısız.")))
                    return
                }

                switch laError.code {
                case .userCancel, .systemCancel, .appCancel:
                    completion(.failure(BiometricAuthError.cancelled))
                default:
                    completion(.failure(BiometricAuthError.failed(self.message(for: laError))))
                }
            }
        }
    }

    private func message(for error: LAError) -> String {
        switch error.code {
        case .biometryNotAvailable:
            return "Face ID / Touch ID kullanılamıyor. Cihaz ayarlarını ve uygulama izinlerini kontrol edin."
        case .biometryNotEnrolled:
            return "Face ID / Touch ID ayarlı değil. Cihaz parolası ile devam edebilirsiniz."
        case .passcodeNotSet:
            return "Cihazda parola ayarlanmadığı için biyometrik doğrulama kullanılamıyor."
        case .authenticationFailed:
            return "Kimlik doğrulama başarısız oldu. Tekrar deneyin."
        default:
            return error.localizedDescription
        }
    }
}
