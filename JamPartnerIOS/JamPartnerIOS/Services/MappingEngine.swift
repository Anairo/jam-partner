import Foundation

final class MappingEngine {
        
        // MARK: - Configuration
        
        /// Mise à jour thread-safe : le setter dispatche sur la queue interne.
        /// ModeManager (ou tout autre owner) peut la changer à chaud —
        /// le prochain appel à handleButtonPress utilisera la nouvelle config.
        var config: MappingConfig {
                get { queue.sync { _config } }
                set { queue.sync { _config = newValue } }
        }
        
        /// Raccourci pour modifier uniquement le debounce (usage fréquent depuis l'UI).
        var debounceMs: Double {
                get { config.debounceMs }
                set {
                        queue.sync { _config.debounceMs = newValue }
                }
        }
        
        // MARK: - Callbacks
        
        var onLog: ((String) -> Void)?
        var onButtonTriggered: (@MainActor (Int) -> Void)?
        var onCycleModeRequested: (@MainActor () -> Void)?
        
        // MARK: - Privé
        
        private let midiService: any MIDIServiceProtocol
        private var _config: MappingConfig
        
        private var lastTriggerTime: [String: TimeInterval] = [:]
        private var pendingButtons: [Int: TimeInterval] = [:]
        private var pendingTimers: [Int: DispatchWorkItem] = [:]
        private let queue = DispatchQueue(label: "com.jampartner.mapping-engine")
        
        
        // MARK: - Init
        
        init(midiService: any MIDIServiceProtocol,
             config: MappingConfig = .default) {
                self.midiService = midiService
                self._config = config
        }
        
        // MARK: - API publique
        
        func trigger(action: Action) {
                queue.async { [weak self] in
                        self?.triggerOnQueue(action: action)
                }
        }
        
        func handleButtonPress(button: Int) {
                queue.async { [weak self] in
                        self?.handleButtonPressOnQueue(button: button)
                }
        }
        
        func handleIncoming(status: UInt8, data1: UInt8, data2: UInt8) {
                queue.async { [weak self] in
                        self?.handleIncomingOnQueue(status: status, data1: data1, data2: data2)
                }
        }
        
        // MARK: - Logique interne (toujours appelée sur `queue`)
        
        private func triggerOnQueue(action: Action) {
                let now = ProcessInfo.processInfo.systemUptime
                if let last = lastTriggerTime[action.id],
                   (now - last) * 1000 < _config.debounceMs {
                        onLog?("debounce: \(action.label) skipped")
                        return
                }
                lastTriggerTime[action.id] = now
                midiService.sendCC(controller: action.cc, value: 127, channel: 0)
        }
        
        private func handleButtonPressOnQueue(button: Int) {
                let now = ProcessInfo.processInfo.systemUptime
                let combo = _config.comboButtons          // lecture locale, config déjà sur queue
                let windowMs = _config.comboWindowMs
                
                if combo.contains(button) {
                        // Cherche le bouton partenaire du combo
                        guard let partner = combo.first(where: { $0 != button }) else {
                                // comboButtons n'a qu'un seul élément — config invalide, on déclenche normalement
                                triggerButtonOnMainActor(button)
                                return
                        }
                        
                        // Si le partenaire est déjà en attente dans la fenêtre → combo détecté
                        if let partnerTime = pendingButtons[partner],
                           (now - partnerTime) * 1000 < windowMs {
                                pendingTimers[partner]?.cancel()
                                pendingTimers.removeValue(forKey: partner)
                                pendingButtons.removeValue(forKey: partner)
                                pendingButtons.removeValue(forKey: button)
                                onLog?("Combo détecté (\(combo.sorted())) → cycle de mode")
                                requestModeCycleOnMainActor()
                                return
                        }
                        
                        // Sinon, mise en attente avec timer
                        pendingButtons[button] = now
                        let work = DispatchWorkItem { [weak self] in
                                self?.queue.async {
                                        self?.pendingButtons.removeValue(forKey: button)
                                        self?.pendingTimers.removeValue(forKey: button)
                                        self?.triggerButtonOnMainActor(button)
                                }
                        }
                        pendingTimers[button]?.cancel()
                        pendingTimers[button] = work
                        queue.asyncAfter(deadline: .now() + windowMs / 1000, execute: work)
                        return
                }
                
                // Bouton normal (hors combo) — déclenchement immédiat
                triggerButtonOnMainActor(button)
        }
        
        private func handleIncomingOnQueue(status: UInt8, data1: UInt8, data2: UInt8) {
                let messageType = status & 0xF0
                let channel = status & 0x0F
                
                switch messageType {
                case 0x90 where data2 > 0:
                        onLog?("IN: Note On  ch=\(channel) note=\(data1) vel=\(data2)")
                        // Utilise noteToButton depuis la config — plus de static hardcodé
                        if let button = _config.noteToButton[data1] {
                                handleButtonPressOnQueue(button: button)
                        }
                case 0x80, 0x90:
                        onLog?("IN: Note Off ch=\(channel) note=\(data1)")
                case 0xB0:
                        onLog?("IN: CC ch=\(channel) cc=\(data1) val=\(data2)")
                default:
                        onLog?("IN: status=0x\(String(status, radix: 16)) d1=\(data1) d2=\(data2)")
                }
        }
        
        // MARK: - Helpers thread
        
        private func triggerButtonOnMainActor(_ button: Int) {
                Task { @MainActor [weak self] in
                        self?.onButtonTriggered?(button)
                }
        }
        
        private func requestModeCycleOnMainActor() {
                Task { @MainActor [weak self] in
                        self?.onCycleModeRequested?()
                }
        }
}
