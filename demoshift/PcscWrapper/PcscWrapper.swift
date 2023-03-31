//
//  PcscWrapper.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


enum ReaderError: Error {
    case unknown
    case readerUnavailable
    case timeout
    case cancelledByUser
    case invalidContext
}

enum NfcStopReason: UInt8 {
    case finished = 0x00
    case unknown = 0x01
    case timeout = 0x02
    case cancelledByUser = 0x03
    case noError = 0x04
}

struct Reader {
    enum ReaderType {
        case unknown
        case bt
        case nfc
        case vcr
        case usb
    }

    let name: String
    let type: ReaderType
}

class PcscWrapper {
    private enum PcscError: UInt32 {
        case noError = 0x00000000
        case cancelled = 0x80100002
        case noReaders = 0x8010002E

        var int32Value: Int32 {
            return Int32(bitPattern: self.rawValue)
        }
    }

    private class StatesHolder {
        var states: [SCARD_READERSTATE]

        init(states: [SCARD_READERSTATE]) {
            self.states = states
        }

        deinit {
            states.forEach { $0.szReader.deallocate() }
        }
    }

    private let newReaderNotification = "\\\\?PnP?\\Notification"
    private var context: SCARDCONTEXT?

    private var readersPublisher = CurrentValueSubject<[Reader], Never>([])

    var readers: AnyPublisher<[Reader], Never> {
        readersPublisher.share().eraseToAnyPublisher()
    }

    private func getLastNfcStopReason(ofHandle handle: SCARDHANDLE) -> UInt8 {
        var result = UInt8(0)
        var resultLen: DWORD = 0
        guard SCARD_S_SUCCESS == SCardControl(handle, DWORD(RUTOKEN_CONTROL_CODE_LAST_NFC_STOP_REASON), nil,
                                              0, &result, 1, &resultLen) else {
            return RUTOKEN_NFC_STOP_REASON_UNKNOWN
        }
        return result
    }

