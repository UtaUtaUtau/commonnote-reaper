-- @description Commonnote Copy
-- @version 1.0
-- @author UtaUtaUtau
-- @about
--   # Commonnote Paste
--
--   For copying selected notes to clipboard in the [commonnote](https://github.com/ExpressiveLabs/commonnote) format

local _, script_path = reaper.get_action_context()
local json = dofile(script_path:match("(.*[/\\])").."json.lua")

function get_take_resolution(take)
  -- There's no way to get the PPQ directly, so just get it by calculating from a quarter note
  return reaper.MIDI_GetPPQPosFromProjQN(take, 1) - reaper.MIDI_GetPPQPosFromProjQN(take, 0)
end

function main()
  local midi_hwnd = reaper.MIDIEditor_GetActive()
  if not midi_hwnd then
    error("MIDI Editor is not open.")
  end
  local take = reaper.MIDIEditor_GetTake(midi_hwnd)
  
  if take and reaper.TakeIsMIDI(take) then
    local data = {
      identifier = "commonnote",
      header = {
        resolution = get_take_resolution(take),
        origin = "reaper"
      }
    }
    local notes = {}
    
    local success, note_count, _, _ = reaper.MIDI_CountEvts(take)
    
    if success then
      for i = 0, note_count - 1 do
        local success, selected, muted, startpos, endpos, _, pitch, vel = reaper.MIDI_GetNote(take, i)
        if success and selected then
          table.insert(notes, {
            start = startpos,
            length = endpos - startpos,
            label = "",
            pitch = pitch,
            extra = { velocity = vel }
          })
        end
      end
      
      if #notes > 0 then
        data.notes = notes
        reaper.CF_SetClipboard(json.encode(data))
      else
        error("No notes are selected.")
      end
    else
      error("Could not retrieve MIDI events")
    end
  else
    error("Take is not MIDI???")
  end
end

local success, err = pcall(main)
if not success then
  reaper.ShowMessageBox(err, "Commonnote Copy", 0)
end

