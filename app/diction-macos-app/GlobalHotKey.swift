import Carbon

extension Notification.Name {
    static let hotKeyPressed = Notification.Name("com.diction.hotKeyPressed")
}

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .hotKeyPressed, object: nil)
    }
    return noErr
}

func registerGlobalHotKey() {
    var eventSpec = EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
    )
    InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, &eventSpec, nil, nil)

    var ref: EventHotKeyRef?
    let id = EventHotKeyID(signature: 0x44696374, id: 1) // 'Dict'
    let superKey = UInt32(cmdKey | shiftKey | optionKey | controlKey)
    RegisterEventHotKey(UInt32(kVK_ANSI_U), superKey, id, GetApplicationEventTarget(), 0, &ref)
}
