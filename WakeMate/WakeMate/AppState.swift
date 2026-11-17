import Foundation
import Observation

@Observable
final class AppState {
    var showMission = false
    var activeAlarmID: String?
}
