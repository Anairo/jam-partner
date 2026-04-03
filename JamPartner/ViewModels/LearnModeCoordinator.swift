import Foundation

/// Gère le mode apprentissage de note.
///
/// S'intercale temporairement sur `BLEService.onMidiMessage` le temps de
/// capturer une Note On, puis restaure le handler original de PerformViewModel.
@MainActor
@Observable
final class LearnModeCoordinator {

    /// Index du bouton en cours d'apprentissage (nil = mode apprentissage inactif)
    var learningButtonIndex: Int? = nil

    /// Note capturée — affichée brièvement avant validation
    var capturedNote: UInt8? = nil

    private var originalHandler: ((UInt8, UInt8, UInt8) -> Void)?
    private var bleService: (any BLEServiceProtocol)?
    private var onNoteAssigned: ((UInt8, Int) -> Void)?
    private var timeoutTask: Task<Void, Never>?

    // MARK: - API publique

    func startLearning(
        buttonIndex: Int,
        bleService: any BLEServiceProtocol,
        onNoteAssigned: @escaping (UInt8, Int) -> Void
    ) {
        cancelLearning()

        originalHandler = bleService.onMidiMessage
        self.bleService = bleService
        self.onNoteAssigned = onNoteAssigned
        learningButtonIndex = buttonIndex
        capturedNote = nil

        bleService.onMidiMessage = { [weak self] status, data1, data2 in
            Task { @MainActor [weak self] in
                self?.handleIncoming(status: status, data1: data1, data2: data2)
            }
        }

        timeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            if !Task.isCancelled { self.cancelLearning() }
        }
    }

    func cancelLearning() {
        timeoutTask?.cancel()
        restoreHandler()
        learningButtonIndex = nil
        capturedNote = nil
    }

    // MARK: - Privé

    private func handleIncoming(status: UInt8, data1: UInt8, data2: UInt8) {
        let messageType = status & 0xF0
        guard messageType == 0x90, data2 > 0 else { return }
        guard let buttonIndex = learningButtonIndex else { return }

        capturedNote = data1
        timeoutTask?.cancel()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            self.onNoteAssigned?(data1, buttonIndex)
            self.restoreHandler()
            self.learningButtonIndex = nil
            self.capturedNote = nil
        }
    }

    private func restoreHandler() {
        bleService?.onMidiMessage = originalHandler
        originalHandler = nil
        bleService = nil
        onNoteAssigned = nil
    }
}
