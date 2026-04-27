extends Node

signal zone_entered(zone_id: String)

# TODO: WORLD-02 — call ZoneTracker.enter_zone() from each zone scene's _ready
# once the Ruins of Veld and other zone scenes are implemented.

func enter_zone(zone_id: String) -> void:
	zone_entered.emit(zone_id)
	QuestManager.report_event(&"zone_entered", 1, {"zone_id": zone_id})
	print("[ZoneTracker] Entered zone: %s" % zone_id)
