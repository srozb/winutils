import winim/lean
import wahelper

proc trigger(eventName: string) =
  ## Trigger SetEvent() with a given eventName.
  let eName = (r"Global\" & eventName).cstring
  var hEvent = OpenEvent(EVENT_ALL_ACCESS, 0, eName)
  if not hEvent.bool:
    printError "OpenEvent"
    return
  SetEvent(hEvent)

when isMainModule:
  import cligen
  dispatch(trigger)