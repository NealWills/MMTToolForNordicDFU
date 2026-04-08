//
//  MMTToolForNordicDFUTool.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//

import CoreBluetooth
import Foundation

class MMTToolForNordicWeakDelegateUnit: NSObject {
    weak var weakDelegate: MMTToolForNordicDFUDelegate?

    init(weakDelegate: MMTToolForNordicDFUDelegate? = nil) {
        self.weakDelegate = weakDelegate
    }
}

public protocol MMTToolForNordicDFUDelegate: NSObject {
    func mmtToolForNordicUnitDidEnter(_ unit: MMTToolForNordicDFUUnit?)
    func mmtToolForNordicUnitDidFailToEnter(_ unit: MMTToolForNordicDFUUnit?, error: Error?)
    func mmtToolForNordicUnitDFUDidBegin(_ unit: MMTToolForNordicDFUUnit?)
    func mmtToolForNordicUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUUnit?, progress: Int)
    func mmtToolForNordicUnitDFUDidEnd(_ unit: MMTToolForNordicDFUUnit?, progress: Int?, error: Error?)
    func mmtToolForNordicUnitDidShowErrorMessage(_ unit: MMTToolForNordicDFUUnit?, stage: String?, error: Error?)

    typealias DFUServerTurple = (
        service: CBService?,
        readCharacter: CBCharacteristic?,
        writeCharacter: CBCharacteristic?,
        controlCharacter: CBCharacteristic?
    )
    func mmtToolForNordicUnitGetUUID(_ unit: MMTToolForNordicDFUUnit?) -> DFUServerTurple?

    func mmtToolForNordicUnitGetPeripheral(_ unit: MMTToolForNordicDFUUnit?) -> CBPeripheral?
}

public class MMTToolForNordicDFU: NSObject {
    static let share = MMTToolForNordicDFU()
    var multiDelegateList: [MMTToolForNordicWeakDelegateUnit] = .init()
    var unitList: [MMTToolForNordicDFUUnit] = .init()

    public class func configManager() {
        MMTToolForNordicDFUFileManager.removeTempDir()
    }

    public class func startDfu(deviceUUID: String?, deviceMac: String?, deviceMacExtra: String?, peripheral: CBPeripheral?, startAddress: String?, filePath: String?) {
        let unit = MMTToolForNordicDFUUnit()

        guard let deviceUUID = deviceUUID,
              let deviceMac = deviceMac,
              let deviceMacExtra = deviceMacExtra,
              let peripheral = peripheral
        else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "DFU Device Not Exist"))
            return
        }

        unit.deviceMac = deviceMac.uppercased()
        unit.deviceMacExtra = deviceMacExtra.uppercased()
        unit.deviceUUID = deviceUUID
        unit.localPeripheral = peripheral

        guard let filePath = filePath else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }

        if filePath.count < 4 {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        unit.dfuFilePath = filePath

        let isExist = FileManager.default.fileExists(atPath: filePath)
        if !isExist {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        MMTToolForNordicDFUFileManager.copyDFUFileToTempDir(originPath: filePath, deviceMac: deviceMac)
        guard let startAddress = startAddress else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "Start Address Unit Not Exist"))
            return
        }
        unit.startAddress = startAddress

        let isContain = MMTToolForNordicDFU.share.unitList.contains(where: {
            $0.deviceMac?.uppercased() == deviceMac.uppercased()
        }) ?? false
        if isContain {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "DFU Unit Exist"))
            return
        }
        guard let turple = MMTToolForNordicDFU.sendDelegateUnitDFUGetUUID(unit) else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "Delegate Not Exist"))
            return
        }
        guard let service = turple.service else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "Service Not Exist"))
            return
        }
        guard let readCharacter = turple.readCharacter else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "ReadCharacter Not Exist"))
            return
        }
        guard let writeCharacter = turple.writeCharacter else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "WriteCharacter Not Exist"))
            return
        }
        guard let controlCharacter = turple.controlCharacter else {
            MMTToolForNordicDFU.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFU.createError(code: -1, localDescrip: "ControlCharacter Not Exist"))
            return
        }
        unit.localServiceUUID = service.uuid.uuidString.uppercased()
        unit.localReadCharacterUUID = readCharacter.uuid.uuidString.uppercased()
        unit.localWriteCharacterUUID = writeCharacter.uuid.uuidString.uppercased()
        unit.localControlCharacterUUID = controlCharacter.uuid.uuidString.uppercased()
        unit.startTimeStamp = Date().timeIntervalSince1970
        MMTToolForNordicDFU.share.unitList.append(unit)
        MMTToolForNordicDFU.sendDelegateUnitDidEnter(unit)

        unit.dfuErrorMsgBlock = { unitId, msg, stage in
            if let toolUnit = MMTToolForNordicDFU.share.unitList.first(where: {
                $0.unitId == unitId
            }) {
//                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidChangeProgress progress: \(progress)", level: .info)
                let error = MMTToolForNordicDFU.createError(code: -1, localDescrip: msg)
                MMTToolForNordicDFU.sendDelegateUnitDFUDidShowErrorMessage(unit, stage: stage, error: error)
            }
        }

        unit.progressBlock = { unitId, progress in
            if let toolUnit = MMTToolForNordicDFU.share.unitList.first(where: {
                $0.unitId == unitId
            }) {
                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidChangeProgress progress: \(progress)", level: .info)
                MMTToolForNordicDFU.sendDelegateUnitDFUDidChangeProgress(toolUnit, progress: progress)
            }
        }

        unit.resultBlock = { unitId, progress, error in
            if let toolUnit = MMTToolForNordicDFU.share.unitList.first(where: {
                $0.unitId == unitId
            }) {
                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidEnd error: \(error)", level: .info)

                MMTToolForNordicDFU.sendDelegateUnitDFUDidEnd(toolUnit, progress: progress, error: error)

                toolUnit.destroyUnit()

                MMTToolForNordicDFU.share.unitList.removeAll {
                    $0.unitId == unitId
                }
            }
        }

        unit.startDfu()

        MMTToolForNordicLog.log("[MEOTANordicManager] mmtToolForNordicUnit Did Start DFU")
    }
}

