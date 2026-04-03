import Foundation

enum AbletonScriptInstaller {
    private static let scriptFolderName = "JamPartner"
    private static let initFileName = "__init__.py"
    private static let scriptFileName = "JamPartner.py"

    @discardableResult
    static func install() -> String {
        let fm = FileManager.default
        var targetsWritten = 0

        // 1) User Library (no admin rights required)
        let userScriptsRoot = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Music/Ableton/User Library/Remote Scripts", isDirectory: true)
        if writeScript(at: userScriptsRoot) {
            targetsWritten += 1
        }

        // 2) Try every installed Ableton app in /Applications (best effort)
        let applicationsURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        if let apps = try? fm.contentsOfDirectory(at: applicationsURL, includingPropertiesForKeys: nil) {
            for app in apps where app.pathExtension == "app" && app.lastPathComponent.hasPrefix("Ableton Live") {
                let scriptsRoot = app
                    .appendingPathComponent("Contents/App-Resources/MIDI Remote Scripts", isDirectory: true)
                if writeScript(at: scriptsRoot) {
                    targetsWritten += 1
                }
            }
        }

        if targetsWritten == 0 {
            return "Ableton script install failed"
        }
        return "Ableton script installed (\(targetsWritten) location\(targetsWritten > 1 ? "s" : ""))"
    }

    @discardableResult
    private static func writeScript(at scriptsRoot: URL) -> Bool {
        let fm = FileManager.default
        let folder = scriptsRoot.appendingPathComponent(scriptFolderName, isDirectory: true)

        do {
            // If "JamPartner" exists as a file/alias, remove it and recreate folder.
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                try fm.removeItem(at: folder)
            }

            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            try initPy.data(using: .utf8)?.write(to: folder.appendingPathComponent(initFileName), options: .atomic)
            try scriptPy.data(using: .utf8)?.write(to: folder.appendingPathComponent(scriptFileName), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static let initPy = """
    from .JamPartner import JamPartner

    def create_instance(c_instance):
        return JamPartner(c_instance)
    """

    private static let scriptPy = """
    from __future__ import absolute_import, print_function, unicode_literals
    import Live
    from _Framework.ControlSurface import ControlSurface
    from _Framework.TransportComponent import TransportComponent
    from _Framework.ButtonElement import ButtonElement

    MIDI_CC_TYPE = 1
    CHANNEL = 0

    CC_PREV_TRACK = 20
    CC_NEXT_TRACK = 21
    CC_RECORD = 22
    CC_PLAY_STOP = 23
    CC_FIRE_CLIP = 24
    CC_STOP_CLIP = 25
    CC_ARM_TRACK = 26
    CC_SCENE_UP = 27
    CC_SCENE_DOWN = 28
    CC_LAUNCH_SCENE = 29
    CC_STOP_ALL = 30
    CC_OVERDUB = 31
    CC_UNDO = 32


    class JamPartner(ControlSurface):

        def __init__(self, c_instance):
            super(JamPartner, self).__init__(c_instance)
            self._buttons = []
            with self.component_guard():
                self._setup_all_actions()
            self.log_message("JamPartner control surface loaded (13 actions registered)")

        def _make_button(self, cc, listener):
            btn = ButtonElement(True, MIDI_CC_TYPE, CHANNEL, cc)
            btn.add_value_listener(listener)
            self._buttons.append((btn, listener))
            return btn

        def _setup_all_actions(self):
            self._make_button(CC_PREV_TRACK, self._on_prev_track)
            self._make_button(CC_NEXT_TRACK, self._on_next_track)
            self._make_button(CC_RECORD, self._on_record)
            self._make_button(CC_PLAY_STOP, self._on_play_stop)
            self._make_button(CC_FIRE_CLIP, self._on_fire_clip)
            self._make_button(CC_STOP_CLIP, self._on_stop_clip)
            self._make_button(CC_ARM_TRACK, self._on_arm_track)
            self._make_button(CC_SCENE_UP, self._on_scene_up)
            self._make_button(CC_SCENE_DOWN, self._on_scene_down)
            self._make_button(CC_LAUNCH_SCENE, self._on_launch_scene)
            self._make_button(CC_STOP_ALL, self._on_stop_all)
            self._make_button(CC_OVERDUB, self._on_overdub)
            self._make_button(CC_UNDO, self._on_undo)

        # -- transport --

        def _on_play_stop(self, value):
            if value > 0:
                song = self.song()
                if song.is_playing:
                    song.stop_playing()
                else:
                    song.start_playing()

        def _on_record(self, value):
            if value > 0:
                song = self.song()
                song.record_mode = not song.record_mode

        def _on_overdub(self, value):
            if value > 0:
                song = self.song()
                song.overdub = not song.overdub

        # -- track navigation --

        def _on_prev_track(self, value):
            if value > 0:
                song = self.song()
                tracks = list(song.tracks)
                try:
                    idx = tracks.index(song.view.selected_track)
                except ValueError:
                    return
                if idx > 0:
                    song.view.selected_track = tracks[idx - 1]

        def _on_next_track(self, value):
            if value > 0:
                song = self.song()
                tracks = list(song.tracks)
                try:
                    idx = tracks.index(song.view.selected_track)
                except ValueError:
                    return
                if idx < len(tracks) - 1:
                    song.view.selected_track = tracks[idx + 1]

        # -- scene navigation --

        def _on_scene_up(self, value):
            if value > 0:
                song = self.song()
                scenes = list(song.scenes)
                try:
                    idx = scenes.index(song.view.selected_scene)
                except ValueError:
                    return
                if idx > 0:
                    song.view.selected_scene = scenes[idx - 1]

        def _on_scene_down(self, value):
            if value > 0:
                song = self.song()
                scenes = list(song.scenes)
                try:
                    idx = scenes.index(song.view.selected_scene)
                except ValueError:
                    return
                if idx < len(scenes) - 1:
                    song.view.selected_scene = scenes[idx + 1]

        # -- clip / scene actions --

        def _on_fire_clip(self, value):
            if value > 0:
                song = self.song()
                track = song.view.selected_track
                scenes = list(song.scenes)
                try:
                    scene_idx = scenes.index(song.view.selected_scene)
                except ValueError:
                    return
                slots = list(track.clip_slots)
                if scene_idx < len(slots):
                    slots[scene_idx].fire()

        def _on_stop_clip(self, value):
            if value > 0:
                song = self.song()
                track = song.view.selected_track
                track.stop_all_clips()

        def _on_launch_scene(self, value):
            if value > 0:
                song = self.song()
                song.view.selected_scene.fire()

        def _on_stop_all(self, value):
            if value > 0:
                self.song().stop_all_clips()

        # -- arm --

        def _on_arm_track(self, value):
            if value > 0:
                song = self.song()
                track = song.view.selected_track
                if track.can_be_armed:
                    track.arm = not track.arm

        # -- undo --

        def _on_undo(self, value):
            if value > 0:
                self.song().undo()

        def disconnect(self):
            for btn, listener in self._buttons:
                btn.remove_value_listener(listener)
            self._buttons = []
            super(JamPartner, self).disconnect()
    """
}
