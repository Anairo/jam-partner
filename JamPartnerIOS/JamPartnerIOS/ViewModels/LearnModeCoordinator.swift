//
//  LearnModeCoordinator.swift
//  JamPartnerIOS
//
//  Created by Perez William on 03/04/2026.
//

import Foundation

/// Gère le mode apprentissage de note sur iOS.
///
/// S'intercale temporairement sur `BLEService.onMidiMessage` le temps de
/// capturer une Note On, puis restaure le handler original de PerformViewModel.
///
/// Emplacement : `JamPartnerIOS/ViewModels/LearnModeCoordinator.swift`
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
                // Annule un apprentissage en cours avant d'en démarrer un nouveau
                cancelLearning()
                
                // Sauvegarde le handler normal (PerformViewModel) pour le restaurer après
                originalHandler = bleService.onMidiMessage
                self.bleService = bleService
                self.onNoteAssigned = onNoteAssigned
                learningButtonIndex = buttonIndex
                capturedNote = nil
                
                // Intercepte temporairement les messages BLE entrants
                bleService.onMidiMessage = { [weak self] status, data1, data2 in
                        Task { @MainActor [weak self] in
                                self?.handleIncoming(status: status, data1: data1, data2: data2)
                        }
                }
                
                // Timeout : restaure le handler si aucune note reçue en 10 secondes
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
                // Capture uniquement les Note On avec vélocité > 0
                guard messageType == 0x90, data2 > 0 else { return }
                guard let buttonIndex = learningButtonIndex else { return }
                
                capturedNote = data1
                timeoutTask?.cancel()
                
                // Bref délai pour que l'utilisateur voie la note capturée avant fermeture
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