public extension MMTToolForNordicDFU {
    class func addDelegate(_ delegate: MMTToolForNordicDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String(format: "%p", delegate)
        var list = MMTToolForNordicDFU.share.multiDelegateList
        list = list.filter {
            $0.weakDelegate != nil
        }
        if list.contains(where: {
            if let item = $0.weakDelegate {
                let id0 = String(format: "%p", item)
                return id0 == delegateId
            }
            return false
        }) {
            return
        }
        let delegateUnit = MMTToolForNordicWeakDelegateUnit(weakDelegate: delegate)
        list.append(delegateUnit)
        MMTToolForNordicDFU.share.multiDelegateList = list
    }

    class func removeDelegate(_ delegate: MMTToolForNordicDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String(format: "%p", delegate)
        var list = MMTToolForNordicDFU.share.multiDelegateList
        list = list.filter {
            guard let item = $0.weakDelegate else {
                return false
            }
            let id0 = String(format: "%p", item)
            return id0 != delegateId
        }
        MMTToolForNordicDFU.share.multiDelegateList = list
    }

    class func sendDelegateUnitDidEnter(_ unit: MMTToolForNordicDFUUnit?) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDidEnter(unit)
        }
    }

    class func sendDelegateUnitDidFailToEnter(_ unit: MMTToolForNordicDFUUnit?, error: Error?) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDidFailToEnter(unit, error: error)
        }
    }

    class func sendDelegateUnitDFUDidBegin(_ unit: MMTToolForNordicDFUUnit?) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDFUDidBegin(unit)
        }
    }

    class func sendDelegateUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUUnit?, progress: Int) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDFUDidChangeProgress(unit, progress: progress)
        }
    }

    class func sendDelegateUnitDFUDidEnd(_ unit: MMTToolForNordicDFUUnit?, progress: Int?, error: Error?) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDFUDidEnd(unit, progress: progress, error: error)
        }
    }

    class func sendDelegateUnitDFUDidShowErrorMessage(_ unit: MMTToolForNordicDFUUnit?, stage: String?, error: Error?) {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        for item in list {
            item.weakDelegate?.mmtToolForNordicUnitDidShowErrorMessage(unit, stage: stage, error: error)
        }
    }

    class func sendDelegateUnitDFUGetUUID(_ unit: MMTToolForNordicDFUUnit?) -> MMTToolForNordicDFUDelegate.DFUServerTurple? {
        let list = MMTToolForNordicDFU.share.multiDelegateList
        let turpleList: [MMTToolForNordicDFUDelegate.DFUServerTurple?] = list.map {
            $0.weakDelegate?.mmtToolForNordicUnitGetUUID(unit)
        }.filter {
            $0 != nil
        }
        return turpleList.first ?? nil
    }

    class func createError(code: Int, localDescrip: String) -> NSError {
        var userInfo: [String: Any] = .init()
        userInfo[NSLocalizedDescriptionKey] = localDescrip
        return NSError(domain: "com.mmt.sdk.NordicDFUTool.error", code: code, userInfo: userInfo)
    }
}
