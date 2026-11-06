-- @description Commonnote Paste
-- @version 1.0
-- @author UtaUtaUtau
-- @about
--   # Commonnote Paste
--
--   For pasting in [commonnote](https://github.com/ExpressiveLabs/commonnote) data into the MIDI editor

local _, script_path = reaper.get_action_context()
local json = dofile(script_path:match("(.*[/\\])").."json.lua")

function get_take_resolution(take)
  -- There's no way to get the PPQ directly, so just get it by calculating from a quarter note
  return reaper.MIDI_GetPPQPosFromProjQN(take, 1) - reaper.MIDI_GetPPQPosFromProjQN(take, 0)
end

function main()
  local data = json.decode(reaper.CF_GetClipboard())

  if data.identifier == "commonnote" then
    if #data.notes > 0 then
      -- Get MIDI Editor window
      local midi_hwnd = reaper.MIDIEditor_GetActive()
      if not midi_hwnd then
        error("MIDI Editor is not open.")
      end
      local take = reaper.MIDIEditor_GetTake(midi_hwnd)
      
      if take and reaper.TakeIsMIDI(take) then
        local resolution_factor = get_take_resolution(take) / data.header.resolution
        local chan = reaper.MIDIEditor_GetSetting_int(midi_hwnd, "default_note_chan")
        
        local data_start = math.huge
        for _, note in ipairs(data.notes) do
          data_start = math.min(data_start, note.start)
        end
        
        local paste_start = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetCursorPosition())
        
        reaper.Undo_BeginBlock()
        for _, note in ipairs(data.notes) do
          local startpos = (note.start - data_start) * resolution_factor + paste_start
          local endpos = startpos + note.length * resolution_factor
          local vel = 96
          if note.extra then
            vel = note.extra.velocity or 96
          end
          reaper.MIDI_InsertNote(take, true, false, startpos, endpos, chan, note.pitch, vel, false)
          reaper.MIDI_InsertTextSysexEvt(take, true, false, startpos, 5, note.label)
        end
        reaper.MIDI_Sort(take)
        reaper.Undo_EndBlock("Commonnote Paste", -1)
      else
        error("Take is not MIDI???")
      end
    else
      error("No notes found in commonnote data.")
    end
  else
    error("Clipboard does not contain commonnote data.")
  end
end

local success, err = pcall(main)
if not success then
  reaper.ShowMessageBox(err, "Commonnote Paste", 0)
end
