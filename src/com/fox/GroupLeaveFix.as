import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.TeamInterface;
import com.Utils.ID32;
import mx.utils.Delegate;

class com.fox.GroupLeaveFix
{
	public static var team:Team;
	public static var raid:Raid;

	public static function main(swfRoot:MovieClip):Void
	{
		var s_app:GroupLeaveFix = new GroupLeaveFix(swfRoot);
		swfRoot.onLoad = function() {s_app.OnLoad()};
		swfRoot.onUnload = function() {s_app.OnUnload()};
	}

	public function GroupLeaveFix() { }

	public function OnLoad()
	{
		var signallers = _global.EffectMonitor.Logic.Signallers;
		if ( !signallers.CharacterSignalWrapper.prototype.GetTeam || !signallers.EverybodyEnumerator.prototype.GetEverybody)
		{
			// long retry attempt, in case someone for some reason tries to use the mod without effectsUI
			setTimeout(Delegate.create(this, OnLoad), 5000);
			return;
		}
		if ( signallers.CharacterSignalWrapper.GroupLeaveFixHook)
		{
			return;
		}

		TeamInterface.SignalClientJoinedTeam.Connect(SlotClientJoinedTeam, this);
		TeamInterface.SignalClientLeftTeam.Connect(SlotClientLeftTeam, this);
		TeamInterface.SignalClientJoinedRaid.Connect(SlotClientJoinedRaid, this);
		TeamInterface.SignalClientLeftRaid.Connect(SlotClientLeftRaid, this);

	// GetTeam creates a new Team object
		var org = signallers.CharacterSignalWrapper.prototype.GetTeam;
		var f:Function = function()
		{
			var id:ID32 = this.m_character.GetID();
			if ( GroupLeaveFix.team && TeamInterface.IsInClientTeam(id))
			{
				// prevent effectUI from creating new Team() object
				return GroupLeaveFix.team;
			}
			if ( GroupLeaveFix.raid && TeamInterface.IsInClientRaid(id))
			{
				for (var key in GroupLeaveFix.raid.m_Teams)
				{
					// // prevent effectUI from creating new Team() object
					var team = GroupLeaveFix.raid.m_Teams[key];
					if ( team.IsTeamMember(id)) return team;
				}
			}
			return org.apply(this, arguments);
		}
		signallers.CharacterSignalWrapper.prototype.GetTeam = f;

	// GetEveryBody creates a new Team object temporarily, it might not get garbage collected right away
		var org2 = signallers.EverybodyEnumerator.prototype.GetEverybody;
		var getEverybody:Function = function()
		{
			var id:ID32 = CharacterBase.GetClientCharID();
			if ( !GroupLeaveFix.team || TeamInterface.IsInRaid(id) || !TeamInterface.IsInTeam(id))
			{
				// if player is in raid effectsUI gets team members through signallers.RaidEnumerator.Instance instead
				return org2.apply(this, arguments);
			}
			var members:Array = new Array();
			for (var i:Number = 0; i < 5; i++)
			{
				var memberId:ID32 = GroupLeaveFix.team.GetTeamMemberID(i);
				if ( memberId != null && !memberId.IsNull()) members.push(Character.GetCharacter(memberId));
			}
			return members;
		}
		signallers.EverybodyEnumerator.prototype.GetEverybody = getEverybody;

		signallers.CharacterSignalWrapper.GroupLeaveFixHook = true;
		TeamInterface.RequestTeamInformation();
	}
	
	public function OnUnload()
	{
		TeamInterface.SignalClientJoinedTeam.Disconnect(SlotClientJoinedTeam, this);
		TeamInterface.SignalClientLeftTeam.Disconnect(SlotClientLeftTeam, this);
		TeamInterface.SignalClientJoinedRaid.Disconnect(SlotClientJoinedRaid, this);
		TeamInterface.SignalClientLeftRaid.Disconnect(SlotClientLeftRaid, this);
	}

	private function SlotClientJoinedTeam(t:Team) { team = t; }
	private function SlotClientLeftTeam() { team = undefined; }
	private function SlotClientJoinedRaid(r:Raid) { raid = r; }
	private function SlotClientLeftRaid() { raid = undefined; }
}