    private func allocatePointerForString(_ str: String) -> UnsafePointer<Int8> {
        let toRawString = str + "\0"
        let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int8>.stride*toRawString.utf8.count,
                                                          alignment: MemoryLayout<Int8>.alignment)
        return UnsafePointer(rawPointer.initializeMemory(as: Int8.self, from: toRawString, count: toRawString.utf8.count))
    }

    private func getReaderList() throws -> [String] {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        var readersLen = DWORD(0)
        var readerNames = [String]()

        let result = SCardListReadersA(ctx, nil, nil, &readersLen)
        guard result == PcscError.noError.int32Value else {
            return []
        }

        var rawReadersName: [Int8] = Array(repeating: Int8(0), count: Int(readersLen))
        guard SCardListReadersA(ctx, nil, &rawReadersName, &readersLen) == PcscError.noError.int32Value else {
            return []
        }

        readerNames = (String(bytes: rawReadersName.map { UInt8($0) }, encoding: .ascii) ?? "")
            .split(separator: Character("\0"))
            .filter { !$0.isEmpty }
            .map { String($0) }

        return readerNames
    }

    private func getReaderStates(for readerNames: [String]) throws -> StatesHolder {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        guard !readerNames.isEmpty else {
            return StatesHolder(states: [])
        }

        var states: [SCARD_READERSTATE] = readerNames.map { name in
            var state = SCARD_READERSTATE()
            state.szReader = allocatePointerForString(name)
            state.dwCurrentState = DWORD(SCARD_STATE_UNAWARE)
            return state
        }

        guard SCardGetStatusChangeA(ctx, 0, &states, DWORD(states.count)) == PcscError.noError.int32Value else {
            return StatesHolder(states: [])
        }

        return StatesHolder(states: states)
    }

    private func getReaderType(for reader: String) throws -> Reader.ReaderType {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        var cardHandle = SCARDHANDLE()
        var proto: UInt32 = 0

        guard SCardConnectA(ctx, reader, DWORD(SCARD_SHARE_DIRECT),
                            0, &cardHandle, &proto) == SCARD_S_SUCCESS else {
            return .unknown
        }
        defer {
            SCardDisconnect(cardHandle, 0)
        }

        var attrValue = [RUTOKEN_UNKNOWN_TYPE]
        var attrLength = UInt32(attrValue.count)
        guard SCardGetAttrib(cardHandle,
                             DWORD(SCARD_ATTR_VENDOR_IFD_TYPE),
                             &attrValue,
                             &attrLength) == SCARD_S_SUCCESS else {
            return .unknown
        }

        guard let type = attrValue.first else {
            return .unknown
        }

        switch type {
        case RUTOKEN_BT_TYPE:
            return .bt
        case RUTOKEN_NFC_TYPE:
            return .nfc
        case RUTOKEN_VCR_TYPE:
            return .vcr
        case RUTOKEN_USB_TYPE:
            return .usb
        default:
            return .unknown
        }
    }

    public func startNfc(onReader readerName: String, waitMessage: String, workMessage: String) throws {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        var handle = SCARDHANDLE()
        var activeProtocol = DWORD()

        guard SCARD_S_SUCCESS == SCardConnectA(ctx, readerName, DWORD(SCARD_SHARE_DIRECT),
                                               0, &handle, &activeProtocol) else {
            throw ReaderError.readerUnavailable
        }
        defer {
            SCardDisconnect(handle, 0)
        }

        var state = SCARD_READERSTATE()
        state.szReader = (readerName as NSString).utf8String
        state.dwCurrentState = DWORD(SCARD_STATE_EMPTY)

        let message = "\(waitMessage)\0\(workMessage)\0\0"

        guard SCARD_S_SUCCESS == SCardControl(handle, DWORD(RUTOKEN_CONTROL_CODE_START_NFC), (message as NSString).utf8String,
                                              DWORD(message.utf8.count), nil, 0, nil),
              SCARD_S_SUCCESS == SCardGetStatusChangeA(ctx, INFINITE, &state, 1) else {
                  throw ReaderError.readerUnavailable
              }

        guard (SCARD_STATE_PRESENT | SCARD_STATE_CHANGED | SCARD_STATE_INUSE) == state.dwEventState else {
            switch getLastNfcStopReason(ofHandle: handle) {
            case RUTOKEN_NFC_STOP_REASON_CANCELLED_BY_USER:
                throw ReaderError.cancelledByUser
            case RUTOKEN_NFC_STOP_REASON_TIMEOUT:
                throw ReaderError.timeout
            default:
                throw ReaderError.unknown
            }
        }
    }

    public func stopNfc(onReader readerName: String, withMessage message: String) throws {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        var handle = SCARDHANDLE()
        var activeProtocol = DWORD()

        guard SCARD_S_SUCCESS == SCardConnectA(ctx, readerName, DWORD(SCARD_SHARE_DIRECT),
                                               0, &handle, &activeProtocol) else {
            throw ReaderError.readerUnavailable
        }
        defer {
            SCardDisconnect(handle, 0)
        }

        var state = SCARD_READERSTATE()
        state.szReader = (readerName as NSString).utf8String
        state.dwCurrentState = DWORD(SCARD_STATE_EMPTY)

        guard SCARD_S_SUCCESS == SCardControl(handle, DWORD(RUTOKEN_CONTROL_CODE_STOP_NFC), (message as NSString).utf8String,
                                              DWORD(message.utf8.count), nil, 0, nil) else {
            throw ReaderError.unknown
        }
    }

    public func getLastNfcStopReason(onReader readerName: String) throws -> NfcStopReason {
        guard let ctx = self.context else {
            throw ReaderError.invalidContext
        }

        var handle = SCARDHANDLE()
        var activeProtocol = DWORD()

        guard SCARD_S_SUCCESS == SCardConnectA(ctx, readerName, DWORD(SCARD_SHARE_DIRECT),
                                               0, &handle, &activeProtocol) else {
            throw ReaderError.readerUnavailable
        }
        defer {
            SCardDisconnect(handle, 0)
        }

        return NfcStopReason(rawValue: getLastNfcStopReason(ofHandle: handle)) ?? .unknown
    }

    public func stop() {
        guard let ctx = context else {
            return
        }

        SCardCancel(ctx)
        SCardReleaseContext(ctx)
        context = nil
    }

    public func start() {
        guard context == nil else {
            return
        }

        var ctx = SCARDCONTEXT()
        guard SCardEstablishContext(DWORD(SCARD_SCOPE_USER), nil, nil, &ctx) == PcscError.noError.int32Value else {
            fatalError("Unable to create SCardEstablishContext")
        }
        context = ctx

        guard let readerNames = try? getReaderList() else {
            return
        }
        readersPublisher.send(readerNames.compactMap { name in
            guard let type = try? getReaderType(for: name) else {
                return nil
            }
            return Reader(name: name, type: type)
        })

        guard let states = try? getReaderStates(for: readerNames) else {
            return
        }
        var readerStates = states

        readerStates.states = readerStates.states.map { oldState in
            let newState = SCARD_READERSTATE(szReader: oldState.szReader,
                                             pvUserData: oldState.pvUserData,
                                             dwCurrentState: oldState.dwEventState & ~UInt32(SCARD_STATE_CHANGED),
                                             dwEventState: 0,
                                             cbAtr: oldState.cbAtr,
                                             rgbAtr: oldState.rgbAtr)
            return newState
        }

        var newReaderState = SCARD_READERSTATE()
        newReaderState.szReader = allocatePointerForString(newReaderNotification)
        readerStates.states.append(newReaderState)

        DispatchQueue.global().async { [unowned self] in
            while true {
                guard let ctx = context else {
                    return
                }

                let rv = SCardGetStatusChangeA(ctx,
                                               INFINITE,
                                               &readerStates.states,
                                               DWORD(readerStates.states.count))
                guard rv != PcscError.cancelled.int32Value else { return }
                guard rv == PcscError.noError.int32Value else { continue }

                var shouldRelistReaders = false
                for s in readerStates.states {
                    if String(cString: s.szReader) == newReaderNotification {
                        if s.dwEventState & UInt32(SCARD_STATE_CHANGED) != 0 {
                            shouldRelistReaders = true
                        }
                    } else {
                        if s.dwEventState == SCARD_STATE_UNKNOWN | SCARD_STATE_CHANGED | SCARD_STATE_IGNORE {
                            shouldRelistReaders = true
                        }
                    }
                }

                if shouldRelistReaders {
                    guard let readerNames = try? getReaderList() else {
                        return
                    }
                    readersPublisher.send(readerNames.compactMap { name in
                        guard let type = try? getReaderType(for: name) else {
                            return nil
                        }
                        return Reader(name: name, type: type)
                    })
                    guard let states = try? getReaderStates(for: readerNames) else {
                        return
                    }
                    readerStates = states
                }

                readerStates.states = readerStates.states.map { oldState in
                    let newState = SCARD_READERSTATE(szReader: oldState.szReader,
                                                     pvUserData: oldState.pvUserData,
                                                     dwCurrentState: oldState.dwEventState & ~UInt32(SCARD_STATE_CHANGED),
                                                     dwEventState: 0,
                                                     cbAtr: oldState.cbAtr,
                                                     rgbAtr: oldState.rgbAtr)
                    return newState
                }

                if shouldRelistReaders {
                    var newReaderState = SCARD_READERSTATE()
                    newReaderState.szReader = allocatePointerForString(newReaderNotification)
                    readerStates.states.append(newReaderState)
                }
            }
        }
    }
}
