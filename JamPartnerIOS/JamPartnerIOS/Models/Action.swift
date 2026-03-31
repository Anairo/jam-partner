struct Action: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let cc: UInt8
}

enum ActionCatalog {
    static let all: [Action] = [
        Action(id: "prev_track",   label: "Prev Track",     cc: 20),
        Action(id: "next_track",   label: "Next Track",     cc: 21),
        Action(id: "record",       label: "Record",         cc: 22),
        Action(id: "play_stop",    label: "Play / Stop",    cc: 23),
        Action(id: "fire_clip",    label: "Fire Clip Slot", cc: 24),
        Action(id: "stop_clip",    label: "Stop Clip",      cc: 25),
        Action(id: "arm_track",    label: "Arm Track",      cc: 26),
        Action(id: "scene_up",     label: "Scene Up",       cc: 27),
        Action(id: "scene_down",   label: "Scene Down",     cc: 28),
        Action(id: "launch_scene", label: "Launch Scene",   cc: 29),
        Action(id: "stop_all",     label: "Stop All Clips", cc: 30),
        Action(id: "overdub",      label: "Overdub",        cc: 31),
        Action(id: "undo",         label: "Undo",           cc: 32),
    ]

    static func find(_ id: String) -> Action? {
        all.first { $0.id == id }
    }
}
