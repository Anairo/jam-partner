import Testing
@testable import JamPartner

@Suite("ActionCatalog")
struct ActionCatalogTests {

    @Test("find returns correct action for valid id")
    func findValid() {
        let action = ActionCatalog.find("play_stop")
        #expect(action != nil)
        #expect(action?.label == "Play / Stop")
        #expect(action?.cc == 23)
    }

    @Test("find returns nil for unknown id")
    func findUnknown() {
        #expect(ActionCatalog.find("nonexistent") == nil)
    }

    @Test("all actions have unique ids")
    func uniqueIds() {
        let ids = ActionCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("all actions have unique CC values")
    func uniqueCCs() {
        let ccs = ActionCatalog.all.map(\.cc)
        #expect(Set(ccs).count == ccs.count)
    }

    @Test("catalog contains 13 actions")
    func actionCount() {
        #expect(ActionCatalog.all.count == 13)
    }

    @Test("CC range is 20-32")
    func ccRange() {
        for action in ActionCatalog.all {
            #expect(action.cc >= 20 && action.cc <= 32)
        }
    }
}
