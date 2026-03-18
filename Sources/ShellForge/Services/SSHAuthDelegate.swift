import Foundation
import NIOSSH
import NIOCore

/// Password authentication delegate
final class PasswordAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    private let username: String
    private let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if availableMethods.contains(.password) {
            nextChallengePromise.succeed(
                .init(username: username, serviceName: "",
                      offer: .password(.init(password: password)))
            )
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}

/// Private key authentication delegate
final class PrivateKeyAuthDelegate: NIOSSHClientUserAuthenticationDelegate {
    private let username: String
    private let privateKey: NIOSSHPrivateKey

    init(username: String, privateKey: NIOSSHPrivateKey) {
        self.username = username
        self.privateKey = privateKey
    }

    func nextAuthenticationType(
        availableMethods: NIOSSHAvailableUserAuthenticationMethods,
        nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
    ) {
        if availableMethods.contains(.publicKey) {
            nextChallengePromise.succeed(
                .init(username: username, serviceName: "",
                      offer: .privateKey(.init(privateKey: privateKey)))
            )
        } else {
            nextChallengePromise.succeed(nil)
        }
    }
}

/// Accept all host keys (development only — replace with proper verification before v1.0)
final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(
        hostKey: NIOSSHPublicKey,
        validationCompletePromise: EventLoopPromise<Void>
    ) {
        validationCompletePromise.succeed(())
    }
}
